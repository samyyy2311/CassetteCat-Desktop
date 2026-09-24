#pragma once

#include <QByteArray>
#include <QString>
#include <QVariantList>
#include <QVariantMap>

struct TrackInfo {
    QString title;
    QString artist;
    QString album;
    QString genre = "Soundtrack";
    QString label;
    QString comment;
    int year = 0;
    int trackNumber = 0;
    int discNumber = 0;
    int durationSeconds = 0;
    QString duration;
    QString filePath;
    QString fileName;
    QString format;
    QString artworkUrl;
    QString lyrics;
    qint64 fileSize = 0;
    qint64 lastModified = 0;

    QVariantMap toMap() const {
        return {{"title", title},
                {"artist", artist},
                {"album", album},
                {"genre", genre.isEmpty() ? "Soundtrack" : genre},
                {"label", label},
                {"comment", comment},
                {"year", year},
                {"trackNumber", trackNumber},
                {"discNumber", discNumber},
                {"duration", duration},
                {"durationSeconds", durationSeconds},
                {"filePath", filePath},
                {"fileName", fileName},
                {"format", format},
                {"artworkUrl", artworkUrl},
                {"lyrics", lyrics},
                {"fileSize", fileSize},
                {"lastModified", lastModified}};
    }

    static TrackInfo fromMap(const QVariantMap &map) {
        TrackInfo info;
        info.title = map.value("title").toString();
        info.artist = map.value("artist").toString();
        info.album = map.value("album").toString();
        info.genre = map.value("genre", "Soundtrack").toString();
        info.label = map.value("label").toString();
        info.comment = map.value("comment").toString();
        info.year = map.value("year").toInt();
        info.trackNumber = map.value("trackNumber").toInt();
        info.discNumber = map.value("discNumber").toInt();
        info.duration = map.value("duration").toString();
        info.durationSeconds = map.value("durationSeconds").toInt();
        info.filePath = map.value("filePath").toString();
        info.fileName = map.value("fileName").toString();
        info.format = map.value("format").toString();
        info.artworkUrl = map.value("artworkUrl").toString();
        info.lyrics = map.value("lyrics").toString();
        info.fileSize = map.value("fileSize").toLongLong();
        info.lastModified = map.value("lastModified").toLongLong();
        return info;
    }
};

QString formatDuration(int totalSeconds);
QString saveArtwork(const QString &filePath, const QByteArray &image, bool png, int maxDimension = 512);
QString saveFolderArtwork(const QString &filePath, int maxDimension = 512);
QString extractEmbeddedArtwork(const QString &filePath, int maxDimension = 512);
QString extractEmbeddedLyrics(const QString &filePath);
/// Returns the track or album ReplayGain value stored in \p filePath.
float extractReplayGain(const QString &filePath, bool albumMode = false);
TrackInfo readTrackInfo(const QString &filePath);
bool writeTrackInfo(const QVariantMap &metadata, QString *error = nullptr);
/// Parses local tracks and HTTP streams from an M3U playlist.
QVariantList parseM3uPlaylist(const QString &playlistPath);
