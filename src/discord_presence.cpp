#include "discord_presence.h"

#include "player_controller.h"
#include "self_check.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QEventLoop>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QLocalServer>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QThread>
#include <QUrl>
#include <QRegularExpression>
#include <QUrlQuery>
#include <QUuid>
#include <QtEndian>

namespace {

// The CassetteCat application registered in the Discord Developer Portal; Discord shows its name.
constexpr auto kClientId = "1553132340107149476";

enum Opcode : quint32 { Handshake = 0, Frame = 1, Close = 2, Ping = 3, Pong = 4 };

// Which field the member list shows after "Listening to": 2 is details, the song.
constexpr int kShowDetails = 2;

// Empty for a song that can't be looked up, which then shows the logo.
QString artworkKey(const QVariantMap &track) {
    const QString artist = track.value("artist").toString().trimmed().toLower();
    const QString title = track.value("title").toString().trimmed().toLower();
    if (artist.isEmpty() || title.isEmpty())
        return {};
    return artist + QChar(0x1f) + title + QChar(0x1f) + track.value("album").toString().trimmed().toLower();
}

// The song's public Last.fm page, which needs no account to open.
QString lastFmUrl(const QString &artist, const QString &title) {
    const auto part = [](const QString &text) {
        return QString::fromUtf8(QUrl::toPercentEncoding(text, " ")).replace(u' ', u'+');
    };
    return "https://www.last.fm/music/" + part(artist) + "/_/" + part(title);
}

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
    : QObject(parent), m_player(player), m_socket(this), m_retryTimer(this), m_updateTimer(this), m_net(this) {
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
        if (m_artworkReply)
            m_artworkReply->abort();
        if (m_ready)
            sendFrame(Frame, setActivityPayload({}));
        m_ready = false;
        m_socket.disconnectFromServer();
    }
    emit enabledChanged();
}

QJsonObject DiscordPresence::activityFor(const QVariantMap &track, bool playing, qint64 positionMs, qint64 durationMs,
                                         qint64 nowMs, const QString &artworkUrl) {
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty())
        title = track.value("fileName").toString().trimmed();
    // Discord rejects text fields shorter than two characters.
    if (!playing || title.size() < 2)
        return {};

    QJsonObject activity{{"type", 2}, {"status_display_type", kShowDetails}, {"details", title.left(128)}};
    const QString artist = track.value("artist").toString().trimmed();
    if (artist.size() >= 2) {
        activity.insert("state", artist.left(128));
        // Discord turns down a button link over 512 characters, and a shortened one would lead nowhere.
        const QString url = lastFmUrl(artist, title);
        if (url.size() <= 512)
            activity.insert("buttons", QJsonArray{QJsonObject{{"label", "Open on Last.fm"}, {"url", url}}});
    }

    const qint64 startMs = nowMs - positionMs;
    QJsonObject timestamps{{"start", startMs}};
    if (durationMs > 0)
        timestamps.insert("end", startMs + durationMs);
    activity.insert("timestamps", timestamps);

    // With a cover, the app logo moves to the small corner image.
    QJsonObject assets{{"large_image", artworkUrl.isEmpty() ? QStringLiteral("cassettecat") : artworkUrl}};
    if (!artworkUrl.isEmpty()) {
        assets.insert("small_image", "cassettecat");
        assets.insert("small_text", "CassetteCat");
    }
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
    const QString key = artworkKey(track);
    if (key != m_artworkFailed)
        m_artworkFailed.clear();
    // Waiting for the cover sends the song once, rather than without it and again a moment later. A pause clears
    // the status straight away, and a lookup that failed shows the logo until the song comes round again.
    if (m_player->isPlaying() && !key.isEmpty() && !m_artwork.contains(key) && key != m_artworkFailed) {
        lookUpArtwork(track);
        return;
    }
    const QJsonObject activity =
        activityFor(track, m_player->isPlaying(), positionMs, m_player->duration(), nowMs, m_artwork.value(key));
    m_sentStartMs = activity.isEmpty() ? 0 : nowMs - positionMs;
    m_lastSentMs = nowMs;
    sendFrame(Frame, setActivityPayload(activity));
}

namespace {
// The cover of the search result that is this song, from the song's own album when iTunes has it there too, as the
// same song is often on a single, the album and a deluxe edition, each with its own cover.
// A title without credits for other artists, which tags and iTunes write differently, such as "(feat. ...)". Other
// bracketed parts, like "(Part One)", are kept, so different songs stay different.
QString baseTitle(const QString &title) {
    static const QRegularExpression credit(
        QStringLiteral(R"(\s*[(\[]\s*(feat\.?|ft\.?|featuring|with|prod\.?)\s[^)\]]*[)\]])"),
        QRegularExpression::CaseInsensitiveOption);
    return QString(title).remove(credit).trimmed();
}

QString coverFor(const QJsonArray &results, const QVariantMap &track) {
    const QString title = baseTitle(track.value("title").toString());
    const QString artist = track.value("artist").toString().trimmed();
    const QString album = track.value("album").toString().trimmed();
    QString cover;
    for (const QJsonValue &result : results) {
        const QJsonObject song = result.toObject();
        // Collaborations are credited differently in tags and on iTunes, so either name may hold the other.
        const QString resultArtist = song.value("artistName").toString();
        const bool sameArtist =
            resultArtist.contains(artist, Qt::CaseInsensitive) || artist.contains(resultArtist, Qt::CaseInsensitive);
        if (baseTitle(song.value("trackName").toString()).compare(title, Qt::CaseInsensitive) != 0 || !sameArtist)
            continue;
        const bool sameAlbum = song.value("collectionName").toString().compare(album, Qt::CaseInsensitive) == 0;
        if (cover.isEmpty() || sameAlbum)
            cover = song.value("artworkUrl100").toString();
        if (sameAlbum)
            break;
    }
    return cover;
}
} // namespace

void DiscordPresence::lookUpArtwork(const QVariantMap &track) {
    const QString key = artworkKey(track);
    if (m_artworkLookup == key)
        return;
    m_artworkLookup = key;
    // iTunes search returns a public cover URL from one request, without a key. Searching by song rather than
    // album finds soundtracks and compilations, whose album artist isn't the song's artist.
    QUrl url(QStringLiteral("https://itunes.apple.com/search"));
    url.setQuery(QUrlQuery{{"term", track.value("artist").toString() + u' ' + track.value("title").toString()},
                           {"entity", "song"},
                           {"limit", "10"}});
    QNetworkRequest request(url);
    // Short, as the status waits for it.
    request.setTransferTimeout(4000);
    QNetworkReply *reply = m_net.get(request);
    m_artworkReply = reply;
    connect(reply, &QNetworkReply::finished, this, [this, reply, key, track] {
        reply->deleteLater();
        if (m_artworkLookup == key)
            m_artworkLookup.clear();
        // Turned off, or offline blackout started, while the lookup ran: nothing from it is kept.
        if (!m_enabled)
            return;
        // A request that didn't get through isn't remembered as a song without a cover.
        if (reply->error() != QNetworkReply::NoError) {
            m_artworkFailed = key;
            sendActivity();
            return;
        }
        const QJsonArray results = QJsonDocument::fromJson(reply->readAll()).object().value("results").toArray();
        const QString small = coverFor(results, track);
        // A song iTunes doesn't have shows the logo.
        m_artwork.insert(key, small.isEmpty() ? QString() : QString(small).replace("100x100bb", "512x512bb"));
        sendActivity();
    });
}

void DiscordPresence::sendFrame(quint32 opcode, const QJsonObject &payload) {
    m_socket.write(encodeFrame(opcode, payload));
}

bool DiscordPresence::selfCheck() {
    SelfCheck check("Discord presence");
    const QVariantMap track{{"title", "Song Title"}, {"artist", "Some Artist"}, {"album", "An Album"}};
    const QJsonObject activity = activityFor(track, true, 30000, 200000, 1000000);
    const QJsonObject timestamps = activity.value("timestamps").toObject();
    const QJsonObject assets = activity.value("assets").toObject();
    check.expect(activity.value("type").toInt() == 2, "shows as listening");
    const auto song = [](const char *name, const char *album, const char *cover) {
        return QJsonObject{
            {"trackName", name}, {"artistName", "Some Artist"}, {"collectionName", album}, {"artworkUrl100", cover}};
    };
    const QJsonArray results{song("Song Title (Part Two)", "An Album", "two"),
                             song("Song Title (feat. Guest)", "An Album (Deluxe)", "deluxe"),
                             song("Song Title", "An Album", "album")};
    check.expect(coverFor(results, track) == "album", "picks the song on its own album, not a deluxe edition");
    check.expect(coverFor(QJsonArray{results[1]}, track) == "deluxe", "matches a title credited to a guest");
    check.expect(coverFor(QJsonArray{results[0]}, track).isEmpty(), "keeps a differently named part apart");
    check.expect(activity.value("details") == "Song Title", "names the song");
    check.expect(activity.value("state") == "Some Artist", "names the artist");
    check.expect(timestamps.value("start").toInteger() == 970000, "starts the timer at the song's start");
    check.expect(timestamps.value("end").toInteger() == 1170000, "ends the timer at the song's end");
    check.expect(assets.value("large_text") == "An Album", "names the album");
    check.expect(assets.value("large_image") == "cassettecat", "shows the logo without a cover");
    check.expect(activity.value("status_display_type").toInt() == kShowDetails, "shows the song in the member list");
    check.expect(activity.value("buttons")[0].toObject().value("url") ==
                     "https://www.last.fm/music/Some+Artist/_/Song+Title",
                 "links the song on Last.fm");
    const QJsonObject coverAssets =
        activityFor(track, true, 0, 1000, 0, "https://example.org/cover.jpg").value("assets").toObject();
    check.expect(coverAssets.value("large_image") == "https://example.org/cover.jpg", "shows the cover");
    check.expect(coverAssets.value("small_image") == "cassettecat", "shows the logo beside the cover");
    check.expect(activityFor(track, false, 0, 0, 0).isEmpty(), "clears the status when paused");
    check.expect(activityFor({{"title", "X"}}, true, 0, 0, 0).isEmpty(), "shows nothing without an artist");

    // Exchange frames with a local stand-in for the Discord client.
    const QString name = QStringLiteral("cassettecat-discord-check-%1").arg(QCoreApplication::applicationPid());
    QLocalServer::removeServer(name);
    QLocalServer server;
    const bool listening = server.listen(name);
    check.expect(listening, "opens a stand-in for Discord");
    if (!listening)
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
    check.expect(presence.m_updateTimer.remainingTime() < firstWaitMs, "keeps a pending update");

    const QPair<quint32, QJsonObject> none{0, {}};
    const auto handshake = frames.value(0, none);
    const auto update = frames.value(1, none);
    check.expect(frames.size() == 2, "sends a handshake and one update");
    check.expect(handshake.first == Handshake, "starts with a handshake");
    check.expect(handshake.second.value("client_id").toString() == kClientId, "names the app in the handshake");
    check.expect(update.first == Frame, "sends the update as a frame");
    check.expect(update.second.value("cmd") == "SET_ACTIVITY", "sets the activity");
    // The player is paused, so the first update clears the activity.
    check.expect(update.second.value("args").toObject().value("activity").isNull(), "clears the activity when paused");
    return check.passed();
}
