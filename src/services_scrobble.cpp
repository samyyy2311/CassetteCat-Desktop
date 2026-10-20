#include "services_controller.h"

#include "app_settings.h"
#include "credential_vault.h"

#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDebug>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
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

struct ScrobbleFields {
    QString artist;
    QString title;
    QString album;
};

// Radio streams aren't scrobbled, and a song needs an artist and a title to be, so both come back empty for them.
ScrobbleFields scrobbleFields(const QVariantMap &track) {
    if (track.value("format").toString().toUpper() == "STREAM")
        return {};
    QString title = track.value("title").toString().trimmed();
    if (title.isEmpty())
        title = track.value("fileName").toString().trimmed();
    return {track.value("artist").toString().trimmed(), title, track.value("album").toString().trimmed()};
}

QNetworkRequest scrobbleRequest(const ScrobbleNetwork &network) {
    QNetworkRequest request(QUrl(QString(network.apiUrl)));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");
    request.setTransferTimeout(services::detail::requestTimeoutMs);
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
    setListenBrainzProblem({});
}

void ServicesController::disconnectListenBrainz() {
    initScrobbleCredentials();
    m_listenBrainzToken.clear();
    CredentialVault vault;
    vault.clearSecret("scrobble/listenbrainz_token");
    SettingsController::setGlobalValue("scrobble_secure/listenbrainz_token", QVariant());
    SettingsController::setGlobalValue("scrobble/listenbrainz_user", QString());
    SettingsController::setGlobalValue("scrobble/listenbrainz_enabled", false);
    setListenBrainzProblem({});
}

QString ServicesController::listenBrainzProblem() const {
    return m_listenBrainzProblem;
}

void ServicesController::setListenBrainzProblem(const QString &problem) {
    if (m_listenBrainzProblem == problem)
        return;
    m_listenBrainzProblem = problem;
    emit listenBrainzProblemChanged();
}

void ServicesController::submitToListenBrainz(const char *listenType, const QString &artist, const QString &title,
                                              const QString &album, qint64 listenedAt) {
    if (!SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() ||
        m_listenBrainzToken.isEmpty())
        return;
    QJsonObject trackMeta{{"artist_name", artist}, {"track_name", title}};
    if (!album.isEmpty())
        trackMeta.insert("release_name", album);
    trackMeta.insert("additional_info",
                     QJsonObject{{"submission_client", "CassetteCat Desktop"},
                                 {"submission_client_version", QCoreApplication::applicationVersion()}});
    QJsonObject listen{{"track_metadata", trackMeta}};
    if (listenedAt > 0)
        listen.insert("listened_at", listenedAt);
    const QJsonObject root{{"listen_type", listenType}, {"payload", QJsonArray{listen}}};

    QNetworkRequest request(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/submit-listens"));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
    request.setRawHeader("Authorization", "Token " + m_listenBrainzToken.toUtf8());
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    auto *reply = trackReply(m_net->post(request, QJsonDocument(root).toJson(QJsonDocument::Compact)));
    connect(reply, &QNetworkReply::finished, this, [this, reply, listenType, token = m_listenBrainzToken] {
        reply->deleteLater();
        // An answer about a token that has since been replaced says nothing about the current one.
        if (token != m_listenBrainzToken)
            return;
        const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        if (reply->error() == QNetworkReply::NoError) {
            // Playing-now is only kept for a moment, so only a saved listen shows the problem is gone.
            if (qstrcmp(listenType, "single") == 0)
                setListenBrainzProblem({});
            return;
        }
        const QString reason = QJsonDocument::fromJson(reply->readAll()).object().value("error").toString();
        qWarning().noquote() << "[SCROBBLE] ListenBrainz refused" << listenType << "status=" << status << reason;
        // Without an answer it was the network, which sorts itself out; an answer says what the person must fix,
        // such as verifying their email, so its first sentence goes to Settings.
        if (status != 0)
            setListenBrainzProblem(reason.isEmpty() ? tr("ListenBrainz didn't accept your listens.")
                                                    : reason.section(QStringLiteral(". "), 0, 0) + '.');
    });
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
        emit listenBrainzValidationFinished(false, {}, tr("Please enter a valid user token"));
        return;
    }
    if (!onlineEnabled()) {
        emit listenBrainzValidationFinished(false, {}, tr("Offline Blackout Mode is active"));
        return;
    }

    QNetworkRequest request(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/validate-token"));
    request.setRawHeader("Authorization", "Token " + trimmed.toUtf8());
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));

    connect(reply, &QNetworkReply::finished, this, [this, reply, trimmed] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit listenBrainzValidationFinished(false, {}, tr("Invalid user token or network error"));
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
            emit listenBrainzValidationFinished(false, {}, tr("Invalid user token or unauthorized"));
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
        emit scrobbleAccountAuthFinished(service, false, {}, tr("Username and password are required"));
        return;
    }
    if (!onlineEnabled()) {
        emit scrobbleAccountAuthFinished(service, false, {}, tr("Offline Blackout Mode is active"));
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
                                             answered ? tr("Invalid username or password")
                                                      : tr("Authentication failed. Check your network."));
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
    if (!onlineEnabled())
        return;
    const auto [artist, title, album] = scrobbleFields(track);
    if (artist.isEmpty() || title.isEmpty())
        return;

    initScrobbleCredentials();

    submitToListenBrainz("playing_now", artist, title, album, 0);

    QMap<QString, QString> params;
    params.insert("method", "track.updateNowPlaying");
    params.insert("artist", artist);
    params.insert("track", title);
    if (!album.isEmpty())
        params.insert("album", album);
    postToScrobbleAccounts(params);
}

void ServicesController::scrobbleTrack(const QVariantMap &track, qint64 timestampSec) {
    if (!onlineEnabled())
        return;
    const auto [artist, title, album] = scrobbleFields(track);
    if (artist.isEmpty() || title.isEmpty())
        return;

    if (timestampSec <= 0) {
        timestampSec = QDateTime::currentSecsSinceEpoch();
    }

    initScrobbleCredentials();

    submitToListenBrainz("single", artist, title, album, timestampSec);

    QMap<QString, QString> params;
    params.insert("method", "track.scrobble");
    params.insert("artist", artist);
    params.insert("track", title);
    if (!album.isEmpty())
        params.insert("album", album);
    params.insert("timestamp", QString::number(timestampSec));
    postToScrobbleAccounts(params);
}
