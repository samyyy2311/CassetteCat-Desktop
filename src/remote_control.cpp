#include "remote_control.h"

#include "app_paths.h"
#include "audio_metadata.h"
#include "library_controller.h"
#include "player_controller.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QEventLoop>
#include <QFile>
#include <QFileInfo>
#include <QHostAddress>
#include <QJsonArray>
#include <QJsonDocument>
#include <QNetworkInformation>
#include <QNetworkInterface>
#include <QNetworkDatagram>
#include <QRandomGenerator>
#include <QSaveFile>
#include <QSet>
#include <QSysInfo>
#include <QTemporaryDir>
#include <QTcpSocket>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

#include <algorithm>
#include <memory>
#include <utility>
#include <cmath>

namespace {
constexpr quint16 kPreferredPort = 47800;
// The phone broadcasts this on UDP kPreferredPort; the reply names this computer and its HTTP port.
constexpr char kDiscoveryProbe[] = "CASSETTECAT_DISCOVER";
constexpr qsizetype kMaxHeaderBytes = 8 * 1024;
// Large enough for a hand-off carrying the phone's queue.
constexpr qsizetype kMaxBodyBytes = 64 * 1024;
// A phone backup carries playlist covers as well as settings and listening stats.
constexpr qsizetype kMaxBackupBytes = 16 * 1024 * 1024;
constexpr int kMaxFailedAttempts = 10;
constexpr qint64 kLockoutMs = 60 * 1000;
// Same alphabet as the Android listening room codes, without look-alike characters.
constexpr char kCodeAlphabet[] = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

// Keeps the backup it replaces beside it, so one bad backup cannot wipe out the last good one.
bool saveBackup(const QString &path, const QByteArray &backup) {
    const QString previous = path + ".previous";
    if (QFile::exists(path)) {
        QFile::remove(previous);
        QFile::copy(path, previous);
    }
    QSaveFile file(path);
    return file.open(QIODevice::WriteOnly) && file.write(backup) == backup.size() && file.commit();
}

// Matches a track across this computer and the phone the way the phone does: by title and artist, ignoring case.
QString matchKey(const QVariantMap &track) {
    const QString title = track.value("title").toString().trimmed();
    return (title.isEmpty() ? track.value("fileName").toString().trimmed() : title).toLower() + QChar(0x1f) +
           track.value("artist").toString().trimmed().toLower();
}

// A stable id for a library track that doesn't reveal its path to the phone.
QString libraryId(const QVariantMap &track) {
    return QString::fromLatin1(
        QCryptographicHash::hash(track.value("filePath").toString().toUtf8(), QCryptographicHash::Sha1)
            .toHex()
            .left(16));
}

QByteArray audioContentType(const QString &path) {
    const QString suffix = QFileInfo(path).suffix().toLower();
    if (suffix == "mp3")
        return "audio/mpeg";
    if (suffix == "flac")
        return "audio/flac";
    if (suffix == "m4a" || suffix == "mp4" || suffix == "alac" || suffix == "aac")
        return "audio/mp4";
    if (suffix == "ogg" || suffix == "opus")
        return "audio/ogg";
    if (suffix == "wav")
        return "audio/wav";
    return "application/octet-stream";
}

QString randomCode() {
    QString code;
    for (int i = 0; i < 6; ++i)
        code += QChar(kCodeAlphabet[QRandomGenerator::system()->bounded(int(sizeof(kCodeAlphabet) - 1))]);
    return code;
}

bool isLocalPeer(const QHostAddress &peer) {
    bool isV4 = false;
    const QHostAddress address(peer.toIPv4Address(&isV4));
    const QHostAddress &checked = isV4 ? address : peer;
    return checked.isLoopback() || checked.isPrivateUse() || checked.isLinkLocal();
}

QString localIpv4() {
    // The adapter holding the default route is the one on the home network; a hotspot or VM adapter can also have a
    // 192.168 address. Connecting a UDP socket only picks the route and sends nothing.
    QUdpSocket route;
    route.connectToHost(QHostAddress(QStringLiteral("192.0.2.1")), 9);
    if (route.waitForConnected(100) && route.localAddress().isPrivateUse())
        return route.localAddress().toString();

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

// Identifies a track's cover for the phone without sending it the file path; changes when the cover does.
QString artworkKey(const QVariantMap &track) {
    // A local song's cover is read from its file, while its artworkUrl is filled in only once it plays, so the
    // path alone keeps the key the same in the queue and when the song comes up.
    const QString filePath = track.value("filePath").toString();
    const QString source = filePath.isEmpty() ? track.value("artworkUrl").toString() : filePath;
    // The size is part of the key so phones holding an earlier, smaller copy fetch the new one.
    return source.isEmpty() ? QString() : QString::number(qHash(source + QString::number(kFullArtworkSize)), 16);
}

// The phone shows covers full screen. A cover the user picked is its own file and goes as it is; any other cover
// comes out of the music file, at full size.
QString artworkPath(const QVariantMap &track) {
    const QString filePath = track.value("filePath").toString();
    const QUrl shown(track.value("artworkUrl").toString());
    const bool extracted = shown.isEmpty() || !shown.isLocalFile() ||
                           shown.toString() == extractEmbeddedArtwork(filePath) ||
                           shown.toString() == extractEmbeddedArtwork(filePath, kFullArtworkSize);
    if (!extracted)
        return QFileInfo::exists(shown.toLocalFile()) ? shown.toLocalFile() : QString();
    if (!QFileInfo::exists(filePath))
        return {};
    const QUrl full(extractEmbeddedArtwork(filePath, kFullArtworkSize));
    return full.isLocalFile() ? full.toLocalFile() : QString();
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
    case 409:
        return "Conflict";
    case 413:
        return "Payload Too Large";
    case 500:
        return "Internal Server Error";
    default:
        return "Too Many Requests";
    }
}
} // namespace

RemoteControlServer::RemoteControlServer(PlayerController *player, LibraryController *library, QObject *parent)
    : QObject(parent), m_player(player), m_library(library) {
    connect(this, &RemoteControlServer::favoritePathsChanged, this, [this] { ++m_likesRevision; });
    connect(m_library, &LibraryController::tracksChanged, this, [this] { ++m_likesRevision; });
    connect(&m_server, &QTcpServer::pendingConnectionAvailable, this, [this] {
        while (QTcpSocket *socket = m_server.nextPendingConnection())
            serve(socket);
    });
    // The address shown for pairing follows the computer joining, leaving or switching networks.
    // A router can also hand out a new address without the connection dropping, so it is checked now and then too.
    m_pairingTimeout.setSingleShot(true);
    connect(&m_pairingTimeout, &QTimer::timeout, this, [this] {
        if (m_pairingAnswer == PairingAnswer::Waiting) {
            answerPairing(false);
            return;
        }
        m_pairingRequestId.clear();
        m_pairingRequestName.clear();
        m_pairingAnswer = PairingAnswer::Waiting;
    });
    m_addressCheck.setInterval(15 * 1000);
    connect(&m_addressCheck, &QTimer::timeout, this, &RemoteControlServer::checkAddress);
    if (QNetworkInformation::loadDefaultBackend())
        connect(QNetworkInformation::instance(), &QNetworkInformation::reachabilityChanged, this,
                &RemoteControlServer::checkAddress);
    else
        qWarning() << "Phone remote cannot follow network changes on this system";
    m_controllerTimeout.setSingleShot(true);
    m_controllerTimeout.setInterval(12 * 1000);
    connect(&m_controllerTimeout, &QTimer::timeout, this, [this] {
        m_controllerName.clear();
        m_handoffToPhone = false;
        emit controllerChanged();
    });
    m_phoneTimeout.setSingleShot(true);
    connect(&m_phoneTimeout, &QTimer::timeout, this, [this] {
        m_phonePlayback.clear();
        m_phoneCommands.clear();
        emit phonePlaybackChanged();
    });
    connect(&m_discovery, &QUdpSocket::readyRead, this, [this] {
        while (m_discovery.hasPendingDatagrams()) {
            const QNetworkDatagram datagram = m_discovery.receiveDatagram(64);
            const QByteArray reply = discoveryReply(datagram.data(), datagram.senderAddress());
            if (!reply.isEmpty())
                m_discovery.writeDatagram(datagram.makeReply(reply));
        }
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
        if (!m_discovery.bind(QHostAddress::AnyIPv4, kPreferredPort, QUdpSocket::ShareAddress))
            qWarning().noquote() << "Phone remote cannot be found automatically:" << m_discovery.errorString();
    } else {
        m_server.close();
        m_discovery.close();
        m_failedAttempts = 0;
    }
    if (enabled)
        m_addressCheck.start();
    else
        m_addressCheck.stop();
    emit enabledChanged();
    checkAddress();
}

void RemoteControlServer::checkAddress() {
    const QString current = address();
    if (current == m_lastAddress)
        return;
    m_lastAddress = current;
    emit addressChanged();
}

QString RemoteControlServer::controllerName() const {
    return m_controllerName;
}

void RemoteControlServer::continueOnPhone() {
    if (!m_controllerName.isEmpty())
        m_handoffToPhone = true;
}

QVariantMap RemoteControlServer::phonePlayback() const {
    return m_phonePlayback;
}

void RemoteControlServer::sendToPhone(const QString &command) {
    if (m_phonePlayback.isEmpty())
        return;
    // Dragging a slider sends many values; only the last one matters.
    const QString kind = command.section(':', 0, 0) + ':';
    if (command.contains(':'))
        m_phoneCommands.removeIf([&](const QString &queued) { return queued.startsWith(kind); });
    if (m_phoneCommands.size() < 8)
        m_phoneCommands.append(command);
}

QString RemoteControlServer::pairingRequest() const {
    return m_pairingAnswer == PairingAnswer::Waiting ? m_pairingRequestName : QString();
}

void RemoteControlServer::answerPairing(bool allow) {
    if (m_pairingRequestId.isEmpty() || m_pairingAnswer != PairingAnswer::Waiting)
        return;
    m_pairingAnswer = allow ? PairingAnswer::Allowed : PairingAnswer::Denied;
    // The asking phone checks every second, so its answer is kept only briefly before the next phone can ask.
    m_pairingTimeout.start(10 * 1000);
    emit pairingRequestChanged();
}

void RemoteControlServer::playNextOnPhone(const QString &title, const QString &artist) {
    if (!m_phonePlayback.isEmpty() && m_phonePlayNext.size() < 8)
        m_phonePlayNext.append(QJsonObject{{"title", title}, {"artist", artist}});
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

QString RemoteControlServer::computerName() const {
    return QSysInfo::machineHostName();
}

QVariantList RemoteControlServer::pairedPhones() const {
    return m_pairedPhones;
}

void RemoteControlServer::setPairedPhones(const QVariantList &phones) {
    if (m_pairedPhones == phones)
        return;
    m_pairedPhones = phones;
    emit pairedPhonesChanged();
}

void RemoteControlServer::unpairPhone(const QString &code) {
    QVariantList phones = m_pairedPhones;
    phones.removeIf([&](const QVariant &phone) { return phone.toMap().value("code") == code; });
    setPairedPhones(phones);
}

bool RemoteControlServer::acceptsCode(const QByteArray &code) const {
    if (code.isEmpty())
        return false;
    if (code == m_code.toLatin1())
        return true;
    return std::any_of(m_pairedPhones.cbegin(), m_pairedPhones.cend(), [&](const QVariant &phone) {
        return phone.toMap().value("code").toString().toLatin1() == code;
    });
}

void RemoteControlServer::regenerateCode() {
    setCode(randomCode());
}

void RemoteControlServer::serve(QTcpSocket *socket) {
    connect(socket, &QTcpSocket::disconnected, socket, &QObject::deleteLater);
    auto *deadline = new QTimer(socket);
    deadline->setSingleShot(true);
    connect(deadline, &QTimer::timeout, socket, &QTcpSocket::abort);
    deadline->start(5000);
    connect(socket, &QTcpSocket::readyRead, socket, [this, socket, deadline, requestBytes = qsizetype(0)]() mutable {
        // A backup arrives in many chunks; wait for all of it instead of re-reading what is buffered each time.
        if (socket->bytesAvailable() < requestBytes)
            return;
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
        QByteArray deviceName;
        QByteArray range;
        qsizetype contentLength = 0;
        for (const QByteArray &line : lines.mid(1)) {
            const qsizetype colon = line.indexOf(':');
            const QByteArray name = line.left(colon).trimmed().toLower();
            if (name == "authorization")
                authorization = line.mid(colon + 1).trimmed();
            else if (name == "x-device-name")
                deviceName = line.mid(colon + 1).trimmed().left(64);
            else if (name == "content-length")
                contentLength = line.mid(colon + 1).trimmed().toLongLong();
            else if (name == "range")
                range = line.mid(colon + 1).trimmed();
        }

        const QByteArray target = requestLine.value(1);
        const qsizetype maxBodyBytes =
            target == "/api/backup" || target == "/api/likes" || target == "/api/playlists" || target == "/api/listens"
                ? kMaxBackupBytes
                : kMaxBodyBytes;
        Response response{413, {}};
        // Only a paired phone may make the server wait for and hold a large upload.
        if (contentLength > kMaxBodyBytes &&
            !(authorization.startsWith("Bearer ") && acceptsCode(authorization.mid(7))))
            response = respond(requestLine.value(0), requestLine.value(1), authorization, {}, socket->peerAddress(),
                               deviceName);
        else if (contentLength >= 0 && contentLength <= maxBodyBytes) {
            requestBytes = headerEnd + 4 + contentLength;
            if (data.size() < requestBytes)
                return;
            if (requestLine.size() < 2)
                response = {400, {}};
            else
                response = respond(requestLine[0], requestLine[1], authorization,
                                   data.mid(headerEnd + 4, contentLength), socket->peerAddress(), deviceName);
        }
        socket->readAll();
        if (!response.filePath.isEmpty()) {
            deadline->stop();
            streamFile(socket, response, range);
            return;
        }
        const QByteArray body = !response.body.isEmpty() ? response.body
                                : response.status == 200 ? QByteArray(R"({"ok":true})")
                                                         : QByteArray(R"({"ok":false})");
        socket->write("HTTP/1.1 " + QByteArray::number(response.status) + ' ' + reasonPhrase(response.status) +
                      "\r\nContent-Type: " + response.contentType + "\r\nContent-Length: " +
                      QByteArray::number(body.size()) + "\r\nConnection: close\r\n\r\n" + body);
        socket->disconnectFromHost();
    });
}

void RemoteControlServer::streamFile(QTcpSocket *socket, const Response &response, const QByteArray &range) {
    auto *file = new QFile(response.filePath, socket);
    if (!file->open(QIODevice::ReadOnly)) {
        socket->write("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
        socket->disconnectFromHost();
        return;
    }
    const qint64 size = file->size();
    qint64 start = 0;
    qint64 end = size - 1;
    // Only the single "bytes=start-[end]" form; the phone's player never asks for more than one range.
    const bool partial = range.startsWith("bytes=") && !range.contains(',');
    if (partial) {
        const QList<QByteArray> bounds = range.mid(6).split('-');
        start = bounds.value(0).toLongLong();
        if (!bounds.value(1).isEmpty())
            end = qMin(end, bounds.value(1).toLongLong());
    }
    if (start < 0 || start > end || start >= size) {
        socket->write("HTTP/1.1 416 Range Not Satisfiable\r\nContent-Range: bytes */" + QByteArray::number(size) +
                      "\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
        socket->disconnectFromHost();
        return;
    }
    file->seek(start);
    QByteArray header = partial ? "HTTP/1.1 206 Partial Content\r\nContent-Range: bytes " + QByteArray::number(start) +
                                      '-' + QByteArray::number(end) + '/' + QByteArray::number(size) + "\r\n"
                                : QByteArray("HTTP/1.1 200 OK\r\n");
    header += "Content-Type: " + response.contentType + "\r\nContent-Length: " + QByteArray::number(end - start + 1) +
              "\r\nAccept-Ranges: bytes\r\nConnection: close\r\n\r\n";
    socket->write(header);
    // Sent in chunks as the socket drains, so a long song never sits in memory at once.
    auto remaining = std::make_shared<qint64>(end - start + 1);
    const auto pump = [socket, file, remaining] {
        while (*remaining > 0 && socket->bytesToWrite() < 256 * 1024) {
            const QByteArray chunk = file->read(qMin<qint64>(64 * 1024, *remaining));
            if (chunk.isEmpty())
                break;
            *remaining -= chunk.size();
            socket->write(chunk);
        }
        if (*remaining <= 0 || file->atEnd())
            socket->disconnectFromHost();
    };
    connect(socket, &QTcpSocket::bytesWritten, socket, pump);
    pump();
}

RemoteControlServer::Response RemoteControlServer::respond(const QByteArray &method, const QByteArray &target,
                                                           const QByteArray &authorization, const QByteArray &body,
                                                           const QHostAddress &peer, const QByteArray &deviceName) {
    const QUrl url(QString::fromLatin1(target));
    const QByteArray path = url.path().toLatin1();
    // The phone's image loader and media player cannot send headers, so artwork and audio streams also take the
    // code in the query, the way Jellyfin artwork URLs carry their key.
    const bool artworkRequest = method == "GET" && path == "/api/artwork";
    const bool streamRequest = method == "GET" && path == "/api/stream";
    const QByteArray code =
        authorization.startsWith("Bearer ")
            ? authorization.mid(7)
            : (artworkRequest || streamRequest ? QUrlQuery(url).queryItemValue("code").toLatin1() : QByteArray());
    if (!isLocalPeer(peer))
        return {403, {}};
    if (m_lockedSince.isValid() && m_lockedSince.elapsed() < kLockoutMs)
        return {429, {}};
    // Asking to pair needs no code: the person at this computer allows or denies it.
    if (path == "/api/pair-request") {
        if (method == "POST") {
            const QString name =
                QString::fromUtf8(QJsonDocument::fromJson(body).object().value("name").toString().toUtf8().left(64));
            if (name.trimmed().isEmpty())
                return {400, {}};
            if (!m_pairingRequestId.isEmpty())
                return {409, {}};
            m_pairingRequestId = QString::number(QRandomGenerator::system()->generate64(), 16) +
                                 QString::number(QRandomGenerator::system()->generate64(), 16);
            m_pairingRequestName = name.trimmed();
            m_pairingAnswer = PairingAnswer::Waiting;
            m_pairingTimeout.start(60 * 1000);
            emit pairingRequestChanged();
            return {200, QJsonDocument(QJsonObject{{"id", m_pairingRequestId}}).toJson(QJsonDocument::Compact)};
        }
        if (m_pairingRequestId.isEmpty() || QUrlQuery(url).queryItemValue("id") != m_pairingRequestId)
            return {404, {}};
        if (m_pairingAnswer == PairingAnswer::Waiting)
            return {200, R"({"status":"waiting"})"};
        const bool allowed = m_pairingAnswer == PairingAnswer::Allowed;
        const QString phoneCode = allowed ? randomCode() : QString();
        if (allowed) {
            // A phone allowed again replaces its old entry, so it is listed once.
            QVariantList phones = m_pairedPhones;
            phones.removeIf([&](const QVariant &phone) { return phone.toMap().value("name") == m_pairingRequestName; });
            setPairedPhones(phones + QVariantList{QVariantMap{{"name", m_pairingRequestName}, {"code", phoneCode}}});
        }
        m_pairingTimeout.stop();
        m_pairingRequestId.clear();
        m_pairingRequestName.clear();
        m_pairingAnswer = PairingAnswer::Waiting;
        return {200, QJsonDocument(allowed ? QJsonObject{{"status", "allowed"}, {"code", phoneCode}}
                                           : QJsonObject{{"status", "denied"}})
                         .toJson(QJsonDocument::Compact)};
    }
    if (!acceptsCode(code)) {
        if (++m_failedAttempts >= kMaxFailedAttempts) {
            m_failedAttempts = 0;
            m_lockedSince.start();
        }
        return {401, {}};
    }
    m_failedAttempts = 0;
    // Every request names the phone, but only these mean it is controlling this computer; check-ins, syncing and
    // browsing happen while the phone plays itself.
    const bool controlsPlayback = path == "/api/playback" || path == "/api/volume" || path == "/api/seek" ||
                                  path.startsWith("/api/queue") || path == "/api/library/play" ||
                                  path == "/api/handoff";
    if (controlsPlayback && !deviceName.isEmpty()) {
        const QString name = QString::fromUtf8(deviceName);
        m_controllerTimeout.start();
        if (m_controllerName != name) {
            m_controllerName = name;
            emit controllerChanged();
        }
    }

    if (method == "GET" && path == "/api/playback")
        return {200, QJsonDocument(status()).toJson(QJsonDocument::Compact)};
    const auto libraryTrack = [this](const QString &id) {
        for (const QVariant &value : m_library->playbackTracks()) {
            const QVariantMap track = value.toMap();
            if (libraryId(track) == id)
                return track;
        }
        return QVariantMap();
    };
    if (method == "GET" && path == "/api/library") {
        const QUrlQuery query(url);
        const QString search = query.queryItemValue("q").trimmed();
        const int offset = qMax(0, query.queryItemValue("offset").toInt());
        const int limit = qBound(1, query.hasQueryItem("limit") ? query.queryItemValue("limit").toInt() : 100, 500);
        QJsonArray page;
        int total = 0;
        for (const QVariant &value : m_library->playbackTracks()) {
            const QVariantMap track = value.toMap();
            const QString title = track.value("title").toString();
            const QString artist = track.value("artist").toString();
            const QString album = track.value("album").toString();
            if (!search.isEmpty() && !title.contains(search, Qt::CaseInsensitive) &&
                !artist.contains(search, Qt::CaseInsensitive) && !album.contains(search, Qt::CaseInsensitive))
                continue;
            if (total >= offset && page.size() < limit)
                page.append(QJsonObject{{"id", libraryId(track)},
                                        {"title", title.isEmpty() ? track.value("fileName").toString() : title},
                                        {"artist", artist},
                                        {"album", album},
                                        {"durationMs", track.value("durationSeconds").toLongLong() * 1000}});
            ++total;
        }
        return {200, QJsonDocument(QJsonObject{{"total", total}, {"tracks", page}}).toJson(QJsonDocument::Compact)};
    }
    if (streamRequest) {
        const QVariantMap track = libraryTrack(QUrlQuery(url).queryItemValue("id"));
        const QString file = track.value("filePath").toString();
        if (file.isEmpty() || !QFileInfo::exists(file))
            return {404, {}};
        Response response{200, {}, audioContentType(file)};
        response.filePath = file;
        return response;
    }
    if (artworkRequest && QUrlQuery(url).hasQueryItem("id")) {
        QFile file(artworkPath(libraryTrack(QUrlQuery(url).queryItemValue("id"))));
        if (!file.open(QIODevice::ReadOnly))
            return {404, {}};
        return {200, file.readAll(), file.fileName().endsWith(".png") ? "image/png" : "image/jpeg"};
    }
    if (artworkRequest) {
        const QString key = QUrlQuery(url).queryItemValue("key");
        QVariantList tracks = m_upNext;
        tracks.prepend(m_player->currentTrack());
        const auto track = std::find_if(tracks.cbegin(), tracks.cend(),
                                        [&](const QVariant &item) { return artworkKey(item.toMap()) == key; });
        QFile file(track == tracks.cend() ? QString() : artworkPath(track->toMap()));
        if (!file.open(QIODevice::ReadOnly))
            return {404, {}};
        return {200, file.readAll(), file.fileName().endsWith(".png") ? "image/png" : "image/jpeg"};
    }
    if (method == "GET" && path == "/api/queue") {
        QJsonArray tracks;
        for (const QVariant &item : m_upNext) {
            const QVariantMap track = item.toMap();
            tracks.append(QJsonObject{{"index", track.value("index").toInt()},
                                      {"title", track.value("title").toString()},
                                      {"artist", track.value("artist").toString()},
                                      {"durationMs", track.value("durationMs").toLongLong()},
                                      {"artworkKey", artworkKey(track)}});
        }
        return {200, QJsonDocument(QJsonObject{{"tracks", tracks}}).toJson(QJsonDocument::Compact)};
    }
    if (method == "GET" && path == "/api/likes") {
        QSet<QString> libraryKeys;
        for (const QVariant &track : m_library->playbackTracks())
            libraryKeys.insert(matchKey(track.toMap()));
        QSet<QString> likedKeys;
        for (const QVariant &track :
             m_library->tracksForPaths(QVariantList(m_favoritePaths.cbegin(), m_favoritePaths.cend())))
            if (!track.toMap().isEmpty())
                likedKeys.insert(matchKey(track.toMap()));
        const QJsonObject likes{{"library", QJsonArray::fromStringList(libraryKeys.values())},
                                {"liked", QJsonArray::fromStringList(likedKeys.values())},
                                {"revision", m_likesRevision}};
        return {200, QJsonDocument(likes).toJson(QJsonDocument::Compact)};
    }
    if (method == "GET" && path == "/api/listens") {
        const qint64 since = QUrlQuery(url).queryItemValue("since").toLongLong();
        return {200,
                QJsonDocument(QJsonObject{{"listens", m_library->listensSince(since)}}).toJson(QJsonDocument::Compact)};
    }
    if (method == "GET" && path == "/api/playlists") {
        QJsonArray playlists;
        for (const QVariant &value : m_playlists) {
            const QVariantMap playlist = value.toMap();
            QJsonArray tracks;
            for (const QVariant &track : m_library->tracksForPaths(playlist.value("trackPaths").toList())) {
                const QVariantMap found = track.toMap();
                if (!found.isEmpty())
                    tracks.append(QJsonObject{{"title", found.value("title").toString()},
                                              {"artist", found.value("artist").toString()}});
            }
            playlists.append(QJsonObject{{"name", playlist.value("name").toString()}, {"tracks", tracks}});
        }
        return {200, QJsonDocument(QJsonObject{{"playlists", playlists}}).toJson(QJsonDocument::Compact)};
    }
    if (method == "GET" && path == "/api/backup") {
        QFile file(phoneBackupFilePath());
        if (!file.open(QIODevice::ReadOnly))
            return {404, {}};
        return {200, file.readAll()};
    }
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
    if (path == "/api/phone-state") {
        const QString title = request.value("title").toString();
        const QString artist = request.value("artist").toString();
        QVariantMap playback;
        if (!title.isEmpty()) {
            // The phone sends a song's cover once, so later check-ins about the same song keep it.
            const QByteArray cover = QByteArray::fromBase64(request.value("artwork").toString().toLatin1());
            const bool sameSong = m_phonePlayback.value("title") == title && m_phonePlayback.value("artist") == artist;
            // The same song in this library, so it can be liked here.
            QString filePath = m_phonePlayback.value("filePath").toString();
            if (!sameSong) {
                filePath.clear();
                const QString key = matchKey({{"title", title}, {"artist", artist}});
                for (const QVariant &value : m_library->playbackTracks()) {
                    if (matchKey(value.toMap()) == key) {
                        filePath = value.toMap().value("filePath").toString();
                        break;
                    }
                }
            }
            const QString artwork = cover.startsWith("\xFF\xD8")
                                        ? "data:image/jpeg;base64," + QString::fromLatin1(cover.toBase64())
                                    : sameSong ? m_phonePlayback.value("artwork").toString()
                                               : QString();
            playback = {{"name", QString::fromUtf8(deviceName)},
                        {"title", title},
                        {"artist", artist},
                        {"isPlaying", request.value("isPlaying").toBool()},
                        {"positionMs", request.value("positionMs").toDouble()},
                        {"durationMs", request.value("durationMs").toDouble()},
                        {"volumePercent", request.value("volumePercent").toInt(-1)},
                        {"updatedAt", QDateTime::currentMSecsSinceEpoch()},
                        {"artwork", artwork},
                        {"filePath", filePath}};
        }
        // A phone paused for a while checks in only every 30 seconds.
        if (playback.isEmpty())
            m_phoneTimeout.stop();
        else
            m_phoneTimeout.start(playback.value("isPlaying").toBool() ? 12 * 1000 : 75 * 1000);
        if (playback != m_phonePlayback) {
            m_phonePlayback = playback;
            emit phonePlaybackChanged();
        }
        const QJsonArray commands = QJsonArray::fromStringList(std::exchange(m_phoneCommands, {}));
        const QJsonObject reply{
            {"ok", true},
            {"commands", commands},
            {"playNext", std::exchange(m_phonePlayNext, {})},
            {"likesRevision", m_likesRevision},
            {"needsArtwork", !playback.isEmpty() && playback.value("artwork").toString().isEmpty()}};
        return {200, QJsonDocument(reply).toJson(QJsonDocument::Compact)};
    }
    if (path == "/api/handoff" && request.value("tracks").isArray()) {
        // The phone plays the song itself when this computer doesn't have it, so it is told which happened.
        const QJsonArray tracks = request.value("tracks").toArray();
        const QString wanted = matchKey(tracks.at(request.value("index").toInt()).toObject().toVariantMap());
        const QVariantList library = m_library->playbackTracks();
        const bool played = std::any_of(library.cbegin(), library.cend(),
                                        [&](const QVariant &track) { return matchKey(track.toMap()) == wanted; });
        // The phone stops playing when it hands over, so its strip goes at once.
        if (played && !m_phonePlayback.isEmpty()) {
            m_phonePlayback.clear();
            m_phoneTimeout.stop();
            emit phonePlaybackChanged();
        }
        emit handoffRequested(tracks.toVariantList(), request.value("index").toInt(),
                              qMax<qint64>(0, request.value("positionMs").toInteger()),
                              request.value("playing").toBool());
        return {200, QJsonDocument(QJsonObject{{"played", played}}).toJson(QJsonDocument::Compact)};
    }
    if (path == "/api/likes") {
        if (!request.value("like").isArray() || !request.value("unlike").isArray())
            return {400, {}};
        const auto keys = [&](const char *name) {
            QSet<QString> set;
            for (const QJsonValue &key : request.value(name).toArray())
                set.insert(key.toString());
            return set;
        };
        const QSet<QString> like = keys("like");
        const QSet<QString> unlike = keys("unlike");
        QStringList likePaths;
        QStringList unlikePaths;
        for (const QVariant &value : m_library->playbackTracks()) {
            const QVariantMap track = value.toMap();
            const QString key = matchKey(track);
            if (like.contains(key))
                likePaths.append(track.value("filePath").toString());
            else if (unlike.contains(key))
                unlikePaths.append(track.value("filePath").toString());
        }
        emit likesChangeRequested(likePaths, unlikePaths);
        return {200, {}};
    }
    if (path == "/api/listens") {
        if (!request.value("listens").isArray())
            return {400, {}};
        QHash<QString, QString> pathByKey;
        for (const QVariant &value : m_library->playbackTracks()) {
            const QVariantMap track = value.toMap();
            pathByKey.insert(matchKey(track), track.value("filePath").toString());
        }
        QList<QJsonObject> listens;
        for (const QJsonValue &value : request.value("listens").toArray()) {
            const QJsonObject listen = value.toObject();
            if (listen.value("title").toString().isEmpty() || listen.value("at").toInteger() <= 0 ||
                listen.value("ms").toInteger() <= 0)
                continue;
            listens.append({{"at", listen.value("at").toInteger()},
                            {"path", pathByKey.value(matchKey(listen.toVariantMap()))},
                            {"title", listen.value("title").toString()},
                            {"artist", listen.value("artist").toString()},
                            {"album", listen.value("album").toString()},
                            {"genre", listen.value("genre").toString()},
                            {"ms", listen.value("ms").toInteger()}});
        }
        return {m_library->appendPhoneListens(listens) ? 200 : 500, {}};
    }
    if (path == "/api/playlists") {
        const QString name = request.value("name").toString().trimmed();
        if (name.isEmpty() || !request.value("tracks").isArray())
            return {400, {}};
        QHash<QString, QString> pathByKey;
        for (const QVariant &value : m_library->playbackTracks()) {
            const QVariantMap track = value.toMap();
            pathByKey.insert(matchKey(track), track.value("filePath").toString());
        }
        const QJsonArray tracks = request.value("tracks").toArray();
        QStringList trackPaths;
        for (const QJsonValue &track : tracks) {
            const QString path = pathByKey.value(matchKey(track.toObject().toVariantMap()));
            if (!path.isEmpty() && !trackPaths.contains(path))
                trackPaths.append(path);
        }
        emit playlistReceived(name, trackPaths, tracks.size());
        return {200, QJsonDocument(QJsonObject{{"ok", true}, {"matched", trackPaths.size()}, {"total", tracks.size()}})
                         .toJson(QJsonDocument::Compact)};
    }
    if (path == "/api/library/play") {
        QVariantList tracks;
        for (const QJsonValue &id : request.value("ids").toArray()) {
            const QVariantMap track = libraryTrack(id.toString());
            if (!track.isEmpty())
                tracks.append(track);
        }
        if (tracks.isEmpty())
            return {400, {}};
        m_player->requestPlayback(tracks, qBound(0, request.value("index").toInt(), int(tracks.size()) - 1));
        return {200, {}};
    }
    if (path == "/api/queue/next") {
        const QString title = request.value("title").toString();
        if (title.isEmpty())
            return {400, {}};
        emit playNextRequested(title, request.value("artist").toString());
        return {200, {}};
    }
    if (path == "/api/queue/move" && request.contains("from") && request.contains("to")) {
        emit queueMoveRequested(request.value("from").toInt(), request.value("to").toInt());
        return {200, {}};
    }
    if (path == "/api/queue/remove" && request.contains("index")) {
        emit queueRemoveRequested(request.value("index").toInt());
        return {200, {}};
    }
    if (path == "/api/queue" && request.contains("index")) {
        emit queueTrackRequested(request.value("index").toInt());
        return {200, {}};
    }
    if (path == "/api/backup") {
        if (request.isEmpty())
            return {400, {}};
        if (!saveBackup(phoneBackupFilePath(), body)) {
            qWarning() << "Could not save the phone backup to" << phoneBackupFilePath();
            return {500, {}};
        }
        return {200, {}};
    }
    if (path == "/api/seek" && request.contains("positionMs")) {
        emit seekRequested(qMax<qint64>(0, request.value("positionMs").toInteger()));
        return {200, {}};
    }
    return {404, {}};
}

QByteArray RemoteControlServer::discoveryReply(const QByteArray &datagram, const QHostAddress &peer) const {
    if (datagram != kDiscoveryProbe || !isLocalPeer(peer) || !m_server.isListening())
        return {};
    return QJsonDocument(QJsonObject{{"name", computerName()}, {"port", m_server.serverPort()}})
        .toJson(QJsonDocument::Compact);
}

QJsonObject RemoteControlServer::status() {
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
        {"artworkKey", artworkKey(track)},
        {"deviceName", computerName()},
        // Reported once, so the phone takes over a single time.
        {"handoffRequested", std::exchange(m_handoffToPhone, false)},
    };
}

bool RemoteControlServer::selfCheck() {
    PlayerController player;
    LibraryController library;
    RemoteControlServer remote(&player, &library);
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
    int queuedIndex = -1;
    connect(&remote, &RemoteControlServer::queueTrackRequested, [&](int index) { queuedIndex = index; });
    remote.m_upNext = {QVariantMap{{"index", 4}, {"title", "Next"}, {"filePath", "C:/Music/next.flac"}}};
    const QJsonArray upNext = QJsonDocument::fromJson(remote.respond("GET", "/api/queue", auth, {}, lan).body)
                                  .object()
                                  .value("tracks")
                                  .toArray();
    QPair<int, int> moved{-1, -1};
    int removedIndex = -1;
    connect(&remote, &RemoteControlServer::queueMoveRequested, [&](int from, int to) { moved = {from, to}; });
    connect(&remote, &RemoteControlServer::queueRemoveRequested, [&](int index) { removedIndex = index; });
    const bool editsQueue =
        remote.respond("POST", "/api/queue/move", auth, R"({"from":5,"to":3})", lan).status == 200 &&
        remote.respond("POST", "/api/queue/remove", auth, R"({"index":6})", lan).status == 200 &&
        moved == QPair<int, int>{5, 3} && removedIndex == 6;
    const bool servesQueue =
        editsQueue && upNext.size() == 1 && upNext[0].toObject().value("title") == "Next" &&
        !upNext[0].toObject().contains("filePath") && !upNext[0].toObject().value("artworkKey").toString().isEmpty() &&
        remote.respond("POST", "/api/queue", auth, R"({"index":4})", lan).status == 200 && queuedIndex == 4;
    const bool codeInQueryOnlyForArtwork =
        remote.respond("GET", "/api/artwork?code=ABC234", {}, {}, lan).status != 401 &&
        remote.respond("GET", "/api/queue?code=ABC234", {}, {}, lan).status == 401 &&
        remote.respond("GET", "/api/artwork?code=WRONG1", {}, {}, lan).status == 401;
    QVariantList handedTracks;
    qint64 handedPosition = -1;
    connect(&remote, &RemoteControlServer::handoffRequested,
            [&](const QVariantList &tracks, int, qint64 positionMs, bool) {
                handedTracks = tracks;
                handedPosition = positionMs;
            });
    const Response handoff =
        remote.respond("POST", "/api/handoff", auth,
                       R"({"tracks":[{"title":"A","artist":"B"}],"index":0,"positionMs":61000,"playing":true})", lan);
    // The test library is empty, so the phone is told to play the song itself.
    const bool acceptsHandoff =
        handoff.status == 200 && QJsonDocument::fromJson(handoff.body).object().value("played") == QJsonValue(false) &&
        handedTracks.size() == 1 && handedTracks[0].toMap().value("title") == "A" && handedPosition == 61000;
    remote.respond("POST", "/api/phone-state", auth, R"({"title":"Song"})", lan, "motorola edge 40");
    const bool checkInIsNotControl = remote.controllerName().isEmpty();
    remote.respond("GET", "/api/playback", auth, {}, lan, "motorola edge 40");
    const bool namesController = checkInIsNotControl && remote.controllerName() == "motorola edge 40";
    remote.continueOnPhone();
    const bool handsBackOnce = QJsonDocument::fromJson(remote.respond("GET", "/api/playback", auth, {}, lan).body)
                                   .object()
                                   .value("handoffRequested")
                                   .toBool() &&
                               !QJsonDocument::fromJson(remote.respond("GET", "/api/playback", auth, {}, lan).body)
                                    .object()
                                    .value("handoffRequested")
                                    .toBool();
    remote.respond("POST", "/api/phone-state", auth, R"({"title":"Song","artist":"Ann","isPlaying":true})", lan,
                   "motorola edge 40");
    remote.sendToPhone("pause");
    const QJsonArray firstCommands =
        QJsonDocument::fromJson(remote
                                    .respond("POST", "/api/phone-state", auth, R"({"title":"Song","isPlaying":true})",
                                             lan, "motorola edge 40")
                                    .body)
            .object()
            .value("commands")
            .toArray();
    const bool relaysToPhone =
        remote.phonePlayback().value("name") == "motorola edge 40" && firstCommands == QJsonArray{"pause"} &&
        QJsonDocument::fromJson(
            remote.respond("POST", "/api/phone-state", auth, R"({"title":"Song"})", lan, "motorola edge 40").body)
            .object()
            .value("commands")
            .toArray()
            .isEmpty();
    const auto checkIn = [&](const QByteArray &body) {
        return QJsonDocument::fromJson(
                   remote.respond("POST", "/api/phone-state", auth, body, lan, "motorola edge 40").body)
            .object();
    };
    const bool asksForCover = checkIn(R"({"title":"Cover","artist":"Ann"})").value("needsArtwork").toBool();
    const bool keepsPhoneCover =
        !checkIn(R"({"title":"Cover","artist":"Ann","artwork":"/9j/AA=="})").value("needsArtwork").toBool() &&
        !checkIn(R"({"title":"Cover","artist":"Ann","positionMs":5000})").value("needsArtwork").toBool() &&
        remote.phonePlayback().value("artwork") == "data:image/jpeg;base64,/9j/AA==" &&
        remote.phonePlayback().value("positionMs").toInt() == 5000 &&
        checkIn(R"({"title":"Next","artist":"Ann"})").value("needsArtwork").toBool();
    const bool rejectsUnknownAction =
        remote.respond("POST", "/api/playback", auth, R"({"action":"reset"})", lan).status == 400;
    const bool keysByTitleAndArtist =
        matchKey({{"title", " One "}, {"artist", "ANN"}}) == QString("one") + QChar(0x1f) + "ann" &&
        matchKey({{"title", "  "}, {"fileName", "Two.mp3"}}) == QString("two.mp3") + QChar(0x1f);
    const auto likesRevision = [&] {
        return QJsonDocument::fromJson(remote.respond("GET", "/api/likes", auth, {}, lan).body)
            .object()
            .value("revision")
            .toInt();
    };
    const int revisionBefore = likesRevision();
    remote.setProperty("favoritePaths", QStringList{"C:/Music/One.mp3"});
    QStringList unlikedPaths{"unchanged"};
    connect(&remote, &RemoteControlServer::likesChangeRequested,
            [&](const QStringList &, const QStringList &unlike) { unlikedPaths = unlike; });
    const bool syncsLikes =
        likesRevision() == revisionBefore + 1 &&
        remote.respond("POST", "/api/likes", auth, R"({"like":[],"unlike":["a"]})", lan).status == 200 &&
        unlikedPaths.isEmpty() && remote.respond("POST", "/api/likes", auth, R"({"like":"a"})", lan).status == 400;
    const bool rejectsBadListens =
        remote.respond("POST", "/api/listens", auth, R"({"listens":"x"})", lan).status == 400 &&
        QJsonDocument::fromJson(remote.respond("GET", "/api/listens?since=0", auth, {}, lan).body)
            .object()
            .value("listens")
            .isArray();
    const auto pairingId = [&] {
        return QJsonDocument::fromJson(remote.respond("POST", "/api/pair-request", {}, R"({"name":"Pixel"})", lan).body)
            .object()
            .value("id")
            .toString();
    };
    const auto pairingStatus = [&](const QString &id) {
        return QJsonDocument::fromJson(remote.respond("GET", "/api/pair-request?id=" + id.toLatin1(), {}, {}, lan).body)
            .object();
    };
    const QString allowedId = pairingId();
    const bool asksBeforePairing =
        !allowedId.isEmpty() && remote.pairingRequest() == "Pixel" &&
        remote.respond("POST", "/api/pair-request", {}, R"({"name":"Other"})", lan).status == 409 &&
        pairingStatus(allowedId).value("status") == "waiting" &&
        remote.respond("GET", "/api/pair-request?id=guess", {}, {}, lan).status == 404;
    remote.answerPairing(true);
    const bool keepsAllowedUntilCollected =
        remote.respond("POST", "/api/pair-request", {}, R"({"name":"Other"})", lan).status == 409;
    const QByteArray phoneCode = pairingStatus(allowedId).value("code").toString().toLatin1();
    const bool givesCodeOnceAllowed =
        phoneCode.size() == 6 && phoneCode != "ABC234" &&
        remote.pairedPhones().value(0).toMap().value("name") == "Pixel" &&
        remote.respond("GET", "/api/playback", "Bearer " + phoneCode, {}, lan).status == 200 &&
        remote.respond("GET", "/api/pair-request?id=" + allowedId.toLatin1(), {}, {}, lan).status == 404;
    remote.unpairPhone(QString::fromLatin1(phoneCode));
    const bool unpairsOnePhone = remote.pairedPhones().isEmpty() &&
                                 remote.respond("GET", "/api/playback", "Bearer " + phoneCode, {}, lan).status == 401 &&
                                 remote.respond("GET", "/api/playback", auth, {}, lan).status == 200;
    const QString deniedId = pairingId();
    remote.answerPairing(false);
    const QJsonObject denied = pairingStatus(deniedId);
    const bool turnsAwayDenied =
        denied.value("status") == "denied" && !denied.contains("code") &&
        remote.respond("POST", "/api/pair-request", {}, R"({"name":"Pixel"})", QHostAddress("8.8.8.8")).status == 403;
    QString receivedPlaylist;
    connect(&remote, &RemoteControlServer::playlistReceived, [&](const QString &name) { receivedPlaylist = name; });
    remote.setProperty("playlists",
                       QVariantList{QVariantMap{{"name", "Road"}, {"trackPaths", QVariantList{"C:/Music/Gone.mp3"}}}});
    const QJsonArray servedPlaylists =
        QJsonDocument::fromJson(remote.respond("GET", "/api/playlists", auth, {}, lan).body)
            .object()
            .value("playlists")
            .toArray();
    const QJsonObject sentPlaylist =
        QJsonDocument::fromJson(remote
                                    .respond("POST", "/api/playlists", auth,
                                             R"({"name":" Gym ","tracks":[{"title":"One","artist":"Ann"}]})", lan)
                                    .body)
            .object();
    const bool copiesPlaylists =
        servedPlaylists.size() == 1 && servedPlaylists[0].toObject().value("name") == "Road" &&
        servedPlaylists[0].toObject().value("tracks").toArray().isEmpty() && receivedPlaylist == "Gym" &&
        sentPlaylist.value("matched").toInt() == 0 && sentPlaylist.value("total").toInt() == 1 &&
        remote.respond("POST", "/api/playlists", auth, R"({"name":"","tracks":[]})", lan).status == 400;
    QString playNextTitle;
    connect(&remote, &RemoteControlServer::playNextRequested, [&](const QString &title) { playNextTitle = title; });
    const bool routesPlayNext =
        remote.respond("POST", "/api/queue/next", auth, R"({"title":"One","artist":"Ann"})", lan).status == 200 &&
        playNextTitle == "One" &&
        remote.respond("POST", "/api/queue/next", auth, R"({"artist":"Ann"})", lan).status == 400;
    remote.playNextOnPhone("Two", "Bo");
    const auto playNextOnPhone = [&] {
        return QJsonDocument::fromJson(remote
                                           .respond("POST", "/api/phone-state", auth,
                                                    R"({"title":"Song","isPlaying":true})", lan, "motorola edge 40")
                                           .body)
            .object()
            .value("playNext")
            .toArray();
    };
    const bool relaysPlayNextOnce =
        playNextOnPhone() == QJsonArray{QJsonObject{{"title", "Two"}, {"artist", "Bo"}}} && playNextOnPhone().isEmpty();
    const bool rejectsInvalidBackup = remote.respond("POST", "/api/backup", auth, "not a backup", lan).status == 400;
    QTemporaryDir backupDir;
    const QString backupPath = backupDir.filePath("backup.json");
    auto read = [](const QString &path) {
        QFile file(path);
        return file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray();
    };
    const bool keepsPreviousBackup = saveBackup(backupPath, R"({"n":1})") && saveBackup(backupPath, R"({"n":2})") &&
                                     read(backupPath) == R"({"n":2})" && read(backupPath + ".previous") == R"({"n":1})";

    remote.setEnabled(true);
    const auto exchange = [&](const QByteArray &request) {
        QTcpSocket client;
        QByteArray reply;
        QEventLoop loop;
        QTimer::singleShot(3000, &loop, &QEventLoop::quit);
        connect(&client, &QTcpSocket::readyRead, &loop, [&] { reply += client.readAll(); });
        connect(&client, &QTcpSocket::disconnected, &loop, &QEventLoop::quit);
        client.connectToHost(QHostAddress::LocalHost, remote.m_server.serverPort());
        client.write(request);
        loop.exec();
        return reply;
    };
    const QByteArray reply = exchange("POST /api/playback HTTP/1.1\r\nAuthorization: Bearer ABC234\r\n"
                                      "Content-Length: 17\r\n\r\n"
                                      R"({"action":"next"})");
    const bool refusesUnpairedUploadEarly =
        exchange("POST /api/backup HTTP/1.1\r\nAuthorization: Bearer WRONG1\r\nContent-Length: 1000000\r\n\r\n")
            .startsWith("HTTP/1.1 401");
    const QJsonObject found =
        QJsonDocument::fromJson(remote.discoveryReply(kDiscoveryProbe, QHostAddress("192.168.1.30"))).object();
    const bool answersDiscovery = found.value("port").toInt() == remote.m_server.serverPort() &&
                                  !found.value("name").toString().isEmpty() &&
                                  remote.discoveryReply("HELLO", QHostAddress("192.168.1.30")).isEmpty() &&
                                  remote.discoveryReply(kDiscoveryProbe, QHostAddress("8.8.8.8")).isEmpty();
    remote.setEnabled(false);
    const QTemporaryDir streamDir;
    const QString streamPath = streamDir.filePath("stream-check.wav");
    {
        QFile streamSource(streamPath);
        streamSource.open(QIODevice::WriteOnly);
        streamSource.write("0123456789");
    }
    const auto streamed = [&](const QByteArray &range) {
        QTcpServer server;
        server.listen(QHostAddress::LocalHost);
        connect(&server, &QTcpServer::newConnection, &server, [&] {
            Response response{200, {}, "audio/wav"};
            response.filePath = streamPath;
            remote.streamFile(server.nextPendingConnection(), response, range);
        });
        QTcpSocket client;
        QByteArray reply;
        QEventLoop loop;
        QTimer::singleShot(3000, &loop, &QEventLoop::quit);
        connect(&client, &QTcpSocket::readyRead, &loop, [&] { reply += client.readAll(); });
        connect(&client, &QTcpSocket::disconnected, &loop, &QEventLoop::quit);
        client.connectToHost(QHostAddress::LocalHost, server.serverPort());
        loop.exec();
        return reply;
    };
    const QByteArray partialReply = streamed("bytes=2-5");
    const QByteArray wholeReply = streamed({});
    const bool streamsRanges = partialReply.startsWith("HTTP/1.1 206") &&
                               partialReply.contains("Content-Range: bytes 2-5/10") &&
                               partialReply.endsWith("\r\n\r\n2345") && wholeReply.startsWith("HTTP/1.1 200") &&
                               wholeReply.endsWith("\r\n\r\n0123456789");
    const bool servesHttp = reply.startsWith("HTTP/1.1 200 OK") && reply.endsWith(R"({"ok":true})") && nextCount == 2;

    const QJsonObject libraryPage =
        QJsonDocument::fromJson(remote.respond("GET", "/api/library?q=x&limit=5", auth, {}, lan).body).object();
    const bool servesLibrary = libraryPage.contains("total") && libraryPage.value("tracks").toArray().size() <= 5;
    // Only ids of library tracks resolve to a file, and a stream needs the code like any other request.
    const bool streamsOnlyLibraryFiles =
        remote.respond("GET", "/api/stream?id=0123456789abcdef&code=ABC234", {}, {}, lan).status == 404 &&
        remote.respond("GET", "/api/stream?id=0123456789abcdef&code=WRONG1", {}, {}, lan).status == 401 &&
        remote.respond("POST", "/api/library/play", auth, R"({"ids":["0123456789abcdef"]})", lan).status == 400;
    for (int i = 0; i < kMaxFailedAttempts; ++i)
        remote.respond("GET", "/api/playback", "Bearer WRONG1", {}, lan);
    const bool locksOutGuessing = remote.respond("GET", "/api/playback", auth, {}, lan).status == 429;

    const bool ok = rejectsPublicPeer && rejectsWrongCode && reportsStatus && routesNext && clampsVolume &&
                    rejectsUnknownAction && relaysToPhone && asksForCover && keepsPhoneCover && acceptsHandoff &&
                    namesController && handsBackOnce && codeInQueryOnlyForArtwork && servesQueue && servesHttp &&
                    answersDiscovery && locksOutGuessing && rejectsInvalidBackup && keepsPreviousBackup &&
                    routesPlayNext && relaysPlayNextOnce && refusesUnpairedUploadEarly && keysByTitleAndArtist &&
                    syncsLikes && copiesPlaylists && rejectsBadListens && asksBeforePairing &&
                    keepsAllowedUntilCollected && givesCodeOnceAllowed && unpairsOnePhone && turnsAwayDenied &&
                    servesLibrary && streamsOnlyLibraryFiles && streamsRanges;
    if (!ok)
        qWarning() << "Remote control self-check failed:" << rejectsPublicPeer << rejectsWrongCode << reportsStatus
                   << routesNext << clampsVolume << rejectsUnknownAction << relaysToPhone << asksForCover
                   << keepsPhoneCover << acceptsHandoff << namesController << handsBackOnce << codeInQueryOnlyForArtwork
                   << servesQueue << servesHttp << answersDiscovery << locksOutGuessing << rejectsInvalidBackup
                   << keepsPreviousBackup << routesPlayNext << relaysPlayNextOnce << refusesUnpairedUploadEarly
                   << keysByTitleAndArtist << syncsLikes << copiesPlaylists << rejectsBadListens << asksBeforePairing
                   << keepsAllowedUntilCollected << givesCodeOnceAllowed << unpairsOnePhone << turnsAwayDenied
                   << servesLibrary << streamsOnlyLibraryFiles << streamsRanges;
    return ok;
}
