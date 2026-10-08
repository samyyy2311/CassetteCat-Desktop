#include "services_controller.h"

#include "app_settings.h"
#include "credential_vault.h"

#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrl>
#include <QUrlQuery>

namespace {
constexpr auto kListenBrainzBaseUrl = "https://api.listenbrainz.org/1";

// Libre.fm and Last.fm speak the same Audioscrobbler 2.0 API.
struct ScrobbleNetwork {
    QLatin1StringView id;
    QLatin1StringView apiUrl;
    QLatin1StringView apiKey;
    QLatin1StringView secret;
};

constexpr ScrobbleNetwork kLibreFm{QLatin1StringView("librefm"), QLatin1StringView("https://libre.fm/2.0/"),
                                   QLatin1StringView("cassettecat"), QLatin1StringView("cassettecat_secret")};
#ifdef CASSETTECAT_LASTFM_API_KEY
constexpr ScrobbleNetwork kLastFm{QLatin1StringView("lastfm"), QLatin1StringView("https://ws.audioscrobbler.com/2.0/"),
                                  QLatin1StringView(CASSETTECAT_LASTFM_API_KEY),
                                  QLatin1StringView(CASSETTECAT_LASTFM_API_SECRET)};
#endif

const ScrobbleNetwork *scrobbleNetwork(const QString &id) {
    if (id == kLibreFm.id)
        return &kLibreFm;
#ifdef CASSETTECAT_LASTFM_API_KEY
    if (id == kLastFm.id)
        return &kLastFm;
#endif
    return nullptr;
}

QString sessionVaultKey(const QString &service) {
    return QStringLiteral("scrobble/%1_session_key").arg(service);
}

QByteArray signedRequestBody(const ScrobbleNetwork &network, QMap<QString, QString> params) {
    params.insert("api_key", network.apiKey);
    QString signature;
    for (auto it = params.cbegin(); it != params.cend(); ++it)
        signature += it.key() + it.value();
    signature += network.secret;
    params.insert("api_sig",
                  QString::fromLatin1(QCryptographicHash::hash(signature.toUtf8(), QCryptographicHash::Md5).toHex()));
    params.insert("format", "json");

    QUrlQuery query;
    for (auto it = params.cbegin(); it != params.cend(); ++it)
        query.addQueryItem(it.key(), it.value());
    return query.toString(QUrl::FullyEncoded).toUtf8();
}

QNetworkRequest scrobbleRequest(const ScrobbleNetwork &network) {
    QNetworkRequest request(QUrl(QString(network.apiUrl)));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    return request;
}

QString loadScrobbleSecret(CredentialVault &vault, const QString &key, const QString &legacySetting) {
    QString secret = vault.loadSecret(key);
    const QString legacy = SettingsController::globalValue(legacySetting).toString().trimmed();
    if (legacy.isEmpty()) {
        return secret;
    }

    if (secret.isEmpty() && vault.saveSecret(key, legacy)) {
        secret = legacy;
    } else if (secret.isEmpty()) {
        qWarning() << "Legacy scrobble credential could not be migrated to secure storage.";
    }
    SettingsController::setGlobalValue(legacySetting, QVariant());
    return secret;
}
} // namespace

void ServicesController::initScrobbleCredentials() {
    if (m_scrobbleCredentialsLoaded)
        return;
    CredentialVault vault;
    m_listenBrainzToken = loadScrobbleSecret(vault, QStringLiteral("scrobble/listenbrainz_token"),
                                             QStringLiteral("scrobble_secure/listenbrainz_token"));
    m_scrobbleSessionKeys.insert(
        kLibreFm.id,
        loadScrobbleSecret(vault, sessionVaultKey(kLibreFm.id), QStringLiteral("scrobble_secure/librefm_session_key")));
#ifdef CASSETTECAT_LASTFM_API_KEY
    m_scrobbleSessionKeys.insert(kLastFm.id, vault.loadSecret(sessionVaultKey(kLastFm.id)));
#endif
    m_scrobbleCredentialsLoaded = true;
}

bool ServicesController::hasListenBrainzSession() {
    initScrobbleCredentials();
    return !m_listenBrainzToken.trimmed().isEmpty();
}

bool ServicesController::hasScrobbleSession(const QString &service) {
    initScrobbleCredentials();
    return !m_scrobbleSessionKeys.value(service).trimmed().isEmpty();
}

bool ServicesController::lastFmAvailable() const {
    return scrobbleNetwork(QStringLiteral("lastfm")) != nullptr;
}

void ServicesController::saveListenBrainzSession(const QString &token, const QString &userName) {
    initScrobbleCredentials();
    const QString value = token.trimmed();
    CredentialVault vault;
    SettingsController::setGlobalValue("scrobble_secure/listenbrainz_token", QVariant());
    if (value.isEmpty() || !vault.saveSecret("scrobble/listenbrainz_token", value)) {
        qWarning() << "ListenBrainz credential could not be saved securely.";
        return;
    }
    m_listenBrainzToken = value;
    SettingsController::setGlobalValue("scrobble/listenbrainz_user", userName.trimmed());
    SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", true);
}

void ServicesController::disconnectListenBrainz() {
    initScrobbleCredentials();
    m_listenBrainzToken.clear();
    CredentialVault vault;
    vault.clearSecret("scrobble/listenbrainz_token");
    SettingsController::setGlobalValue("scrobble_secure/listenbrainz_token", QVariant());
    SettingsController::setGlobalValue("scrobble/listenbrainz_user", QString());
    SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", false);
}

void ServicesController::saveScrobbleSession(const QString &service, const QString &username,
                                             const QString &sessionKey) {
    initScrobbleCredentials();
    const QString value = sessionKey.trimmed();
    CredentialVault vault;
    if (service == kLibreFm.id)
        SettingsController::setGlobalValue("scrobble_secure/librefm_session_key", QVariant());
    if (value.isEmpty() || !vault.saveSecret(sessionVaultKey(service), value)) {
        qWarning() << "Scrobbling credential could not be saved securely.";
        return;
    }
    m_scrobbleSessionKeys.insert(service, value);
    SettingsController::setGlobalValue("scrobble/" + service + "_user", username.trimmed());
    SettingsController::setGlobalValue("scrobble/" + service + "_enabled", true);
}

void ServicesController::disconnectScrobbleAccount(const QString &service) {
    if (!scrobbleNetwork(service))
        return;
    initScrobbleCredentials();
    m_scrobbleSessionKeys.remove(service);
    CredentialVault vault;
    vault.clearSecret(sessionVaultKey(service));
    if (service == kLibreFm.id)
        SettingsController::setGlobalValue("scrobble_secure/librefm_session_key", QVariant());
    SettingsController::setGlobalValue("scrobble/" + service + "_user", QString());
    SettingsController::setGlobalValue("scrobble/" + service + "_enabled", false);
}

void ServicesController::postToScrobbleAccounts(const QMap<QString, QString> &params) {
    for (auto it = m_scrobbleSessionKeys.cbegin(); it != m_scrobbleSessionKeys.cend(); ++it) {
        const ScrobbleNetwork *network = scrobbleNetwork(it.key());
        if (!network || it.value().isEmpty() ||
            !SettingsController::globalValue("scrobble/" + it.key() + "_enabled", false).toBool())
            continue;
        QMap<QString, QString> withSession = params;
        withSession.insert("sk", it.value());
        trackReply(m_net->post(scrobbleRequest(*network), signedRequestBody(*network, withSession)));
    }
}

void ServicesController::validateListenBrainzToken(const QString &token) {
    const QString trimmed = token.trimmed();
    if (trimmed.isEmpty()) {
        emit listenBrainzValidationFinished(false, {}, QStringLiteral("Please enter a valid user token"));
        return;
    }
    if (!onlineEnabled()) {
        emit listenBrainzValidationFinished(false, {}, QStringLiteral("Offline Blackout Mode is active"));
        return;
    }

    QNetworkRequest request(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/validate-token"));
    request.setRawHeader("Authorization", "Token " + trimmed.toUtf8());
    QNetworkReply *reply = trackReply(m_net->get(request));

    auto *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->setInterval(services::detail::requestTimeoutMs);
    connect(timer, &QTimer::timeout, reply, [reply] {
        if (reply->isRunning())
            reply->abort();
    });
    timer->start();

    connect(reply, &QNetworkReply::finished, this, [this, reply, trimmed] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit listenBrainzValidationFinished(false, {}, QStringLiteral("Invalid user token or network error"));
            return;
        }
        const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
        const QJsonObject root = doc.object();
        const bool valid = root.value("valid").toBool();
        const QString userName = root.value("user_name").toString();
        if (valid && !userName.isEmpty()) {
            saveListenBrainzSession(trimmed, userName);
            CredentialVault vault;
            if (vault.loadSecret("scrobble/listenbrainz_token") == trimmed) {
                emit listenBrainzValidationFinished(true, userName, {});
            } else {
                emit listenBrainzValidationFinished(
                    false, {}, QStringLiteral("Token is valid, but secure credential storage is unavailable"));
            }
        } else {
            emit listenBrainzValidationFinished(false, {}, QStringLiteral("Invalid user token or unauthorized"));
        }
    });
}

void ServicesController::authenticateScrobbleAccount(const QString &service, const QString &username,
                                                     const QString &password) {
    const QString user = username.trimmed();
    const ScrobbleNetwork *network = scrobbleNetwork(service);
    if (!network)
        return;
    if (user.isEmpty() || password.isEmpty()) {
        emit scrobbleAccountAuthFinished(service, false, {}, QStringLiteral("Username and password are required"));
        return;
    }
    if (!onlineEnabled()) {
        emit scrobbleAccountAuthFinished(service, false, {}, QStringLiteral("Offline Blackout Mode is active"));
        return;
    }

    QMap<QString, QString> params;
    params.insert("method", "auth.getMobileSession");
    params.insert("username", user);
    if (service == kLibreFm.id) {
        // Libre.fm takes a token made from the password, Last.fm the password itself over HTTPS.
        const QByteArray passMd5 = QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Md5).toHex();
        const QByteArray token = user.toLower().toUtf8() + passMd5;
        params.insert("authToken",
                      QString::fromLatin1(QCryptographicHash::hash(token, QCryptographicHash::Md5).toHex()));
    } else {
        params.insert("password", password);
    }

    QNetworkReply *reply = trackReply(m_net->post(scrobbleRequest(*network), signedRequestBody(*network, params)));

    auto *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->setInterval(services::detail::requestTimeoutMs);
    connect(timer, &QTimer::timeout, reply, [reply] {
        if (reply->isRunning())
            reply->abort();
    });
    timer->start();

    connect(reply, &QNetworkReply::finished, this, [this, reply, user, service] {
        reply->deleteLater();
        const QByteArray responseData = reply->readAll();
        const QJsonObject session = QJsonDocument::fromJson(responseData).object().value("session").toObject();
        QString sessionKey = session.value("key").toString();
        const QString sessionName = session.value("name").toString(user);
        if (sessionKey.isEmpty()) {
            const QString rawText = QString::fromUtf8(responseData);
            const int keyStart = rawText.indexOf("<key>");
            if (keyStart >= 0) {
                const int keyEnd = rawText.indexOf("</key>", keyStart + 5);
                if (keyEnd > keyStart)
                    sessionKey = rawText.mid(keyStart + 5, keyEnd - keyStart - 5).trimmed();
            }
        }

        if (sessionKey.isEmpty()) {
            // Both networks answer a wrong password with an error body, which Qt reports as an HTTP error.
            const bool answered = !responseData.isEmpty();
            emit scrobbleAccountAuthFinished(service, false, {},
                                             answered ? QStringLiteral("Invalid username or password")
                                                      : QStringLiteral("Authentication failed. Check your network."));
            return;
        }
        saveScrobbleSession(service, sessionName, sessionKey);
        CredentialVault vault;
        if (vault.loadSecret(sessionVaultKey(service)) == sessionKey) {
            emit scrobbleAccountAuthFinished(service, true, sessionName, {});
        } else {
            emit scrobbleAccountAuthFinished(
                service, false, {}, QStringLiteral("Login succeeded, but secure credential storage is unavailable"));
        }
    });
}

void ServicesController::scrobbleNowPlaying(const QVariantMap &track) {
    if (!onlineEnabled() || track.isEmpty())
        return;
    if (track.value("format").toString().toUpper() == "STREAM")
        return;

    const QString artist = track.value("artist").toString().trimmed();
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty())
        title = track.value("fileName").toString().trimmed();
    if (artist.isEmpty() || title.isEmpty())
        return;
    const QString album = track.value("album").toString().trimmed();

    initScrobbleCredentials();

    if (SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() &&
        !m_listenBrainzToken.isEmpty()) {
        QJsonObject trackMeta;
        trackMeta.insert("artist_name", artist);
        trackMeta.insert("track_name", title);
        if (!album.isEmpty())
            trackMeta.insert("release_name", album);

        QJsonObject payloadItem;
        payloadItem.insert("track_metadata", trackMeta);

        QJsonArray payloadArray;
        payloadArray.append(payloadItem);

        QJsonObject root;
        root.insert("listen_type", "playing_now");
        root.insert("payload", payloadArray);

        QNetworkRequest request(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/submit-listens"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
        request.setRawHeader("Authorization", "Token " + m_listenBrainzToken.toUtf8());
        trackReply(m_net->post(request, QJsonDocument(root).toJson(QJsonDocument::Compact)));
    }

    QMap<QString, QString> params;
    params.insert("method", "track.updateNowPlaying");
    params.insert("artist", artist);
    params.insert("track", title);
    if (!album.isEmpty())
        params.insert("album", album);
    postToScrobbleAccounts(params);
}

void ServicesController::scrobbleTrack(const QVariantMap &track, qint64 timestampSec) {
    if (!onlineEnabled() || track.isEmpty())
        return;
    if (track.value("format").toString().toUpper() == "STREAM")
        return;

    const QString artist = track.value("artist").toString().trimmed();
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty())
        title = track.value("fileName").toString().trimmed();
    if (artist.isEmpty() || title.isEmpty())
        return;
    const QString album = track.value("album").toString().trimmed();

    if (timestampSec <= 0) {
        timestampSec = QDateTime::currentSecsSinceEpoch();
    }

    initScrobbleCredentials();

    if (SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() &&
        !m_listenBrainzToken.isEmpty()) {
        QJsonObject trackMeta;
        trackMeta.insert("artist_name", artist);
        trackMeta.insert("track_name", title);
        if (!album.isEmpty())
            trackMeta.insert("release_name", album);

        QJsonObject payloadItem;
        payloadItem.insert("listened_at", timestampSec);
        payloadItem.insert("track_metadata", trackMeta);

        QJsonArray payloadArray;
        payloadArray.append(payloadItem);

        QJsonObject root;
        root.insert("listen_type", "single");
        root.insert("payload", payloadArray);

        QNetworkRequest request(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/submit-listens"));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
        request.setRawHeader("Authorization", "Token " + m_listenBrainzToken.toUtf8());
        trackReply(m_net->post(request, QJsonDocument(root).toJson(QJsonDocument::Compact)));
    }

    QMap<QString, QString> params;
    params.insert("method", "track.scrobble");
    params.insert("artist", artist);
    params.insert("track", title);
    if (!album.isEmpty())
        params.insert("album", album);
    params.insert("timestamp", QString::number(timestampSec));
    postToScrobbleAccounts(params);
}
