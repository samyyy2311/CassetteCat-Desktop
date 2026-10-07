#include "audio_metadata.h"
#include "image_cache.h"

#include <QBuffer>
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QStandardPaths>
#include <QTextStream>
#include <QUrl>
#include <QtEndian>
#include <cmath>

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
#include <ape/apeproperties.h>
#include <mpeg/mpegproperties.h>
#include <ogg/opus/opusproperties.h>
#include <ogg/vorbis/vorbisproperties.h>
#include <riff/aiff/aiffproperties.h>
#include <riff/wav/wavproperties.h>

QString formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) {
        return QString();
    }
    const int minutes = totalSeconds / 60;
    const int seconds = totalSeconds % 60;
    return QString("%1:%2").arg(minutes).arg(seconds, 2, 10, QChar('0'));
}

namespace {

// Includes the file's size and modification time so edited tags or replaced images get a fresh cover.
QString artworkCacheKey(const QString &filePath, int targetDim) {
    const QFileInfo info(filePath);
    return filePath + ':' + QString::number(info.size()) + ':' +
           QString::number(info.lastModified().toMSecsSinceEpoch()) + ':' + QString::number(targetDim);
}

// Extension-less path of the cached cover for \p key; the image is saved with ".png" or ".jpg".
QString artworkCacheBase(const QString &key) {
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/covers_v2/" +
           QString::fromLatin1(QCryptographicHash::hash(key.toUtf8(), QCryptographicHash::Sha1).toHex());
}

} // namespace

QString saveArtwork(const QString &filePath, const QByteArray &image, bool png, int maxDimension) {
    if (image.isEmpty())
        return {};
    const int targetDim = maxDimension > 0 ? maxDimension : 512;
    const QString key = artworkCacheKey(filePath, targetDim);
    const QString targetPath = artworkCacheBase(key) + (png ? ".png" : ".jpg");
    if (QFileInfo::exists(targetPath)) {
        return QUrl::fromLocalFile(targetPath).toString();
    }

    QByteArray outputImage = image;
    QBuffer input(&outputImage);
    if (!input.open(QIODevice::ReadOnly))
        return {};
    QImageReader reader(&input);
    const QSize sourceSize = reader.size();
    if (!sourceSize.isValid())
        return {};
    if (sourceSize.width() > targetDim || sourceSize.height() > targetDim) {
        reader.setScaledSize(sourceSize.scaled(targetDim, targetDim, Qt::KeepAspectRatio));
    }
    const QImage thumbnail = reader.read();
    if (thumbnail.isNull())
        return {};
    outputImage.clear();
    QBuffer output(&outputImage);
    if (!output.open(QIODevice::WriteOnly) || !thumbnail.save(&output, png ? "PNG" : "JPEG", png ? -1 : 88))
        return {};
    return saveCachedImage(outputImage, key, png, "covers_v2");
}

QString saveFolderArtwork(const QString &filePath, int maxDimension) {
    if (filePath.isEmpty() || !QFileInfo::exists(filePath))
        return {};
    const int targetDim = maxDimension > 0 ? maxDimension : 512;
    const QString key = artworkCacheKey(filePath, targetDim);
    const bool png = filePath.endsWith(".png", Qt::CaseInsensitive);
    const QString targetPath = artworkCacheBase(key) + (png ? ".png" : ".jpg");
    if (QFileInfo::exists(targetPath)) {
        return QUrl::fromLocalFile(targetPath).toString();
    }

    QImageReader reader(filePath);
    const QSize sourceSize = reader.size();
    if (!sourceSize.isValid())
        return {};
    if (sourceSize.width() > targetDim || sourceSize.height() > targetDim) {
        reader.setScaledSize(sourceSize.scaled(targetDim, targetDim, Qt::KeepAspectRatio));
    }
    const QImage thumbnail = reader.read();
    if (thumbnail.isNull())
        return {};
    QByteArray outputImage;
    QBuffer output(&outputImage);
    if (!output.open(QIODevice::WriteOnly) || !thumbnail.save(&output, png ? "PNG" : "JPEG", png ? -1 : 88))
        return {};
    return saveCachedImage(outputImage, key, png, "covers_v2");
}

QString extractEmbeddedArtwork(const QString &filePath, int maxDimension) {
    if (filePath.isEmpty())
        return {};
    const QString cachedBase = artworkCacheBase(artworkCacheKey(filePath, maxDimension > 0 ? maxDimension : 512));
    for (const char *extension : {".jpg", ".png"}) {
        if (QFileInfo::exists(cachedBase + extension))
            return QUrl::fromLocalFile(cachedBase + extension).toString();
    }
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
                    return saveArtwork(filePath, QByteArray(data.data(), data.size()),
                                       cover.format() == TagLib::MP4::CoverArt::PNG, maxDimension);
                }
            }
        } catch (...) {
        }
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
                    filePath, QByteArray(pic->data().data(), pic->data().size()),
                    QString::fromStdWString(pic->mimeType().toWString()).contains("png", Qt::CaseInsensitive),
                    maxDimension);
            }
        } catch (...) {
        }
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
                        return saveArtwork(filePath, QByteArray(picture->picture().data(), picture->picture().size()),
                                           QString::fromStdWString(picture->mimeType().toWString())
                                               .contains("png", Qt::CaseInsensitive),
                                           maxDimension);
                    }
                }
            }
        } catch (...) {
        }
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
    } catch (...) {
    }

    // Fallback: check track's directory for cover image files
    try {
        const QFileInfo fi(filePath);
        const QDir trackFolder = fi.absoluteDir();
        const QStringList covers = {"cover.jpg", "cover.jpeg", "cover.png", "folder.jpg", "folder.jpeg", "folder.png",
                                    "front.jpg", "front.jpeg", "front.png", "album.jpg",  "album.jpeg",  "album.png"};
        for (const QString &name : covers) {
            const QString candidate = trackFolder.filePath(name);
            if (QFileInfo::exists(candidate)) {
                return QUrl::fromLocalFile(candidate).toString();
            }
        }
    } catch (...) {
    }

    return {};
}

QString extractEmbeddedLyrics(const QString &filePath) {
    if (filePath.isEmpty())
        return {};

    const QFileInfo fileInfo(filePath);
    const QString dirPath = fileInfo.absolutePath();
    const QString baseName = fileInfo.completeBaseName();
    const QString lrcPath = dirPath + "/" + baseName + ".lrc";
    const QString txtPath = dirPath + "/" + baseName + ".txt";

    if (QFileInfo::exists(lrcPath)) {
        QFile lrcFile(lrcPath);
        if (lrcFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString content = QString::fromUtf8(lrcFile.readAll()).trimmed();
            if (!content.isEmpty())
                return content;
        }
    }
    if (QFileInfo::exists(txtPath)) {
        QFile txtFile(txtPath);
        if (txtFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString content = QString::fromUtf8(txtFile.readAll()).trimmed();
            if (!content.isEmpty())
                return content;
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
                            if (!lyrics.trimmed().isEmpty())
                                return lyrics.trimmed();
                        }
                    }
                }
            }
        } catch (...) {
        }
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
                        if (!text.isEmpty())
                            return text;
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
                        if (!text.trimmed().isEmpty())
                            return text.trimmed();
                    }
                }
            }
        } catch (...) {
        }
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
                        if (!text.trimmed().isEmpty())
                            return text.trimmed();
                    }
                }
                if (properties.contains("UNSYNCEDLYRICS")) {
                    const auto &list = properties["UNSYNCEDLYRICS"];
                    if (!list.isEmpty()) {
                        QString text;
                        for (const auto &s : list) {
                            text += QString::fromStdWString(s.toWString()) + "\n";
                        }
                        if (!text.trimmed().isEmpty())
                            return text.trimmed();
                    }
                }
            }
        }
    } catch (...) {
    }

    return {};
}

float extractReplayGain(const QString &filePath, bool albumMode) {
    if (filePath.isEmpty())
        return 0.0f;
    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif
        if (!fileRef.isNull() && fileRef.file() && fileRef.file()->isValid()) {
            const TagLib::PropertyMap properties = fileRef.file()->properties();
            auto parseGain = [&properties](const char *key, float &outDb) -> bool {
                if (!properties.contains(key) || properties[key].isEmpty()) {
                    return false;
                }
                QString val = QString::fromStdWString(properties[key].front().toWString());
                val.remove("dB", Qt::CaseInsensitive);
                bool ok = false;
                const float db = val.trimmed().toFloat(&ok);
                if (ok && std::isfinite(db)) {
                    outDb = db;
                    return true;
                }
                return false;
            };

            float db = 0.0f;
            const char *primaryKey = albumMode ? "REPLAYGAIN_ALBUM_GAIN" : "REPLAYGAIN_TRACK_GAIN";
            if (parseGain(primaryKey, db)) {
                return db;
            }
            if (albumMode && parseGain("REPLAYGAIN_TRACK_GAIN", db)) {
                return db;
            }
        }
    } catch (...) {
    }
    return 0.0f;
}

QVariantMap readAudioFormat(const QString &filePath) {
    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif
        const TagLib::AudioProperties *props = fileRef.isNull() ? nullptr : fileRef.audioProperties();
        if (!props)
            return {};

        QString codec = QFileInfo(filePath).suffix().toUpper();
        int bitDepth = 0;
        if (dynamic_cast<const TagLib::MPEG::Properties *>(props)) {
            codec = "MP3";
        } else if (auto *flac = dynamic_cast<const TagLib::FLAC::Properties *>(props)) {
            codec = "FLAC";
            bitDepth = flac->bitsPerSample();
        } else if (auto *mp4 = dynamic_cast<const TagLib::MP4::Properties *>(props)) {
            const bool alac = mp4->codec() == TagLib::MP4::Properties::ALAC;
            codec = alac ? "ALAC" : "AAC";
            if (alac)
                bitDepth = mp4->bitsPerSample();
        } else if (dynamic_cast<const TagLib::Ogg::Vorbis::Properties *>(props)) {
            codec = "Vorbis";
        } else if (dynamic_cast<const TagLib::Ogg::Opus::Properties *>(props)) {
            codec = "Opus";
        } else if (auto *wav = dynamic_cast<const TagLib::RIFF::WAV::Properties *>(props)) {
            codec = "WAV";
            bitDepth = wav->bitsPerSample();
        } else if (auto *aiff = dynamic_cast<const TagLib::RIFF::AIFF::Properties *>(props)) {
            codec = "AIFF";
            bitDepth = aiff->bitsPerSample();
        } else if (auto *ape = dynamic_cast<const TagLib::APE::Properties *>(props)) {
            codec = "APE";
            bitDepth = ape->bitsPerSample();
        }

        // Same rules and wording as the Android app's quality badge.
        const bool lossless = QStringList{"FLAC", "ALAC", "WAV", "AIFF", "APE"}.contains(codec);
        const int sampleRate = props->sampleRate();
        const int bitrateKbps = props->bitrate();
        const bool hiRes = lossless && (sampleRate > 48000 || bitDepth > 16);

        QStringList label;
        if (bitDepth > 0)
            label << QString("%1-bit").arg(bitDepth);
        if (sampleRate >= 1000)
            label << (sampleRate % 1000 == 0 ? QString("%1 kHz").arg(sampleRate / 1000)
                                             : QString("%1 kHz").arg(sampleRate / 1000.0, 0, 'f', 1));
        else if (sampleRate > 0)
            label << QString("%1 Hz").arg(sampleRate);
        if (bitrateKbps > 0 && !lossless)
            label << QString("%1 kbps").arg(bitrateKbps);
        label << codec;

        return {{"label", label.join(" · ")},
                {"badgeLabel", hiRes ? "Hi-Res Lossless" : (lossless ? "Lossless" : codec)},
                {"codecName", codec},
                {"sampleRateHz", sampleRate},
                {"bitDepth", bitDepth},
                {"bitrateKbps", bitrateKbps},
                {"isLossless", lossless},
                {"isHiRes", hiRes}};
    } catch (...) {
        return {};
    }
}

TrackInfo readTrackInfo(const QString &filePath) {
    const QFileInfo fileInfo(filePath);
    const QString fallbackTitle = fileInfo.completeBaseName();

    TrackInfo info;
    info.filePath = filePath;
    info.fileName = fileInfo.fileName();
    info.format = fileInfo.suffix().toUpper();
    info.fileSize = fileInfo.size();
    info.lastModified = fileInfo.lastModified().toMSecsSinceEpoch();
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
                        if (s.isEmpty())
                            return QString();
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
                info.comment = safeString(tag->comment());
                info.year = static_cast<int>(tag->year());
                info.trackNumber = static_cast<int>(tag->track());
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
                if (recordLabel.isEmpty())
                    recordLabel = getProp("ORGANIZATION");
                if (recordLabel.isEmpty())
                    recordLabel = getProp("PUBLISHER");
                if (recordLabel.isEmpty())
                    recordLabel = getProp("COPYRIGHT");
                info.label = recordLabel;
                info.discNumber = getProp("DISCNUMBER").section('/', 0, 0).toInt();
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
                } catch (...) {
                }
            }

            if (const TagLib::AudioProperties *props = fileRef.audioProperties()) {
                info.durationSeconds = props->lengthInSeconds();
                info.duration = formatDuration(info.durationSeconds);
            }
        }

        info.lyrics = extractEmbeddedLyrics(filePath);
    } catch (...) {
        qWarning() << "Error reading tags for:" << filePath;
    }

    return info;
}

bool writeTrackInfo(const QVariantMap &metadata, QString *error) {
    const QString filePath = metadata.value("filePath").toString();
    if (filePath.isEmpty() || !QFileInfo::exists(filePath)) {
        if (error)
            *error = "The audio file is unavailable.";
        return false;
    }

    try {
#ifdef _WIN32
        TagLib::FileRef fileRef(QDir::toNativeSeparators(filePath).toStdWString().c_str());
#else
        TagLib::FileRef fileRef(filePath.toUtf8().constData());
#endif
        if (fileRef.isNull() || !fileRef.file() || !fileRef.file()->isValid() || !fileRef.tag()) {
            if (error)
                *error = "This file format does not support editable metadata.";
            return false;
        }

        const auto toTagString = [](const QString &value) {
            return TagLib::String(value.toUtf8().constData(), TagLib::String::UTF8);
        };
        // Only the fields present are written, so a batch edit leaves every other tag as it was.
        auto *tag = fileRef.tag();
        const auto text = [&](const char *key) { return toTagString(metadata.value(key).toString()); };
        const auto number = [&](const char *key) {
            return static_cast<unsigned int>(qMax(0, metadata.value(key).toInt()));
        };
        // An empty number clears the tag; anything else must be a whole number rather than quietly becoming zero.
        for (const char *key : {"year", "trackNumber", "discNumber"}) {
            const QString value = metadata.value(key).toString().trimmed();
            bool valid = true;
            if (!value.isEmpty())
                value.toInt(&valid);
            if (!valid) {
                if (error)
                    *error = "Year, track and disc must be whole numbers.";
                return false;
            }
        }
        if (metadata.contains("title"))
            tag->setTitle(text("title"));
        if (metadata.contains("artist"))
            tag->setArtist(text("artist"));
        if (metadata.contains("album"))
            tag->setAlbum(text("album"));
        if (metadata.contains("genre"))
            tag->setGenre(text("genre"));
        if (metadata.contains("comment"))
            tag->setComment(text("comment"));
        if (metadata.contains("year"))
            tag->setYear(number("year"));
        if (metadata.contains("trackNumber"))
            tag->setTrack(number("trackNumber"));

        TagLib::PropertyMap properties = fileRef.file()->properties();
        const auto setProperty = [&](const char *key, const QString &value) {
            const TagLib::String propertyKey(key, TagLib::String::Latin1);
            if (value.trimmed().isEmpty())
                properties.erase(propertyKey);
            else
                properties.replace(propertyKey, TagLib::StringList(toTagString(value.trimmed())));
        };
        if (metadata.contains("label")) {
            const QString label = metadata.value("label").toString();
            setProperty("LABEL", label);
            // The label is also read from these when LABEL is missing, so clearing it clears them too.
            if (label.trimmed().isEmpty()) {
                setProperty("ORGANIZATION", {});
                setProperty("PUBLISHER", {});
            }
        }
        if (metadata.contains("discNumber")) {
            const int disc = metadata.value("discNumber").toInt();
            setProperty("DISCNUMBER", disc > 0 ? QString::number(disc) : QString());
        }
        if (metadata.contains("lyrics"))
            setProperty("LYRICS", metadata.value("lyrics").toString());
        fileRef.file()->setProperties(properties);

        if (!fileRef.file()->save()) {
            if (error)
                *error = "CassetteCat could not save this file.";
            return false;
        }
        return true;
    } catch (...) {
        if (error)
            *error = "CassetteCat could not update this file.";
        return false;
    }
}

QVariantList parseM3uPlaylist(const QString &playlistPath) {
    QFile file(playlistPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return {};
    }

    const QFileInfo playlistFileInfo(playlistPath);
    const QDir playlistDir = playlistFileInfo.dir();

    QVariantList tracks;
    int extDuration = 0;
    QString extTitle;
    QString extArtist;

    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.isEmpty()) {
            continue;
        }

        if (line.startsWith("#EXTINF:", Qt::CaseInsensitive)) {
            const QString directive = line.mid(8).trimmed();
            const int commaIdx = directive.indexOf(',');
            if (commaIdx != -1) {
                bool ok = false;
                const int dur = directive.left(commaIdx).trimmed().toInt(&ok);
                extDuration = ok ? qMax(0, dur) : 0;
                const QString infoPart = directive.mid(commaIdx + 1).trimmed();
                const int dashIdx = infoPart.indexOf(" - ");
                if (dashIdx != -1) {
                    extArtist = infoPart.left(dashIdx).trimmed();
                    extTitle = infoPart.mid(dashIdx + 3).trimmed();
                } else {
                    extArtist.clear();
                    extTitle = infoPart;
                }
            }
            continue;
        }

        if (line.startsWith('#')) {
            continue;
        }

        QString targetPath = line;
        if (targetPath.startsWith("file:///", Qt::CaseInsensitive) ||
            targetPath.startsWith("file://", Qt::CaseInsensitive)) {
            targetPath = QUrl(targetPath).toLocalFile();
        }

        if (targetPath.startsWith("http://", Qt::CaseInsensitive) ||
            targetPath.startsWith("https://", Qt::CaseInsensitive)) {
            QVariantMap track;
            track.insert("filePath", targetPath);
            track.insert("fileName", targetPath.section('/', -1));
            track.insert("title", extTitle.isEmpty() ? targetPath : extTitle);
            track.insert("artist", extArtist.isEmpty() ? QStringLiteral("Radio Stream") : extArtist);
            track.insert("album", QStringLiteral("Stream"));
            track.insert("format", QStringLiteral("STREAM"));
            track.insert("durationSeconds", extDuration);
            track.insert("duration", formatDuration(extDuration));
            tracks.append(track);

            extDuration = 0;
            extTitle.clear();
            extArtist.clear();
            continue;
        }

        targetPath.replace('\\', '/');
        QFileInfo candidate(targetPath);
        if (!candidate.isAbsolute()) {
            targetPath = playlistDir.filePath(targetPath);
            candidate.setFile(targetPath);
        }

        targetPath = QDir::cleanPath(targetPath);
        candidate.setFile(targetPath);

        if (candidate.exists() && candidate.isFile()) {
            TrackInfo info = readTrackInfo(targetPath);
            QVariantMap track = info.toMap();
            if (!extTitle.isEmpty() && (info.title.isEmpty() || info.title == candidate.completeBaseName())) {
                track["title"] = extTitle;
            }
            if (!extArtist.isEmpty() && (info.artist.trimmed().isEmpty() || info.artist == "Unknown Artist")) {
                track["artist"] = extArtist;
            }
            if (info.durationSeconds <= 0 && extDuration > 0) {
                track["durationSeconds"] = extDuration;
                track["duration"] = formatDuration(extDuration);
            }
            if (track.value("artworkUrl").toString().isEmpty()) {
                const QDir trackDir = candidate.dir();
                static const QStringList coverNames = {"cover.jpg",  "cover.jpeg", "cover.png", "folder.jpg",
                                                       "folder.png", "front.jpg",  "front.png"};
                for (const QString &coverName : coverNames) {
                    const QString coverPath = trackDir.filePath(coverName);
                    if (QFileInfo::exists(coverPath)) {
                        track["artworkUrl"] = QUrl::fromLocalFile(coverPath).toString();
                        break;
                    }
                }
            }
            tracks.append(track);
        }

        extDuration = 0;
        extTitle.clear();
        extArtist.clear();
    }

    return tracks;
}
