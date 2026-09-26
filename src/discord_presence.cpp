#include "discord_presence.h"

#include "player_controller.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QEventLoop>
#include <QFileInfo>
#include <QJsonDocument>
#include <QLocalServer>
#include <QThread>
#include <QUuid>
#include <QtEndian>

namespace {

// The CassetteCat application registered in the Discord Developer Portal; Discord shows its name.
constexpr auto kClientId = "1553132340107149476";

enum Opcode : quint32 { Handshake = 0, Frame = 1, Close = 2, Ping = 3, Pong = 4 };

QStringList ipcCandidates() {
    QStringList names;
#ifdef Q_OS_WIN
    for (int i = 0; i < 10; ++i)
        names.append(QStringLiteral("discord-ipc-%1").arg(i));
#else
    // Discord creates its socket in the runtime or temp directory; Flatpak and Snap builds use a subdirectory.
    const QString runtime = qEnvironmentVariable("XDG_RUNTIME_DIR");
    QStringList dirs;
    if (!runtime.isEmpty())
        dirs << runtime << runtime + "/app/com.discordapp.Discord" << runtime + "/snap.discord";
    dirs << qEnvironmentVariable("TMPDIR", "/tmp") << "/tmp";
    dirs.removeDuplicates();
    for (const QString &dir : std::as_const(dirs)) {
        for (int i = 0; i < 10; ++i) {
            const QString path = dir + QStringLiteral("/discord-ipc-%1").arg(i);
            if (QFileInfo::exists(path))
                names.append(path);
        }
    }
#endif
    return names;
}

QByteArray encodeFrame(quint32 opcode, const QJsonObject &payload) {
    const QByteArray json = QJsonDocument(payload).toJson(QJsonDocument::Compact);
    QByteArray frame(8, Qt::Uninitialized);
    qToLittleEndian<quint32>(opcode, frame.data());
    qToLittleEndian<quint32>(static_cast<quint32>(json.size()), frame.data() + 4);
    return frame + json;
}

// Takes one complete frame off the front of \p buffer, if one has arrived.
bool takeFrame(QByteArray &buffer, quint32 &opcode, QJsonObject &payload) {
    if (buffer.size() < 8)
        return false;
    const quint32 length = qFromLittleEndian<quint32>(buffer.constData() + 4);
    if (static_cast<quint64>(buffer.size()) < 8 + static_cast<quint64>(length))
        return false;
    opcode = qFromLittleEndian<quint32>(buffer.constData());
    payload = QJsonDocument::fromJson(buffer.mid(8, length)).object();
    buffer.remove(0, 8 + length);
    return true;
}

QJsonObject setActivityPayload(const QJsonObject &activity) {
    QJsonObject args{{"pid", QCoreApplication::applicationPid()}};
    args.insert("activity", activity.isEmpty() ? QJsonValue(QJsonValue::Null) : QJsonValue(activity));
    return {{"cmd", "SET_ACTIVITY"}, {"args", args}, {"nonce", QUuid::createUuid().toString(QUuid::WithoutBraces)}};
}

} // namespace

DiscordPresence::DiscordPresence(PlayerController *player, QObject *parent)
    : QObject(parent), m_player(player), m_socket(this), m_retryTimer(this), m_updateTimer(this) {
    m_retryTimer.setSingleShot(true);
    m_retryTimer.setInterval(15000);
    connect(&m_retryTimer, &QTimer::timeout, this, [this] {
        m_candidates = ipcCandidates();
        m_candidate = 0;
        connectToNextCandidate();
    });
    m_updateTimer.setSingleShot(true);
    connect(&m_updateTimer, &QTimer::timeout, this, &DiscordPresence::sendActivity);

    connect(&m_socket, &QLocalSocket::connected, this,
            [this] { sendFrame(Handshake, {{"v", 1}, {"client_id", kClientId}}); });
    connect(&m_socket, &QLocalSocket::readyRead, this, &DiscordPresence::readFrames);
    connect(&m_socket, &QLocalSocket::errorOccurred, this, [this] {
        if (!m_ready && m_socket.state() == QLocalSocket::UnconnectedState)
            connectToNextCandidate();
    });
    connect(&m_socket, &QLocalSocket::disconnected, this, [this] {
        m_ready = false;
        m_buffer.clear();
        if (m_enabled)
            m_retryTimer.start();
    });

    if (!m_player)
        return;
    connect(m_player, &PlayerController::currentTrackChanged, this, &DiscordPresence::scheduleUpdate);
    connect(m_player, &PlayerController::isPlayingChanged, this, &DiscordPresence::scheduleUpdate);
    connect(m_player, &PlayerController::durationChanged, this, &DiscordPresence::scheduleUpdate);
    // A seek moves the song's start time; resend so Discord's progress bar stays in step.
    connect(m_player, &PlayerController::positionChanged, this, [this] {
        if (!m_ready || m_sentStartMs == 0 || !m_player->isPlaying())
            return;
        const qint64 startMs = QDateTime::currentMSecsSinceEpoch() - m_player->position();
        if (qAbs(startMs - m_sentStartMs) > 3000)
            scheduleUpdate();
    });
}

DiscordPresence::~DiscordPresence() {
    // The socket reports its disconnection while it is destroyed, after the timers it would restart are gone.
    disconnect(&m_socket, nullptr, this, nullptr);
}

bool DiscordPresence::enabled() const {
    return m_enabled;
}

void DiscordPresence::setEnabled(bool enabled) {
    if (m_enabled == enabled)
        return;
    m_enabled = enabled;
    if (enabled) {
        m_candidates = ipcCandidates();
        m_candidate = 0;
        connectToNextCandidate();
    } else {
        m_retryTimer.stop();
        m_updateTimer.stop();
        if (m_ready)
            sendFrame(Frame, setActivityPayload({}));
        m_ready = false;
        m_socket.disconnectFromServer();
    }
    emit enabledChanged();
}

QJsonObject DiscordPresence::activityFor(const QVariantMap &track, bool playing, qint64 positionMs, qint64 durationMs,
                                         qint64 nowMs) {
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty())
        title = track.value("fileName").toString().trimmed();
    // Discord rejects text fields shorter than two characters.
    if (!playing || title.size() < 2)
        return {};

    QJsonObject activity{{"type", 2}, {"details", title.left(128)}};
    const QString artist = track.value("artist").toString().trimmed();
    if (artist.size() >= 2)
        activity.insert("state", artist.left(128));

    const qint64 startMs = nowMs - positionMs;
    QJsonObject timestamps{{"start", startMs}};
    if (durationMs > 0)
        timestamps.insert("end", startMs + durationMs);
    activity.insert("timestamps", timestamps);

    QJsonObject assets{{"large_image", "cassettecat"}};
    const QString album = track.value("album").toString().trimmed();
    if (album.size() >= 2)
        assets.insert("large_text", album.left(128));
    activity.insert("assets", assets);
    return activity;
}

void DiscordPresence::connectToNextCandidate() {
    if (!m_enabled)
        return;
    if (m_candidate >= m_candidates.size()) {
        // Discord is not running; try again later without logging, since this is the normal case.
        m_retryTimer.start();
        return;
    }
    m_socket.connectToServer(m_candidates.at(m_candidate++));
}

void DiscordPresence::readFrames() {
    m_buffer += m_socket.readAll();
    quint32 opcode = 0;
    QJsonObject payload;
    while (takeFrame(m_buffer, opcode, payload)) {
        if (opcode == Frame && payload.value("evt").toString() == "READY") {
            m_ready = true;
            sendActivity();
        } else if (opcode == Frame && payload.value("evt").toString() == "ERROR") {
            qWarning() << "Discord rejected the status update:"
                       << payload.value("data").toObject().value("message").toString();
        } else if (opcode == Close) {
            qWarning() << "Discord closed the connection:" << payload.value("message").toString();
            m_socket.disconnectFromServer();
        } else if (opcode == Ping) {
            sendFrame(Pong, payload);
        }
    }
}

void DiscordPresence::scheduleUpdate() {
    // Restarting a pending update would let steady position ticks postpone it forever.
    if (!m_ready || m_updateTimer.isActive())
        return;
    // Discord accepts about five updates every 20 seconds, so bursts of changes are combined.
    const qint64 sinceLastMs = QDateTime::currentMSecsSinceEpoch() - m_lastSentMs;
    m_updateTimer.start(static_cast<int>(qMax<qint64>(1000, 4000 - sinceLastMs)));
}

void DiscordPresence::sendActivity() {
    if (!m_ready || !m_player)
        return;
    const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
    const qint64 positionMs = m_player->position();
    const QVariantMap track = m_player->currentTrack();
    const QJsonObject activity = activityFor(track, m_player->isPlaying(), positionMs, m_player->duration(), nowMs);
    m_sentStartMs = activity.isEmpty() ? 0 : nowMs - positionMs;
    m_lastSentMs = nowMs;
    sendFrame(Frame, setActivityPayload(activity));
}

void DiscordPresence::sendFrame(quint32 opcode, const QJsonObject &payload) {
    m_socket.write(encodeFrame(opcode, payload));
}

bool DiscordPresence::selfCheck() {
    const QVariantMap track{{"title", "Song Title"}, {"artist", "Some Artist"}, {"album", "An Album"}};
    const QJsonObject activity = activityFor(track, true, 30000, 200000, 1000000);
    const QJsonObject timestamps = activity.value("timestamps").toObject();
    if (activity.value("type").toInt() != 2 || activity.value("details") != "Song Title" ||
        activity.value("state") != "Some Artist" || timestamps.value("start").toInteger() != 970000 ||
        timestamps.value("end").toInteger() != 1170000 ||
        activity.value("assets").toObject().value("large_text") != "An Album")
        return false;
    if (!activityFor(track, false, 0, 0, 0).isEmpty() || !activityFor({{"title", "X"}}, true, 0, 0, 0).isEmpty())
        return false;

    // Exchange frames with a local stand-in for the Discord client.
    const QString name = QStringLiteral("cassettecat-discord-check-%1").arg(QCoreApplication::applicationPid());
    QLocalServer::removeServer(name);
    QLocalServer server;
    if (!server.listen(name))
        return false;

    PlayerController player;
    DiscordPresence presence(&player);
    presence.m_enabled = true;
    presence.m_candidates = {name};
    presence.connectToNextCandidate();

    QLocalSocket *client = nullptr;
    QByteArray received;
    QList<QPair<quint32, QJsonObject>> frames;
    QEventLoop loop;
    QTimer::singleShot(3000, &loop, &QEventLoop::quit);
    QObject::connect(&server, &QLocalServer::newConnection, &loop, [&] {
        client = server.nextPendingConnection();
        QObject::connect(client, &QLocalSocket::readyRead, &loop, [&] {
            received += client->readAll();
            quint32 opcode = 0;
            QJsonObject payload;
            while (takeFrame(received, opcode, payload)) {
                frames.append({opcode, payload});
                if (opcode == Handshake)
                    client->write(encodeFrame(Frame, {{"cmd", "DISPATCH"}, {"evt", "READY"}}));
                else
                    loop.quit();
            }
        });
    });
    loop.exec();

    presence.m_lastSentMs = 0;
    presence.scheduleUpdate();
    const int firstWaitMs = presence.m_updateTimer.remainingTime();
    QThread::msleep(20);
    presence.scheduleUpdate();
    const bool keepsPendingUpdate = presence.m_updateTimer.remainingTime() < firstWaitMs;

    // The player is paused, so the first update clears the activity.
    return keepsPendingUpdate && frames.size() == 2 && frames[0].first == Handshake &&
           frames[0].second.value("client_id").toString() == kClientId && frames[1].first == Frame &&
           frames[1].second.value("cmd") == "SET_ACTIVITY" &&
           frames[1].second.value("args").toObject().value("activity").isNull();
}
