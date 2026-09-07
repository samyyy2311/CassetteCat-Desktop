#include "audio_metadata.h"
#include "image_cache.h"

#include <QBuffer>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QUrl>
#include <QtEndian>

#include <taglib/audioproperties.h>
#include <taglib/fileref.h>
#include <taglib/tag.h>
#include <toolkit/tpropertymap.h>
#include <mpeg/mpegfile.h>
#include <mpeg/id3v2/id3v2tag.h>
#include <mpeg/id3v2/frames/attachedpictureframe.h>
#include <mpeg/id3v2/frames/unsynchronizedlyricsframe.h>
#include <mpeg/id3v2/frames/synchronizedlyricsframe.h>
#include <mp4/mp4file.h>
#include <mp4/mp4tag.h>
#include <flac/flacfile.h>
#include <flac/flacpicture.h>

QString formatDuration(int totalSeconds)
{
    if (totalSeconds <= 0) {
        return QString();
    }
    const int minutes = totalSeconds / 60;
    const int seconds = totalSeconds % 60;
    return QString("%1:%2").arg(minutes).arg(seconds, 2, 10, QChar('0'));
}

QString saveArtwork(const QString &filePath, const QByteArray &image, bool png, int maxDimension)
{
    if (image.isEmpty()) return {};
    QByteArray outputImage = image;
    if (maxDimension > 0) {
        QBuffer input(&outputImage);
        if (!input.open(QIODevice::ReadOnly)) return {};
        QImageReader reader(&input);
        const QSize sourceSize = reader.size();
        if (!sourceSize.isValid()) return {};
        reader.setScaledSize(sourceSize.scaled(maxDimension, maxDimension, Qt::KeepAspectRatio));
        const QImage thumbnail = reader.read();
        if (thumbnail.isNull()) return {};
        outputImage.clear();
        QBuffer output(&outputImage);
        if (!output.open(QIODevice::WriteOnly)
            || !thumbnail.save(&output, png ? "PNG" : "JPEG", png ? -1 : 90)) return {};
    }
    return saveCachedImage(outputImage, filePath + ':' + QString::number(maxDimension), png, "covers");
}

QString extractEmbeddedArtwork(const QString &filePath, int maxDimension)
{
    if (filePath.isEmpty()) return {};
    const QString suffix = QFileInfo(filePath).suffix().toLower();

    if (suffix == "m4a" || suffix == "mp4" || suffix == "alac") {
        try {
#ifdef _WIN32
            TagLib::MP4::File file(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
            TagLib::MP4::File file(filePath.toUtf8().constData());
#endif
            if (const TagLib::MP4::Tag *tag = file.tag()) {
                const TagLib::MP4::CoverArtList covers = tag->item("covr").toCoverArtList();
                if (!covers.isEmpty()) {
                    const TagLib::MP4::CoverArt cover = covers.front();
                    const TagLib::ByteVector data = cover.data();
                    return saveArtwork(filePath, QByteArray(data.data(), data.size()), cover.format() == TagLib::MP4::CoverArt::PNG, maxDimension);
                }
            }
        } catch (...) {}
        return {};
    }

    if (suffix == "flac") {
        try {
#ifdef _WIN32
            TagLib::FLAC::File file(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
            TagLib::FLAC::File file(filePath.toUtf8().constData());
#endif
            const auto picList = file.pictureList();
            if (!picList.isEmpty()) {
                const auto *pic = picList.front();
                return saveArtwork(
                    filePath,
                    QByteArray(pic->data().data(), pic->data().size()),
                    QString::fromStdWString(pic->mimeType().toWString()).contains("png", Qt::CaseInsensitive), maxDimension
                );
            }
        } catch (...) {}
        return {};
    }

    if (suffix == "mp3") {
        try {
#ifdef _WIN32
            TagLib::MPEG::File file(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
            TagLib::MPEG::File file(filePath.toUtf8().constData());
#endif
            if (const TagLib::ID3v2::Tag *tag = file.ID3v2Tag()) {
                const TagLib::ID3v2::FrameList frames = tag->frameListMap()["APIC"];
                if (!frames.isEmpty()) {
                    const auto *picture = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(frames.front());
                    if (picture && !picture->picture().isEmpty()) {
                        return saveArtwork(
                            filePath,
                            QByteArray(picture->picture().data(), picture->picture().size()),
                            QString::fromStdWString(picture->mimeType().toWString()).contains("png", Qt::CaseInsensitive), maxDimension
                        );
                    }
                }
            }
        } catch (...) {}
        return {};
    }

    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif
        if (!fileRef.isNull() && fileRef.file() && fileRef.file()->isValid()) {
            TagLib::PropertyMap props = fileRef.file()->properties();
            if (props.contains("METADATA_BLOCK_PICTURE")) {
                const auto &list = props["METADATA_BLOCK_PICTURE"];
                if (!list.isEmpty()) {
                    QByteArray base64Data = QString::fromStdWString(list.front().toWString()).toLatin1();
                    QByteArray binaryData = QByteArray::fromBase64(base64Data);
                    if (binaryData.size() > 32) {
                        quint32 mimeLen = qFromBigEndian<quint32>(binaryData.constData() + 4);
                        if (mimeLen < 128 && binaryData.size() > (int)(8 + mimeLen + 4)) {
                            QByteArray mime = binaryData.mid(8, mimeLen);
                            int offset = 8 + mimeLen;
                            quint32 descLen = qFromBigEndian<quint32>(binaryData.constData() + offset);
                            offset += 4 + descLen + 16;
                            if (offset + 4 <= binaryData.size()) {
                                quint32 picLen = qFromBigEndian<quint32>(binaryData.constData() + offset);
                                offset += 4;
                                if (offset + picLen <= (quint32)binaryData.size()) {
                                    QByteArray picBytes = binaryData.mid(offset, picLen);
                                    return saveArtwork(filePath, picBytes, mime.contains("png"), maxDimension);
                                }
                            }
                        }
                    }
                }
            }
        }
    } catch (...) {}

    // Fallback: check track's directory for cover image files
    try {
        const QFileInfo fi(filePath);
        const QDir trackFolder = fi.absoluteDir();
        const QStringList covers = {
            "cover.jpg", "cover.jpeg", "cover.png",
            "folder.jpg", "folder.jpeg", "folder.png",
            "front.jpg", "front.jpeg", "front.png",
            "album.jpg", "album.jpeg", "album.png"
        };
        for (const QString &name : covers) {
            const QString candidate = trackFolder.filePath(name);
            if (QFileInfo::exists(candidate)) {
                return QUrl::fromLocalFile(candidate).toString();
            }
        }
    } catch (...) {}

    return {};
}

QString extractEmbeddedLyrics(const QString &filePath)
{
    if (filePath.isEmpty()) return {};

    const QFileInfo fileInfo(filePath);
    const QString dirPath = fileInfo.absolutePath();
    const QString baseName = fileInfo.completeBaseName();
    const QString lrcPath = dirPath + "/" + baseName + ".lrc";
    const QString txtPath = dirPath + "/" + baseName + ".txt";

    if (QFileInfo::exists(lrcPath)) {
        QFile lrcFile(lrcPath);
        if (lrcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString content = QString::fromUtf8(lrcFile.readAll()).trimmed();
            if (!content.isEmpty()) return content;
        }
    }
    if (QFileInfo::exists(txtPath)) {
        QFile txtFile(txtPath);
        if (txtFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString content = QString::fromUtf8(txtFile.readAll()).trimmed();
            if (!content.isEmpty()) return content;
        }
    }

    const QString suffix = fileInfo.suffix().toLower();

    if (suffix == "m4a" || suffix == "mp4" || suffix == "alac") {
        try {
#ifdef _WIN32
            TagLib::MP4::File file(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
            TagLib::MP4::File file(filePath.toUtf8().constData());
#endif
            if (const TagLib::MP4::Tag *tag = file.tag()) {
                const auto &itemMap = tag->itemMap();
                for (auto it = itemMap.begin(); it != itemMap.end(); ++it) {
                    const QString key = QString::fromStdWString(it->first.toWString()).toLower();
                    if (key.contains("lyr") || key.contains("lyrics")) {
                        const auto strList = it->second.toStringList();
                        if (!strList.isEmpty()) {
                            QString lyrics;
                            for (const auto &s : strList) {
                                lyrics += QString::fromStdWString(s.toWString()) + "\n";
                            }
                            if (!lyrics.trimmed().isEmpty()) return lyrics.trimmed();
                        }
                    }
                }
            }
        } catch (...) {}
    }

    if (suffix == "mp3") {
        try {
#ifdef _WIN32
            TagLib::MPEG::File file(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
            TagLib::MPEG::File file(filePath.toUtf8().constData());
#endif
            if (const TagLib::ID3v2::Tag *tag = file.ID3v2Tag()) {
                const TagLib::ID3v2::FrameList usltFrames = tag->frameListMap()["USLT"];
                for (auto *frame : usltFrames) {
                    if (auto *uslt = dynamic_cast<TagLib::ID3v2::UnsynchronizedLyricsFrame *>(frame)) {
                        QString text = QString::fromStdWString(uslt->text().toWString()).trimmed();
                        if (!text.isEmpty()) return text;
                    }
                }

                const TagLib::ID3v2::FrameList syltFrames = tag->frameListMap()["SYLT"];
                for (auto *frame : syltFrames) {
                    if (auto *sylt = dynamic_cast<TagLib::ID3v2::SynchronizedLyricsFrame *>(frame)) {
                        const auto &synchedText = sylt->synchedText();
                        QString text;
                        for (const auto &item : synchedText) {
                            text += QString::fromStdWString(item.text.toWString()) + "\n";
                        }
                        if (!text.trimmed().isEmpty()) return text.trimmed();
                    }
                }
            }
        } catch (...) {}
    }

    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif
        if (!fileRef.isNull() && fileRef.file() && fileRef.file()->isValid()) {
            if (TagLib::PropertyMap properties = fileRef.file()->properties(); !properties.isEmpty()) {
                if (properties.contains("LYRICS")) {
                    const auto &list = properties["LYRICS"];
                    if (!list.isEmpty()) {
                        QString text;
                        for (const auto &s : list) {
                            text += QString::fromStdWString(s.toWString()) + "\n";
                        }
                        if (!text.trimmed().isEmpty()) return text.trimmed();
                    }
                }
                if (properties.contains("UNSYNCEDLYRICS")) {
                    const auto &list = properties["UNSYNCEDLYRICS"];
                    if (!list.isEmpty()) {
                        QString text;
                        for (const auto &s : list) {
                            text += QString::fromStdWString(s.toWString()) + "\n";
                        }
                        if (!text.trimmed().isEmpty()) return text.trimmed();
                    }
                }
            }
        }
    } catch (...) {}

    return {};
}

TrackInfo readTrackInfo(const QString &filePath)
{
    const QFileInfo fileInfo(filePath);
    const QString fallbackTitle = fileInfo.completeBaseName();

    TrackInfo info;
    info.filePath = filePath;
    info.fileName = fileInfo.fileName();
    info.format = fileInfo.suffix().toUpper();
    info.title = fallbackTitle;
    info.artist = "Unknown Artist";
    info.album = "Unknown Album";
    info.durationSeconds = 0;
    info.duration = "";
    info.lyrics = "";

    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif

        if (!fileRef.isNull() && fileRef.file() && fileRef.file()->isValid()) {
            if (const TagLib::Tag *tag = fileRef.tag()) {
                auto safeString = [](const TagLib::String &s) -> QString {
                    try {
                        if (s.isEmpty()) return QString();
                        return QString::fromUtf8(s.toCString(true)).trimmed();
                    } catch (...) {
                        return QString();
                    }
                };

                const QString tagTitle = safeString(tag->title());
                if (!tagTitle.isEmpty()) {
                    info.title = tagTitle;
                }

                const QString tagArtist = safeString(tag->artist());
                if (!tagArtist.isEmpty()) {
                    info.artist = tagArtist;
                }

                const QString tagAlbum = safeString(tag->album());
                if (!tagAlbum.isEmpty()) {
                    info.album = tagAlbum;
                }

                const QString tagGenre = safeString(tag->genre());
                if (!tagGenre.isEmpty()) {
                    info.genre = tagGenre;
                }
            }

            if (TagLib::PropertyMap properties = fileRef.file()->properties(); !properties.isEmpty()) {
                const auto getProp = [&](const char *key) -> QString {
                    if (properties.contains(key)) {
                        const auto &list = properties[key];
                        if (!list.isEmpty()) {
                            try {
                                return QString::fromStdWString(list.front().toWString()).trimmed();
                            } catch (...) {
                                return QString();
                            }
                        }
                    }
                    return QString();
                };

                QString recordLabel = getProp("LABEL");
                if (recordLabel.isEmpty()) recordLabel = getProp("ORGANIZATION");
                if (recordLabel.isEmpty()) recordLabel = getProp("PUBLISHER");
                if (recordLabel.isEmpty()) recordLabel = getProp("COPYRIGHT");
                info.label = recordLabel;
            }

            if (info.label.isEmpty() && fileInfo.suffix().toLower() == "mp3") {
                try {
                    if (auto *mpegFile = dynamic_cast<TagLib::MPEG::File *>(fileRef.file())) {
                        if (const TagLib::ID3v2::Tag *id3 = mpegFile->ID3v2Tag()) {
                            const TagLib::ID3v2::FrameList tpubList = id3->frameListMap()["TPUB"];
                            if (!tpubList.isEmpty()) {
                                info.label = QString::fromUtf8(tpubList.front()->toString().toCString(true)).trimmed();
                            }
                        }
                    }
                } catch (...) {}
            }

            if (const TagLib::AudioProperties *props = fileRef.audioProperties()) {
                info.durationSeconds = props->lengthInSeconds();
                info.duration = formatDuration(info.durationSeconds);
            }
        }

        info.lyrics = "";
    } catch (...) {
        qWarning() << "Error reading tags for:" << filePath;
    }

    return info;
}
