#include "streaming.h"

#include "credential_vault.h"
#include "streaming_protocols.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QUrlQuery>

#include <memory>

using namespace streaming::protocol;

namespace {

constexpr int kSubsonicPageSize = 500;
constexpr int kJellyfinPageSize = 200;

} // namespace

void StreamingController::connectSubsonic(const QString &serverUrl, const QString &username, const QString &password)
{
    if (blackoutEnabled()) {
        emit serverFailed("subsonic", QString("Offline Blackout Mode is enabled."));
        return;
    }
    const QString base = normalizeServerUrl(serverUrl, 4533);
    const QString user = username.trimmed();
    if (base.isEmpty() || user.isEmpty() || password.isEmpty()) {
        emit serverFailed("subsonic", QString("Enter a server URL, username, and password."));
        return;
    }
    const QString salt = randomSalt();
    const QString token = md5Hex(password + salt);
    const int attempt = ++m_subConnectToken;
    QNetworkRequest request(subsonicUrl(base, "ping.view", user, token, salt));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        if (attempt != m_subConnectToken) {
            return;
        }
        const QByteArray body = reply->readAll();
        const QJsonObject response = parseSubsonicBody(body);
        if (response.contains("_error")) {
            const QString message = reply->error() != QNetworkReply::NoError
                ? friendlyError(reply, response.value("_error").toString())
                : response.value("_error").toString();
            setStatus("subsonic", false, message);
            emit serverFailed("subsonic", message);
            return;
        }
        CredentialVault vault;
        if (!vault.saveSecret("subsonic", password)) {
            const QString message = QString("Connected, but the password couldn't be saved securely.");
            setStatus("subsonic", false, message);
            emit serverFailed("subsonic", message);
            return;
        }
        QSettings settings(m_settingsPath, QSettings::IniFormat);
        settings.setValue("stream/subsonicUrl", base);
        settings.setValue("stream/subsonicUsername", user);
        settings.setValue("stream/subsonicConnected", true);
        setStatus("subsonic", true, QString());
        updateStatusTexts();
        emit serverConnected("subsonic", user);
        refreshLibrary();
    });
}

void StreamingController::refreshSubsonic(const QString &base, const QString &user, const QString &password,
                                          int tokenSnapshot)
{
    const QString salt = randomSalt();
    const QString token = md5Hex(password + salt);
    auto allIds = std::make_shared<QStringList>();
    auto albums = std::make_shared<QVariantList>();
    fetchSubsonicAlbumIds(base, user, token, salt, 0, allIds, albums, tokenSnapshot);
}

void StreamingController::fetchSubsonicAlbumIds(const QString &base, const QString &user, const QString &token,
                                                const QString &salt, int offset, std::shared_ptr<QStringList> ids,
                                                std::shared_ptr<QVariantList> out, int tokenSnapshot)
{
    if (tokenSnapshot != m_refreshToken) return;

    const QList<QPair<QString, QString>> extra = {
        {"type", "alphabeticalByName"},
        {"size", QString::number(kSubsonicPageSize)},
        {"offset", QString::number(offset)},
    };
    QNetworkRequest request(subsonicUrl(base, "getAlbumList2.view", user, token, salt, extra));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        if (tokenSnapshot != m_refreshToken) return;

        const QJsonObject response = parseSubsonicBody(reply->readAll());
        if (response.contains("_error")) {
            const QString message = reply->error() != QNetworkReply::NoError
                ? friendlyError(reply, response.value("_error").toString())
                : response.value("_error").toString();
            setStatus("subsonic", true, message);
            emit serverFailed("subsonic", message);
            finishRefreshStage();
            return;
        }

        const QJsonArray page = jsonArrayTolerant(response.value("albumList2").toObject(), "album");
        for (const QJsonValue &entry : page) {
            const QString id = entry.toObject().value("id").toString();
            if (!id.isEmpty()) ids->append(id);
        }
        if (page.size() < kSubsonicPageSize) {
            fetchSubsonicAlbum(base, user, token, salt, ids, out, std::make_shared<int>(0),
                               std::make_shared<int>(0), tokenSnapshot);
        } else {
            fetchSubsonicAlbumIds(base, user, token, salt, offset + kSubsonicPageSize, ids, out, tokenSnapshot);
        }
    });
}

void StreamingController::fetchSubsonicAlbum(const QString &base, const QString &user, const QString &token,
                                             const QString &salt, std::shared_ptr<QStringList> ids,
                                             std::shared_ptr<QVariantList> out, std::shared_ptr<int> nextIndex,
                                             std::shared_ptr<int> activeRequests, int tokenSnapshot)
{
    if (tokenSnapshot != m_refreshToken) return;
    if (*nextIndex >= ids->size() && *activeRequests == 0) {
        if (!out->isEmpty()) {
            QVariantList merged = m_remoteTracks;
            merged += *out;
            setRemoteTracks(merged);
        }
        setStatus("subsonic", true, QString());
        finishRefreshStage();
        return;
    }

    while (*nextIndex < ids->size() && *activeRequests < 6) {
        const QString id = ids->at((*nextIndex)++);
        ++*activeRequests;

        QNetworkRequest request(subsonicUrl(base, "getAlbum.view", user, token, salt, {{"id", id}}));
        request.setTransferTimeout(streaming::detail::requestTimeoutMs);
        QNetworkReply *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [=, this] {
            if (tokenSnapshot != m_refreshToken) return;

            --*activeRequests;
            const QJsonObject response = parseSubsonicBody(reply->readAll());
            if (!response.contains("_error")) {
                const QJsonObject album = response.value("album").toObject();
                const QString name = album.value("name").toString();
                const QString cover = album.value("coverArt").toString();
                for (const QJsonValue &entry : jsonArrayTolerant(album, "song")) {
                    const QJsonObject song = entry.toObject();
                    if (song.value("id").toString().isEmpty()) continue;

                    QVariantMap track = subsonicTrackMap(song, name.isEmpty() ? QString("Unknown Album") : name, cover);
                    const QString artId = track.value("remoteArtId").toString();
                    if (!artId.isEmpty()) {
                        m_remoteArtSource.insert(track.value("filePath").toString(),
                                                 subsonicUrl(base, "getCoverArt.view", user, token, salt, {{"id", artId}}).toString());
                    }
                    out->append(track);
                }
            }

            fetchSubsonicAlbum(base, user, token, salt, ids, out, nextIndex, activeRequests, tokenSnapshot);
        });
    }
}

void StreamingController::connectJellyfin(const QString &serverUrl, const QString &username, const QString &password)
{
    if (blackoutEnabled()) {
        emit serverFailed("jellyfin", QString("Offline Blackout Mode is enabled."));
        return;
    }
    const QString base = normalizeServerUrl(serverUrl, 8096);
    const QString user = username.trimmed();
    if (base.isEmpty() || user.isEmpty() || password.isEmpty()) {
        emit serverFailed("jellyfin", QString("Enter a server URL, username, and password."));
        return;
    }
    const int attempt = ++m_jellyConnectToken;
    QNetworkRequest request(QUrl(base + "/Users/AuthenticateByName"));
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    const QString authHeader = jellyfinAuthHeader(deviceId(), {});
    request.setRawHeader("Authorization", authHeader.toUtf8());
    request.setRawHeader("X-Emby-Authorization", authHeader.toUtf8());
    QJsonObject payload;
    payload.insert("Username", user);
    payload.insert("Pw", password);
    QNetworkReply *reply = trackReply(m_net->post(request, QJsonDocument(payload).toJson(QJsonDocument::Compact)));
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        if (attempt != m_jellyConnectToken) {
            return;
        }
        if (reply->error() != QNetworkReply::NoError) {
            const QString message = friendlyError(reply, QString("Couldn't connect"));
            setStatus("jellyfin", false, message);
            emit serverFailed("jellyfin", message);
            return;
        }
        const QJsonObject result = QJsonDocument::fromJson(reply->readAll()).object();
        const QString accessToken = result.value("AccessToken").toString();
        const QJsonObject userObj = result.value("User").toObject();
        if (accessToken.isEmpty() || userObj.value("Id").toString().isEmpty()) {
            const QString message = QString("Login failed. Check the username and password.");
            setStatus("jellyfin", false, message);
            emit serverFailed("jellyfin", message);
            return;
        }
        CredentialVault vault;
        if (!vault.saveSecret("jellyfin", accessToken)) {
            const QString message = QString("Connected, but the access token couldn't be saved securely.");
            setStatus("jellyfin", false, message);
            emit serverFailed("jellyfin", message);
            return;
        }
        QSettings settings(m_settingsPath, QSettings::IniFormat);
        settings.setValue("stream/jellyfinUrl", base);
        settings.setValue("stream/jellyfinUsername", userObj.value("Name").toString(user));
        settings.setValue("stream/jellyfinUserId", userObj.value("Id").toString());
        settings.setValue("stream/jellyfinConnected", true);
        setStatus("jellyfin", true, QString());
        updateStatusTexts();
        emit serverConnected("jellyfin", userObj.value("Name").toString(user));
        refreshLibrary();
    });
}

void StreamingController::refreshJellyfin(const QString &base, const QString &userId, const QString &accessToken,
                                          int tokenSnapshot)
{
    fetchJellyfinPage(base, userId, accessToken, 0, std::make_shared<QVariantList>(), tokenSnapshot);
}

void StreamingController::fetchJellyfinPage(const QString &base, const QString &userId, const QString &accessToken,
                                            int startIndex, std::shared_ptr<QVariantList> out, int tokenSnapshot)
{
    if (tokenSnapshot != m_refreshToken) return;

    QUrl url(base + "/Users/" + userId + "/Items");
    QUrlQuery q;
    q.addQueryItem("IncludeItemTypes", "Audio");
    q.addQueryItem("Recursive", "true");
    q.addQueryItem("SortBy", "SortName");
    q.addQueryItem("Fields", "Genres,ProductionYear");
    q.addQueryItem("StartIndex", QString::number(startIndex));
    q.addQueryItem("Limit", QString::number(kJellyfinPageSize));
    url.setQuery(q);

    const QString header = jellyfinAuthHeader(deviceId(), accessToken);
    QNetworkRequest request(url);
    request.setTransferTimeout(streaming::detail::requestTimeoutMs);
    request.setRawHeader("Authorization", header.toUtf8());
    request.setRawHeader("X-Emby-Authorization", header.toUtf8());
    request.setRawHeader("X-Emby-Token", accessToken.toUtf8());
    QNetworkReply *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [=, this] {
        if (tokenSnapshot != m_refreshToken) return;

        if (reply->error() != QNetworkReply::NoError) {
            const QString message = friendlyError(reply, QString("Couldn't load the Jellyfin library."));
            setStatus("jellyfin", true, message);
            emit serverFailed("jellyfin", message);
            finishRefreshStage();
            return;
        }

        const QJsonArray items = QJsonDocument::fromJson(reply->readAll()).object().value("Items").toArray();
        for (const QJsonValue &entry : items) {
            const QJsonObject item = entry.toObject();
            if (item.value("Id").toString().isEmpty()) continue;

            QVariantMap track = jellyfinTrackMap(item);
            const QString artItem = track.value("remoteArtId").toString();
            if (!artItem.isEmpty()) {
                QUrl artUrl(base + "/Items/" + artItem + "/Images/Primary");
                QUrlQuery aq;
                aq.addQueryItem("api_key", accessToken);
                artUrl.setQuery(aq);
                m_remoteArtSource.insert(track.value("filePath").toString(), artUrl.toString());
            }
            out->append(track);
        }

        if (items.size() < kJellyfinPageSize) {
            if (!out->isEmpty()) {
                QVariantList merged = m_remoteTracks;
                merged += *out;
                setRemoteTracks(merged);
            }
            setStatus("jellyfin", true, QString());
            finishRefreshStage();
            return;
        }

        fetchJellyfinPage(base, userId, accessToken, startIndex + kJellyfinPageSize, out, tokenSnapshot);
    });
}

