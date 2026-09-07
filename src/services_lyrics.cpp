#include "services_controller.h"

#include "app_paths.h"

#include <QCryptographicHash>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSet>
#include <QSettings>
#include <QUrlQuery>

QString ServicesController::localLyricsFor(const QString &filePath) const
{
        const QFileInfo info(filePath);
        const QString lrcPath = QDir(info.absolutePath()).filePath(info.completeBaseName() + ".lrc");
        QFile file(lrcPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
        return QString::fromUtf8(file.readAll()).trimmed();
    }

void ServicesController::cacheLyrics(const QString &title, const QString &artist, const QString &album, const QString &syncedLyrics, const QString &plainLyrics, const QString &provider)
{
        const QString lyrics = !syncedLyrics.trimmed().isEmpty() ? syncedLyrics.trimmed() : plainLyrics.trimmed();
        if (lyrics.isEmpty()) return;
        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        const QString key = lyricsCacheKey(title, artist, album);
        settings.setValue("lyrics/cache/" + key, lyrics);
        settings.setValue("lyrics/provider/" + key, provider.isEmpty() ? "LRCLIB" : provider);
    }

void ServicesController::fetchLyrics(const QString &title, const QString &artist, const QString &album, int durationSeconds)
{
        if (title.isEmpty() || artist.isEmpty() || !serviceEnabled("lrclib")) return;
        const quint64 requestToken = ++m_lyricsRequestToken;

        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        const QString cached = settings.value("lyrics/cache/" + lyricsCacheKey(title, artist, album)).toString();
        if (!cached.isEmpty()) {
            emit lyricsFetched(title, artist, cached, settings.value("lyrics/provider/" + lyricsCacheKey(title, artist, album), "LRCLIB").toString());
            return;
        }
        if (!onlineEnabled()) return;

        QUrl url("https://lrclib.net/api/get");
        QUrlQuery q;
        q.addQueryItem("artist_name", artist);
        q.addQueryItem("track_name", title);
        if (!album.isEmpty()) q.addQueryItem("album_name", album);
        if (durationSeconds > 0) q.addQueryItem("duration", QString::number(durationSeconds));
        url.setQuery(q);

        QNetworkRequest req(url);
        req.setTransferTimeout(services::detail::requestTimeoutMs);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = trackReply(m_net->get(req));
        connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, album, requestToken]() {
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("lrclib")) return;
            if (requestToken != m_lyricsRequestToken) return;
            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isObject()) {
                    const auto obj = doc.object();
                    QString synced = obj.value("syncedLyrics").toString();
                    QString plain = obj.value("plainLyrics").toString();
                    QString res = !synced.isEmpty() ? synced : plain;
                    if (!res.isEmpty()) {
                        cacheLyrics(title, artist, album, synced, plain, "LRCLIB");
                        emit lyricsFetched(title, artist, res, "LRCLIB");
                        return;
                    }
                }
            }

            QUrl searchUrl("https://lrclib.net/api/search");
            QUrlQuery sq;
            sq.addQueryItem("artist_name", artist);
            sq.addQueryItem("track_name", title);
            searchUrl.setQuery(sq);

            QNetworkRequest sReq(searchUrl);
            sReq.setTransferTimeout(services::detail::requestTimeoutMs);
            sReq.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
            auto *sReply = trackReply(m_net->get(sReq));
            connect(sReply, &QNetworkReply::finished, this, [this, sReply, title, artist, album, requestToken]() {
                sReply->deleteLater();
                if (!onlineEnabled() || !serviceEnabled("lrclib")) return;
                if (requestToken != m_lyricsRequestToken) return;
                if (sReply->error() == QNetworkReply::NoError) {
                    const auto doc = QJsonDocument::fromJson(sReply->readAll());
                    if (doc.isArray()) {
                        const auto arr = doc.array();
                        for (const auto &val : arr) {
                            const auto obj = val.toObject();
                            QString synced = obj.value("syncedLyrics").toString();
                            QString plain = obj.value("plainLyrics").toString();
                            QString res = !synced.isEmpty() ? synced : plain;
                            if (!res.isEmpty()) {
                                cacheLyrics(title, artist, album, synced, plain, "LRCLIB");
                                emit lyricsFetched(title, artist, res, "LRCLIB");
                                return;
                            }
                        }
                    }
                }
            });
        });
    }

void ServicesController::searchLyrics(const QString &title, const QString &artist)
{
        if (!onlineEnabled() || !serviceEnabled("lrclib") || title.trimmed().isEmpty()) return;
        const quint64 requestToken = ++m_lyricsRequestToken;

        QUrl url("https://lrclib.net/api/search");
        QUrlQuery query;
        query.addQueryItem("track_name", title.trimmed());
        if (!artist.trimmed().isEmpty()) query.addQueryItem("artist_name", artist.trimmed());
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setTransferTimeout(services::detail::requestTimeoutMs);
        request.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
        auto *reply = trackReply(m_net->get(request));
        connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken]() {
            reply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("lrclib")) return;
            if (requestToken != m_lyricsRequestToken) return;
            QVariantList results;
            if (reply->error() == QNetworkReply::NoError) {
                const auto entries = QJsonDocument::fromJson(reply->readAll()).array();
                QSet<QString> seenLyrics;
                for (const auto &entry : entries) {
                    const auto object = entry.toObject();
                    const QString synced = object.value("syncedLyrics").toString();
                    const QString plain = object.value("plainLyrics").toString();
                    if (synced.isEmpty() && plain.isEmpty()) continue;
                    const QString key = synced.isEmpty() ? plain : synced;
                    if (seenLyrics.contains(key)) continue;
                    seenLyrics.insert(key);
                    QVariantMap result;
                    result["title"] = object.value("trackName").toString();
                    result["artist"] = object.value("artistName").toString();
                    result["album"] = object.value("albumName").toString();
                    result["syncedLyrics"] = synced;
                    result["plainLyrics"] = plain;
                    results.append(result);
                }
            }
            emit lyricsSearchResultsReady(results);
        });
    }

QString ServicesController::lyricsCacheKey(const QString &title, const QString &artist, const QString &album)
{
        const QString source = (artist + "|" + title + "|" + album).trimmed().toCaseFolded();
        return QString::fromLatin1(QCryptographicHash::hash(source.toUtf8(), QCryptographicHash::Sha256).toHex());
    }
