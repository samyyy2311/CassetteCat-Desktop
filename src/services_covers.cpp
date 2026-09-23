#include "services_controller.h"
#include "image_cache.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QTimer>
#include <QUrlQuery>
#include <functional>

/// @copydoc ServicesController::searchAlbumCovers
void ServicesController::searchAlbumCovers(const QString &album, const QString &artist) {
    if (!onlineEnabled() || album.trimmed().isEmpty()) {
        emit coverSearchResultsReady({});
        return;
    }

    const quint64 requestToken = ++m_coverRequestToken;

    QUrl url("https://itunes.apple.com/search");
    QUrlQuery query;
    QString term = album.trimmed();
    if (!artist.trimmed().isEmpty())
        term += " " + artist.trimmed();
    query.addQueryItem("term", term);
    query.addQueryItem("entity", "album");
    query.addQueryItem("limit", "25");
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken, term, album, artist]() {
        reply->deleteLater();
        if (!onlineEnabled() || requestToken != m_coverRequestToken)
            return;

        QVariantList results;
        QSet<QString> seenUrls;

        if (reply->error() == QNetworkReply::NoError) {
            const auto doc = QJsonDocument::fromJson(reply->readAll());
            const auto array = doc.object().value("results").toArray();
            for (const auto &val : array) {
                const auto obj = val.toObject();
                QString art100 = obj.value("artworkUrl100").toString();
                if (art100.isEmpty() || seenUrls.contains(art100))
                    continue;
                seenUrls.insert(art100);

                QString fullArt = art100;
                fullArt.replace("100x100bb", "1200x1200bb");
                QString thumbArt = art100;
                thumbArt.replace("100x100bb", "300x300bb");

                QString releaseYear;
                const QString releaseDate = obj.value("releaseDate").toString();
                if (releaseDate.length() >= 4)
                    releaseYear = releaseDate.left(4);

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

        auto queryArchive = [this, requestToken, album, artist](QVariantList res, QSet<QString> seen) {
            if (!serviceEnabled("archive")) {
                emit coverSearchResultsReady(res);
                return;
            }

            QUrl mbUrl("https://musicbrainz.org/ws/2/release");
            QUrlQuery mbQuery;
            mbQuery.addQueryItem("fmt", "json");
            mbQuery.addQueryItem("limit", "10");

            QString cleanAlbum = album.trimmed();
            cleanAlbum.replace("\"", "");
            QString cleanArtist = artist.trimmed();
            cleanArtist.replace("\"", "");

            QString queryStr = QString("release:\"%1\"").arg(cleanAlbum);
            if (!cleanArtist.isEmpty()) {
                queryStr += QString(" AND artist:\"%1\"").arg(cleanArtist);
            }
            mbQuery.addQueryItem("query", queryStr);
            mbUrl.setQuery(mbQuery);

            QNetworkRequest mbReq(mbUrl);
            mbReq.setTransferTimeout(services::detail::requestTimeoutMs);
            mbReq.setHeader(QNetworkRequest::UserAgentHeader,
                            "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

            static qint64 s_lastMbRequestMs = 0;

            auto sendMbRequest = std::make_shared<std::function<void(int)>>();
            std::weak_ptr<std::function<void(int)>> weakSendMbRequest = sendMbRequest;
            *sendMbRequest = [this, mbReq, requestToken, res, seen, weakSendMbRequest](int retryCount) mutable {
                if (!onlineEnabled() || requestToken != m_coverRequestToken)
                    return;

                const qint64 now = QDateTime::currentMSecsSinceEpoch();
                const qint64 elapsed = now - s_lastMbRequestMs;
                const int delayMs = (elapsed < 1000) ? static_cast<int>(1000 - elapsed) : 0;

                auto nextCallback = weakSendMbRequest.lock();
                if (!nextCallback)
                    return;

                QTimer::singleShot(
                    delayMs, this,
                    [this, mbReq, requestToken, res, seen, nextCallback, weakSendMbRequest, retryCount]() mutable {
                        if (!onlineEnabled() || requestToken != m_coverRequestToken)
                            return;
                        s_lastMbRequestMs = QDateTime::currentMSecsSinceEpoch();

                        auto *mbReply = trackReply(m_net->get(mbReq));
                        connect(
                            mbReply, &QNetworkReply::finished, this,
                            [this, mbReply, requestToken, res, seen, nextCallback, weakSendMbRequest,
                             retryCount]() mutable {
                                mbReply->deleteLater();
                                if (!onlineEnabled() || requestToken != m_coverRequestToken)
                                    return;

                                const int statusCode =
                                    mbReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
                                if (statusCode == 503 && retryCount < 2) {
                                    if (auto retryCb = weakSendMbRequest.lock()) {
                                        QTimer::singleShot(1100, this,
                                                           [retryCb, retryCount]() { (*retryCb)(retryCount + 1); });
                                    }
                                    return;
                                }

                                if (mbReply->error() == QNetworkReply::NoError) {
                                    const auto doc = QJsonDocument::fromJson(mbReply->readAll());
                                    const auto releases = doc.object().value("releases").toArray();
                                    for (const auto &val : releases) {
                                        const auto obj = val.toObject();
                                        const auto caaObj = obj.value("cover-art-archive").toObject();
                                        const auto rgCaa =
                                            obj.value("release-group").toObject().value("cover-art-archive").toObject();
                                        const bool hasCover =
                                            caaObj.value("front").toBool() || caaObj.value("artwork").toBool() ||
                                            caaObj.value("count").toInt() > 0 || rgCaa.value("front").toBool() ||
                                            rgCaa.value("artwork").toBool() || rgCaa.value("count").toInt() > 0;
                                        if (!hasCover)
                                            continue;

                                        const QString mbid = obj.value("id").toString();
                                        if (mbid.isEmpty())
                                            continue;

                                        const QString fullUrl =
                                            "https://coverartarchive.org/release/" + mbid + "/front";
                                        if (seen.contains(fullUrl))
                                            continue;
                                        seen.insert(fullUrl);

                                        const QString thumbUrl =
                                            "https://coverartarchive.org/release/" + mbid + "/front-500";

                                        QString releaseYear;
                                        const QString dateStr = obj.value("date").toString();
                                        if (dateStr.length() >= 4)
                                            releaseYear = dateStr.left(4);

                                        QString artistCreditName;
                                        const auto artistCredits = obj.value("artist-credit").toArray();
                                        for (const auto &creditVal : artistCredits) {
                                            const auto creditObj = creditVal.toObject();
                                            QString name = creditObj.value("name").toString();
                                            if (name.isEmpty()) {
                                                name = creditObj.value("artist").toObject().value("name").toString();
                                            }
                                            artistCreditName += name + creditObj.value("joinphrase").toString();
                                        }

                                        QVariantMap item;
                                        item["album"] = obj.value("title").toString();
                                        item["artist"] = artistCreditName;
                                        item["year"] = releaseYear;
                                        item["thumbUrl"] = thumbUrl;
                                        item["fullUrl"] = fullUrl;
                                        item["resolution"] = "Original";
                                        item["source"] = "Cover Art Archive";
                                        res.append(item);
                                    }
                                }

                                emit coverSearchResultsReady(res);
                            });
                    });
            };

            (*sendMbRequest)(0);
        };

        if (!serviceEnabled("deezer")) {
            queryArchive(results, seenUrls);
            return;
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
        connect(deezerReply, &QNetworkReply::finished, this,
                [this, deezerReply, requestToken, results, seenUrls, queryArchive]() mutable {
                    deezerReply->deleteLater();
                    if (!onlineEnabled() || requestToken != m_coverRequestToken)
                        return;

                    if (deezerReply->error() == QNetworkReply::NoError) {
                        const auto doc = QJsonDocument::fromJson(deezerReply->readAll());
                        const auto data = doc.object().value("data").toArray();
                        for (const auto &val : data) {
                            const auto obj = val.toObject();
                            QString full = obj.value("cover_xl").toString();
                            if (full.isEmpty())
                                full = obj.value("cover_big").toString();
                            if (full.isEmpty() || seenUrls.contains(full))
                                continue;
                            seenUrls.insert(full);

                            QString thumb = obj.value("cover_medium").toString();
                            if (thumb.isEmpty())
                                thumb = full;

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

                    queryArchive(results, seenUrls);
                });
    });
}

/// @copydoc ServicesController::applyAlbumCover
void ServicesController::applyAlbumCover(const QString &album, const QString &artist, const QString &imageUrl,
                                         const QString &filePath) {
    if (!onlineEnabled() || imageUrl.trimmed().isEmpty())
        return;

    QUrl url(imageUrl.trimmed());
    QNetworkRequest request(url);
    request.setTransferTimeout(services::detail::requestTimeoutMs);
    request.setHeader(QNetworkRequest::UserAgentHeader,
                      "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute, QNetworkRequest::NoLessSafeRedirectPolicy);

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

        const QString key = "cover:" + album.trimmed().toLower() + ":" + artist.trimmed().toLower() + ":" +
                            QString::number(QDateTime::currentMSecsSinceEpoch());
        const QString savedUrl = saveCachedImage(imageBytes, key, false, "covers");
        if (savedUrl.isEmpty()) {
            emit coverSearchFailed("Failed to save cover to local cache");
            return;
        }

        emit coverApplied(album, artist, savedUrl, filePath);
    });
}
