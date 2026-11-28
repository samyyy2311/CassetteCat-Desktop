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
#include <QTimer>
#include <QUrlQuery>

namespace {
constexpr auto kListenBrainzBaseUrl = "https://api.listenbrainz.org/1";
// The most loves the services hand back in one request.
constexpr int kLovesPerPage = 1000;

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
// Each account's record is kept by service and username, so signing in to a different account starts afresh.
QString lovedKey(const QString &service) {
    const QString user = SettingsController::globalValue("scrobble/" + service + "_user").toString();
    return "scrobble/loved_" + service + "/" + user;
}

// Artist and title, ignoring case, identify a song across accounts and rescans.
QString loveKey(const QString &artist, const QString &title) {
    return artist.toLower() + QChar(0x1f) + title.toLower();
}

QString unloveId(const QString &record, const QString &song) {
    return record + QChar(0x1e) + song;
}

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
    // What this account loved is forgotten, as the next sign-in may be someone else.
    SettingsController::setGlobalValue(lovedKey(QStringLiteral("listenbrainz")), QVariant());
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
    SettingsController::setGlobalValue(lovedKey(service), QVariant());
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
        QNetworkReply *sent =
            trackReply(m_net->post(scrobbleRequest(*network), signedRequestBody(*network, withSession)));
        connect(sent, &QNetworkReply::finished, sent, &QObject::deleteLater);
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
    // The transfer timeout only notices silence, so a sign-in check also has a hard deadline.
    QTimer::singleShot(services::detail::requestTimeoutMs, reply, [reply] {
        if (reply->isRunning())
            reply->abort();
    });

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
    // The transfer timeout only notices silence, so a sign-in check also has a hard deadline.
    QTimer::singleShot(services::detail::requestTimeoutMs, reply, [reply] {
        if (reply->isRunning())
            reply->abort();
    });

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

void ServicesController::loveTrack(const QVariantMap &track, bool loved) {
    loveTrackOn(track, loved, {});
}

// A love skips accounts that already have it: by the account's own list when it was read, else by the app's record.
void ServicesController::loveTrackOn(const QVariantMap &track, bool loved, const AccountLoves &onAccounts) {
    if (!onlineEnabled())
        return;
    const auto [artist, title, album] = scrobbleFields(track);
    if (artist.isEmpty() || title.isEmpty())
        return;
    // A song liked and unliked before its turn is sent once, as it ended up.
    m_loves.removeIf([&](const Love &queued) { return queued.artist == artist && queued.title == title; });
    // A love isn't queued when every account has it.
    const QString song = loveKey(artist, title);
    QStringList to;
    for (const QString &service : lovingServices()) {
        const QString record = lovedKey(service);
        const auto known = onAccounts.constFind(service);
        const bool has = known != onAccounts.cend() ? known->contains(song) : hasLove(record, song);
        if (!loved || !has)
            to.append(record);
    }
    if (to.isEmpty()) {
        emit lovesChanged();
        return;
    }
    queueLove({artist, title, loved, to});
}

void ServicesController::queueLove(const Love &love) {
    m_loves.removeIf([&](const Love &queued) { return queued.artist == love.artist && queued.title == love.title; });
    m_loves.append(love);
    emit lovesChanged();
    if (!m_lovesRunning)
        sendNextLove();
}

void ServicesController::sendNextLove() {
    if (m_loves.isEmpty() || !onlineEnabled()) {
        m_lovesRunning = false;
        if (!m_loves.isEmpty()) {
            m_loves.clear();
            emit lovesChanged();
        }
        return;
    }
    m_lovesRunning = true;
    sendLove(m_loves.takeFirst());
    emit lovesChanged();
    QTimer::singleShot(1000, this, &ServicesController::sendNextLove);
}

void ServicesController::sendLove(const Love &love) {
    initScrobbleCredentials();
    sendLoveToScrobblers(love);
    if (!love.to.contains(lovedKey(QStringLiteral("listenbrainz"))) ||
        !SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool() ||
        m_listenBrainzToken.isEmpty())
        return;
    sendLoveToListenBrainz(love);
}

void ServicesController::sendLoveToScrobblers(const Love &love) {
    const QString key = loveKey(love.artist, love.title);
    for (auto it = m_scrobbleSessionKeys.cbegin(); it != m_scrobbleSessionKeys.cend(); ++it) {
        const ScrobbleNetwork *network = scrobbleNetwork(it.key());
        const QString record = lovedKey(it.key());
        if (!network || it.value().isEmpty() || !love.to.contains(record) ||
            !SettingsController::globalValue("scrobble/" + it.key() + "_enabled", false).toBool())
            continue;
        if (!love.loved)
            m_unloving.insert(unloveId(record, key));
        const QMap<QString, QString> params{{"method", love.loved ? "track.love" : "track.unlove"},
                                            {"artist", love.artist},
                                            {"track", love.title},
                                            {"sk", it.value()}};
        QNetworkReply *sent = trackReply(m_net->post(scrobbleRequest(*network), signedRequestBody(*network, params)));
        // The record is the account this was sent from, even if someone else signs in before the answer comes.
        connect(sent, &QNetworkReply::finished, this, [this, sent, record, key, loved = love.loved] {
            sent->deleteLater();
            m_unloving.remove(unloveId(record, key));
            // Only what the account took is recorded, so a failed love or unlove is sent again by the next Sync Likes.
            if (sent->error() == QNetworkReply::NoError && !sent->readAll().contains("\"error\""))
                recordLove(record, key, loved);
        });
    }
}

// ListenBrainz takes feedback for a MusicBrainz recording, which the files don't name, so it's looked up first.
void ServicesController::sendLoveToListenBrainz(const Love &love) {
    const QString record = lovedKey(QStringLiteral("listenbrainz"));
    if (!love.loved)
        m_unloving.insert(unloveId(record, loveKey(love.artist, love.title)));
    QUrl lookupUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/metadata/lookup/");
    lookupUrl.setQuery(QUrlQuery{{"artist_name", love.artist}, {"recording_name", love.title}});
    QNetworkRequest lookup(lookupUrl);
    lookup.setRawHeader("Authorization", "Token " + m_listenBrainzToken.toUtf8());
    lookup.setTransferTimeout(services::detail::requestTimeoutMs);
    // Lookups can finish out of order, so only the newest like or unlike of a song is sent.
    const QString song = love.artist + u'\x1f' + love.title;
    const quint64 generation = ++m_loveGenerations[song];
    auto *reply = trackReply(m_net->get(lookup));
    connect(reply, &QNetworkReply::finished, this,
            [this, reply, loved = love.loved, song, key = loveKey(love.artist, love.title), generation, record,
             token = m_listenBrainzToken] {
                reply->deleteLater();
                const QString mbid =
                    QJsonDocument::fromJson(reply->readAll()).object().value("recording_mbid").toString();
                const bool current = reply->error() == QNetworkReply::NoError && !mbid.isEmpty() &&
                                     token == m_listenBrainzToken && m_loveGenerations.value(song) == generation;
                if (current)
                    m_loveGenerations.remove(song);
                // ListenBrainz may have been turned off, or the app taken offline, while the lookup ran.
                if (current && onlineEnabled() &&
                    SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool())
                    sendListenBrainzFeedback(mbid, loved, key, record, token);
                else if (!loved)
                    m_unloving.remove(unloveId(record, key));
            });
}

void ServicesController::sendListenBrainzFeedback(const QString &mbid, bool loved, const QString &key,
                                                  const QString &record, const QString &token) {
    QNetworkRequest feedback(QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/feedback/recording-feedback"));
    feedback.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
    feedback.setRawHeader("Authorization", "Token " + token.toUtf8());
    feedback.setTransferTimeout(services::detail::requestTimeoutMs);
    const QJsonObject body{{"recording_mbid", mbid}, {"score", loved ? 1 : 0}};
    QNetworkReply *sent = trackReply(m_net->post(feedback, QJsonDocument(body).toJson(QJsonDocument::Compact)));
    connect(sent, &QNetworkReply::finished, this, [this, sent, key, loved, record] {
        sent->deleteLater();
        m_unloving.remove(unloveId(record, key));
        if (sent->error() == QNetworkReply::NoError)
            recordLove(record, key, loved);
    });
}

// Each account's own list of loves is read first, so loves sent from another device or the website aren't sent again.
void ServicesController::syncLikes(const QVariantList &likedTracks, const QVariantList &libraryTracks) {
    m_likesSync = LikesSync{likedTracks, libraryTracks, {}, 0};
    const quint64 sync = ++m_likesSyncId;
    const QStringList services = onlineEnabled() ? lovingServices() : QStringList();
    m_likesSync->waiting = int(services.size());
    for (const QString &service : services)
        readAccountLoves(service, sync, 0);
    if (services.isEmpty())
        finishLikesSync();
}

void ServicesController::readAccountLoves(const QString &service, quint64 sync, int position) {
    const QString user = SettingsController::globalValue("scrobble/" + service + "_user").toString();
    const bool listenBrainz = service == u"listenbrainz";
    QUrl url;
    if (listenBrainz) {
        url = QUrl(QString::fromLatin1(kListenBrainzBaseUrl) + "/feedback/user/" +
                   QString::fromLatin1(QUrl::toPercentEncoding(user)) + "/get-feedback");
        url.setQuery(QUrlQuery{{"score", "1"},
                               {"count", QString::number(kLovesPerPage)},
                               {"offset", QString::number(position)},
                               {"metadata", "true"}});
    } else {
        const ScrobbleNetwork *network = scrobbleNetwork(service);
        url = QUrl(QString(network->apiUrl));
        url.setQuery(QUrlQuery{{"method", "user.getLovedTracks"},
                               {"user", user},
                               {"api_key", QString(network->apiKey)},
                               {"limit", QString::number(kLovesPerPage)},
                               {"page", QString::number(position + 1)},
                               {"format", "json"}});
    }
    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, service, sync, position, listenBrainz] {
        reply->deleteLater();
        if (sync != m_likesSyncId || !m_likesSync)
            return;
        const QJsonObject body = QJsonDocument::fromJson(reply->readAll()).object();
        const std::optional<LovedPage> page = reply->error() != QNetworkReply::NoError ? std::nullopt
                                              : listenBrainz                           ? feedbackPage(body)
                                                                                       : lovedTracksPage(body);
        // An account whose list can't be read whole is left to the app's own record.
        if (!page) {
            m_likesSync->onAccounts.remove(service);
        } else {
            m_likesSync->onAccounts[service].unite(page->songs);
            const int next = position + (listenBrainz ? kLovesPerPage : 1);
            if (next < page->total) {
                readAccountLoves(service, sync, next);
                return;
            }
        }
        if (--m_likesSync->waiting == 0)
            finishLikesSync();
    });
}

std::optional<ServicesController::LovedPage> ServicesController::lovedTracksPage(const QJsonObject &reply) {
    const QJsonValue loved = reply.value("lovedtracks");
    if (!loved.isObject())
        return std::nullopt;
    // A page holding a single song gives it as an object rather than a list of one.
    const QJsonValue track = loved["track"];
    const QJsonArray tracks = track.isArray() ? track.toArray() : QJsonArray{track};
    LovedPage page;
    for (const QJsonValue &value : tracks) {
        const QString title = value["name"].toString();
        const QString artist = value["artist"]["name"].toString();
        if (!title.isEmpty() && !artist.isEmpty())
            page.songs.insert(loveKey(artist, title));
    }
    page.total = loved["@attr"]["totalPages"].toString().toInt();
    return page;
}

std::optional<ServicesController::LovedPage> ServicesController::feedbackPage(const QJsonObject &reply) {
    if (!reply.value("feedback").isArray())
        return std::nullopt;
    LovedPage page;
    for (const QJsonValue &value : reply.value("feedback").toArray()) {
        // Recordings ListenBrainz has no details for can't be matched to a song.
        const QString title = value["track_metadata"]["track_name"].toString();
        const QString artist = value["track_metadata"]["artist_name"].toString();
        if (!title.isEmpty() && !artist.isEmpty())
            page.songs.insert(loveKey(artist, title));
    }
    page.total = reply.value("total_count").toInt();
    return page;
}

void ServicesController::finishLikesSync() {
    const LikesSync sync = *std::exchange(m_likesSync, std::nullopt);
    QSet<QString> liked;
    for (const QVariant &value : sync.liked) {
        const QVariantMap track = value.toMap();
        const auto [artist, title, album] = scrobbleFields(track);
        liked.insert(loveKey(artist, title));
        loveTrackOn(track, true, sync.onAccounts);
    }
    // A love is only taken back from the accounts the app sent it to, so one made on the website stays.
    QStringList records;
    for (const QString &service : lovingServices())
        records.append(lovedKey(service));
    for (const QVariant &value : sync.library) {
        const auto [artist, title, album] = scrobbleFields(value.toMap());
        const QString key = loveKey(artist, title);
        if (artist.isEmpty() || title.isEmpty() || liked.contains(key))
            continue;
        QStringList to;
        for (const QString &record : records) {
            if (hasLove(record, key))
                to.append(record);
        }
        if (!to.isEmpty())
            queueLove({artist, title, false, to});
    }
}

QStringList ServicesController::lovedSongs(const QString &record) {
    return SettingsController::globalValue(record).toStringList();
}

bool ServicesController::hasLove(const QString &record, const QString &song) const {
    return lovedSongs(record).contains(song) && !m_unloving.contains(unloveId(record, song));
}

void ServicesController::recordLove(const QString &record, const QString &song, bool loved) {
    QStringList songs = lovedSongs(record);
    if (loved == songs.contains(song))
        return;
    if (loved)
        songs.append(song);
    else
        songs.removeAll(song);
    SettingsController::setGlobalValue(record, songs);
}

// The accounts a love goes to right now: signed in and switched on.
QStringList ServicesController::lovingServices() const {
    QStringList services;
    for (auto it = m_scrobbleSessionKeys.cbegin(); it != m_scrobbleSessionKeys.cend(); ++it) {
        if (scrobbleNetwork(it.key()) && !it.value().isEmpty() &&
            SettingsController::globalValue("scrobble/" + it.key() + "_enabled", false).toBool())
            services.append(it.key());
    }
    if (!m_listenBrainzToken.isEmpty() &&
        SettingsController::globalValue("scrobble/listenbrainz_enabled", false).toBool())
        services.append(QStringLiteral("listenbrainz"));
    return services;
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
