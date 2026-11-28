#include "streaming.h"

#include "app_paths.h"
#include "app_settings.h"
#include "remote_track_model.h"
#include "credential_vault.h"
#include "image_cache.h"
#include "network_requests.h"
#include "streaming_protocols.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkInformation>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QRegularExpression>
#include <QSet>
#include <QSettings>
#include <QSslError>
#include <QStandardPaths>
#include <QTimer>
#include <QTemporaryDir>
#include <QUrlQuery>
#include <QUuid>

#include <algorithm>
#include <optional>

#include <iostream>
#include <memory>

using namespace streaming::protocol;

namespace {

constexpr int kMaxArtDownloads = 6;
constexpr int kMaxArtBytes = 3 * 1024 * 1024;

void releaseArtworkDownload(QSet<QString> &pending, int &downloads, const QString &filePath) {
    if (pending.remove(filePath) && downloads > 0)
        --downloads;
}

} // namespace

StreamingController::StreamingController(const QString &settingsPath, QObject *parent)
    : QObject(parent), m_settingsPath(settingsPath), m_net(new QNetworkAccessManager(this)),
      m_jellyfinModel(new RemoteTrackModel("jellyfin", this)), m_subsonicModel(new RemoteTrackModel("subsonic", this)) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    m_subsonicConnected = settings.value("stream/subsonicConnected", false).toBool();
    m_jellyfinConnected = settings.value("stream/jellyfinConnected", false).toBool();
    if (m_subsonicConnected && settings.value("stream/subsonicUrl").toString().isEmpty()) {
        m_subsonicConnected = false;
    }
    if (m_jellyfinConnected && settings.value("stream/jellyfinUrl").toString().isEmpty()) {
        m_jellyfinConnected = false;
    }
    const QJsonDocument cachedDocument =
        QJsonDocument::fromJson(SettingsController::loadDataFile("server-tracks", "stream/cachedTracks").toUtf8());
    if (cachedDocument.isArray()) {
        m_remoteTracks = cachedDocument.array().toVariantList();
        m_jellyfinModel->setTracks(m_remoteTracks);
        m_subsonicModel->setTracks(m_remoteTracks);
    }
    updateStatusTexts();
    // Which address answers is checked again whenever the network changes, such as leaving home.
    if (QNetworkInformation::loadDefaultBackend())
        connect(QNetworkInformation::instance(), &QNetworkInformation::reachabilityChanged, this,
                &StreamingController::checkServerAddresses);
    checkServerAddresses();
}

QString StreamingController::serverBase(const QString &protocol) const {
    const QString active = m_activeBase.value(protocol);
    if (!active.isEmpty())
        return active;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    return settings.value("stream/" + protocol + "Url").toString();
}

// The queue is kept on your Navidrome or Subsonic server, so CassetteCat on another device can carry on from it.
// Songs from elsewhere are left out, and so is anything past the first 200, which keeps the request short.
void StreamingController::saveServerQueue(const QStringList &filePaths, const QString &currentPath, qint64 positionMs) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const QString password = CredentialVault().loadSecret("subsonic");
    if (blackoutEnabled() || !currentPath.startsWith("subsonic:") || password.isEmpty() ||
        !settings.value("stream/subsonicConnected", false).toBool())
        return;
    QList<QPair<QString, QString>> extra;
    for (const QString &path : filePaths) {
        if (path.startsWith("subsonic:") && extra.size() < 200)
            extra.append({"id", path.mid(9)});
    }
    extra.append({{"current", currentPath.mid(9)}, {"position", QString::number(qMax<qint64>(0, positionMs))}});
    const QString salt = randomSalt();
    QNetworkRequest request(subsonicUrl(serverBase(QStringLiteral("subsonic")), "savePlayQueue.view",
                                        settings.value("stream/subsonicUsername").toString(), md5Hex(password + salt),
                                        salt, extra));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, reply, &QObject::deleteLater);
}

// The queue another player left on the server, offered to carry on here; one this app saved itself isn't.
void StreamingController::checkServerQueue() {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const QString password = CredentialVault().loadSecret("subsonic");
    if (blackoutEnabled() || password.isEmpty() || !settings.value("stream/subsonicConnected", false).toBool())
        return;
    const QString salt = randomSalt();
    QNetworkRequest request(subsonicUrl(serverBase(QStringLiteral("subsonic")), "getPlayQueue.view",
                                        settings.value("stream/subsonicUsername").toString(), md5Hex(password + salt),
                                        salt));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        const QJsonObject queue = parseSubsonicBody(reply->readAll()).value("playQueue").toObject();
        const QString from = queue.value("changedBy").toString();
        if (reply->error() != QNetworkReply::NoError || from.isEmpty() || from == subsonicClientName())
            return;
        QStringList paths;
        for (const QJsonValue &entry : jsonArrayTolerant(queue, "entry"))
            paths.append("subsonic:" + entry.toObject().value("id").toVariant().toString());
        const QString current = queue.value("current").toVariant().toString();
        if (!paths.isEmpty() && !current.isEmpty())
            emit serverQueueFound(paths, "subsonic:" + current, queue.value("position").toVariant().toLongLong(), from);
    });
}

// How good a server stream is, in kbps; 0 is the original file. A metered connection, such as a phone's hotspot, has
// its own choice, so data isn't spent on large files there.
int StreamingController::streamLimitKbps() const {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const bool metered = QNetworkInformation::instance() && QNetworkInformation::instance()->isMetered();
    return settings.value(metered ? "stream/meteredQualityKbps" : "stream/qualityKbps", 0).toInt();
}

void StreamingController::setStreamQuality(bool metered, int kbps) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    settings.setValue(metered ? "stream/meteredQualityKbps" : "stream/qualityKbps", kbps);
}

void StreamingController::setAwayUrl(const QString &protocol, const QString &url) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const QString trimmed = withoutTrailingSlashes(url.trimmed());
    if (trimmed.isEmpty())
        settings.remove("stream/" + protocol + "AwayUrl");
    else
        settings.setValue("stream/" + protocol + "AwayUrl", trimmed);
    m_activeBase.remove(protocol);
    checkServerAddresses();
}

// A server with an away address, such as a domain name for when you're out, uses whichever address answers, a home
// network one first. Nothing answering keeps the address already in use.
void StreamingController::checkServerAddresses() {
    if (blackoutEnabled())
        return;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    for (const QString protocol : {QStringLiteral("subsonic"), QStringLiteral("jellyfin")}) {
        const QString home = withoutTrailingSlashes(settings.value("stream/" + protocol + "Url").toString());
        const QString away = settings.value("stream/" + protocol + "AwayUrl").toString();
        if (home.isEmpty() || away.isEmpty() || !settings.value("stream/" + protocol + "Connected", false).toBool()) {
            m_activeBase.remove(protocol);
            continue;
        }
        QStringList candidates{home, away};
        std::stable_sort(candidates.begin(), candidates.end(), [](const QString &a, const QString &b) {
            return isPrivateOrLocalHost(QUrl(a).host()) && !isPrivateOrLocalHost(QUrl(b).host());
        });
        probeServerAddress(protocol, candidates, ++m_addressChecks[protocol]);
    }
}

void StreamingController::probeServerAddress(const QString &protocol, const QStringList &candidates, quint64 check) {
    if (candidates.isEmpty() || check != m_addressChecks.value(protocol))
        return;
    const QString base = candidates.first();
    // Any answer means the server is there; these need no sign-in, or turn down the missing one.
    QNetworkRequest request(QUrl(base + (protocol == u"jellyfin" ? "/System/Info/Public" : "/rest/ping.view")));
    request.setTransferTimeout(4000);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, protocol, candidates, check, base] {
        reply->deleteLater();
        const bool answered = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).isValid();
        if (check != m_addressChecks.value(protocol))
            return;
        if (!answered) {
            probeServerAddress(protocol, candidates.mid(1), check);
            return;
        }
        if (m_activeBase.value(protocol) == base)
            return;
        const bool switched = !m_activeBase.value(protocol).isEmpty();
        m_activeBase.insert(protocol, base);
        // Covers were linked to the other address, so the library is fetched again from this one.
        if (switched)
            refreshLibrary();
    });
}

bool StreamingController::isRemotePath(const QString &filePath) {
    return filePath.startsWith("subsonic:") || filePath.startsWith("jellyfin:");
}

bool StreamingController::blackoutEnabled() const {
    return SettingsController::globalValue("network/offlineBlackout", false).toBool();
}

QString StreamingController::deviceId() {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    QString id = settings.value("stream/deviceId").toString();
    if (id.isEmpty()) {
        id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        settings.setValue("stream/deviceId", id);
        settings.sync();
    }
    return id;
}

void StreamingController::setRemoteTracks(const QVariantList &tracks) {
    m_remoteTracks = tracks;
    SettingsController::saveDataFile(
        "server-tracks", QString::fromUtf8(QJsonDocument::fromVariant(tracks).toJson(QJsonDocument::Compact)),
        "stream/cachedTracks");
    m_jellyfinModel->setTracks(tracks);
    m_subsonicModel->setTracks(tracks);
    emit remoteTracksChanged();
    updateStatusTexts();
}

void StreamingController::replaceProviderTracks(const QString &prefix, const QVariantList &tracks) {
    QSet<QString> replacementArtPaths;
    for (const QVariant &track : tracks) {
        const QVariantMap map = track.toMap();
        if (!map.value("remoteArtId").toString().isEmpty())
            replacementArtPaths.insert(map.value("filePath").toString());
    }

    QVariantList kept;
    kept.reserve(m_remoteTracks.size() + tracks.size());
    for (const QVariant &track : m_remoteTracks) {
        const QString path = track.toMap().value("filePath").toString();
        if (!path.startsWith(prefix)) {
            kept.append(track);
            continue;
        }
        m_remoteArt.remove(path);
        if (!replacementArtPaths.contains(path)) {
            m_remoteArtSource.remove(path);
            releaseArtworkDownload(m_remoteArtPending, m_remoteArtDownloads, path);
        }
    }
    kept += tracks;
    setRemoteTracks(kept);
}

void StreamingController::removeProviderTracks(const QString &prefix) {
    replaceProviderTracks(prefix, {});
}

void StreamingController::setStatus(const QString &protocol, bool connected, const QString &status) {
    if (protocol == "subsonic") {
        m_subsonicConnected = connected;
        m_subsonicStatus = status;
    } else {
        m_jellyfinConnected = connected;
        m_jellyfinStatus = status;
    }
    emit statusChanged();
}

void StreamingController::setRemoteLibraryLoading(bool loading) {
    if (m_refreshing == loading)
        return;
    m_refreshing = loading;
    emit remoteLibraryLoadingChanged();
}

void StreamingController::updateStatusTexts() {
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
        m_subsonicStatus = tr("%1 · %n song(s)", "", subCount).arg(user.isEmpty() ? tr("Connected") : user);
    }
    if (m_jellyfinConnected) {
        const QString user = settings.value("stream/jellyfinUsername").toString();
        m_jellyfinStatus = tr("%1 · %n song(s)", "", jellyCount).arg(user.isEmpty() ? tr("Connected") : user);
    }
    if (m_subsonicStatus.isEmpty()) {
        m_subsonicStatus = tr("Not connected");
    }
    if (m_jellyfinStatus.isEmpty()) {
        m_jellyfinStatus = tr("Not connected");
    }
    emit statusChanged();
}

namespace {
bool sameServer(const QUrl &a, const QUrl &b) {
    return a.host().compare(b.host(), Qt::CaseInsensitive) == 0 && a.port(443) == b.port(443);
}

// Whether the user chose to trust the certificate of the saved server that \p url points at.
bool trustsSavedServer(const QSettings &settings, const QString &service, const QUrl &url) {
    const QUrl savedUrl(settings.value("stream/" + service + "Url").toString());
    return settings.value("stream/" + service + "TrustCert", false).toBool() && savedUrl.isValid() &&
           sameServer(savedUrl, url);
}

// Only errors about who issued the certificate can be set aside; any other error keeps the connection refused.
std::optional<QList<QSslError>> ignorableErrors(const QList<QSslError> &errors) {
    QList<QSslError> ignorable;
    for (const auto &err : errors) {
        switch (err.error()) {
        case QSslError::SelfSignedCertificate:
        case QSslError::SelfSignedCertificateInChain:
        case QSslError::UnableToGetLocalIssuerCertificate:
        case QSslError::UnableToVerifyFirstCertificate:
        case QSslError::CertificateUntrusted:
            ignorable.append(err);
            break;
        default:
            return std::nullopt;
        }
    }
    return ignorable;
}
} // namespace

QNetworkReply *StreamingController::trackReply(QNetworkReply *reply, bool allowSelfSigned) {
    if (!reply) {
        return nullptr;
    }
    const QUrl originalUrl = reply->url();
    const QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (allowSelfSigned || trustsSavedServer(settings, "subsonic", originalUrl) ||
        trustsSavedServer(settings, "jellyfin", originalUrl)) {
        connect(reply, &QNetworkReply::sslErrors, reply,
                [this, reply, originalUrl, allowSelfSigned](const QList<QSslError> &errors) {
                    handleSslErrors(reply, originalUrl, allowSelfSigned, errors);
                });
    }
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

void StreamingController::handleSslErrors(QNetworkReply *reply, const QUrl &originalUrl, bool allowSelfSigned,
                                          const QList<QSslError> &errors) {
    const QUrl currentUrl = reply->url();
    const bool sameOrigin = currentUrl.scheme() == originalUrl.scheme() && sameServer(currentUrl, originalUrl);
    QSslCertificate peerCert = reply->sslConfiguration().peerCertificate();
    if (peerCert.isNull() && !errors.isEmpty()) {
        peerCert = errors.first().certificate();
    }
    if (!acceptsCertificate(currentUrl, peerCert, sameOrigin && allowSelfSigned)) {
        return;
    }
    const std::optional<QList<QSslError>> ignorable = ignorableErrors(errors);
    if (ignorable && !ignorable->isEmpty()) {
        reply->ignoreSslErrors(*ignorable);
    }
}

bool StreamingController::acceptsCertificate(const QUrl &url, const QSslCertificate &cert, bool connecting) {
    // A saved certificate is only replaced after the user disconnects, which clears it.
    if (!connecting || hasPinnedCertificate(m_settingsPath, url)) {
        return isServerCertTrusted(url, cert);
    }
    if (cert.isNull()) {
        return false;
    }
    // While connecting, the first certificate the server shows is taken, and a different one after it is refused.
    const QString digest = QString::fromLatin1(cert.digest(QCryptographicHash::Sha256).toHex());
    const QString hostKey = QString("%1:%2").arg(url.host().toLower()).arg(url.port(443));
    if (!m_pendingCertDigests.contains(hostKey)) {
        m_pendingCertDigests.insert(hostKey, digest);
        return true;
    }
    return m_pendingCertDigests.value(hostKey).compare(digest, Qt::CaseInsensitive) == 0;
}

bool StreamingController::isServerCertTrusted(const QUrl &url, const QSslCertificate &cert) const {
    if (url.scheme() != QLatin1String("https") || cert.isNull()) {
        return false;
    }
    const QString certDigest = QString::fromLatin1(cert.digest(QCryptographicHash::Sha256).toHex());
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (settings.value("stream/subsonicTrustCert", false).toBool()) {
        const QUrl subUrl(settings.value("stream/subsonicUrl").toString());
        if (subUrl.isValid() && subUrl.host().compare(url.host(), Qt::CaseInsensitive) == 0 &&
            (subUrl.port(443) == url.port(443))) {
            const QString storedDigest = settings.value("stream/subsonicCertDigest").toString();
            if (!storedDigest.isEmpty() && storedDigest.compare(certDigest, Qt::CaseInsensitive) == 0) {
                return true;
            }
        }
    }
    if (settings.value("stream/jellyfinTrustCert", false).toBool()) {
        const QUrl jellyUrl(settings.value("stream/jellyfinUrl").toString());
        if (jellyUrl.isValid() && jellyUrl.host().compare(url.host(), Qt::CaseInsensitive) == 0 &&
            (jellyUrl.port(443) == url.port(443))) {
            const QString storedDigest = settings.value("stream/jellyfinCertDigest").toString();
            if (!storedDigest.isEmpty() && storedDigest.compare(certDigest, Qt::CaseInsensitive) == 0) {
                return true;
            }
        }
    }
    return false;
}

bool StreamingController::hasPinnedCertificate(const QString &settingsPath, const QUrl &url) {
    QSettings settings(settingsPath, QSettings::IniFormat);
    for (const QString &provider : {QStringLiteral("subsonic"), QStringLiteral("jellyfin")}) {
        const QUrl serverUrl(settings.value("stream/" + provider + "Url").toString());
        if (serverUrl.host().compare(url.host(), Qt::CaseInsensitive) == 0 && serverUrl.port(443) == url.port(443) &&
            !settings.value("stream/" + provider + "CertDigest").toString().isEmpty())
            return true;
    }
    return false;
}

QString StreamingController::friendlyError(QNetworkReply *reply, const QString &fallback) {
    if (!reply) {
        return fallback;
    }
    switch (reply->error()) {
    case QNetworkReply::HostNotFoundError:
        return tr("Couldn't find that server. Check the URL.");
    case QNetworkReply::ConnectionRefusedError:
        return tr("Couldn't reach the server. Check the URL and that it's running.");
    case QNetworkReply::TimeoutError:
    case QNetworkReply::OperationCanceledError:
        return tr("The server took too long to respond. Check the URL and your connection.");
    case QNetworkReply::SslHandshakeFailedError:
        return tr("The server certificate isn't trusted. Self-signed certificates need manual trust.");
    case QNetworkReply::AuthenticationRequiredError:
        return tr("Wrong username or password.");
    case QNetworkReply::ContentAccessDenied:
    case QNetworkReply::ContentOperationNotPermittedError:
        return tr("Access denied. Check the username and password.");
    case QNetworkReply::ContentNotFoundError:
        return tr("Server endpoint not found. Check the URL and server type.");
    case QNetworkReply::NoError:
        return fallback;
    default:
        return fallback;
    }
}

void StreamingController::beginRefresh() {
    if (blackoutEnabled()) {
        setRemoteTracks({});
        return;
    }
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const bool wantSubsonic = settings.value("stream/subsonicConnected", false).toBool() &&
                              !settings.value("stream/subsonicUrl").toString().isEmpty();
    const bool wantJellyfin = settings.value("stream/jellyfinConnected", false).toBool() &&
                              !settings.value("stream/jellyfinUrl").toString().isEmpty();
    if (!wantSubsonic && !wantJellyfin) {
        setRemoteTracks({});
        return;
    }
    if (m_refreshing) {
        m_refreshQueued = true;
        return;
    }
    setRemoteLibraryLoading(true);
    if (!wantSubsonic) {
        removeProviderTracks("subsonic:");
    }
    if (!wantJellyfin) {
        removeProviderTracks("jellyfin:");
    }
    m_pendingStages = 0;
    m_subsonicRefreshActive = false;
    m_jellyfinRefreshActive = false;
    if (wantSubsonic) {
        const QString password = vault.loadSecret("subsonic");
        if (password.isEmpty()) {
            setStatus("subsonic", false, tr("Saved password is missing. Connect again."));
            emit serverFailed("subsonic", tr("Saved password is missing. Connect again."));
        } else {
            m_subsonicRefreshActive = true;
            ++m_pendingStages;
            refreshSubsonic(serverBase(QStringLiteral("subsonic")),
                            settings.value("stream/subsonicUsername").toString(), password, ++m_subsonicRefreshToken);
        }
    }
    if (wantJellyfin) {
        const QString token = vault.loadSecret("jellyfin");
        const QString userId = settings.value("stream/jellyfinUserId").toString();
        if (token.isEmpty() || userId.isEmpty()) {
            setStatus("jellyfin", false, tr("Saved login is missing. Connect again."));
            emit serverFailed("jellyfin", tr("Saved login is missing. Connect again."));
        } else {
            m_jellyfinRefreshActive = true;
            ++m_pendingStages;
            refreshJellyfin(serverBase(QStringLiteral("jellyfin")), userId, token, ++m_jellyfinRefreshToken);
        }
    }
    if (m_pendingStages == 0) {
        setRemoteLibraryLoading(false);
    }
}

void StreamingController::refreshLibrary() {
    beginRefresh();
}

void StreamingController::finishRefreshStage(const QString &provider) {
    if (provider == "subsonic")
        m_subsonicRefreshActive = false;
    else if (provider == "jellyfin")
        m_jellyfinRefreshActive = false;
    if (m_pendingStages > 0)
        --m_pendingStages;
    if (m_pendingStages == 0) {
        if (m_refreshQueued) {
            m_refreshQueued = false;
            m_refreshing = false;
            beginRefresh();
        } else {
            setRemoteLibraryLoading(false);
        }
    }
}

void StreamingController::cancelPendingRequests() {
    ++m_subConnectToken;
    ++m_jellyConnectToken;
    ++m_subsonicRefreshToken;
    ++m_jellyfinRefreshToken;
    m_subsonicRefreshActive = false;
    m_jellyfinRefreshActive = false;
    setRemoteLibraryLoading(false);
    m_refreshQueued = false;
    m_pendingStages = 0;
    cancelNetworkReplies(m_pendingReplies);
}

void StreamingController::setBlackoutEnabled(bool enabled) {
    if (!enabled)
        return;

    cancelPendingRequests();
    m_remoteArt.clear();
    m_remoteArtSource.clear();
    m_remoteArtFailedAt.clear();
    m_remoteArtPending.clear();
    m_remoteArtDownloads = 0;
    setRemoteTracks({});
}

void StreamingController::disconnectServer(const QString &protocol) {
    CredentialVault vault;
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    if (protocol == "subsonic") {
        ++m_subConnectToken;
        ++m_subsonicRefreshToken;
        vault.clearSecret("subsonic");
        settings.setValue("stream/subsonicConnected", false);
        settings.remove("stream/subsonicCertDigest");
        setStatus("subsonic", false, tr("Not connected"));
        if (m_subsonicRefreshActive)
            finishRefreshStage("subsonic");
        removeProviderTracks("subsonic:");
    } else if (protocol == "jellyfin") {
        cancelJellyfinQuickConnect();
        ++m_jellyConnectToken;
        ++m_jellyfinRefreshToken;
        vault.clearSecret("jellyfin");
        settings.setValue("stream/jellyfinConnected", false);
        settings.remove("stream/jellyfinCertDigest");
        setStatus("jellyfin", false, tr("Not connected"));
        if (m_jellyfinRefreshActive)
            finishRefreshStage("jellyfin");
        removeProviderTracks("jellyfin:");
    }
    settings.sync();
}

void StreamingController::setServerFavorite(const QString &filePath, bool favorite) {
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
        const QString base = serverBase(QStringLiteral("subsonic"));
        const QString user = settings.value("stream/subsonicUsername").toString();
        const QString salt = randomSalt();
        const QString endpoint = favorite ? "star.view" : "unstar.view";
        QNetworkRequest request(
            subsonicUrl(base, endpoint, user, md5Hex(password + salt), salt, {{"id", filePath.mid(9)}}));
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
        const QString base = serverBase(QStringLiteral("jellyfin"));
        QNetworkRequest request(QUrl(base + "/Users/" + userId + "/FavoriteItems/" + filePath.mid(9)));
        request.setTransferTimeout(streaming::detail::requestTimeoutMs);
        const QString header = jellyfinAuthHeader(deviceId(), token);
        request.setRawHeader("Authorization", header.toUtf8());
        request.setRawHeader("X-Emby-Authorization", header.toUtf8());
        request.setRawHeader("X-Emby-Token", token.toUtf8());
        QNetworkReply *reply =
            favorite ? trackReply(m_net->post(request, QByteArray())) : trackReply(m_net->deleteResource(request));
        connect(reply, &QNetworkReply::finished, this, [=, this] {
            if (reply->error() != QNetworkReply::NoError) {
                emit serverFavoriteFailed(filePath);
            }
        });
        return;
    }
}

namespace {
// One lyric line, timed as LRC when it has a start time.
QString lyricLine(const QString &text, qint64 startMs, bool timed) {
    if (!timed || startMs < 0)
        return text + QLatin1Char('\n');
    return QString("[%1:%2.%3]%4\n")
        .arg(startMs / 60000, 2, 10, QLatin1Char('0'))
        .arg((startMs / 1000) % 60, 2, 10, QLatin1Char('0'))
        .arg((startMs % 1000) / 10, 2, 10, QLatin1Char('0'))
        .arg(text);
}

// Timed lyrics when the server has them, else the first plain ones; the offset is how much later they should show.
QString subsonicLyricsText(const QJsonObject &response) {
    const QJsonArray all = response.value("lyricsList").toObject().value("structuredLyrics").toArray();
    QJsonObject chosen;
    for (const QJsonValue &value : all) {
        const QJsonObject lyrics = value.toObject();
        if (lyrics.value("line").toArray().isEmpty())
            continue;
        if (chosen.isEmpty() || (lyrics.value("synced").toBool() && !chosen.value("synced").toBool()))
            chosen = lyrics;
    }
    const bool timed = chosen.value("synced").toBool();
    const qint64 offset = chosen.value("offset").toInteger();
    QString result;
    for (const QJsonValue &value : chosen.value("line").toArray()) {
        const QJsonObject line = value.toObject();
        const QString text = line.value("value").toString();
        if (!text.trimmed().isEmpty())
            result += lyricLine(text, line.contains("start") ? line.value("start").toInteger() + offset : -1, timed);
    }
    return result.trimmed();
}
} // namespace

// Lyrics kept on your own server, asked for before an online search.
void StreamingController::fetchServerLyrics(const QString &filePath, const QString &remoteId) {
    if (remoteId.isEmpty())
        emit serverLyricsFetched(filePath, QString(), QString());
    else if (filePath.startsWith("jellyfin:"))
        fetchJellyfinLyrics(filePath, remoteId);
    else if (filePath.startsWith("subsonic:"))
        fetchSubsonicLyrics(filePath, remoteId);
    else
        emit serverLyricsFetched(filePath, QString(), QString());
}

void StreamingController::fetchJellyfinLyrics(const QString &filePath, const QString &remoteId) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    CredentialVault vault;
    const QString base = serverBase(QStringLiteral("jellyfin"));
    const QString token = vault.loadSecret("jellyfin");
    if (base.isEmpty() || token.isEmpty()) {
        emit serverLyricsFetched(filePath, QString(), QString());
        return;
    }

    QNetworkRequest request(QUrl(base + "/Audio/" + remoteId + "/Lyrics"));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    const QString header = jellyfinAuthHeader(deviceId(), token);
    request.setRawHeader("Authorization", header.toUtf8());
    request.setRawHeader("X-Emby-Authorization", header.toUtf8());
    request.setRawHeader("X-Emby-Token", token.toUtf8());
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, filePath] {
        QString result;
        if (reply->error() == QNetworkReply::NoError) {
            const QJsonObject body = QJsonDocument::fromJson(reply->readAll()).object();
            // Timed lyrics are timed throughout, including a first line that starts at zero.
            const bool timed = body.value("Metadata").toObject().value("IsSynced").toBool();
            for (const QJsonValue &value : body.value("Lyrics").toArray()) {
                const QJsonObject line = value.toObject();
                const QString text = line.value("Text").toString();
                if (!text.isEmpty())
                    result += lyricLine(text, line.value("Start").toVariant().toLongLong() / 10000, timed);
            }
        }
        emit serverLyricsFetched(filePath, result.trimmed(), QStringLiteral("Jellyfin"));
    });
}

// OpenSubsonic servers, such as Navidrome, keep a song's lyrics, sometimes in several languages and timed or not.
void StreamingController::fetchSubsonicLyrics(const QString &filePath, const QString &remoteId) {
    QSettings settings(m_settingsPath, QSettings::IniFormat);
    const QString password = CredentialVault().loadSecret("subsonic");
    const QString base = serverBase(QStringLiteral("subsonic"));
    if (base.isEmpty() || password.isEmpty()) {
        emit serverLyricsFetched(filePath, QString(), QString());
        return;
    }
    const QString user = settings.value("stream/subsonicUsername").toString();
    const QString salt = randomSalt();
    QNetworkRequest request(
        subsonicUrl(base, "getLyricsBySongId.view", user, md5Hex(password + salt), salt, {{"id", remoteId}}));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, filePath] {
        // A server without OpenSubsonic doesn't know the request, which counts as no lyrics.
        const QString result = reply->error() == QNetworkReply::NoError
                                   ? subsonicLyricsText(parseSubsonicBody(reply->readAll()))
                                   : QString();
        emit serverLyricsFetched(filePath, result, QStringLiteral("Your server"));
    });
}

QString StreamingController::remoteArtwork(const QString &filePath) {
    if (blackoutEnabled())
        return {};

    const auto cached = m_remoteArt.constFind(filePath);
    if (cached != m_remoteArt.cend()) {
        return *cached;
    }
    if (m_remoteArtPending.contains(filePath) || m_remoteArtDownloads >= kMaxArtDownloads) {
        return {};
    }
    // A failed download is retried after a pause rather than on every rebind.
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (now - m_remoteArtFailedAt.value(filePath, 0) < 60000)
        return {};
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
        if (blackoutEnabled() || m_remoteArtSource.value(filePath) != artworkSource)
            return;

        if (reply->error() != QNetworkReply::NoError) {
            // Network errors are often temporary, so they are not cached as "no artwork".
            m_remoteArtFailedAt.insert(filePath, QDateTime::currentMSecsSinceEpoch());
            if (!m_remoteArtRetryScheduled) {
                // Covers only ask again when their binding re-evaluates, so prompt that once the pause is over.
                m_remoteArtRetryScheduled = true;
                QTimer::singleShot(61000, this, [this] {
                    m_remoteArtRetryScheduled = false;
                    ++m_remoteArtRevision;
                    emit remoteArtChanged();
                });
            }
            return;
        }
        QString local;
        const QByteArray data = reply->readAll();
        const QString contentType = reply->header(QNetworkRequest::ContentTypeHeader).toString();
        // Bound what we keep: small embedded-style artwork only.
        if (data.size() > 32 && data.size() <= kMaxArtBytes)
            local = saveCachedImage(data, filePath, contentType.contains("png", Qt::CaseInsensitive), "covers");
        m_remoteArt.insert(filePath, local);
        ++m_remoteArtRevision;
        emit remoteArtChanged();
    });
    return {};
}

QUrl StreamingController::streamSourceFor(const QString &source, const QString &remoteId) const {
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
        QList<QPair<QString, QString>> extra{{"id", remoteId}};
        // Over the chosen quality, the server converts the song to MP3 at that bitrate.
        if (const int kbps = streamLimitKbps(); kbps > 0)
            extra.append({{"maxBitRate", QString::number(kbps)}, {"format", "mp3"}});
        return subsonicUrl(serverBase(QStringLiteral("subsonic")), "stream.view",
                           settings.value("stream/subsonicUsername").toString(), md5Hex(password + salt), salt, extra);
    }
    if (source == "jellyfin" && settings.value("stream/jellyfinConnected", false).toBool()) {
        const QString token = vault.loadSecret("jellyfin");
        if (token.isEmpty()) {
            return {};
        }
        // The universal stream sends a song as it is when the player reads its format, and otherwise has the server
        // convert it, so songs in formats the player can't decode still play. FFmpeg decodes nearly every format, so
        // conversion is rarely needed here.
        QUrl url(serverBase(QStringLiteral("jellyfin")) + "/Audio/" + remoteId + "/universal");
        QUrlQuery q;
        q.addQueryItem("container", "mp3,aac,m4a,m4b,flac,alac,ogg,oga,opus,webm,webma,wav,aiff,aif,wma,ape,wv,mka,"
                                    "mpc,dsf,dff");
        q.addQueryItem("transcodingContainer", "mp3");
        q.addQueryItem("transcodingProtocol", "http");
        q.addQueryItem("audioCodec", "mp3");
        // Without a chosen quality the limit is high enough that lossless files are sent as they are; with one, a
        // song over it is converted to MP3 at that bitrate.
        const int kbps = streamLimitKbps();
        q.addQueryItem("audioBitRate", kbps > 0 ? QString::number(kbps * 1000) : QStringLiteral("320000"));
        q.addQueryItem("maxStreamingBitrate", kbps > 0 ? QString::number(kbps * 1000) : QStringLiteral("140000000"));
        q.addQueryItem("userId", settings.value("stream/jellyfinUserId").toString());
        q.addQueryItem("deviceId", settings.value("stream/deviceId").toString());
        q.addQueryItem("api_key", token);
        url.setQuery(q);
        return url;
    }
    return {};
}

bool StreamingController::isUnencryptedPublicUrl(const QString &serverUrl) const {
    return streaming::protocol::isUnencryptedPublicUrl(serverUrl);
}

QVariantMap StreamingController::serverConfigSnapshot() const {
    return serverConfigSnapshot(m_settingsPath);
}

QVariantMap StreamingController::serverConfigSnapshot(const QString &settingsPath) {
    QSettings settings(settingsPath, QSettings::IniFormat);
    QVariantMap snapshot;
    snapshot.insert("subsonic/url", settings.value("stream/subsonicUrl").toString());
    snapshot.insert("subsonic/username", settings.value("stream/subsonicUsername").toString());
    snapshot.insert("subsonic/connected", settings.value("stream/subsonicConnected", false).toBool());
    snapshot.insert("subsonic/trustCert", settings.value("stream/subsonicTrustCert", false).toBool());
    snapshot.insert("subsonic/awayUrl", settings.value("stream/subsonicAwayUrl").toString());
    snapshot.insert("jellyfin/url", settings.value("stream/jellyfinUrl").toString());
    snapshot.insert("jellyfin/username", settings.value("stream/jellyfinUsername").toString());
    snapshot.insert("jellyfin/connected", settings.value("stream/jellyfinConnected", false).toBool());
    snapshot.insert("jellyfin/trustCert", settings.value("stream/jellyfinTrustCert", false).toBool());
    snapshot.insert("jellyfin/awayUrl", settings.value("stream/jellyfinAwayUrl").toString());
    snapshot.insert("quality/normal", settings.value("stream/qualityKbps", 0).toInt());
    snapshot.insert("quality/metered", settings.value("stream/meteredQualityKbps", 0).toInt());
    return snapshot;
}

namespace streaming {

namespace {

int g_failures = 0;

void check(bool condition, const char *name) {
    if (!condition) {
        ++g_failures;
        std::cerr << "streaming self-check FAILED: " << name << std::endl;
    }
}

// Whether a settings snapshot names or carries a credential, which it must never pass on.
bool holdsSecret(const QVariantMap &snapshot) {
    static const QStringList secretWords{"password", "token", "secret", "session", "credential"};
    for (auto it = snapshot.cbegin(); it != snapshot.cend(); ++it) {
        const QString key = it.key().toLower();
        const QString value = it.value().toString();
        const bool namesSecret = std::any_of(secretWords.cbegin(), secretWords.cend(),
                                             [&](const QString &word) { return key.contains(word); });
        if (namesSecret || value.contains("s3cret-pw") || value.contains("tok-abc"))
            return true;
    }
    return false;
}

} // namespace

bool runSelfChecks(bool includeVaultProbe) {
    g_failures = 0;

    check(normalizeServerUrl("music.example.com") == "https://music.example.com", "normalize-adds-https");
    check(normalizeServerUrl("  http://music.example.com/ ") == "http://music.example.com",
          "normalize-keeps-typed-http");
    check(isUnencryptedPublicUrl("http://music.example.com"), "unencrypted-public-url");
    check(!isUnencryptedPublicUrl("http://jellyfin.lan"), "unencrypted-home-url");
    check(!isUnencryptedPublicUrl("https://music.example.com"), "encrypted-public-url");
    check(isUnencryptedPublicUrl("http://100.101.1.2:8096"), "unencrypted-shared-address-url");
    check(normalizeServerUrl("https://user:password@music.example.com").isEmpty(), "normalize-rejects-userinfo");
    check(normalizeServerUrl("https://music.example.com?token=secret").isEmpty(), "normalize-rejects-query");
    check(normalizeServerUrl("https://music.example.com#fragment").isEmpty(), "normalize-rejects-fragment");
    check(normalizeServerUrl("https://music.example.com///") == "https://music.example.com", "normalize-trims-slashes");
    check(normalizeServerUrl("   ").isEmpty(), "normalize-blank");
    check(normalizeServerUrl("192.168.1.112", 8096) == "http://192.168.1.112:8096", "normalize-local-ip-default-port");
    check(normalizeServerUrl("192.168.1.112:8096", 8096) == "http://192.168.1.112:8096",
          "normalize-local-ip-explicit-port");
    check(normalizeServerUrl("http://localhost", 4533) == "http://localhost:4533", "normalize-localhost-default-port");
    check(normalizeServerUrl("http://nas.lan:8096", 8096) == "http://nas.lan:8096", "normalize-lan-http");

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
    check(subQuery.queryItemValue("c") == "CassetteCat Desktop", "subsonic-client");
    check(subQuery.queryItemValue("f") == "json", "subsonic-format");
    check(!subUrl.toString().contains("secret-password"), "subsonic-no-password-in-url");
    check(subsonicUrl("https://m.example.com", "stream.view", "u", "t", "s", {{"id", "42"}})
              .toString()
              .contains("stream.view"),
          "subsonic-stream-endpoint");

    const QJsonObject lyricsResponse = QJsonDocument::fromJson(R"({"lyricsList": {"structuredLyrics": [
        {"synced": false, "line": [{"value": "Plain"}]},
        {"synced": true, "offset": 500, "line": [{"start": 0, "value": "First"}, {"start": 61000, "value": "Second"}]}]}})")
                                           .object();
    check(subsonicLyricsText(lyricsResponse) == "[00:00.50]First\n[01:01.50]Second", "subsonic-timed-lyrics-first");
    check(subsonicLyricsText(QJsonObject{}).isEmpty(), "subsonic-no-lyrics");

    const QByteArray okBody = R"({"subsonic-response": {"status": "ok", "albumList2": {"album": [{"id": "a1"}]}}})";
    const QJsonObject okResponse = parseSubsonicBody(okBody);
    check(!okResponse.contains("_error"), "subsonic-ok");
    check(jsonArrayTolerant(okResponse.value("albumList2").toObject(), "album").size() == 1, "subsonic-album-ids");

    const QByteArray singleBody =
        R"({"subsonic-response": {"status": "ok", "album": {"id": "a1", "name": "N", "song": {"id": "s1", "title": "T"}}}})";
    const QJsonObject singleResponse = parseSubsonicBody(singleBody);
    check(jsonArrayTolerant(singleResponse.value("album").toObject(), "song").size() == 1, "subsonic-single-tolerance");

    const QByteArray failBody =
        R"({"subsonic-response": {"status": "failed", "error": {"code": 40, "message": "Wrong username"}}})";
    check(parseSubsonicBody(failBody).value("_error").toString() == "Wrong username", "subsonic-error-message");
    check(parseSubsonicBody(QByteArray("{broken")).contains("_error"), "subsonic-broken-json");

    const QString preHeader = jellyfinAuthHeader("device-1", {});
    check(preHeader.contains("Client=\"CassetteCat\""), "jellyfin-client");
    check(preHeader.contains("DeviceId=\"device-1\""), "jellyfin-device");
    check(!preHeader.contains("Token="), "jellyfin-no-token-pre-login");
    const QString postHeader = jellyfinAuthHeader("device-1", "tok123");
    check(postHeader.contains("Token=\"tok123\""), "jellyfin-token-post-login");
    check(!postHeader.contains("s3cret"), "jellyfin-no-password-in-header");

    const QByteArray itemsBody =
        R"({"Items": [{"Id": "1", "Name": "Song", "AlbumArtist": "A", "Album": "B", "AlbumId": "al", "ProductionYear": 2020, "RunTimeTicks": 2100000000, "ImageTags": {"Primary": "p"}, "UserData": {"IsFavorite": true}, "Genres": ["Rock"], "Container": "mp3"}, {"Id": "2", "Name": "Bare"}]})";
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
        model.setTracks(
            {QVariantMap{{"source", "jellyfin"}, {"title", "J"}}, QVariantMap{{"source", "subsonic"}, {"title", "S"}}});
        check(model.rowCount() == 1, "remote-model-filter");
        check(model.data(model.index(0, 0), RemoteTrackModel::TrackRole).toMap().value("title") == "J",
              "remote-model-role");
    }

    {
        QSet<QString> pending{"jellyfin:1"};
        int downloads = 1;
        releaseArtworkDownload(pending, downloads, "jellyfin:1");
        releaseArtworkDownload(pending, downloads, "jellyfin:1");
        check(pending.isEmpty(), "remote-art-released");
        check(downloads == 0, "remote-art-slot-released");
    }

    const QString redacted = CredentialVault::redactSecrets(
        "https://m.example.com/Audio/1/stream?static=true&api_key=tok123 and t=abc&s=def Token=\"tok123\"");
    check(!redacted.contains("tok123"), "redact-token");
    check(!redacted.contains("t=abc"), "redact-subsonic-token");
    const QString redactedHeaders =
        CredentialVault::redactSecrets("Authorization: Bearer secret-token\nX-Emby-Token: second-token");
    check(!redactedHeaders.contains("secret-token"), "redact-authorization-header");
    check(!redactedHeaders.contains("second-token"), "redact-emby-header");
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
        check(snapshot.value("subsonic/trustCert").toBool() == false, "snapshot-trust-cert-default-false");
        settings.setValue("stream/subsonicTrustCert", true);
        settings.sync();
        const QVariantMap snapshot2 = StreamingController::serverConfigSnapshot(dir.filePath("s.ini"));
        check(snapshot2.value("subsonic/trustCert").toBool() == true, "snapshot-trust-cert-true");
        const QString settingsPath = dir.filePath("s.ini");
        const QUrl serverUrl("https://m.example.com/rest/ping.view");
        check(!StreamingController::hasPinnedCertificate(settingsPath, serverUrl), "pinned-cert-absent");
        settings.setValue("stream/subsonicCertDigest", "ab12");
        settings.sync();
        check(StreamingController::hasPinnedCertificate(settingsPath, serverUrl), "pinned-cert-present");
        const QUrl otherUrl("https://other.example.com");
        check(!StreamingController::hasPinnedCertificate(settingsPath, otherUrl), "pinned-cert-other-host");
        check(!holdsSecret(snapshot), "snapshot-excludes-secrets");
    }

    return g_failures == 0;
}

} // namespace streaming
