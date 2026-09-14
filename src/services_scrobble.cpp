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
constexpr auto kLibreFmApiUrl = "https://libre.fm/2.0/";
constexpr auto kLibreFmApiKey = "cassettecat";
constexpr auto kLibreFmSecret = "cassettecat_secret";
constexpr auto kListenBrainzBaseUrl = "https://api.listenbrainz.org/1";

QString loadScrobbleSecret(CredentialVault &vault, const QString &key, const QString &legacySetting)
{
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
}

void ServicesController::initScrobbleCredentials()
{
    if (m_scrobbleCredentialsLoaded) return;
    CredentialVault vault;
    m_listenBrainzToken = loadScrobbleSecret(
        vault, QStringLiteral("scrobble/listenbrainz_token"), QStringLiteral("scrobble_secure/listenbrainz_token"));
    m_libreFmSessionKey = loadScrobbleSecret(
        vault, QStringLiteral("scrobble/librefm_session_key"), QStringLiteral("scrobble_secure/librefm_session_key"));
    m_scrobbleCredentialsLoaded = true;
}

bool ServicesController::hasListenBrainzSession()
{
    initScrobbleCredentials();
    return !m_listenBrainzToken.trimmed().isEmpty();
}

bool ServicesController::hasLibreFmSession()
{
    initScrobbleCredentials();
    return !m_libreFmSessionKey.trimmed().isEmpty();
}

void ServicesController::saveListenBrainzSession(const QString &token, const QString &userName)
{
    initScrobbleCredentials();
    const QString value = token.trimmed();
    CredentialVault vault;
    SettingsController::setGlobalValue("scrobble_secure/listenbrainz_token", QVariant());
    if (value.isEmpty() || !vault.saveSecret("scrobble/listenbrainz_token", value)) {
        m_listenBrainzToken.clear();
        SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", false);
        qWarning() << "ListenBrainz credential could not be saved securely.";
        return;
    }
    m_listenBrainzToken = value;
    SettingsController::setGlobalValue("scrobble/listenbrainz_user", userName.trimmed());
    SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", true);
}

void ServicesController::disconnectListenBrainz()
{
    initScrobbleCredentials();
    m_listenBrainzToken.clear();
    CredentialVault vault;
    vault.clearSecret("scrobble/listenbrainz_token");
    SettingsController::setGlobalValue("scrobble_secure/listenbrainz_token", QVariant());
    SettingsController::setGlobalValue("scrobble/listenbrainz_user", QString());
    SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", false);
}

void ServicesController::saveLibreFmSession(const QString &username, const QString &sessionKey)
{
    initScrobbleCredentials();
    const QString value = sessionKey.trimmed();
    CredentialVault vault;
    SettingsController::setGlobalValue("scrobble_secure/librefm_session_key", QVariant());
    if (value.isEmpty() || !vault.saveSecret("scrobble/librefm_session_key", value)) {
        m_libreFmSessionKey.clear();
        SettingsController::setGlobalValue("scrobble/librefm_enabled", false);
        qWarning() << "Libre.fm credential could not be saved securely.";
        return;
    }
    m_libreFmSessionKey = value;
    SettingsController::setGlobalValue("scrobble/librefm_user", username.trimmed());
    SettingsController::setGlobalValue("scrobble/librefm_enabled", true);
}

void ServicesController::disconnectLibreFm()
{
    initScrobbleCredentials();
    m_libreFmSessionKey.clear();
    CredentialVault vault;
    vault.clearSecret("scrobble/librefm_session_key");
    SettingsController::setGlobalValue("scrobble_secure/librefm_session_key", QVariant());
    SettingsController::setGlobalValue("scrobble/librefm_user", QString());
    SettingsController::setGlobalValue("scrobble/librefm_enabled", false);
}

QString ServicesController::generateLibreFmApiSig(const QMap<QString, QString> &params)
{
    QString concatenated;
    for (auto it = params.cbegin(); it != params.cend(); ++it) {
        if (it.key() == "format" || it.key() == "callback" || it.key() == "api_sig") continue;
        concatenated += it.key();
        concatenated += it.value();
    }
    concatenated += QString::fromLatin1(kLibreFmSecret);
    return QString::fromUtf8(QCryptographicHash::hash(concatenated.toUtf8(), QCryptographicHash::Md5).toHex());
}

void ServicesController::validateListenBrainzToken(const QString &token)
{
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
        if (reply->isRunning()) reply->abort();
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
            if (hasListenBrainzSession()) {
                emit listenBrainzValidationFinished(true, userName, {});
            } else {
                emit listenBrainzValidationFinished(false, {}, QStringLiteral("Token is valid, but secure credential storage is unavailable"));
            }
        } else {
            emit listenBrainzValidationFinished(false, {}, QStringLiteral("Invalid user token or unauthorized"));
        }
    });
}

void ServicesController::authenticateLibreFm(const QString &username, const QString &password)
{
    const QString user = username.trimmed();
    if (user.isEmpty() || password.isEmpty()) {
        emit libreFmAuthFinished(false, {}, {}, QStringLiteral("Username and password are required"));
        return;
    }
    if (!onlineEnabled()) {
        emit libreFmAuthFinished(false, {}, {}, QStringLiteral("Offline Blackout Mode is active"));
        return;
    }

    const QString passMd5 = QString::fromUtf8(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Md5).toHex());
    const QString authPayload = user.toLower() + passMd5;
    const QString authToken = QString::fromUtf8(QCryptographicHash::hash(authPayload.toUtf8(), QCryptographicHash::Md5).toHex());

    QMap<QString, QString> params;
    params.insert("method", "auth.getMobileSession");
    params.insert("username", user);
    params.insert("authToken", authToken);
    params.insert("api_key", kLibreFmApiKey);
    params.insert("api_sig", generateLibreFmApiSig(params));
    params.insert("format", "json");

    QUrlQuery query;
    for (auto it = params.cbegin(); it != params.cend(); ++it) {
        query.addQueryItem(it.key(), it.value());
    }

    QNetworkRequest request(QUrl(QString::fromLatin1(kLibreFmApiUrl)));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    QNetworkReply *reply = trackReply(m_net->post(request, query.toString(QUrl::FullyEncoded).toUtf8()));

    auto *timer = new QTimer(reply);
    timer->setSingleShot(true);
    timer->setInterval(services::detail::requestTimeoutMs);
    connect(timer, &QTimer::timeout, reply, [reply] {
        if (reply->isRunning()) reply->abort();
    });
    timer->start();

    connect(reply, &QNetworkReply::finished, this, [this, reply, user] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit libreFmAuthFinished(false, {}, {}, QStringLiteral("Authentication failed. Check your network or credentials."));
            return;
        }
        const QByteArray responseData = reply->readAll();
        QString sessionKey;
        QString sessionName = user;

        const QJsonDocument doc = QJsonDocument::fromJson(responseData);
        if (doc.isObject()) {
            const QJsonObject root = doc.object();
            if (root.contains("session")) {
                const QJsonObject sessionObj = root.value("session").toObject();
                sessionKey = sessionObj.value("key").toString();
                if (sessionObj.contains("name")) sessionName = sessionObj.value("name").toString();
            }
        }
        if (sessionKey.isEmpty()) {
            const QString rawText = QString::fromUtf8(responseData);
            const int keyStart = rawText.indexOf("<key>");
            if (keyStart >= 0) {
                const int keyEnd = rawText.indexOf("</key>", keyStart + 5);
                if (keyEnd > keyStart) sessionKey = rawText.mid(keyStart + 5, keyEnd - keyStart - 5).trimmed();
            }
        }

        if (!sessionKey.isEmpty()) {
            saveLibreFmSession(sessionName, sessionKey);
            if (hasLibreFmSession()) {
                emit libreFmAuthFinished(true, sessionName, sessionKey, {});
            } else {
                emit libreFmAuthFinished(false, {}, {}, QStringLiteral("Login succeeded, but secure credential storage is unavailable"));
            }
        } else {
            emit libreFmAuthFinished(false, {}, {}, QStringLiteral("Invalid username or password"));
        }
    });
}

void ServicesController::scrobbleNowPlaying(const QVariantMap &track)
{
    if (!onlineEnabled() || track.isEmpty()) return;
    if (track.value("format").toString().toUpper() == "STREAM") return;

    const QString artist = track.value("artist").toString().trimmed();
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty()) title = track.value("fileName").toString().trimmed();
    if (artist.isEmpty() || title.isEmpty()) return;
    const QString album = track.value("album").toString().trimmed();

    initScrobbleCredentials();

    if (SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() && !m_listenBrainzToken.isEmpty()) {
        QJsonObject trackMeta;
        trackMeta.insert("artist_name", artist);
        trackMeta.insert("track_name", title);
        if (!album.isEmpty()) trackMeta.insert("release_name", album);

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

    if (SettingsController::globalValue("scrobble/librefm_enabled", false).toBool() && !m_libreFmSessionKey.isEmpty()) {
        QMap<QString, QString> params;
        params.insert("method", "track.updateNowPlaying");
        params.insert("artist", artist);
        params.insert("track", title);
        if (!album.isEmpty()) params.insert("album", album);
        params.insert("sk", m_libreFmSessionKey);
        params.insert("api_key", kLibreFmApiKey);
        params.insert("api_sig", generateLibreFmApiSig(params));
        params.insert("format", "json");

        QUrlQuery query;
        for (auto it = params.cbegin(); it != params.cend(); ++it) {
            query.addQueryItem(it.key(), it.value());
        }

        QNetworkRequest request(QUrl(QString::fromLatin1(kLibreFmApiUrl)));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        trackReply(m_net->post(request, query.toString(QUrl::FullyEncoded).toUtf8()));
    }
}

void ServicesController::scrobbleTrack(const QVariantMap &track, qint64 timestampSec)
{
    if (!onlineEnabled() || track.isEmpty()) return;
    if (track.value("format").toString().toUpper() == "STREAM") return;

    const QString artist = track.value("artist").toString().trimmed();
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty()) title = track.value("fileName").toString().trimmed();
    if (artist.isEmpty() || title.isEmpty()) return;
    const QString album = track.value("album").toString().trimmed();

    if (timestampSec <= 0) {
        timestampSec = QDateTime::currentSecsSinceEpoch();
    }

    initScrobbleCredentials();

    if (SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() && !m_listenBrainzToken.isEmpty()) {
        QJsonObject trackMeta;
        trackMeta.insert("artist_name", artist);
        trackMeta.insert("track_name", title);
        if (!album.isEmpty()) trackMeta.insert("release_name", album);

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

    if (SettingsController::globalValue("scrobble/librefm_enabled", false).toBool() && !m_libreFmSessionKey.isEmpty()) {
        QMap<QString, QString> params;
        params.insert("method", "track.scrobble");
        params.insert("artist", artist);
        params.insert("track", title);
        if (!album.isEmpty()) params.insert("album", album);
        params.insert("timestamp", QString::number(timestampSec));
        params.insert("sk", m_libreFmSessionKey);
        params.insert("api_key", kLibreFmApiKey);
        params.insert("api_sig", generateLibreFmApiSig(params));
        params.insert("format", "json");

        QUrlQuery query;
        for (auto it = params.cbegin(); it != params.cend(); ++it) {
            query.addQueryItem(it.key(), it.value());
        }

        QNetworkRequest request(QUrl(QString::fromLatin1(kLibreFmApiUrl)));
        request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
        trackReply(m_net->post(request, query.toString(QUrl::FullyEncoded).toUtf8()));
    }
}
