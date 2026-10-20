#include "services_controller.h"

#include "app_paths.h"
#include "app_settings.h"
#include "image_cache.h"

#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QStringList>
#include <QUrlQuery>

QString ServicesController::getArtistImage(const QString &artist) const {
    return m_artistImages.value(canonicalArtistName(artist.trimmed()));
}

void ServicesController::fetchArtistBio(const QString &artist) {
    if (!onlineEnabled())
        return;
    const QString artistName = artist.trimmed();
    if (artistName.isEmpty())
        return;
    if (serviceEnabled("wiki")) {
        fetchWikipediaIntro(
            {artistName + " (band)", artistName + " (musician)", artistName + " (singer)", artistName}, 0,
            [this, artistName](const QString &bio) { emit artistBioLoaded(artistName, bio); },
            [this, artistName] { fetchArtistBioFromAudioDb(artistName); });
    } else if (serviceEnabled("audiodb")) {
        fetchArtistBioFromAudioDb(artistName);
    }
}

void ServicesController::fetchArtistImage(const QString &artist) {
    if (!onlineEnabled())
        return;
    const QString artistName = artist.trimmed();
    if (artistName.isEmpty())
        return;

    const QString key = canonicalArtistName(artistName);
    if (m_artistImages.contains(key)) {
        emit artistImageLoaded(artistName, m_artistImages.value(key));
        return;
    }

    if (!serviceEnabled("deezer")) {
        if (serviceEnabled("audiodb"))
            fetchArtistImageFromAudioDb(artistName);
        return;
    }

    QUrl url("https://api.deezer.com/search/artist");
    QUrlQuery q;
    q.addQueryItem("q", artistName);
    url.setQuery(q);

    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, artistName, key]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("deezer"))
            return;
        if (reply->error() == QNetworkReply::NoError) {
            const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("data").toArray();
            for (const auto &value : artists) {
                const auto entry = value.toObject();
                if (canonicalArtistName(entry.value("name").toString()) != key)
                    continue;
                const QString image =
                    entry.value("picture_xl").toString().isEmpty()
                        ? (entry.value("picture_big").toString().isEmpty() ? entry.value("picture_medium").toString()
                                                                           : entry.value("picture_big").toString())
                        : entry.value("picture_xl").toString();
                if (!image.isEmpty() && !image.contains("/artist//") && !image.contains("default-artist")) {
                    downloadArtistImage(artistName, image, "deezer");
                    return;
                }
            }
        }
        fetchArtistImageFromAudioDb(artistName);
    });
}

QString ServicesController::canonicalArtistName(const QString &artist) {
    // Provider search is fuzzy; a missing portrait beats the wrong artist.
    QString canonical;
    for (const QChar character : artist.toLower()) {
        if (character.isLetterOrNumber())
            canonical.append(character);
    }
    return canonical;
}

void ServicesController::publishArtistImage(const QString &artist, const QString &imageUrl) {
    const QString key = canonicalArtistName(artist);
    m_artistImages.insert(key, imageUrl);
    SettingsController::setGlobalValue("artist_images/" + key, imageUrl);
    emit artistImageLoaded(artist, imageUrl);
}

void ServicesController::fetchAlbumBio(const QString &album, const QString &artist) {
    if (!onlineEnabled() || !serviceEnabled("wiki"))
        return;
    const QString albumName = album.trimmed();
    if (albumName.isEmpty())
        return;
    const QString artistName = artist.trimmed();
    const QStringList queries = artistName.isEmpty()
                                    ? QStringList{albumName + " (album)"}
                                    : QStringList{albumName + " (" + artistName + " album)", albumName + " (album)"};
    fetchWikipediaIntro(
        queries, 0, [this, albumName](const QString &bio) { emit albumBioLoaded(albumName, bio); }, [] {});
}

void ServicesController::fetchWikipediaIntro(const QStringList &queries, int index,
                                             std::function<void(const QString &)> found,
                                             std::function<void()> missing) {
    if (!onlineEnabled() || !serviceEnabled("wiki") || index >= queries.size()) {
        missing();
        return;
    }

    QUrl url("https://en.wikipedia.org/w/api.php");
    QUrlQuery q;
    q.addQueryItem("action", "query");
    q.addQueryItem("format", "json");
    q.addQueryItem("prop", "extracts");
    q.addQueryItem("exintro", "true");
    q.addQueryItem("explaintext", "true");
    q.addQueryItem("redirects", "true");
    q.addQueryItem("titles", queries.at(index));
    url.setQuery(q);

    QNetworkRequest request = services::detail::request(url);
    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, queries, index, found, missing]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("wiki")) {
            missing();
            return;
        }
        if (reply->error() == QNetworkReply::NoError) {
            const auto pages =
                QJsonDocument::fromJson(reply->readAll()).object().value("query").toObject().value("pages").toObject();
            for (const auto &key : pages.keys()) {
                const QString extract = pages.value(key).toObject().value("extract").toString().trimmed();
                if (!extract.isEmpty()) {
                    found(extract);
                    return;
                }
            }
        }
        fetchWikipediaIntro(queries, index + 1, found, missing);
    });
}

void ServicesController::downloadArtistImage(const QString &artist, const QString &imageUrl, const QString &service) {
    const QString key = canonicalArtistName(artist);
    if (imageUrl.isEmpty() || !serviceEnabled(service) || m_artistImagePending.contains(key)) {
        return;
    }

    m_artistImagePending.insert(key);
    QNetworkRequest request{QUrl{imageUrl}};
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::PreferCache);
    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, artist, key, service]() {
        m_artistImagePending.remove(key);
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled(service))
            return;
        if (reply->error() != QNetworkReply::NoError) {
            return;
        }

        const QByteArray image = reply->readAll();
        if (image.size() <= 32 || image.size() > 3 * 1024 * 1024) {
            return;
        }
        const QString local = saveCachedImage(
            image, "artist-" + key,
            reply->header(QNetworkRequest::ContentTypeHeader).toString().contains("png", Qt::CaseInsensitive),
            "artists");
        if (!local.isEmpty()) {
            publishArtistImage(artist, local);
        }
    });
}

void ServicesController::searchAudioDb(const QString &artist, std::function<void(const QJsonArray &)> handle) {
    if (!onlineEnabled() || !serviceEnabled("audiodb"))
        return;
    QUrl url("https://www.theaudiodb.com/api/v1/json/123/search.php");
    QUrlQuery q;
    q.addQueryItem("s", artist);
    url.setQuery(q);

    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, handle]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("audiodb") || reply->error() != QNetworkReply::NoError)
            return;
        handle(QJsonDocument::fromJson(reply->readAll()).object().value("artists").toArray());
    });
}

void ServicesController::fetchArtistImageFromAudioDb(const QString &artist) {
    searchAudioDb(artist, [this, artist](const QJsonArray &artists) {
        const QString key = canonicalArtistName(artist);
        for (const auto &value : artists) {
            const auto entry = value.toObject();
            if (canonicalArtistName(entry.value("strArtist").toString()) != key)
                continue;
            const QString image = entry.value("strArtistFanart").toString().isEmpty()
                                      ? entry.value("strArtistThumb").toString()
                                      : entry.value("strArtistFanart").toString();
            if (!image.isEmpty())
                downloadArtistImage(artist, image, "audiodb");
            return;
        }
    });
}

void ServicesController::fetchArtistBioFromAudioDb(const QString &artist) {
    searchAudioDb(artist, [this, artist](const QJsonArray &artists) {
        const QString biography =
            artists.isEmpty() ? QString() : artists.first().toObject().value("strBiographyEN").toString().trimmed();
        if (!biography.isEmpty())
            emit artistBioLoaded(artist, biography);
    });
}
