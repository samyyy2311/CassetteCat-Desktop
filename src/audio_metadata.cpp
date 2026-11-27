#include "audio_metadata.h"

#include <QCoreApplication>
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

// TagLib opens wide-character paths on Windows and UTF-8 paths elsewhere.
#ifdef _WIN32
std::wstring tagLibPath(const QString &filePath) {
    return QDir::toNativeSeparators(filePath).toStdWString();
}
#else
std::string tagLibPath(const QString &filePath) {
    return filePath.toStdString();
}
#endif

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

// Scales the image down to fit \p targetDim and caches it as the cover for \p key.
QString saveThumbnail(QImageReader &reader, const QString &key, bool png, int targetDim) {
    const QSize sourceSize = reader.size();
    if (!sourceSize.isValid())
        return {};
    if (sourceSize.width() > targetDim || sourceSize.height() > targetDim)
        reader.setScaledSize(sourceSize.scaled(targetDim, targetDim, Qt::KeepAspectRatio));
    const QImage thumbnail = reader.read();
    if (thumbnail.isNull())
        return {};
    QByteArray outputImage;
    QBuffer output(&outputImage);
    if (!output.open(QIODevice::WriteOnly) || !thumbnail.save(&output, png ? "PNG" : "JPEG", png ? -1 : 88))
        return {};
    return saveCachedImage(outputImage, key, png, "covers_v2");
}

QString saveArtwork(const QString &filePath, const QByteArray &image, bool png, int maxDimension) {
    if (image.isEmpty())
        return {};
    const int targetDim = maxDimension > 0 ? maxDimension : 512;
    const QString key = artworkCacheKey(filePath, targetDim);
    const QString targetPath = artworkCacheBase(key) + (png ? ".png" : ".jpg");
    if (QFileInfo::exists(targetPath)) {
        return QUrl::fromLocalFile(targetPath).toString();
    }

    QByteArray source = image;
    QBuffer input(&source);
    if (!input.open(QIODevice::ReadOnly))
        return {};
    QImageReader reader(&input);
    return saveThumbnail(reader, key, png, targetDim);
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
    return saveThumbnail(reader, key, png, targetDim);
}

namespace {
QString mp4Artwork(const QString &filePath, int maxDimension) {
    try {
        TagLib::MP4::File file(tagLibPath(filePath).c_str());
        const TagLib::MP4::Tag *tag = file.tag();
        if (!tag)
            return {};
        const TagLib::MP4::CoverArtList covers = tag->item("covr").toCoverArtList();
        if (covers.isEmpty())
            return {};
        const TagLib::MP4::CoverArt cover = covers.front();
        const TagLib::ByteVector data = cover.data();
        return saveArtwork(filePath, QByteArray(data.data(), data.size()), cover.format() == TagLib::MP4::CoverArt::PNG,
                           maxDimension);
    } catch (...) {
    }
    return {};
}

QString flacArtwork(const QString &filePath, int maxDimension) {
    try {
        TagLib::FLAC::File file(tagLibPath(filePath).c_str());
        const auto picList = file.pictureList();
        if (picList.isEmpty())
            return {};
        const auto *pic = picList.front();
        return saveArtwork(filePath, QByteArray(pic->data().data(), pic->data().size()),
                           QString::fromStdWString(pic->mimeType().toWString()).contains("png", Qt::CaseInsensitive),
                           maxDimension);
    } catch (...) {
    }
    return {};
}

QString mp3Artwork(const QString &filePath, int maxDimension) {
    try {
        TagLib::MPEG::File file(tagLibPath(filePath).c_str());
        const TagLib::ID3v2::Tag *tag = file.ID3v2Tag();
        if (!tag)
            return {};
        const TagLib::ID3v2::FrameList frames = tag->frameListMap()["APIC"];
        if (frames.isEmpty())
            return {};
        const auto *picture = dynamic_cast<TagLib::ID3v2::AttachedPictureFrame *>(frames.front());
        if (!picture || picture->picture().isEmpty())
            return {};
        return saveArtwork(
            filePath, QByteArray(picture->picture().data(), picture->picture().size()),
            QString::fromStdWString(picture->mimeType().toWString()).contains("png", Qt::CaseInsensitive),
            maxDimension);
    } catch (...) {
    }
    return {};
}

// The image in a FLAC picture block, which Ogg files carry base64-encoded in METADATA_BLOCK_PICTURE.
QByteArray pictureFromBlock(const QByteArray &block, bool &png) {
    if (block.size() <= 32)
        return {};
    const quint32 mimeLen = qFromBigEndian<quint32>(block.constData() + 4);
    if (mimeLen >= 128 || block.size() <= (int)(8 + mimeLen + 4))
        return {};
    png = block.mid(8, mimeLen).contains("png");
    int offset = 8 + mimeLen;
    const quint32 descLen = qFromBigEndian<quint32>(block.constData() + offset);
    offset += 4 + descLen + 16;
    if (offset + 4 > block.size())
        return {};
    const quint32 picLen = qFromBigEndian<quint32>(block.constData() + offset);
    offset += 4;
    if (offset + picLen > (quint32)block.size())
        return {};
    return block.mid(offset, picLen);
}

QString pictureBlockArtwork(const QString &filePath, int maxDimension) {
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        if (fileRef.isNull() || !fileRef.file() || !fileRef.file()->isValid())
            return {};
        TagLib::PropertyMap props = fileRef.file()->properties();
        if (!props.contains("METADATA_BLOCK_PICTURE") || props["METADATA_BLOCK_PICTURE"].isEmpty())
            return {};
        const QByteArray block = QByteArray::fromBase64(
            QString::fromStdWString(props["METADATA_BLOCK_PICTURE"].front().toWString()).toLatin1());
        bool png = false;
        const QByteArray picture = pictureFromBlock(block, png);
        if (!picture.isEmpty())
            return saveArtwork(filePath, picture, png, maxDimension);
    } catch (...) {
    }
    return {};
}

// A cover image saved beside the song, for files whose tags carry none.
QString folderArtwork(const QString &filePath) {
    const QDir trackFolder = QFileInfo(filePath).absoluteDir();
    const QStringList covers = {"cover.jpg", "cover.jpeg", "cover.png", "folder.jpg", "folder.jpeg", "folder.png",
                                "front.jpg", "front.jpeg", "front.png", "album.jpg",  "album.jpeg",  "album.png"};
    for (const QString &name : covers) {
        const QString candidate = trackFolder.filePath(name);
        if (QFileInfo::exists(candidate))
            return QUrl::fromLocalFile(candidate).toString();
    }
    return {};
}
} // namespace

QString extractEmbeddedArtwork(const QString &filePath, int maxDimension) {
    if (filePath.isEmpty())
        return {};
    const QString cachedBase = artworkCacheBase(artworkCacheKey(filePath, maxDimension > 0 ? maxDimension : 512));
    for (const char *extension : {".jpg", ".png"}) {
        if (QFileInfo::exists(cachedBase + extension))
            return QUrl::fromLocalFile(cachedBase + extension).toString();
    }
    const QString suffix = QFileInfo(filePath).suffix().toLower();
    if (suffix == "m4a" || suffix == "mp4" || suffix == "alac")
        return mp4Artwork(filePath, maxDimension);
    if (suffix == "flac")
        return flacArtwork(filePath, maxDimension);
    if (suffix == "mp3")
        return mp3Artwork(filePath, maxDimension);
    const QString tagged = pictureBlockArtwork(filePath, maxDimension);
    return tagged.isEmpty() ? folderArtwork(filePath) : tagged;
}

namespace {
QString joinedLines(const TagLib::StringList &lines) {
    QString text;
    for (const auto &line : lines)
        text += QString::fromStdWString(line.toWString()) + "\n";
    return text.trimmed();
}

// A .lrc or .txt file beside the song comes before lyrics in its tags.
QString sidecarLyrics(const QFileInfo &song) {
    for (const char *extension : {".lrc", ".txt"}) {
        QFile file(song.absolutePath() + "/" + song.completeBaseName() + extension);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
            continue;
        const QString content = QString::fromUtf8(file.readAll()).trimmed();
        if (!content.isEmpty())
            return content;
    }
    return {};
}

QString mp4Lyrics(const QString &filePath) {
    try {
        TagLib::MP4::File file(tagLibPath(filePath).c_str());
        const TagLib::MP4::Tag *tag = file.tag();
        if (!tag)
            return {};
        const auto &itemMap = tag->itemMap();
        for (auto it = itemMap.begin(); it != itemMap.end(); ++it) {
            if (!QString::fromStdWString(it->first.toWString()).toLower().contains("lyr"))
                continue;
            const QString lyrics = joinedLines(it->second.toStringList());
            if (!lyrics.isEmpty())
                return lyrics;
        }
    } catch (...) {
    }
    return {};
}

QString mp3Lyrics(const QString &filePath) {
    try {
        TagLib::MPEG::File file(tagLibPath(filePath).c_str());
        const TagLib::ID3v2::Tag *tag = file.ID3v2Tag();
        if (!tag)
            return {};
        for (auto *frame : tag->frameListMap()["USLT"]) {
            const auto *uslt = dynamic_cast<TagLib::ID3v2::UnsynchronizedLyricsFrame *>(frame);
            const QString text = uslt ? QString::fromStdWString(uslt->text().toWString()).trimmed() : QString();
            if (!text.isEmpty())
                return text;
        }
        for (auto *frame : tag->frameListMap()["SYLT"]) {
            const auto *sylt = dynamic_cast<TagLib::ID3v2::SynchronizedLyricsFrame *>(frame);
            if (!sylt)
                continue;
            TagLib::StringList lines;
            for (const auto &item : sylt->synchedText())
                lines.append(item.text);
            const QString text = joinedLines(lines);
            if (!text.isEmpty())
                return text;
        }
    } catch (...) {
    }
    return {};
}

QString propertyLyrics(const QString &filePath) {
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        if (fileRef.isNull() || !fileRef.file() || !fileRef.file()->isValid())
            return {};
        TagLib::PropertyMap properties = fileRef.file()->properties();
        for (const char *key : {"LYRICS", "UNSYNCEDLYRICS"}) {
            const QString text = properties.contains(key) ? joinedLines(properties[key]) : QString();
            if (!text.isEmpty())
                return text;
        }
    } catch (...) {
    }
    return {};
}
} // namespace

QString extractEmbeddedLyrics(const QString &filePath) {
    if (filePath.isEmpty())
        return {};
    const QFileInfo fileInfo(filePath);
    const QString sidecar = sidecarLyrics(fileInfo);
    if (!sidecar.isEmpty())
        return sidecar;
    const QString suffix = fileInfo.suffix().toLower();
    QString lyrics;
    if (suffix == "m4a" || suffix == "mp4" || suffix == "alac")
        lyrics = mp4Lyrics(filePath);
    else if (suffix == "mp3")
        lyrics = mp3Lyrics(filePath);
    return lyrics.isEmpty() ? propertyLyrics(filePath) : lyrics;
}

float extractReplayGain(const QString &filePath, bool albumMode) {
    if (filePath.isEmpty())
        return 0.0f;
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
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

namespace {
struct Codec {
    QString name;
    int bitDepth = 0;
    // WAV and AIFF-C can also carry compressed audio such as ADPCM or MP3.
    bool uncompressed = true;
};

bool isUncompressedAiff(const TagLib::RIFF::AIFF::Properties *aiff) {
    const QByteArray compression(aiff->compressionType().data(), aiff->compressionType().size());
    return !aiff->isAiffC() ||
           QList<QByteArray>{"NONE", "sowt", "twos", "in24", "in32", "fl32", "fl64", "FL32", "FL64"}.contains(
               compression);
}

Codec codecOf(const TagLib::AudioProperties *props, const QString &suffix) {
    if (dynamic_cast<const TagLib::MPEG::Properties *>(props))
        return {"MP3"};
    if (auto *flac = dynamic_cast<const TagLib::FLAC::Properties *>(props))
        return {"FLAC", flac->bitsPerSample()};
    if (auto *mp4 = dynamic_cast<const TagLib::MP4::Properties *>(props)) {
        if (mp4->codec() == TagLib::MP4::Properties::ALAC)
            return {"ALAC", mp4->bitsPerSample()};
        return {"AAC"};
    }
    if (dynamic_cast<const TagLib::Ogg::Vorbis::Properties *>(props))
        return {"Vorbis"};
    if (dynamic_cast<const TagLib::Ogg::Opus::Properties *>(props))
        return {"Opus"};
    // PCM, IEEE float, and the extensible header that wraps them.
    if (auto *wav = dynamic_cast<const TagLib::RIFF::WAV::Properties *>(props))
        return {"WAV", wav->bitsPerSample(), wav->format() == 1 || wav->format() == 3 || wav->format() == 0xFFFE};
    if (auto *aiff = dynamic_cast<const TagLib::RIFF::AIFF::Properties *>(props))
        return {"AIFF", aiff->bitsPerSample(), isUncompressedAiff(aiff)};
    if (auto *ape = dynamic_cast<const TagLib::APE::Properties *>(props))
        return {"APE", ape->bitsPerSample()};
    return {suffix.toUpper()};
}

QString formatLabel(const Codec &codec, int sampleRate, int bitrateKbps, bool lossless) {
    QStringList label;
    if (codec.bitDepth > 0)
        label << QString("%1-bit").arg(codec.bitDepth);
    if (sampleRate >= 1000)
        label << (sampleRate % 1000 == 0 ? QString("%1 kHz").arg(sampleRate / 1000)
                                         : QString("%1 kHz").arg(sampleRate / 1000.0, 0, 'f', 1));
    else if (sampleRate > 0)
        label << QString("%1 Hz").arg(sampleRate);
    if (bitrateKbps > 0 && !lossless)
        label << QString("%1 kbps").arg(bitrateKbps);
    label << codec.name;
    return label.join(" · ");
}
} // namespace

QVariantMap readAudioFormat(const QString &filePath) {
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        const TagLib::AudioProperties *props = fileRef.isNull() ? nullptr : fileRef.audioProperties();
        if (!props)
            return {};
        const Codec codec = codecOf(props, QFileInfo(filePath).suffix());

        // Same rules and wording as the Android app's quality badge.
        const bool lossless =
            codec.uncompressed && QStringList{"FLAC", "ALAC", "WAV", "AIFF", "APE"}.contains(codec.name);
        const int sampleRate = props->sampleRate();
        const int bitrateKbps = props->bitrate();
        const bool hiRes = lossless && (sampleRate > 48000 || codec.bitDepth > 16);
        const QString badge = hiRes ? "Hi-Res Lossless" : (lossless ? "Lossless" : codec.name);
        return {{"label", formatLabel(codec, sampleRate, bitrateKbps, lossless)},
                {"badgeLabel", badge},
                {"codecName", codec.name},
                {"sampleRateHz", sampleRate},
                {"bitDepth", codec.bitDepth},
                {"bitrateKbps", bitrateKbps},
                {"isLossless", lossless},
                {"isHiRes", hiRes}};
    } catch (...) {
        return {};
    }
}

namespace {
QString tagText(const TagLib::String &value) {
    try {
        return value.isEmpty() ? QString() : QString::fromUtf8(value.toCString(true)).trimmed();
    } catch (...) {
        return {};
    }
}

void readBasicTags(const TagLib::Tag *tag, TrackInfo &info) {
    // A blank tag keeps the file-name title and the Unknown names already in place.
    const auto keepIfSet = [](QString &field, const QString &value) {
        if (!value.isEmpty())
            field = value;
    };
    keepIfSet(info.title, tagText(tag->title()));
    keepIfSet(info.artist, tagText(tag->artist()));
    keepIfSet(info.album, tagText(tag->album()));
    keepIfSet(info.genre, tagText(tag->genre()));
    info.comment = tagText(tag->comment());
    info.year = static_cast<int>(tag->year());
    info.trackNumber = static_cast<int>(tag->track());
}

QString firstProperty(TagLib::PropertyMap &properties, const char *key) {
    if (!properties.contains(key) || properties[key].isEmpty())
        return {};
    try {
        return QString::fromStdWString(properties[key].front().toWString()).trimmed();
    } catch (...) {
        return {};
    }
}

// Tag formats name the record label differently.
QString recordLabel(TagLib::PropertyMap &properties) {
    for (const char *key : {"LABEL", "ORGANIZATION", "PUBLISHER", "COPYRIGHT"}) {
        const QString label = firstProperty(properties, key);
        if (!label.isEmpty())
            return label;
    }
    return {};
}

QString id3Publisher(TagLib::File *file) {
    try {
        auto *mpegFile = dynamic_cast<TagLib::MPEG::File *>(file);
        const TagLib::ID3v2::Tag *id3 = mpegFile ? mpegFile->ID3v2Tag() : nullptr;
        if (!id3)
            return {};
        const TagLib::ID3v2::FrameList publishers = id3->frameListMap()["TPUB"];
        if (!publishers.isEmpty())
            return QString::fromUtf8(publishers.front()->toString().toCString(true)).trimmed();
    } catch (...) {
    }
    return {};
}

void readFileTags(TagLib::FileRef &fileRef, const QString &suffix, TrackInfo &info) {
    if (const TagLib::Tag *tag = fileRef.tag())
        readBasicTags(tag, info);
    if (TagLib::PropertyMap properties = fileRef.file()->properties(); !properties.isEmpty()) {
        info.label = recordLabel(properties);
        info.discNumber = firstProperty(properties, "DISCNUMBER").section('/', 0, 0).toInt();
    }
    if (info.label.isEmpty() && suffix.toLower() == "mp3")
        info.label = id3Publisher(fileRef.file());
    if (const TagLib::AudioProperties *props = fileRef.audioProperties()) {
        info.durationSeconds = props->lengthInSeconds();
        info.duration = formatDuration(info.durationSeconds);
    }
}
} // namespace

TrackInfo readTrackInfo(const QString &filePath) {
    const QFileInfo fileInfo(filePath);
    TrackInfo info;
    info.filePath = filePath;
    info.fileName = fileInfo.fileName();
    info.format = fileInfo.suffix().toUpper();
    info.fileSize = fileInfo.size();
    info.lastModified = fileInfo.lastModified().toMSecsSinceEpoch();
    info.title = fileInfo.completeBaseName();
    info.artist = "Unknown Artist";
    info.album = "Unknown Album";
    info.durationSeconds = 0;
    info.duration = "";
    info.lyrics = "";

    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        if (!fileRef.isNull() && fileRef.file() && fileRef.file()->isValid())
            readFileTags(fileRef, fileInfo.suffix(), info);
        info.lyrics = extractEmbeddedLyrics(filePath);
    } catch (...) {
        qWarning() << "Error reading tags for:" << filePath;
    }
    return info;
}

bool hasEmbeddedArtwork(const QString &filePath) {
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        return !fileRef.isNull() && !fileRef.complexProperties("PICTURE").isEmpty();
    } catch (...) {
        return false;
    }
}

bool writeEmbeddedArtwork(const QString &filePath, const QByteArray &image, QString *error) {
    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        if (fileRef.isNull() || !fileRef.file() || !fileRef.file()->isValid()) {
            if (error)
                *error = QCoreApplication::translate("AudioMetadata", "This file format does not support cover art.");
            return false;
        }
        TagLib::VariantMap picture;
        picture["data"] = TagLib::ByteVector(image.constData(), static_cast<unsigned int>(image.size()));
        picture["mimeType"] = TagLib::String(image.startsWith("\x89PNG") ? "image/png" : "image/jpeg");
        picture["pictureType"] = TagLib::String("Front Cover");
        picture["description"] = TagLib::String("");
        if (!fileRef.setComplexProperties("PICTURE", {picture}) || !fileRef.save()) {
            if (error)
                *error = QCoreApplication::translate("AudioMetadata",
                                                     "CassetteCat could not save the cover into this file.");
            return false;
        }
        return true;
    } catch (...) {
        if (error)
            *error = QCoreApplication::translate("AudioMetadata", "CassetteCat could not update this file.");
        return false;
    }
}

namespace {
TagLib::String tagString(const QString &value) {
    return TagLib::String(value.toUtf8().constData(), TagLib::String::UTF8);
}

// An empty number clears the tag; anything else must be a whole number rather than quietly becoming zero.
bool hasWholeNumbers(const QVariantMap &metadata) {
    for (const char *key : {"year", "trackNumber", "discNumber"}) {
        const QString value = metadata.value(key).toString().trimmed();
        bool valid = true;
        if (!value.isEmpty())
            value.toInt(&valid);
        if (!valid)
            return false;
    }
    return true;
}

// Only the fields present are written, so a batch edit leaves every other tag as it was.
void writeBasicTags(TagLib::Tag *tag, const QVariantMap &metadata) {
    const auto text = [&](const char *key) { return tagString(metadata.value(key).toString()); };
    const auto number = [&](const char *key) {
        return static_cast<unsigned int>(qMax(0, metadata.value(key).toInt()));
    };
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
}

void writeExtraProperties(TagLib::PropertyMap &properties, const QVariantMap &metadata) {
    const auto setProperty = [&](const char *key, const QString &value) {
        const TagLib::String propertyKey(key, TagLib::String::Latin1);
        if (value.trimmed().isEmpty())
            properties.erase(propertyKey);
        else
            properties.replace(propertyKey, TagLib::StringList(tagString(value.trimmed())));
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
}
} // namespace

bool writeTrackInfo(const QVariantMap &metadata, QString *error) {
    const auto fail = [error](const char *message) {
        if (error)
            *error = QCoreApplication::translate("AudioMetadata", message);
        return false;
    };
    const QString filePath = metadata.value("filePath").toString();
    if (filePath.isEmpty() || !QFileInfo::exists(filePath))
        return fail(QT_TRANSLATE_NOOP("AudioMetadata", "The audio file is unavailable."));

    try {
        TagLib::FileRef fileRef(tagLibPath(filePath).c_str());
        if (fileRef.isNull() || !fileRef.file() || !fileRef.file()->isValid() || !fileRef.tag())
            return fail(QT_TRANSLATE_NOOP("AudioMetadata", "This file format does not support editable metadata."));
        if (!hasWholeNumbers(metadata))
            return fail(QT_TRANSLATE_NOOP("AudioMetadata", "Year, track and disc must be whole numbers."));
        writeBasicTags(fileRef.tag(), metadata);
        TagLib::PropertyMap properties = fileRef.file()->properties();
        writeExtraProperties(properties, metadata);
        fileRef.file()->setProperties(properties);
        if (!fileRef.file()->save())
            return fail(QT_TRANSLATE_NOOP("AudioMetadata", "CassetteCat could not save this file."));
        return true;
    } catch (...) {
        return fail(QT_TRANSLATE_NOOP("AudioMetadata", "CassetteCat could not update this file."));
    }
}

namespace {
// What an #EXTINF line says about the entry after it.
struct ExtInf {
    int durationSeconds = 0;
    QString title;
    QString artist;
};

void readExtInf(const QString &line, ExtInf &ext) {
    const QString directive = line.mid(8).trimmed();
    const int comma = directive.indexOf(',');
    if (comma == -1)
        return;
    bool ok = false;
    const int duration = directive.left(comma).trimmed().toInt(&ok);
    ext.durationSeconds = ok ? qMax(0, duration) : 0;
    const QString description = directive.mid(comma + 1).trimmed();
    const int dash = description.indexOf(" - ");
    ext.artist = dash == -1 ? QString() : description.left(dash).trimmed();
    ext.title = dash == -1 ? description : description.mid(dash + 3).trimmed();
}

QVariantMap streamEntry(const QString &url, const ExtInf &ext) {
    return {{"filePath", url},
            {"fileName", url.section('/', -1)},
            {"title", ext.title.isEmpty() ? url : ext.title},
            {"artist", ext.artist.isEmpty() ? QStringLiteral("Radio Stream") : ext.artist},
            {"album", QStringLiteral("Stream")},
            {"format", QStringLiteral("STREAM")},
            {"durationSeconds", ext.durationSeconds},
            {"duration", formatDuration(ext.durationSeconds)}};
}

// The playlist's own title, artist and length fill in what the file's tags leave out.
QVariantMap fileEntry(const QString &path, const ExtInf &ext) {
    const TrackInfo info = readTrackInfo(path);
    QVariantMap track = info.toMap();
    if (!ext.title.isEmpty() && (info.title.isEmpty() || info.title == QFileInfo(path).completeBaseName()))
        track["title"] = ext.title;
    if (!ext.artist.isEmpty() && (info.artist.trimmed().isEmpty() || info.artist == "Unknown Artist"))
        track["artist"] = ext.artist;
    if (info.durationSeconds <= 0 && ext.durationSeconds > 0) {
        track["durationSeconds"] = ext.durationSeconds;
        track["duration"] = formatDuration(ext.durationSeconds);
    }
    const QString folderCover = track.value("artworkUrl").toString().isEmpty() ? folderArtwork(path) : QString();
    if (!folderCover.isEmpty())
        track["artworkUrl"] = folderCover;
    return track;
}

// Entries may use either slash, and relative ones start from the playlist's folder.
QString playlistEntryPath(QString path, const QDir &playlistDir) {
    path.replace('\\', '/');
    if (!QFileInfo(path).isAbsolute())
        path = playlistDir.filePath(path);
    return QDir::cleanPath(path);
}
} // namespace

QVariantList parseM3uPlaylist(const QString &playlistPath) {
    QFile file(playlistPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    const QDir playlistDir = QFileInfo(playlistPath).dir();

    QVariantList tracks;
    ExtInf ext;
    QTextStream stream(&file);
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (line.startsWith("#EXTINF:", Qt::CaseInsensitive)) {
            readExtInf(line, ext);
            continue;
        }
        if (line.isEmpty() || line.startsWith('#'))
            continue;

        const QString target = line.startsWith("file://", Qt::CaseInsensitive) ? QUrl(line).toLocalFile() : line;
        if (target.startsWith("http://", Qt::CaseInsensitive) || target.startsWith("https://", Qt::CaseInsensitive)) {
            tracks.append(streamEntry(target, ext));
        } else {
            const QString path = playlistEntryPath(target, playlistDir);
            if (QFileInfo(path).isFile())
                tracks.append(fileEntry(path, ext));
        }
        ext = {};
    }
    return tracks;
}
