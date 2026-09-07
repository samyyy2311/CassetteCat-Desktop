#include "streaming.h"
#include "remote_track_model.h"
#include "credential_vault.h"
#include "image_cache.h"
#include "network_requests.h"
#include "streaming_protocols.h"

#include <QCryptographicHash>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <QStandardPaths>
#include <QTimer>
#include <QTemporaryDir>
#include <QUrlQuery>
#include <QUuid>

#include <iostream>
#include <memory>

using namespace streaming::protocol;

namespace {

constexpr int kMaxArtDownloads = 6;
constexpr int kMaxArtBytes = 3 * 1024 * 1024;

void releaseArtworkDownload(QSet<QString> &pending, int &downloads, const QString &filePath)
{
    if (pending.remove(filePath) && downloads > 0) --downloads;
}

} // namespace

StreamingController::StreamingController(const QString &settingsPath, QObject *parent)
    : QObject(parent)
    , m_settingsPath(settingsPath)
    , m_net(new QNetworkAccessManager(this))
    , m_jellyfinModel(new RemoteTrackModel("jellyfin", this))
    , m_subsonicModel(new RemoteTrackModel("subsonic", this))
{
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    m_subsonicConnected = settings.value("stream/subsonicConnected", false).toBool();
    m_jellyfinConnected = settings.value("stream/jellyfinConnected", false).toBool();
    if (m_subsonicConnected && settings.value("stream/subsonicUrl").toString().isEmpty()) {
        m_subsonicConnected = false;
    }
    if (m_jellyfinConnected && settings.value("stream/jellyfinUrl").toString().isEmpty()) {
        m_jellyfinConnected = false;
    }
    updateStatusTexts();
}

bool StreamingController::isRemotePath(const QString &filePath)
{
    return filePath.startsWith("subsonic:") || filePath.startsWith("jellyfin:");
}

bool StreamingController::blackoutEnabled() const
{
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    return settings.value("network/offlineBlackout", false).toBool();
}

QString StreamingController::deviceId()
{
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    QString id = settings.value("stream/deviceId").toString();
    if (id.isEmpty()) {
        id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        settings.setValue("stream/deviceId", id);
    }
    return id;
}

void StreamingController::setRemoteTracks(const QVariantList &tracks)
{
    m_remoteTracks = tracks;
    m_jellyfinModel->setTracks(tracks);
    m_subsonicModel->setTracks(tracks);
    emit remoteTracksChanged();
    updateStatusTexts();
}

void StreamingController::removeProviderTracks(const QString &prefix)
{
    QVariantList kept;
    kept.reserve(m_remoteTracks.size());
    for (const QVariant &track : m_remoteTracks) {
        const QString path = track.toMap().value("filePath").toString();
        if (!path.startsWith(prefix)) {
            kept.append(track);
            continue;
        }
        m_remoteArt.remove(path);
        m_remoteArtSource.remove(path);
        releaseArtworkDownload(m_remoteArtPending, m_remoteArtDownloads, path);
    }
    setRemoteTracks(kept);
}

void StreamingController::setStatus(const QString &protocol, bool connected, const QString &status)
{
    if (protocol == "subsonic") {
        m_subsonicConnected = connected;
        m_subsonicStatus = status;
    } else {
        m_jellyfinConnected = connected;
        m_jellyfinStatus = status;
    }
    emit statusChanged();
}

void StreamingController::setRemoteLibraryLoading(bool loading)
{
    if (m_refreshing == loading) return;
    m_refreshing = loading;
    emit remoteLibraryLoadingChanged();
}

void StreamingController::updateStatusTexts()
{
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    int subCount = 0;
    int jellyCount = 0;
    for (const QVariant &track : m_remoteTracks) {
        const QString path = track.toMap().value("filePath").toString();
        if (path.startsWith("subsonic:")) {
            ++subCount;
        } else if (path.startsWith("jellyfin:")) {
            ++jellyCount;
        }
    }
    if (m_subsonicConnected) {
        const QString user = settings.value("stream/subsonicUsername").toString();
        m_subsonicStatus = QString("%1 · %2 %3").arg(
            user.isEmpty() ? QString("Connected") : user,
            QString::number(subCount), subCount == 1 ? QString("song") : QString("songs"));
    }
    if (m_jellyfinConnected) {
        const QString user = settings.value("stream/jellyfinUsername").toString();
        m_jellyfinStatus = QString("%1 · %2 %3").arg(
            user.isEmpty() ? QString("Connected") : user,
            QString::number(jellyCount), jellyCount == 1 ? QString("song") : QString("songs"));
    }
    if (m_subsonicStatus.isEmpty()) {
        m_subsonicStatus = QString("Not connected");
    }
    if (m_jellyfinStatus.isEmpty()) {
        m_jellyfinStatus = QString("Not connected");
    }
    emit statusChanged();
}

QNetworkReply *StreamingController::trackReply(QNetworkReply *reply)
{
    m_pendingReplies.append(QPointer<QNetworkReply>(reply));
    QTimer::singleShot(streaming::detail::requestTimeoutMs, reply, [reply] {
        if (reply && reply->isRunning()) {
            reply->abort();
        }
    });
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        m_pendingReplies.removeAll(reply);
        reply->deleteLater();
    });
    return reply;
}

QString StreamingController::friendlyError(QNetworkReply *reply, const QString &fallback)
{
    if (!reply) {
        return fallback;
    }
    switch (reply->error()) {
    case QNetworkReply::HostNotFoundError:
        return QString("Couldn't find that server. Check the URL.");
    case QNetworkReply::ConnectionRefusedError:
        return QString("Couldn't reach the server. Check the URL and that it's running.");
    case QNetworkReply::TimeoutError:
    case QNetworkReply::OperationCanceledError:
        return QString("The server took too long to respond. Check the URL and your connection.");
    case QNetworkReply::SslHandshakeFailedError:
        return QString("The server certificate isn't trusted. Self-signed certificates need manual trust.");
    case QNetworkReply::AuthenticationRequiredError:
        return QString("Wrong username or password.");
    case QNetworkReply::ContentAccessDenied:
    case QNetworkReply::ContentOperationNotPermittedError:
        return QString("Access denied. Check the username and password.");
    case QNetworkReply::ContentNotFoundError:
        return QString("Server endpoint not found. Check the URL and server type.");
    case QNetworkReply::NoError:
        return fallback;
    default:
        return fallback;
    }
}

void StreamingController::beginRefresh()
{
    if (blackoutEnabled()) {
        setRemoteTracks({});
        return;
    }
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const bool wantSubsonic = settings.value("stream/subsonicConnected", false).toBool()
        && !settings.value("stream/subsonicUrl").toString().isEmpty();
    const bool wantJellyfin = settings.value("stream/jellyfinConnected", false).toBool()
        && !settings.value("stream/jellyfinUrl").toString().isEmpty();
    if (!wantSubsonic && !wantJellyfin) {
        setRemoteTracks({});
        return;
    }
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }
    setRemoteLibraryLoading(true);
    const int tokenSnapshot = ++m_refreshToken;
    if (wantSubsonic) {
        removeProviderTracks("subsonic:");
    }
    if (wantJellyfin) {
        removeProviderTracks("jellyfin:");
    }
    m_pendingStages = 0;
    if (wantSubsonic) {
        const QString password = vault.loadSecret("subsonic");
        if (password.isEmpty()) {
            setStatus("subsonic", false, QString("Saved password is missing. Connect again."));
            emit serverFailed("subsonic", QString("Saved password is missing. Connect again."));
        } else {
            ++m_pendingStages;
            refreshSubsonic(settings.value("stream/subsonicUrl").toString(),
                            settings.value("stream/subsonicUsername").toString(), password, tokenSnapshot);
        }
    }
    if (wantJellyfin) {
        const QString token = vault.loadSecret("jellyfin");
        const QString userId = settings.value("stream/jellyfinUserId").toString();
        if (token.isEmpty() || userId.isEmpty()) {
            setStatus("jellyfin", false, QString("Saved login is missing. Connect again."));
            emit serverFailed("jellyfin", QString("Saved login is missing. Connect again."));
        } else {
            ++m_pendingStages;
            refreshJellyfin(settings.value("stream/jellyfinUrl").toString(), userId, token, tokenSnapshot);
        }
    }
    if (m_pendingStages == 0) {
        setRemoteLibraryLoading(false);
    }
}

void StreamingController::refreshLibrary()
{
    beginRefresh();
}

void StreamingController::finishRefreshStage()
{
    if (--m_pendingStages <= 0) {
        m_pendingStages = 0;
        if (m_refreshQueued) {
            m_refreshQueued = false;
            m_refreshing = false;
            beginRefresh();
        } else {
            setRemoteLibraryLoading(false);
        }
    }
}

void StreamingController::cancelPendingRequests()
{
    ++m_subConnectToken;
    ++m_jellyConnectToken;
    ++m_refreshToken;
    setRemoteLibraryLoading(false);
    m_refreshQueued = false;
    m_pendingStages = 0;
    cancelNetworkReplies(m_pendingReplies);
}

void StreamingController::setBlackoutEnabled(bool enabled)
{
    if (!enabled) return;

    cancelPendingRequests();
    m_remoteArt.clear();
    m_remoteArtSource.clear();
    m_remoteArtPending.clear();
    m_remoteArtDownloads = 0;
    setRemoteTracks({});
}

void StreamingController::disconnectServer(const QString &protocol)
{
    cancelPendingRequests();
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (protocol == "subsonic") {
        vault.clearSecret("subsonic");
        settings.setValue("stream/subsonicConnected", false);
        setStatus("subsonic", false, QString("Not connected"));
        removeProviderTracks("subsonic:");
    } else if (protocol == "jellyfin") {
        vault.clearSecret("jellyfin");
        settings.setValue("stream/jellyfinConnected", false);
        setStatus("jellyfin", false, QString("Not connected"));
        removeProviderTracks("jellyfin:");
    }
}

void StreamingController::setServerFavorite(const QString &filePath, bool favorite)
{
    if (blackoutEnabled()) {
        emit serverFavoriteFailed(filePath);
        return;
    }
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (filePath.startsWith("subsonic:") && settings.value("stream/subsonicConnected", false).toBool()) {
        const QString password = vault.loadSecret("subsonic");
        if (password.isEmpty()) {
            emit serverFavoriteFailed(filePath);
            return;
        }
        const QString base = settings.value("stream/subsonicUrl").toString();
        const QString user = settings.value("stream/subsonicUsername").toString();
        const QString salt = randomSalt();
        const QString endpoint = favorite ? "star.view" : "unstar.view";
        QNetworkRequest request(subsonicUrl(base, endpoint, user, md5Hex(password + salt), salt,
                                            {{"id", filePath.mid(9)}}));
        request.setTransferTimeout(streaming::detail::requestTimeoutMs);
        QNetworkReply *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [=, this] {
            const QJsonObject response = parseSubsonicBody(reply->readAll());
            if (response.contains("_error") || reply->error() != QNetworkReply::NoError) {
                emit serverFavoriteFailed(filePath);
            }
        });
        return;
    }
    if (filePath.startsWith("jellyfin:") && settings.value("stream/jellyfinConnected", false).toBool()) {
        const QString token = vault.loadSecret("jellyfin");
        const QString userId = settings.value("stream/jellyfinUserId").toString();
        if (token.isEmpty() || userId.isEmpty()) {
            emit serverFavoriteFailed(filePath);
            return;
        }
        const QString base = settings.value("stream/jellyfinUrl").toString();
        QNetworkRequest request(QUrl(base + "/Users/" + userId + "/FavoriteItems/" + filePath.mid(9)));
        request.setTransferTimeout(streaming::detail::requestTimeoutMs);
        const QString header = jellyfinAuthHeader(deviceId(), token);
        request.setRawHeader("Authorization", header.toUtf8());
        request.setRawHeader("X-Emby-Authorization", header.toUtf8());
        request.setRawHeader("X-Emby-Token", token.toUtf8());
        QNetworkReply *reply = favorite
            ? trackReply(m_net->post(request, QByteArray()))
            : trackReply(m_net->deleteResource(request));
        connect(reply, &QNetworkReply::finished, this, [=, this] {
            if (reply->error() != QNetworkReply::NoError) {
                emit serverFavoriteFailed(filePath);
            }
        });
        return;
    }
}

QString StreamingController::remoteArtwork(const QString &filePath)
{
    if (blackoutEnabled()) return {};

    const auto cached = m_remoteArt.constFind(filePath);
    if (cached != m_remoteArt.cend()) {
        return *cached;
    }
    if (m_remoteArtPending.contains(filePath) || m_remoteArtDownloads >= kMaxArtDownloads) {
        return {};
    }
    const auto source = m_remoteArtSource.constFind(filePath);
    if (source == m_remoteArtSource.cend() || source->isEmpty()) {
        return {};
    }
    m_remoteArtPending.insert(filePath);
    ++m_remoteArtDownloads;
    const QString artworkSource = *source;
    QNetworkRequest request{QUrl{artworkSource}};
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, filePath, artworkSource] {
        releaseArtworkDownload(m_remoteArtPending, m_remoteArtDownloads, filePath);
        if (blackoutEnabled() || m_remoteArtSource.value(filePath) != artworkSource) return;

        QString local;
        if (reply->error() == QNetworkReply::NoError) {
            const QByteArray data = reply->readAll();
            const QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
            // Bound what we keep: small embedded-style artwork only.
            if (data.size() > 32 && data.size() <= kMaxArtBytes) {
                local = saveCachedImage(data, filePath, contentType.contains("png", Qt::CaseInsensitive), "covers");
            }
        }
        m_remoteArt.insert(filePath, local);
        ++m_remoteArtRevision;
        emit remoteArtChanged();
    });
    return {};
}

QUrl StreamingController::streamSourceFor(const QString &source, const QString &remoteId) const
{
    if (remoteId.isEmpty() || blackoutEnabled()) {
        return {};
    }
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (source == "subsonic" && settings.value("stream/subsonicConnected", false).toBool()) {
        const QString password = vault.loadSecret("subsonic");
        if (password.isEmpty()) {
            return {};
        }
        const QString salt = randomSalt();
        return subsonicUrl(settings.value("stream/subsonicUrl").toString(), "stream.view",
                           settings.value("stream/subsonicUsername").toString(),
                           md5Hex(password + salt), salt, {{"id", remoteId}});
    }
    if (source == "jellyfin" && settings.value("stream/jellyfinConnected", false).toBool()) {
        const QString token = vault.loadSecret("jellyfin");
        if (token.isEmpty()) {
            return {};
        }
        QUrl url(settings.value("stream/jellyfinUrl").toString() + "/Audio/" + remoteId + "/stream");
        QUrlQuery q;
        q.addQueryItem("static", "true");
        q.addQueryItem("api_key", token);
        url.setQuery(q);
        return url;
    }
    return {};
}

QVariantMap StreamingController::serverConfigSnapshot() const
{
    return serverConfigSnapshot(m_settingsPath);
}

QVariantMap StreamingController::serverConfigSnapshot(const QString &settingsPath)
{
    QSettings settings(settingsPath, QSettings::IniFormat);
    QVariantMap snapshot;
    snapshot.insert("subsonic/url", settings.value("stream/subsonicUrl").toString());
    snapshot.insert("subsonic/username", settings.value("stream/subsonicUsername").toString());
    snapshot.insert("subsonic/connected", settings.value("stream/subsonicConnected", false).toBool());
    snapshot.insert("jellyfin/url", settings.value("stream/jellyfinUrl").toString());
    snapshot.insert("jellyfin/username", settings.value("stream/jellyfinUsername").toString());
    snapshot.insert("jellyfin/connected", settings.value("stream/jellyfinConnected", false).toBool());
    return snapshot;
}

namespace streaming {

namespace {

int g_failures = 0;

void check(bool condition, const char *name)
{
    if (!condition) {
        ++g_failures;
        std::cerr << "streaming self-check FAILED: " << name << std::endl;
    }
}

} // namespace

bool runSelfChecks(bool includeVaultProbe)
{
    g_failures = 0;

    check(normalizeServerUrl("music.example.com") == "https://music.example.com", "normalize-adds-https");
    check(normalizeServerUrl("  http://music.example.com/ ") == "http://music.example.com", "normalize-keeps-http");
    check(normalizeServerUrl("https://music.example.com///") == "https://music.example.com", "normalize-trims-slashes");
    check(normalizeServerUrl("   ").isEmpty(), "normalize-blank");
    check(normalizeServerUrl("192.168.1.112", 8096) == "http://192.168.1.112:8096", "normalize-local-ip-default-port");
    check(normalizeServerUrl("192.168.1.112:8096", 8096) == "http://192.168.1.112:8096", "normalize-local-ip-explicit-port");
    check(normalizeServerUrl("http://localhost", 4533) == "http://localhost:4533", "normalize-localhost-default-port");

    check(md5Hex("abc") == "900150983cd24fb0d6963f7d28e17f72", "md5-vector");
    const QString salt = randomSalt();
    check(salt.size() == 12, "salt-length");
    check(!salt.contains(QRegularExpression("[^0-9a-f]")), "salt-hex");

    const QUrl subUrl = subsonicUrl("https://music.example.com", "ping.view", "user",
                                    "0123456789abcdef0123456789abcdef", "abcdef012345");
    const QUrlQuery subQuery(subUrl);
    check(subQuery.queryItemValue("u") == "user", "subsonic-user");
    check(subQuery.queryItemValue("t") == "0123456789abcdef0123456789abcdef", "subsonic-token");
    check(subQuery.queryItemValue("s") == "abcdef012345", "subsonic-salt");
    check(subQuery.queryItemValue("v") == "1.16.1", "subsonic-version");
    check(subQuery.queryItemValue("c") == "CassetteCat", "subsonic-client");
    check(subQuery.queryItemValue("f") == "json", "subsonic-format");
    check(!subUrl.toString().contains("secret-password"), "subsonic-no-password-in-url");
    check(subsonicUrl("https://m.example.com", "stream.view", "u", "t", "s", {{"id", "42"}}).toString()
              .contains("stream.view"),
          "subsonic-stream-endpoint");

    const QByteArray okBody = R"({"subsonic-response": {"status": "ok", "albumList2": {"album": [{"id": "a1"}]}}})";
    const QJsonObject okResponse = parseSubsonicBody(okBody);
    check(!okResponse.contains("_error"), "subsonic-ok");
    check(jsonArrayTolerant(okResponse.value("albumList2").toObject(), "album").size() == 1, "subsonic-album-ids");

    const QByteArray singleBody = R"({"subsonic-response": {"status": "ok", "album": {"id": "a1", "name": "N", "song": {"id": "s1", "title": "T"}}}})";
    const QJsonObject singleResponse = parseSubsonicBody(singleBody);
    check(jsonArrayTolerant(singleResponse.value("album").toObject(), "song").size() == 1, "subsonic-single-tolerance");

    const QByteArray failBody = R"({"subsonic-response": {"status": "failed", "error": {"code": 40, "message": "Wrong username"}}})";
    check(parseSubsonicBody(failBody).value("_error").toString() == "Wrong username", "subsonic-error-message");
    check(parseSubsonicBody(QByteArray("{broken")).contains("_error"), "subsonic-broken-json");

    const QString preHeader = jellyfinAuthHeader("device-1", {});
    check(preHeader.contains("Client=\"CassetteCat\""), "jellyfin-client");
    check(preHeader.contains("DeviceId=\"device-1\""), "jellyfin-device");
    check(!preHeader.contains("Token="), "jellyfin-no-token-pre-login");
    const QString postHeader = jellyfinAuthHeader("device-1", "tok123");
    check(postHeader.contains("Token=\"tok123\""), "jellyfin-token-post-login");
    check(!postHeader.contains("s3cret"), "jellyfin-no-password-in-header");

    const QByteArray itemsBody = R"({"Items": [{"Id": "1", "Name": "Song", "AlbumArtist": "A", "Album": "B", "AlbumId": "al", "ProductionYear": 2020, "RunTimeTicks": 2100000000, "ImageTags": {"Primary": "p"}, "UserData": {"IsFavorite": true}, "Genres": ["Rock"], "Container": "mp3"}, {"Id": "2", "Name": "Bare"}]})";
    const QJsonArray items = QJsonDocument::fromJson(itemsBody).object().value("Items").toArray();
    const QVariantMap full = jellyfinTrackMap(items.at(0).toObject());
    check(full.value("filePath").toString() == "jellyfin:1", "jellyfin-path");
    check(full.value("durationSeconds").toInt() == 210, "jellyfin-duration");
    check(full.value("format").toString() == "MP3", "jellyfin-format");
    check(full.value("isFavorite").toBool(), "jellyfin-favorite");
    check(full.value("remoteArtId").toString() == "1", "jellyfin-art-item");
    const QVariantMap bare = jellyfinTrackMap(items.at(1).toObject());
    check(bare.value("artist").toString() == "Unknown Artist", "jellyfin-defaults");
    check(bare.value("remoteArtId").toString().isEmpty(), "jellyfin-no-art");

    const QVariantMap subTrack = subsonicTrackMap(
        QJsonDocument::fromJson(R"({"id": "s9", "title": "T", "duration": 200})").object(), "Alb", "cov");
    check(subTrack.value("filePath").toString() == "subsonic:s9", "subsonic-path");
    check(subTrack.value("durationSeconds").toInt() == 200, "subsonic-duration");
    check(!subTrack.value("isFavorite").toBool(), "subsonic-unstarred");
    check(subTrack.value("remoteArtId").toString() == "cov", "subsonic-album-art-fallback");

    {
        RemoteTrackModel model("jellyfin");
        model.setTracks({
            QVariantMap{{"source", "jellyfin"}, {"title", "J"}},
            QVariantMap{{"source", "subsonic"}, {"title", "S"}}
        });
        check(model.rowCount() == 1, "remote-model-filter");
        check(model.data(model.index(0, 0), RemoteTrackModel::TrackRole).toMap().value("title") == "J",
              "remote-model-role");
    }

    {
        QSet<QString> pending{"jellyfin:1"};
        int downloads = 1;
        releaseArtworkDownload(pending, downloads, "jellyfin:1");
        releaseArtworkDownload(pending, downloads, "jellyfin:1");
        check(pending.isEmpty() && downloads == 0, "remote-art-slot-released");
    }

    const QString redacted = CredentialVault::redactSecrets(
        "https://m.example.com/Audio/1/stream?static=true&api_key=tok123 and t=abc&s=def Token=\"tok123\"");
    check(!redacted.contains("tok123") && !redacted.contains("t=abc"), "redact-secrets");
    const QString redactedHeaders = CredentialVault::redactSecrets(
        "Authorization: Bearer secret-token\nX-Emby-Token: second-token");
    check(!redactedHeaders.contains("secret-token") && !redactedHeaders.contains("second-token"),
          "redact-secret-headers");
    check(redacted.contains("static=true"), "redact-keeps-rest");

#ifdef _WIN32
    if (includeVaultProbe) {
        CredentialVault vault;
        const QString probe = QString("selfcheck-%1").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
        check(vault.saveSecret("__probe__", probe), "vault-save");
        check(vault.loadSecret("__probe__") == probe, "vault-roundtrip");
        check(vault.clearSecret("__probe__"), "vault-clear");
        check(vault.loadSecret("__probe__").isEmpty(), "vault-cleared");
    }
#else
    Q_UNUSED(includeVaultProbe);
#endif

    {
        QTemporaryDir dir;
        check(dir.isValid(), "snapshot-tempdir");
        QSettings settings(dir.filePath("s.ini"), QSettings::IniFormat);
        settings.setValue("stream/subsonicUrl", "https://m.example.com");
        settings.setValue("stream/subsonicUsername", "user");
        settings.setValue("stream/subsonicConnected", true);
        settings.sync();
        const QVariantMap snapshot = StreamingController::serverConfigSnapshot(dir.filePath("s.ini"));
        check(snapshot.value("subsonic/url").toString() == "https://m.example.com", "snapshot-url");
        bool secretLeak = false;
        for (auto it = snapshot.cbegin(); it != snapshot.cend(); ++it) {
            const QString key = it.key().toLower();
            if (key.contains("password") || key.contains("token") || key.contains("secret")
                || key.contains("session") || key.contains("credential")) {
                secretLeak = true;
            }
            if (it.value().toString().contains("s3cret-pw") || it.value().toString().contains("tok-abc")) {
                secretLeak = true;
            }
        }
        check(!secretLeak, "snapshot-excludes-secrets");
    }

    return g_failures == 0;
}

} // namespace streaming
