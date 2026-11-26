#include "services_controller.h"

#include "lyrics_store.h"

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
#include <QTimer>
#include <QtConcurrent>
#include <QUrlQuery>

namespace {

struct LibraryLyricsScan {
    QList<QVariantMap> queue;
    int found = 0;
    int total = 0;
};

LibraryLyricsScan scanLibraryLyrics(const QVariantList &tracks) {
    LibraryLyricsScan scan;
    scan.total = int(tracks.size());
    for (const QVariant &value : tracks) {
        const QVariantMap track = value.toMap();
        const bool embedded = !track.value("lyrics").toString().trimmed().isEmpty();
        const lyrics::Stored stored = embedded ? lyrics::Stored{} : lyrics::load(lyrics::keyFor(track));
        if (embedded || !stored.text.isEmpty()) {
            ++scan.found;
            continue;
        }
        if (track.value("artist").toString().isEmpty() || lyrics::missingRecently(stored))
            continue;
        const QString title = track.value("title").toString();
        scan.queue.append({{"title", title.isEmpty() ? track.value("fileName").toString() : title},
                           {"artist", track.value("artist")},
                           {"album", track.value("album")},
                           {"durationSeconds", track.value("durationSeconds")}});
    }
    return scan;
}

} // namespace

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
    const QString text = !syncedLyrics.trimmed().isEmpty() ? syncedLyrics.trimmed() : plainLyrics.trimmed();
    if (text.isEmpty())
        return;
    const QString key = lyrics::key(title, artist, album);
    if (lyrics::save(key, text, provider.isEmpty() ? "LRCLIB" : provider))
        emit lyricsSaved(key, text);
}

void ServicesController::fetchLyrics(const QString &title, const QString &artist, const QString &album,
                                     int durationSeconds) {
    if (title.isEmpty() || artist.isEmpty() || !serviceEnabled("lrclib"))
        return;
    const quint64 requestToken = ++m_lyricsRequestToken;

    const lyrics::Stored stored = lyrics::load(lyrics::key(title, artist, album));
    if (!stored.text.isEmpty()) {
        emit lyricsFetched(title, artist, stored.text, stored.provider.isEmpty() ? "LRCLIB" : stored.provider);
        return;
    }
    if (!onlineEnabled())
        return;

    const QVariantMap song{
        {"title", title}, {"artist", artist}, {"album", album}, {"durationSeconds", durationSeconds}};
    lookUpLyrics(song, [this, title, artist, album, requestToken](LyricsLookup result, const QString &text) {
        if (result != LyricsLookup::Found)
            return;
        cacheLyrics(title, artist, album, text, {}, "LRCLIB");
        if (requestToken == m_lyricsRequestToken)
            emit lyricsFetched(title, artist, text, "LRCLIB");
    });
}

void ServicesController::lookUpLyrics(const QVariantMap &song,
                                      std::function<void(LyricsLookup, const QString &)> done) {
    const QString title = song.value("title").toString();
    const QString artist = song.value("artist").toString();
    const QString album = song.value("album").toString();
    const int durationSeconds = song.value("durationSeconds").toInt();

    QUrl url("https://lrclib.net/api/get");
    QUrlQuery q;
    q.addQueryItem("artist_name", artist);
    q.addQueryItem("track_name", title);
    if (!album.isEmpty())
        q.addQueryItem("album_name", album);
    if (durationSeconds > 0)
        q.addQueryItem("duration", QString::number(durationSeconds));
    url.setQuery(q);

    const auto lyricsOf = [](const QJsonObject &result) {
        const QString synced = result.value("syncedLyrics").toString().trimmed();
        return synced.isEmpty() ? result.value("plainLyrics").toString().trimmed() : synced;
    };
    auto *reply = trackReply(m_net->get(services::detail::request(url)));
    connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, done, lyricsOf]() {
        reply->deleteLater();
        if (!onlineEnabled() || !serviceEnabled("lrclib"))
            return done(LyricsLookup::Failed, {});
        // No exact match is a 404, or a 503 for some album queries. Fall back to search.
        const bool noMatch = reply->error() == QNetworkReply::ContentNotFoundError ||
                             reply->error() == QNetworkReply::ServiceUnavailableError;
        if (reply->error() != QNetworkReply::NoError && !noMatch)
            return done(LyricsLookup::Failed, {});
        if (!noMatch) {
            const QString text = lyricsOf(QJsonDocument::fromJson(reply->readAll()).object());
            if (!text.isEmpty())
                return done(LyricsLookup::Found, text);
        }

        QUrl searchUrl("https://lrclib.net/api/search");
        QUrlQuery sq;
        sq.addQueryItem("artist_name", artist);
        sq.addQueryItem("track_name", title);
        searchUrl.setQuery(sq);

        auto *sReply = trackReply(m_net->get(services::detail::request(searchUrl)));
        connect(sReply, &QNetworkReply::finished, this, [this, sReply, done, lyricsOf]() {
            sReply->deleteLater();
            if (!onlineEnabled() || !serviceEnabled("lrclib") || sReply->error() != QNetworkReply::NoError)
                return done(LyricsLookup::Failed, {});
            const QJsonArray results = QJsonDocument::fromJson(sReply->readAll()).array();
            for (const auto &result : results) {
                const QString text = lyricsOf(result.toObject());
                if (!text.isEmpty())
                    return done(LyricsLookup::Found, text);
            }
            done(LyricsLookup::Missing, {});
        });
    });
}

void ServicesController::fetchLibraryLyrics(const QVariantList &tracks) {
    // Reading every song's saved lyrics takes a while for a large library, so it's done off the interface thread.
    const quint64 scan = ++m_libraryLyricsScan;
    m_libraryLyricsHandled.clear();
    QtConcurrent::run(scanLibraryLyrics, tracks).then(this, [this, scan](const LibraryLyricsScan &result) {
        if (scan != m_libraryLyricsScan)
            return;
        m_libraryLyricsQueue = result.queue;
        m_libraryLyricsFound = result.found;
        m_libraryLyricsQueue.removeIf([this](const QVariantMap &song) {
            const auto handled = m_libraryLyricsHandled.constFind(lyrics::keyFor(song));
            if (handled == m_libraryLyricsHandled.cend())
                return false;
            m_libraryLyricsFound += handled.value() ? 1 : 0;
            return true;
        });
        m_libraryLyricsHandled.clear();
        m_libraryLyricsTotal = result.total;
        emit libraryLyricsChanged();
        if (!m_libraryLyricsRunning)
            fetchNextLibraryLyrics();
    });
}

int ServicesController::libraryLyricsFound() const {
    return m_libraryLyricsFound;
}

int ServicesController::libraryLyricsTotal() const {
    return m_libraryLyricsTotal;
}

int ServicesController::libraryLyricsLeft() const {
    return int(m_libraryLyricsQueue.size());
}

void ServicesController::stopLibraryLyrics() {
    ++m_libraryLyricsScan;
    m_libraryLyricsQueue.clear();
    emit libraryLyricsChanged();
}

void ServicesController::fetchNextLibraryLyrics() {
    if (m_libraryLyricsQueue.isEmpty() || !onlineEnabled() || !serviceEnabled("lrclib")) {
        m_libraryLyricsRunning = false;
        if (!m_libraryLyricsQueue.isEmpty())
            stopLibraryLyrics();
        return;
    }
    m_libraryLyricsRunning = true;
    const QVariantMap song = m_libraryLyricsQueue.first();
    lookUpLyrics(song, [this, song](LyricsLookup result, const QString &text) {
        const QString key = lyrics::keyFor(song);
        if (result == LyricsLookup::Failed) {
            // Transient failure: retry in a minute, skip the song after three.
            if (++m_libraryLyricsFailures < 3) {
                QTimer::singleShot(60'000, this, &ServicesController::fetchNextLibraryLyrics);
                return;
            }
        } else if (result == LyricsLookup::Found) {
            if (lyrics::save(key, text, "LRCLIB"))
                emit lyricsSaved(key, text);
            ++m_libraryLyricsFound;
        } else {
            lyrics::markMissing(key);
        }
        m_libraryLyricsFailures = 0;
        m_libraryLyricsHandled.insert(key, result == LyricsLookup::Found);
        // The queue may have been rebuilt meanwhile.
        m_libraryLyricsQueue.removeOne(song);
        emit libraryLyricsChanged();
        // Throttle: one request at a time, with a short gap.
        QTimer::singleShot(300, this, &ServicesController::fetchNextLibraryLyrics);
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
