#include "services_controller.h"

#include "app_paths.h"
#include "app_settings.h"

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

QString ServicesController::localLyricsFor(const QString &filePath) const {
    const QFileInfo info(filePath);
    const QString lrcPath = QDir(info.absolutePath()).filePath(info.completeBaseName() + ".lrc");
    QFile file(lrcPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll()).trimmed();
}

void ServicesController::cacheLyrics(const QString &title, const QString &artist, const QString &album,
                                     const QString &syncedLyrics, const QString &plainLyrics, const QString &provider) {
    const QString lyrics = !syncedLyrics.trimmed().isEmpty() ? syncedLyrics.trimmed() : plainLyrics.trimmed();
    if (lyrics.isEmpty())
        return;
    const QString key = lyricsCacheKey(title, artist, album);
    SettingsController::setGlobalValue("lyrics/cache/" + key, lyrics);
    SettingsController::setGlobalValue("lyrics/provider/" + key, provider.isEmpty() ? "LRCLIB" : provider);
}

void ServicesController::fetchLyrics(const QString &title, const QString &artist, const QString &album,
                                     int durationSeconds) {
    if (title.isEmpty() || artist.isEmpty() || !serviceEnabled("lrclib"))
        return;
    const quint64 requestToken = ++m_lyricsRequestToken;

    const QString key = lyricsCacheKey(title, artist, album);
    const QString cached = SettingsController::globalValue("lyrics/cache/" + key).toString();
    if (!cached.isEmpty()) {
        emit lyricsFetched(title, artist, cached,
                           SettingsController::globalValue("lyrics/provider/" + key, "LRCLIB").toString());
        return;
    }
    if (!onlineEnabled())
        return;

    QUrl url("https://lrclib.net/api/get");
    QUrlQuery q;
    q.addQueryItem("artist_name", artist);
    q.addQueryItem("track_name", title);
    if (!album.isEmpty())
        q.addQueryItem("album_name", album);
    if (durationSeconds > 0)
        q.addQueryItem("duration", QString::number(durationSeconds));
    url.setQuery(q);

    QNetworkRequest req = services::detail::request(url);

    // Shows and caches a result that has lyrics, preferring the synced ones.
    const auto deliver = [this, title, artist, album](const QJsonObject &result) {
        const QString synced = result.value("syncedLyrics").toString();
        const QString plain = result.value("plainLyrics").toString();
        if (synced.isEmpty() && plain.isEmpty())
            return false;
        cacheLyrics(title, artist, album, synced, plain, "LRCLIB");
        emit lyricsFetched(title, artist, synced.isEmpty() ? plain : synced, "LRCLIB");
        return true;
    };
    auto *reply = trackReply(m_net->get(req));
    connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, requestToken, deliver]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("lrclib"))
            return;
        if (requestToken != m_lyricsRequestToken)
            return;
        if (reply->error() == QNetworkReply::NoError && deliver(QJsonDocument::fromJson(reply->readAll()).object()))
            return;

        QUrl searchUrl("https://lrclib.net/api/search");
        QUrlQuery sq;
        sq.addQueryItem("artist_name", artist);
        sq.addQueryItem("track_name", title);
        searchUrl.setQuery(sq);

        QNetworkRequest sReq = services::detail::request(searchUrl);
        auto *sReply = trackReply(m_net->get(sReq));
        connect(sReply, &QNetworkReply::finished, this, [this, sReply, requestToken, deliver]() {
            sReply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("lrclib"))
                return;
            if (requestToken != m_lyricsRequestToken)
                return;
            if (sReply->error() != QNetworkReply::NoError)
                return;
            const QJsonArray results = QJsonDocument::fromJson(sReply->readAll()).array();
            for (const auto &result : results) {
                if (deliver(result.toObject()))
                    return;
            }
        });
    });
}

void ServicesController::searchLyrics(const QString &title, const QString &artist) {
    if (!onlineEnabled() || !serviceEnabled("lrclib") || title.trimmed().isEmpty())
        return;
    const quint64 requestToken = ++m_lyricsRequestToken;

    QUrl url("https://lrclib.net/api/search");
    QUrlQuery query;
    query.addQueryItem("track_name", title.trimmed());
    if (!artist.trimmed().isEmpty())
        query.addQueryItem("artist_name", artist.trimmed());
    url.setQuery(query);

    QNetworkRequest request = services::detail::request(url);
    auto *reply = trackReply(m_net->get(request));
    connect(reply, &QNetworkReply::finished, this, [this, reply, requestToken]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("lrclib"))
            return;
        if (requestToken != m_lyricsRequestToken)
            return;
        QVariantList results;
        if (reply->error() == QNetworkReply::NoError) {
            const auto entries = QJsonDocument::fromJson(reply->readAll()).array();
            QSet<QString> seenLyrics;
            for (const auto &entry : entries) {
                const auto object = entry.toObject();
                const QString synced = object.value("syncedLyrics").toString();
                const QString plain = object.value("plainLyrics").toString();
                if (synced.isEmpty() && plain.isEmpty())
                    continue;
                const QString key = synced.isEmpty() ? plain : synced;
                if (seenLyrics.contains(key))
                    continue;
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

QString ServicesController::lyricsCacheKey(const QString &title, const QString &artist, const QString &album) {
    const QString source = (artist + "|" + title + "|" + album).trimmed().toCaseFolded();
    return QString::fromLatin1(QCryptographicHash::hash(source.toUtf8(), QCryptographicHash::Sha256).toHex());
}
