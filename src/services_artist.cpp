#include "services_controller.h"

#include "app_paths.h"
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

QString ServicesController::getArtistImage(const QString &artist) const
{
        return m_artistImages.value(canonicalArtistName(artist.trimmed()));
    }

void ServicesController::fetchArtistBio(const QString &artist)
{
        if (!onlineEnabled()) return;
        const QString artistName = artist.trimmed();
        if (artistName.isEmpty()) return;
        if (serviceEnabled("wiki")) {
            fetchArtistBioFromWikipedia(
                artistName,
                {artistName + " (band)", artistName + " (musician)", artistName + " (singer)", artistName},
                0);
        } else if (serviceEnabled("audiodb")) {
            fetchArtistBioFromAudioDb(artistName);
        }
    }

void ServicesController::fetchArtistImage(const QString &artist)
{
        if (!onlineEnabled()) return;
        const QString artistName = artist.trimmed();
        if (artistName.isEmpty()) return;

        const QString key = canonicalArtistName(artistName);
        if (m_artistImages.contains(key)) {
            emit artistImageLoaded(artistName, m_artistImages.value(key));
            return;
        }

        if (!serviceEnabled("deezer")) {
            if (serviceEnabled("audiodb")) fetchArtistImageFromAudioDb(artistName);
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
            if (!onlineEnabled() || !serviceEnabled("deezer")) return;
            if (reply->error() == QNetworkReply::NoError) {
                const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("data").toArray();
                for (const auto &value : artists) {
                    const auto entry = value.toObject();
                    if (canonicalArtistName(entry.value("name").toString()) != key) continue;
                    const QString image = entry.value("picture_xl").toString().isEmpty()
                        ? (entry.value("picture_big").toString().isEmpty() ? entry.value("picture_medium").toString() : entry.value("picture_big").toString())
                        : entry.value("picture_xl").toString();
                    if (!image.isEmpty()) {
                        downloadArtistImage(artistName, image, "deezer");
                        return;
                    }
                }
            }
            fetchArtistImageFromAudioDb(artistName);
        });
    }

QString ServicesController::canonicalArtistName(const QString &artist)
{
        // Provider search is fuzzy; a missing portrait beats the wrong artist.
        QString canonical;
        for (const QChar character : artist.toLower()) {
            if (character.isLetterOrNumber()) canonical.append(character);
        }
        return canonical;
    }

void ServicesController::publishArtistImage(const QString &artist, const QString &imageUrl)
{
        const QString key = canonicalArtistName(artist);
        m_artistImages.insert(key, imageUrl);
        QSettings s(settingsFilePath(), QSettings::IniFormat);
        s.setValue("artist_images/" + key, imageUrl);
        emit artistImageLoaded(artist, imageUrl);
}

void ServicesController::downloadArtistImage(const QString &artist, const QString &imageUrl, const QString &service)
{
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
        if (!onlineEnabled() || !serviceEnabled(service)) return;
        if (reply->error() != QNetworkReply::NoError) {
            return;
        }

        const QByteArray image = reply->readAll();
        if (image.size() <= 32 || image.size() > 3 * 1024 * 1024) {
            return;
        }
        const QString local = saveCachedImage(
            image,
            "artist-" + key,
            reply->header(QNetworkRequest::ContentTypeHeader).toString().contains("png", Qt::CaseInsensitive),
            "artists");
        if (!local.isEmpty()) {
            publishArtistImage(artist, local);
        }
    });
}

void ServicesController::fetchArtistImageFromAudioDb(const QString &artist)
{
        if (!onlineEnabled() || !serviceEnabled("audiodb")) return;
        QUrl url("https://www.theaudiodb.com/api/v1/json/123/search.php");
        QUrlQuery q;
        q.addQueryItem("s", artist);
        url.setQuery(q);

        QNetworkRequest request(url);
        request.setTransferTimeout(services::detail::requestTimeoutMs);
        auto *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist]() {
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("audiodb")) return;
            if (reply->error() != QNetworkReply::NoError) return;
            const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("artists").toArray();
            const QString key = canonicalArtistName(artist);
            for (const auto &value : artists) {
                const auto entry = value.toObject();
                if (canonicalArtistName(entry.value("strArtist").toString()) != key) continue;
                const QString image = entry.value("strArtistFanart").toString().isEmpty()
                    ? entry.value("strArtistThumb").toString()
                    : entry.value("strArtistFanart").toString();
                if (!image.isEmpty()) downloadArtistImage(artist, image, "audiodb");
                return;
            }
        });
    }

void ServicesController::fetchArtistBioFromWikipedia(const QString &artist, const QStringList &queries, int index)
{
        if (!onlineEnabled() || !serviceEnabled("wiki")) {
            fetchArtistBioFromAudioDb(artist);
            return;
        }
        if (index >= queries.size()) {
            fetchArtistBioFromAudioDb(artist);
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

        QNetworkRequest req(url);
        req.setTransferTimeout(services::detail::requestTimeoutMs);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = trackReply(m_net->get(req));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist, queries, index]() {
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("wiki")) {
                fetchArtistBioFromAudioDb(artist);
                return;
            }
            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                const auto query = doc.object().value("query").toObject();
                const auto pages = query.value("pages").toObject();
                for (const auto &key : pages.keys()) {
                    const auto page = pages.value(key).toObject();
                    const QString extract = page.value("extract").toString().trimmed();
                    if (!extract.isEmpty()) {
                        emit artistBioLoaded(artist, extract);
                        return;
                    }
                }
            }
            fetchArtistBioFromWikipedia(artist, queries, index + 1);
        });
    }

void ServicesController::fetchArtistBioFromAudioDb(const QString &artist)
{
        if (!onlineEnabled() || !serviceEnabled("audiodb")) return;
        QUrl url("https://www.theaudiodb.com/api/v1/json/123/search.php");
        QUrlQuery q;
        q.addQueryItem("s", artist);
        url.setQuery(q);

        QNetworkRequest request(url);
        request.setTransferTimeout(services::detail::requestTimeoutMs);
        auto *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist]() {
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("audiodb")) return;
            if (reply->error() != QNetworkReply::NoError) return;
            const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("artists").toArray();
            const QString biography = artists.isEmpty() ? QString() : artists.first().toObject().value("strBiographyEN").toString().trimmed();
            if (!biography.isEmpty()) emit artistBioLoaded(artist, biography);
        });
    }
