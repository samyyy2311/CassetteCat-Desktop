#include "services_controller.h"
#include "image_cache.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QUrlQuery>

void ServicesController::searchAlbumCovers(const QString &album, const QString &artist)
{
    if (!onlineEnabled() || album.trimmed().isEmpty()) {
        emit coverSearchResultsReady({});
        return;
    }

    const quint64 requestToken = ++m_coverRequestToken;

    QUrl url("https://itunes.apple.com/search");
    QUrlQuery query;
    QString term = album.trimmed();
    if (!artist.trimmed().isEmpty()) term += " " + artist.trimmed();
    query.addQueryItem("term", term);
    query.addQueryItem("entity", "album");
    query.addQueryItem("limit", "25");
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken, term]() {
        reply->deleteLater();
        if (!onlineEnabled() || requestToken != m_coverRequestToken) return;

        QVariantList results;
        QSet<QString> seenUrls;

        if (reply->error() == QNetworkReply::NoError) {
            const auto doc = QJsonDocument::fromJson(reply->readAll());
            const auto array = doc.object().value("results").toArray();
            for (const auto &val : array) {
                const auto obj = val.toObject();
                QString art100 = obj.value("artworkUrl100").toString();
                if (art100.isEmpty() || seenUrls.contains(art100)) continue;
                seenUrls.insert(art100);

                QString fullArt = art100;
                fullArt.replace("100x100bb", "1200x1200bb");
                QString thumbArt = art100;
                thumbArt.replace("100x100bb", "300x300bb");

                QString releaseYear;
                const QString releaseDate = obj.value("releaseDate").toString();
                if (releaseDate.length() >= 4) releaseYear = releaseDate.left(4);

                QVariantMap item;
                item["album"] = obj.value("collectionName").toString();
                item["artist"] = obj.value("artistName").toString();
                item["year"] = releaseYear;
                item["thumbUrl"] = thumbArt;
                item["fullUrl"] = fullArt;
                item["resolution"] = "1200×1200";
                item["source"] = "iTunes";
                results.append(item);
            }
        }

        QUrl deezerUrl("https://api.deezer.com/search/album");
        QUrlQuery deezerQuery;
        deezerQuery.addQueryItem("q", term);
        deezerQuery.addQueryItem("limit", "15");
        deezerUrl.setQuery(deezerQuery);

        QNetworkRequest deezerReq(deezerUrl);
        deezerReq.setTransferTimeout(services::detail::requestTimeoutMs);
        deezerReq.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0");

        auto *deezerReply = trackReply(m_net->get(deezerReq));
        connect(deezerReply, &QNetworkReply::finished, this, [this, deezerReply, requestToken, results, seenUrls]() mutable {
            deezerReply->deleteLater();
            if (!onlineEnabled() || requestToken != m_coverRequestToken) return;

            if (deezerReply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(deezerReply->readAll());
                const auto data = doc.object().value("data").toArray();
                for (const auto &val : data) {
                    const auto obj = val.toObject();
                    QString full = obj.value("cover_xl").toString();
                    if (full.isEmpty()) full = obj.value("cover_big").toString();
                    if (full.isEmpty() || seenUrls.contains(full)) continue;
                    seenUrls.insert(full);

                    QString thumb = obj.value("cover_medium").toString();
                    if (thumb.isEmpty()) thumb = full;

                    QVariantMap item;
                    item["album"] = obj.value("title").toString();
                    item["artist"] = obj.value("artist").toObject().value("name").toString();
                    item["year"] = "";
                    item["thumbUrl"] = thumb;
                    item["fullUrl"] = full;
                    item["resolution"] = "1000×1000";
                    item["source"] = "Deezer";
                    results.append(item);
                }
            }

            emit coverSearchResultsReady(results);
        });
    });
}

void ServicesController::applyAlbumCover(const QString &album, const QString &artist, const QString &imageUrl, const QString &filePath)
{
    if (!onlineEnabled() || imageUrl.trimmed().isEmpty()) return;

    QUrl url(imageUrl.trimmed());
    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0");

    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, album, artist, filePath]() {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            emit coverSearchFailed("Failed to download cover image");
            return;
        }

        const QByteArray imageBytes = reply->readAll();
        if (imageBytes.isEmpty()) {
            emit coverSearchFailed("Downloaded image is empty");
            return;
        }

        const QString key = "cover:" + album.trimmed().toLower() + ":" + artist.trimmed().toLower() + ":" + QString::number(QDateTime::currentMSecsSinceEpoch());
        const QString savedUrl = saveCachedImage(imageBytes, key, false, "covers");
        if (savedUrl.isEmpty()) {
            emit coverSearchFailed("Failed to save cover to local cache");
            return;
        }

        emit coverApplied(album, artist, savedUrl, filePath);
    });
}
