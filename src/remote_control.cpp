#include "remote_control.h"

#include "player_controller.h"

#include <QEventLoop>
#include <QHostAddress>
#include <QJsonDocument>
#include <QNetworkInterface>
#include <QRandomGenerator>
#include <QTcpSocket>
#include <QTimer>

#include <algorithm>
#include <cmath>

namespace {
constexpr quint16 kPreferredPort = 47800;
constexpr qsizetype kMaxHeaderBytes = 8 * 1024;
constexpr qsizetype kMaxBodyBytes = 4 * 1024;
constexpr int kMaxFailedAttempts = 10;
constexpr qint64 kLockoutMs = 60 * 1000;
// Same alphabet as the Android listening room codes, without look-alike characters.
constexpr char kCodeAlphabet[] = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

bool isLocalPeer(const QHostAddress &peer) {
    bool isV4 = false;
    const QHostAddress address(peer.toIPv4Address(&isV4));
    const QHostAddress &checked = isV4 ? address : peer;
    return checked.isLoopback() || checked.isPrivateUse() || checked.isLinkLocal();
}

QString localIpv4() {
    QString fallback;
    for (const QNetworkInterface &interface : QNetworkInterface::allInterfaces()) {
        const auto flags = interface.flags();
        if (!flags.testFlag(QNetworkInterface::IsUp) || !flags.testFlag(QNetworkInterface::IsRunning) ||
            flags.testFlag(QNetworkInterface::IsLoopBack) || interface.type() == QNetworkInterface::Virtual)
            continue;
        for (const QNetworkAddressEntry &entry : interface.addressEntries()) {
            const QHostAddress ip = entry.ip();
            if (ip.protocol() != QAbstractSocket::IPv4Protocol || !ip.isPrivateUse())
                continue;
            // Home routers hand out 192.168.x; 172.x is usually a VM or WSL adapter.
            if (ip.toString().startsWith("192.168."))
                return ip.toString();
            if (fallback.isEmpty())
                fallback = ip.toString();
        }
    }
    return fallback;
}

QByteArray reasonPhrase(int status) {
    switch (status) {
    case 200:
        return "OK";
    case 400:
        return "Bad Request";
    case 401:
        return "Unauthorized";
    case 403:
        return "Forbidden";
    case 404:
        return "Not Found";
    case 413:
        return "Payload Too Large";
    default:
        return "Too Many Requests";
    }
}
} // namespace

RemoteControlServer::RemoteControlServer(PlayerController *player, QObject *parent)
    : QObject(parent), m_player(player) {
    connect(&m_server, &QTcpServer::pendingConnectionAvailable, this, [this] {
        while (QTcpSocket *socket = m_server.nextPendingConnection())
            serve(socket);
    });
}

bool RemoteControlServer::enabled() const {
    return m_enabled;
}

void RemoteControlServer::setEnabled(bool enabled) {
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    if (enabled) {
        if (m_code.isEmpty())
            regenerateCode();
        if (!m_server.listen(QHostAddress::Any, kPreferredPort) && !m_server.listen(QHostAddress::Any))
            qWarning().noquote() << "Phone remote could not listen:" << m_server.errorString();
    } else {
        m_server.close();
        m_failedAttempts = 0;
    }
    emit enabledChanged();
    emit addressChanged();
}

QString RemoteControlServer::code() const {
    return m_code;
}

void RemoteControlServer::setCode(const QString &code) {
    if (m_code == code)
        return;
    m_code = code;
    emit codeChanged();
}

QString RemoteControlServer::address() const {
    if (!m_server.isListening())
        return {};
    const QString ip = localIpv4();
    return ip.isEmpty() ? QString() : ip + ':' + QString::number(m_server.serverPort());
}

void RemoteControlServer::regenerateCode() {
    QString code;
    for (int i = 0; i < 6; ++i)
        code += QChar(kCodeAlphabet[QRandomGenerator::system()->bounded(int(sizeof(kCodeAlphabet) - 1))]);
    setCode(code);
}

void RemoteControlServer::serve(QTcpSocket *socket) {
    connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
    QTimer::singleShot(5000, socket, &QTcpSocket::abort);
    connect(socket, &QTcpSocket::readyRead, socket, [this, socket] {
        const QByteArray data = socket->peek(socket->bytesAvailable());
        const qsizetype headerEnd = data.indexOf("\r\n\r\n");
        if (headerEnd < 0) {
            if (data.size() > kMaxHeaderBytes)
                socket->abort();
            return;
        }
        const QList<QByteArray> lines = data.left(headerEnd).split('\n');
        const QList<QByteArray> requestLine = lines.first().trimmed().split(' ');
        QByteArray authorization;
        qsizetype contentLength = 0;
        for (const QByteArray &line : lines.mid(1)) {
            const qsizetype colon = line.indexOf(':');
            const QByteArray name = line.left(colon).trimmed().toLower();
            if (name == "authorization")
                authorization = line.mid(colon + 1).trimmed();
            else if (name == "content-length")
                contentLength = line.mid(colon + 1).trimmed().toLongLong();
        }

        Response response{413, {}};
        if (contentLength >= 0 && contentLength <= kMaxBodyBytes) {
            if (data.size() < headerEnd + 4 + contentLength)
                return;
            if (requestLine.size() < 2)
                response = {400, {}};
            else
                response = respond(requestLine[0], requestLine[1], authorization,
                                   data.mid(headerEnd + 4, contentLength), socket->peerAddress());
        }
        socket->readAll();
        const QByteArray body = !response.body.isEmpty() ? response.body
                                : response.status == 200 ? QByteArray(R"({"ok":true})")
                                                         : QByteArray(R"({"ok":false})");
        socket->write("HTTP/1.1 " + QByteArray::number(response.status) + ' ' + reasonPhrase(response.status) +
                      "\r\nContent-Type: application/json\r\nContent-Length: " + QByteArray::number(body.size()) +
                      "\r\nConnection: close\r\n\r\n" + body);
        socket->disconnectFromHost();
    });
}

RemoteControlServer::Response RemoteControlServer::respond(const QByteArray &method, const QByteArray &path,
                                                           const QByteArray &authorization, const QByteArray &body,
                                                           const QHostAddress &peer) {
    if (!isLocalPeer(peer))
        return {403, {}};
    if (m_lockedSince.isValid() && m_lockedSince.elapsed() < kLockoutMs)
        return {429, {}};
    if (m_code.isEmpty() || authorization != "Bearer " + m_code.toLatin1()) {
        if (++m_failedAttempts >= kMaxFailedAttempts) {
            m_failedAttempts = 0;
            m_lockedSince.start();
        }
        return {401, {}};
    }
    m_failedAttempts = 0;

    if (method == "GET" && path == "/api/playback")
        return {200, QJsonDocument(status()).toJson(QJsonDocument::Compact)};
    if (method != "POST")
        return {404, {}};

    const QJsonObject request = QJsonDocument::fromJson(body).object();
    if (path == "/api/playback") {
        const QString action = request.value("action").toString();
        if (action == "play")
            emit playRequested();
        else if (action == "pause")
            emit pauseRequested();
        else if (action == "next")
            emit nextRequested();
        else if (action == "previous")
            emit previousRequested();
        else if (action == "toggle_shuffle")
            emit shuffleToggleRequested();
        else if (action == "cycle_repeat")
            emit repeatCycleRequested();
        else
            return {400, {}};
        return {200, {}};
    }
    if (path == "/api/volume" && request.contains("percent")) {
        emit volumeRequested(qBound(0, request.value("percent").toInt(), 100) / 100.0);
        return {200, {}};
    }
    if (path == "/api/seek" && request.contains("positionMs")) {
        emit seekRequested(qMax<qint64>(0, request.value("positionMs").toInteger()));
        return {200, {}};
    }
    return {404, {}};
}

QJsonObject RemoteControlServer::status() const {
    const QVariantMap track = m_player->currentTrack();
    const QString title = track.value("title").toString();
    return {
        {"isPlaying", m_player->isPlaying()},
        {"trackTitle", title.isEmpty() ? track.value("fileName").toString() : title},
        {"trackArtist", track.value("artist").toString()},
        {"positionMs", m_player->position()},
        {"durationMs", m_player->duration()},
        {"volumePercent", int(std::lround(m_player->volume() * 100))},
        {"shuffleEnabled", m_player->shuffleEnabled()},
        {"repeatMode", m_repeatMode},
    };
}

bool RemoteControlServer::selfCheck() {
    PlayerController player;
    RemoteControlServer remote(&player);
    remote.setCode("ABC234");
    const QHostAddress lan("192.168.1.20");
    const QByteArray auth = "Bearer ABC234";
    int nextCount = 0;
    double volume = -1;
    connect(&remote, &RemoteControlServer::nextRequested, [&] { ++nextCount; });
    connect(&remote, &RemoteControlServer::volumeRequested, [&](double value) { volume = value; });

    const bool rejectsPublicPeer =
        remote.respond("GET", "/api/playback", auth, {}, QHostAddress("8.8.8.8")).status == 403;
    const bool rejectsWrongCode = remote.respond("GET", "/api/playback", "Bearer XYZ999", {}, lan).status == 401;
    const Response status = remote.respond("GET", "/api/playback", auth, {}, lan);
    const QJsonObject payload = QJsonDocument::fromJson(status.body).object();
    // Android's DevicePlaybackStatus has no defaults, so every field must be present.
    const QStringList statusFields = {"isPlaying",  "trackTitle",    "trackArtist",    "positionMs",
                                      "durationMs", "volumePercent", "shuffleEnabled", "repeatMode"};
    const bool reportsStatus =
        status.status == 200 && std::all_of(statusFields.begin(), statusFields.end(),
                                            [&](const QString &field) { return payload.contains(field); });
    const bool routesNext =
        remote.respond("POST", "/api/playback", auth, R"({"action":"next"})", lan).status == 200 && nextCount == 1;
    const bool clampsVolume =
        remote.respond("POST", "/api/volume", auth, R"({"percent":140})", lan).status == 200 && volume == 1.0;
    const bool rejectsUnknownAction =
        remote.respond("POST", "/api/playback", auth, R"({"action":"reset"})", lan).status == 400;

    remote.setEnabled(true);
    QTcpSocket client;
    QByteArray reply;
    QEventLoop loop;
    QTimer::singleShot(3000, &loop, &QEventLoop::quit);
    connect(&client, &QTcpSocket::readyRead, &loop, [&] { reply += client.readAll(); });
    connect(&client, &QTcpSocket::disconnected, &loop, &QEventLoop::quit);
    client.connectToHost(QHostAddress::LocalHost, remote.m_server.serverPort());
    client.write("POST /api/playback HTTP/1.1\r\nAuthorization: Bearer ABC234\r\nContent-Length: 17\r\n\r\n");
    client.write(R"({"action":"next"})");
    loop.exec();
    remote.setEnabled(false);
    const bool servesHttp = reply.startsWith("HTTP/1.1 200 OK") && reply.endsWith(R"({"ok":true})") && nextCount == 2;

    for (int i = 0; i < kMaxFailedAttempts; ++i)
        remote.respond("GET", "/api/playback", "Bearer WRONG1", {}, lan);
    const bool locksOutGuessing = remote.respond("GET", "/api/playback", auth, {}, lan).status == 429;

    const bool ok = rejectsPublicPeer && rejectsWrongCode && reportsStatus && routesNext && clampsVolume &&
                    rejectsUnknownAction && servesHttp && locksOutGuessing;
    if (!ok)
        qWarning() << "Remote control self-check failed:" << rejectsPublicPeer << rejectsWrongCode << reportsStatus
                   << routesNext << clampsVolume << rejectsUnknownAction << servesHttp << locksOutGuessing;
    return ok;
}
