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

    QVariantMap toMap() const
    {
        return {
            {"title", title},
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
            {"lyrics", lyrics}
        };
    }
};

QString formatDuration(int totalSeconds);
QString saveArtwork(const QString &filePath, const QByteArray &image, bool png, int maxDimension = 0);
QString extractEmbeddedArtwork(const QString &filePath, int maxDimension = 0);
QString extractEmbeddedLyrics(const QString &filePath);
/// Returns the track or album ReplayGain value stored in \p filePath.
float extractReplayGain(const QString &filePath, bool albumMode = false);
TrackInfo readTrackInfo(const QString &filePath);
bool writeTrackInfo(const QVariantMap &metadata, QString *error = nullptr);
/// Parses local tracks and HTTP streams from an M3U playlist.
QVariantList parseM3uPlaylist(const QString &playlistPath);
