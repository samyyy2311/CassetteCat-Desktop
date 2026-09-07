#include "library_scanner.h"

#include "audio_metadata.h"

#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QUrl>
#include <QVariantMap>

#include <algorithm>

QVariantList scanTracks(const QString &folder)
{
    const QStringList filters = {
        "*.aac", "*.aiff", "*.alac", "*.flac", "*.m4a", "*.mp3", "*.ogg", "*.opus", "*.wav", "*.wma"
    };
    QList<TrackInfo> trackList;
    QHash<QString, QString> artworkByFolder;
    QDirIterator iterator(folder, filters, QDir::Files, QDirIterator::Subdirectories);

    while (iterator.hasNext()) {
        const QString filePath = iterator.next();
        const QFileInfo fileInfo(filePath);
        if (fileInfo.fileName().startsWith('.') || fileInfo.isHidden()) {
            continue;
        }

        const QString folderPath = fileInfo.absolutePath();
        if (!artworkByFolder.contains(folderPath)) {
            const QDir trackFolder(folderPath);
            const QStringList covers = {"cover.jpg", "cover.jpeg", "cover.png", "folder.jpg", "folder.png", "front.jpg", "front.png"};
            QString cover;

            for (const QString &name : covers) {
                const QString candidate = trackFolder.filePath(name);
                if (QFileInfo::exists(candidate)) {
                    cover = QUrl::fromLocalFile(candidate).toString();
                    break;
                }
            }

            artworkByFolder.insert(folderPath, cover);
        }

        TrackInfo track = readTrackInfo(filePath);
        track.artworkUrl = artworkByFolder.value(folderPath);
        trackList.append(track);
    }

    std::sort(trackList.begin(), trackList.end(), [](const TrackInfo &a, const TrackInfo &b) {
        return QString::compare(a.title, b.title, Qt::CaseInsensitive) < 0;
    });

    QVariantList result;
    result.reserve(trackList.size());
    for (const auto &track : trackList) {
        result.append(track.toMap());
    }
    return result;
}

bool scanSelfCheck()
{
    QTemporaryDir folder;
    QFile track(folder.filePath("CassetteCat Check.mp3"));
    QFile dotTrack(folder.filePath(".trashed-12345.mp3"));

    if (!folder.isValid() || !track.open(QIODevice::WriteOnly) || !dotTrack.open(QIODevice::WriteOnly)) {
        return false;
    }

    track.close();
    dotTrack.close();

    const QVariantList tracks = scanTracks(folder.path());
    if (tracks.size() != 1) {
        return false;
    }

    const QVariantMap trackMap = tracks.first().toMap();
    return trackMap.value("title").toString() == "CassetteCat Check"
        && trackMap.value("artist").toString() == "Unknown Artist"
        && trackMap.value("album").toString() == "Unknown Album";
}
