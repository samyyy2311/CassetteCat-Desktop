#pragma once

#include <QByteArray>
#include <QString>
#include <QVariantMap>

struct TrackInfo {
    QString title;
    QString artist;
    QString album;
    QString genre = "Soundtrack";
    QString label;
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
TrackInfo readTrackInfo(const QString &filePath);
