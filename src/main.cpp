#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDesktopServices>
#include <QAudioOutput>
#include <QAudioBuffer>
#include <QAudioBufferOutput>
#include <QAudioFormat>
#include <QCoreApplication>
#include <QCryptographicHash>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QFutureWatcher>
#include <QGuiApplication>
#include <QIcon>
#include <QHash>
#include <QMediaPlayer>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSettings>
#include <QSaveFile>
#include <QSet>
#include <QStringList>
#include <QStandardPaths>
#include <QTemporaryDir>
#include <QTimer>
#include <QUrl>
#include <QVariantList>
#include <QVariantMap>

#include <QtConcurrentRun>

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

#include <QQuickWindow>
#include <QQuickStyle>
#ifdef _WIN32
#include <windows.h>
#endif

#include <algorithm>
#include <cmath>
#include <cstring>
#include <QFont>
#include <QFontDatabase>

#include <flac/flacfile.h>
#include <flac/flacpicture.h>
#include <QtEndian>
#include <iostream>

namespace {

struct TrackInfo {
    QString title;
    QString artist;
    QString album;
    QString genre = "Soundtrack";
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

QString formatDuration(int totalSeconds)
{
    if (totalSeconds <= 0) {
        return QString();
    }
    const int minutes = totalSeconds / 60;
    const int seconds = totalSeconds % 60;
    return QString("%1:%2").arg(minutes).arg(seconds, 2, 10, QChar('0'));
}

QString settingsFilePath()
{
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    QDir().mkpath(configDir);
    return QDir(configDir).filePath("settings.ini");
}

void writeDebugLog(QtMsgType, const QMessageLogContext &, const QString &message)
{
    static QMutex logMutex;
    QMutexLocker locker(&logMutex);
    std::cerr << message.toStdString() << std::endl;
    QFile logFile("debug.log");
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append | QIODevice::Text)) {
        QTextStream(&logFile) << message << '\n';
    }
}

QString saveArtwork(const QString &filePath, const QByteArray &image, bool png)
{
    if (image.isEmpty()) return {};
    const QByteArray suffix = png ? ".png" : ".jpg";
    const QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/covers";
    QDir().mkpath(cacheDir);
    const QString imagePath = cacheDir + "/" + QCryptographicHash::hash(filePath.toUtf8(), QCryptographicHash::Sha1).toHex() + suffix;

    if (!QFileInfo::exists(imagePath)) {
        QSaveFile output(imagePath);
        if (!output.open(QIODevice::WriteOnly) || output.write(image) != image.size() || !output.commit()) {
            return {};
        }
    }
    return QUrl::fromLocalFile(imagePath).toString();
}

QString extractEmbeddedArtwork(const QString &filePath)
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
                    return saveArtwork(filePath, QByteArray(data.data(), data.size()), cover.format() == TagLib::MP4::CoverArt::PNG);
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
                        QString::fromStdWString(pic->mimeType().toWString()).contains("png", Qt::CaseInsensitive)
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
                            QString::fromStdWString(picture->mimeType().toWString()).contains("png", Qt::CaseInsensitive)
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
                                    return saveArtwork(filePath, picBytes, mime.contains("png"));
                                }
                            }
                        }
                    }
                }
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

class LibraryController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString folder READ folder NOTIFY changed)
    Q_PROPERTY(QVariantList tracks READ tracks NOTIFY changed)

public:
    explicit LibraryController(QObject *parent = nullptr)
        : QObject(parent)
        , m_scanWatcher(this)
    {
        connect(&m_scanWatcher, &QFutureWatcher<QVariantList>::finished, this, [this] {
            m_tracks = m_scanWatcher.result();
            emit changed();
        });

        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        const QString savedFolder = settings.value("library/folder").toString();
        if (!savedFolder.isEmpty() && QDir(savedFolder).exists()) {
            QTimer::singleShot(100, this, [this, savedFolder] {
                setFolderPath(savedFolder);
            });
        }
    }

    QString folder() const { return m_folder; }
    QVariantList tracks() const { return m_tracks; }

    Q_INVOKABLE void loadFolder(const QUrl &url)
    {
        const QString path = url.toLocalFile();

        if (path.isEmpty()) {
            return;
        }

        setFolderPath(path);

        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        settings.setValue("library/folder", path);
    }

    Q_INVOKABLE QString artworkFor(const QString &filePath)
    {
        const auto cached = m_artworkUrls.constFind(filePath);
        if (cached != m_artworkUrls.cend()) {
            return *cached;
        }

        // ponytail: visible artwork is read on the UI thread; move extraction to a worker if initial card rendering stutters.
        const QString artworkUrl = extractEmbeddedArtwork(filePath);
        m_artworkUrls.insert(filePath, artworkUrl);
        return artworkUrl;
    }

signals:
    void changed();

private:
    void setFolderPath(const QString &path)
    {
        m_folder = path;
        m_tracks.clear();
        m_artworkUrls.clear();
        emit changed();
        m_scanWatcher.setFuture(QtConcurrent::run([path] {
            return scanTracks(path);
        }));
    }

    QString m_folder;
    QVariantList m_tracks;
    QHash<QString, QString> m_artworkUrls;
    QFutureWatcher<QVariantList> m_scanWatcher;
};

class PlayerController final : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantMap currentTrack READ currentTrack NOTIFY currentTrackChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(QString formattedPosition READ formattedPosition NOTIFY positionChanged)
    Q_PROPERTY(QString formattedDuration READ formattedDuration NOTIFY durationChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(bool shuffleEnabled READ shuffleEnabled WRITE setShuffleEnabled NOTIFY shuffleEnabledChanged)
    Q_PROPERTY(qreal audioLevel READ audioLevel NOTIFY audioLevelChanged)

    Q_PROPERTY(QString currentLyrics READ currentLyrics NOTIFY currentLyricsChanged)

public:
    explicit PlayerController(QObject *parent = nullptr)
        : QObject(parent)
        , m_audioOutput(new QAudioOutput(this))
        , m_bufferOutput(new QAudioBufferOutput(this))
        , m_player(new QMediaPlayer(this))
    {
        m_player->setAudioOutput(m_audioOutput);
        m_player->setAudioBufferOutput(m_bufferOutput);
        m_audioOutput->setVolume(1.0f);

        connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
            const bool playing = (state == QMediaPlayer::PlayingState);
            if (m_isPlaying != playing) {
                m_isPlaying = playing;
                emit isPlayingChanged();
            }
            if (!playing) setAudioLevel(0.0);
        });

        connect(m_bufferOutput, &QAudioBufferOutput::audioBufferReceived, this, [this](const QAudioBuffer &buffer) {
            const int sampleCount = buffer.sampleCount();
            if (sampleCount <= 0) return;

            double sum = 0.0;
            if (buffer.format().sampleFormat() == QAudioFormat::Float) {
                const auto *samples = buffer.constData<float>();
                for (int i = 0; i < sampleCount; ++i) sum += samples[i] * samples[i];
            } else if (buffer.format().sampleFormat() == QAudioFormat::Int16) {
                const auto *samples = buffer.constData<qint16>();
                for (int i = 0; i < sampleCount; ++i) {
                    const double sample = samples[i] / 32768.0;
                    sum += sample * sample;
                }
            } else {
                return;
            }
            setAudioLevel(std::clamp(std::sqrt(sum / sampleCount) * 3.0, 0.0, 1.0));
        });

        connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
            if (status == QMediaPlayer::EndOfMedia) {
                emit trackEnded();
            }
        });

        connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64 pos) {
            m_position = pos;
            emit positionChanged();
        });

        connect(m_player, &QMediaPlayer::durationChanged, this, [this](qint64 dur) {
            m_duration = dur;
            emit durationChanged();
        });
    }

    QVariantMap currentTrack() const { return m_currentTrack; }
    QString currentLyrics() const { return m_currentLyrics; }
    bool isPlaying() const { return m_isPlaying; }
    bool shuffleEnabled() const { return m_shuffleEnabled; }
    qreal audioLevel() const { return m_audioLevel; }
    qint64 position() const { return m_position; }
    qint64 duration() const { return m_duration; }
    QString formattedPosition() const { return formatDuration(static_cast<int>(m_position / 1000)); }
    QString formattedDuration() const { return formatDuration(static_cast<int>(m_duration / 1000)); }
    float volume() const { return m_audioOutput ? m_audioOutput->volume() : 1.0f; }

    Q_INVOKABLE QString getLyrics(const QString &filePath) const
    {
        return extractEmbeddedLyrics(filePath);
    }

    Q_INVOKABLE void setCurrentLyrics(const QString &lyrics)
    {
        if (m_currentLyrics == lyrics) return;
        m_currentLyrics = lyrics;
        emit currentLyricsChanged();
    }

    Q_INVOKABLE void setShuffleEnabled(bool enabled)
    {
        if (m_shuffleEnabled != enabled) {
            m_shuffleEnabled = enabled;
            emit shuffleEnabledChanged();
        }
    }

    Q_INVOKABLE void toggleShuffle()
    {
        setShuffleEnabled(!m_shuffleEnabled);
    }

    Q_INVOKABLE void setVolume(float vol)
    {
        if (m_audioOutput) {
            const float clamped = std::clamp(vol, 0.0f, 1.0f);
            if (m_audioOutput->volume() != clamped) {
                m_audioOutput->setVolume(clamped);
                emit volumeChanged();
            }
        }
    }

    Q_INVOKABLE void restoreTrack(const QVariantMap &track, qint64 positionMs = 0)
    {
        const QString filePath = track.value("filePath").toString();
        if (filePath.isEmpty()) {
            return;
        }

        m_currentTrack = track;
        if (m_currentTrack.value("artworkUrl").toString().isEmpty()) {
            m_currentTrack.insert("artworkUrl", extractEmbeddedArtwork(filePath));
        }
        m_currentLyrics = track.value("lyrics").toString();
        if (m_currentLyrics.isEmpty()) {
            m_currentLyrics = extractEmbeddedLyrics(filePath);
        }
        emit currentTrackChanged();
        emit currentLyricsChanged();

        m_position = 0;
        emit positionChanged();
        m_player->setSource(QUrl::fromLocalFile(filePath));
        m_player->pause();
        if (positionMs > 0) {
            m_player->setPosition(positionMs);
            m_position = positionMs;
            emit positionChanged();
        }
    }

    Q_INVOKABLE void playTrack(const QVariantMap &track)
    {
        const QString filePath = track.value("filePath").toString();
        if (filePath.isEmpty()) {
            return;
        }

        m_currentTrack = track;
        if (m_currentTrack.value("artworkUrl").toString().isEmpty()) {
            // ponytail: load embedded artwork only for the current track; add async thumbnailing if browsing embedded art needs it.
            m_currentTrack.insert("artworkUrl", extractEmbeddedArtwork(filePath));
        }
        m_currentLyrics = track.value("lyrics").toString();
        if (m_currentLyrics.isEmpty()) {
            m_currentLyrics = extractEmbeddedLyrics(filePath);
        }
        emit currentTrackChanged();
        emit currentLyricsChanged();

        m_position = 0;
        emit positionChanged();
        m_player->setSource(QUrl::fromLocalFile(filePath));
        m_player->play();
    }

    Q_INVOKABLE void togglePlay()
    {
        if (m_player->playbackState() == QMediaPlayer::PlayingState) {
            m_player->pause();
        } else if (m_player->playbackState() == QMediaPlayer::PausedState) {
            m_player->play();
        } else if (!m_currentTrack.isEmpty()) {
            playTrack(m_currentTrack);
        }
    }

    Q_INVOKABLE void pause()
    {
        m_player->pause();
    }

    Q_INVOKABLE void seek(qint64 positionMs)
    {
        m_player->setPosition(positionMs);
    }

    Q_INVOKABLE void setWindowAlwaysOnTop(QQuickWindow *win, bool onTop)
    {
#ifdef _WIN32
        if (win) {
            HWND hwnd = reinterpret_cast<HWND>(win->winId());
            if (hwnd) {
                SetWindowPos(hwnd, onTop ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
            }
        }
#else
        Q_UNUSED(win);
        Q_UNUSED(onTop);
#endif
    }

signals:
    void currentTrackChanged();
    void currentLyricsChanged();
    void isPlayingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void shuffleEnabledChanged();
    void audioLevelChanged();
    void trackEnded();

private:
    void setAudioLevel(qreal level)
    {
        if (qAbs(m_audioLevel - level) < 0.01) return;
        m_audioLevel = level;
        emit audioLevelChanged();
    }

    QAudioOutput *m_audioOutput = nullptr;
    QAudioBufferOutput *m_bufferOutput = nullptr;
    QMediaPlayer *m_player = nullptr;
    QVariantMap m_currentTrack;
    QString m_currentLyrics;
    bool m_isPlaying = false;
    bool m_shuffleEnabled = false;
    qreal m_audioLevel = 0.0;
    qint64 m_position = 0;
    qint64 m_duration = 0;
};

class ServicesController : public QObject {
    Q_OBJECT
public:
    explicit ServicesController(QObject *parent = nullptr)
        : QObject(parent), m_net(new QNetworkAccessManager(this))
    {
        QSettings s(settingsFilePath(), QSettings::IniFormat);
        s.beginGroup("artist_images");
        for (const QString &key : s.childKeys()) {
            m_artistImages.insert(key, s.value(key).toString());
        }
        s.endGroup();
    }

    Q_INVOKABLE QString getArtistImage(const QString &artist) const
    {
        return m_artistImages.value(canonicalArtistName(artist.trimmed()));
    }

    Q_INVOKABLE QString localLyricsFor(const QString &filePath) const
    {
        const QFileInfo info(filePath);
        const QString lrcPath = QDir(info.absolutePath()).filePath(info.completeBaseName() + ".lrc");
        QFile file(lrcPath);
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return {};
        return QString::fromUtf8(file.readAll()).trimmed();
    }

    Q_INVOKABLE void cacheLyrics(const QString &title, const QString &artist, const QString &album, const QString &syncedLyrics, const QString &plainLyrics, const QString &provider)
    {
        const QString lyrics = !syncedLyrics.trimmed().isEmpty() ? syncedLyrics.trimmed() : plainLyrics.trimmed();
        if (lyrics.isEmpty()) return;
        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        const QString key = lyricsCacheKey(title, artist, album);
        settings.setValue("lyrics/cache/" + key, lyrics);
        settings.setValue("lyrics/provider/" + key, provider.isEmpty() ? "LRCLIB" : provider);
    }

    Q_INVOKABLE void fetchLyrics(const QString &title, const QString &artist, const QString &album, int durationSeconds)
    {
        if (title.isEmpty() || artist.isEmpty()) return;

        QSettings settings(settingsFilePath(), QSettings::IniFormat);
        const QString cached = settings.value("lyrics/cache/" + lyricsCacheKey(title, artist, album)).toString();
        if (!cached.isEmpty()) {
            emit lyricsFetched(title, artist, cached, settings.value("lyrics/provider/" + lyricsCacheKey(title, artist, album), "LRCLIB").toString());
            return;
        }

        QUrl url("https://lrclib.net/api/get");
        QUrlQuery q;
        q.addQueryItem("artist_name", artist);
        q.addQueryItem("track_name", title);
        if (!album.isEmpty()) q.addQueryItem("album_name", album);
        if (durationSeconds > 0) q.addQueryItem("duration", QString::number(durationSeconds));
        url.setQuery(q);

        QNetworkRequest req(url);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = m_net->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, title, artist, album]() {
            reply->deleteLater();
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
            sReq.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
            auto *sReply = m_net->get(sReq);
            connect(sReply, &QNetworkReply::finished, this, [this, sReply, title, artist, album]() {
                sReply->deleteLater();
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

    Q_INVOKABLE void searchLyrics(const QString &title, const QString &artist)
    {
        if (title.trimmed().isEmpty()) return;

        QUrl url("https://lrclib.net/api/search");
        QUrlQuery query;
        query.addQueryItem("track_name", title.trimmed());
        if (!artist.trimmed().isEmpty()) query.addQueryItem("artist_name", artist.trimmed());
        url.setQuery(query);

        QNetworkRequest request(url);
        request.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");
        auto *reply = m_net->get(request);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
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

    Q_INVOKABLE void fetchRadioStations(const QString &searchQuery = "", const QString &country = "", const QString &language = "", const QString &tag = "", const QString &sort = "votes", bool reverse = true)
    {
        QUrl url("https://de1.api.radio-browser.info/json/stations/search");
        QUrlQuery q;
        const QString normalizedSort = QStringList{"votes", "clicktrend", "name", "country", "bitrate"}.contains(sort) ? sort : "votes";
        q.addQueryItem("order", normalizedSort);
        q.addQueryItem("reverse", reverse ? "true" : "false");
        q.addQueryItem("lastcheckok", "1");
        q.addQueryItem("limit", "80");
        if (!searchQuery.trimmed().isEmpty()) {
            q.addQueryItem("name", searchQuery.trimmed());
        }
        if (!country.trimmed().isEmpty()) q.addQueryItem("country", country.trimmed());
        if (!language.trimmed().isEmpty()) q.addQueryItem("language", language.trimmed());
        if (!tag.trimmed().isEmpty()) q.addQueryItem("tag", tag.trimmed());
        url.setQuery(q);

        QNetworkRequest req(url);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = m_net->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                if (doc.isArray()) {
                    QVariantList stations;
                    const auto arr = doc.array();
                    for (const auto &v : arr) {
                        const auto obj = v.toObject();
                        const QString streamUrl = obj.value("url_resolved").toString();
                        if (streamUrl.isEmpty()) continue;

                        QVariantMap s;
                        s["id"] = obj.value("stationuuid").toString();
                        s["name"] = obj.value("name").toString();
                        s["streamUrl"] = streamUrl;
                        s["favicon"] = obj.value("favicon").toString();
                        s["tags"] = obj.value("tags").toString();
                        s["country"] = obj.value("country").toString();
                        s["language"] = obj.value("language").toString();
                        s["bitrate"] = obj.value("bitrate").toInt();
                        stations.append(s);
                    }
                    emit radioStationsLoaded(stations);
                }
            }
        });
    }

    Q_INVOKABLE void fetchArtistBio(const QString &artist)
    {
        const QString artistName = artist.trimmed();
        if (artistName.isEmpty()) return;
        // Qualified pages avoid landing on a song or disambiguation page first.
        fetchArtistBioFromWikipedia(
            artistName,
            {artistName + " (band)", artistName + " (musician)", artistName + " (singer)", artistName},
            0);
    }

    Q_INVOKABLE void fetchArtistImage(const QString &artist)
    {
        const QString artistName = artist.trimmed();
        if (artistName.isEmpty()) return;

        const QString key = canonicalArtistName(artistName);
        if (m_artistImages.contains(key)) {
            emit artistImageLoaded(artistName, m_artistImages.value(key));
            return;
        }

        QUrl url("https://api.deezer.com/search/artist");
        QUrlQuery q;
        q.addQueryItem("q", artistName);
        url.setQuery(q);

        auto *reply = m_net->get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artistName, key]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("data").toArray();
                for (const auto &value : artists) {
                    const auto entry = value.toObject();
                    if (canonicalArtistName(entry.value("name").toString()) != key) continue;
                    const QString image = entry.value("picture_xl").toString().isEmpty()
                        ? (entry.value("picture_big").toString().isEmpty() ? entry.value("picture_medium").toString() : entry.value("picture_big").toString())
                        : entry.value("picture_xl").toString();
                    if (!image.isEmpty()) {
                        publishArtistImage(artistName, image);
                        return;
                    }
                }
            }
            fetchArtistImageFromAudioDb(artistName);
        });
    }

    Q_INVOKABLE void openExternalUrl(const QString &url)
    {
        QDesktopServices::openUrl(QUrl(url));
    }

signals:
    void lyricsFetched(const QString &title, const QString &artist, const QString &lyrics, const QString &provider);
    void lyricsSearchResultsReady(const QVariantList &results);
    void radioStationsLoaded(const QVariantList &stations);
    void artistBioLoaded(const QString &artist, const QString &bio);
    void artistImageLoaded(const QString &artist, const QString &imageUrl);

private:
    static QString lyricsCacheKey(const QString &title, const QString &artist, const QString &album)
    {
        const QString source = (artist + "|" + title + "|" + album).trimmed().toCaseFolded();
        return QString::fromLatin1(QCryptographicHash::hash(source.toUtf8(), QCryptographicHash::Sha256).toHex());
    }

    static QString canonicalArtistName(const QString &artist)
    {
        // Provider search is fuzzy; a missing portrait beats the wrong artist.
        QString canonical;
        for (const QChar character : artist.toLower()) {
            if (character.isLetterOrNumber()) canonical.append(character);
        }
        return canonical;
    }

    void publishArtistImage(const QString &artist, const QString &imageUrl)
    {
        const QString key = canonicalArtistName(artist);
        m_artistImages.insert(key, imageUrl);
        QSettings s(settingsFilePath(), QSettings::IniFormat);
        s.setValue("artist_images/" + key, imageUrl);
        emit artistImageLoaded(artist, imageUrl);
    }

    void fetchArtistImageFromAudioDb(const QString &artist)
    {
        QUrl url("https://www.theaudiodb.com/api/v1/json/123/search.php");
        QUrlQuery q;
        q.addQueryItem("s", artist);
        url.setQuery(q);

        auto *reply = m_net->get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) return;
            const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("artists").toArray();
            const QString key = canonicalArtistName(artist);
            for (const auto &value : artists) {
                const auto entry = value.toObject();
                if (canonicalArtistName(entry.value("strArtist").toString()) != key) continue;
                const QString image = entry.value("strArtistFanart").toString().isEmpty()
                    ? entry.value("strArtistThumb").toString()
                    : entry.value("strArtistFanart").toString();
                if (!image.isEmpty()) publishArtistImage(artist, image);
                return;
            }
        });
    }

    void fetchArtistBioFromWikipedia(const QString &artist, const QStringList &queries, int index)
    {
        if (index >= queries.size()) {
            fetchArtistBioFromAudioDb(artist);
            return;
        }

        QUrl url("https://en.wikipedia.org/w/api.php");
        QUrlQuery q;
        q.addQueryItem("action", "query");
        q.addQueryItem("format", "json");
        q.addQueryItem("prop", "extracts");
        q.addQueryItem("exintro", "true");
        q.addQueryItem("explaintext", "true");
        q.addQueryItem("redirects", "true");
        q.addQueryItem("titles", queries.at(index));
        url.setQuery(q);

        QNetworkRequest req(url);
        req.setHeader(QNetworkRequest::UserAgentHeader, "CassetteCat/2.0.0 (https://github.com/samyyy2311/CassetteCat)");

        auto *reply = m_net->get(req);
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist, queries, index]() {
            reply->deleteLater();
            if (reply->error() == QNetworkReply::NoError) {
                const auto doc = QJsonDocument::fromJson(reply->readAll());
                const auto query = doc.object().value("query").toObject();
                const auto pages = query.value("pages").toObject();
                for (const auto &key : pages.keys()) {
                    const auto page = pages.value(key).toObject();
                    const QString extract = page.value("extract").toString().trimmed();
                    if (!extract.isEmpty()) {
                        emit artistBioLoaded(artist, extract);
                        return;
                    }
                }
            }
            fetchArtistBioFromWikipedia(artist, queries, index + 1);
        });
    }

    void fetchArtistBioFromAudioDb(const QString &artist)
    {
        QUrl url("https://www.theaudiodb.com/api/v1/json/123/search.php");
        QUrlQuery q;
        q.addQueryItem("s", artist);
        url.setQuery(q);

        auto *reply = m_net->get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [this, reply, artist]() {
            reply->deleteLater();
            if (reply->error() != QNetworkReply::NoError) return;
            const auto artists = QJsonDocument::fromJson(reply->readAll()).object().value("artists").toArray();
            const QString biography = artists.isEmpty() ? QString() : artists.first().toObject().value("strBiographyEN").toString().trimmed();
            if (!biography.isEmpty()) emit artistBioLoaded(artist, biography);
        });
    }

    QNetworkAccessManager *m_net = nullptr;
    QHash<QString, QString> m_artistImages;
};


}

#ifdef Q_OS_WIN
#include <windows.h>
#include <dwmapi.h>
#include <shobjidl.h>

static void setupWindowsFrameless(QQuickWindow *window) {
    if (!window) return;
    HWND hwnd = (HWND)window->winId();
    if (!hwnd) return;

    // A one-pixel client extension keeps DWM shadowing on a frameless window.
    MARGINS margins = { 1, 1, 1, 1 };
    DwmExtendFrameIntoClientArea(hwnd, &margins);
}
#endif

class SettingsController final : public QObject
{
    Q_OBJECT

public:
    explicit SettingsController(QObject *parent = nullptr)
        : QObject(parent)
        , m_settings(settingsFilePath(), QSettings::IniFormat)
    {
    }

    Q_INVOKABLE void setValue(const QString &key, const QVariant &value)
    {
        m_settings.setValue(key, value);
        m_settings.sync();
    }

    Q_INVOKABLE void setValues(const QVariantMap &values)
    {
        for (auto it = values.cbegin(); it != values.cend(); ++it) {
            m_settings.setValue(it.key(), it.value());
        }
        m_settings.sync();
    }

    Q_INVOKABLE QVariant value(const QString &key, const QVariant &defaultValue = QVariant()) const
    {
        return m_settings.value(key, defaultValue);
    }

    Q_INVOKABLE void sync()
    {
        m_settings.sync();
    }

private:
    mutable QSettings m_settings;
};

int main(int argc, char *argv[])
{
    qInstallMessageHandler(writeDebugLog);

    if (argc == 2 && std::strcmp(argv[1], "--self-check") == 0) {
        return scanSelfCheck() ? 0 : 1;
    }

#ifdef Q_OS_WIN
    SetCurrentProcessExplicitAppUserModelID(L"CassetteCat.AudioEngine.Desktop.App");
#endif

    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");
    QCoreApplication::setOrganizationName("CassetteCat");
    QCoreApplication::setApplicationName("CassetteCat");

    QIcon appIcon;
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(16, 16));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(24, 24));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(32, 32));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(48, 48));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(64, 64));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(128, 128));
    appIcon.addFile(":/CassetteCat/assets/cassettecat_icon.png", QSize(256, 256));
    app.setWindowIcon(appIcon);

    const QStringList fontFiles = {
        ":/CassetteCat/fonts/space_grotesk_variable.ttf",
        ":/CassetteCat/fonts/ibm_plex_sans_variable.ttf",
        ":/CassetteCat/fonts/ibm_plex_mono_regular.ttf",
        ":/CassetteCat/fonts/ibm_plex_mono_semibold.ttf",
        ":/CassetteCat/fonts/silkscreen_regular.ttf",
        ":/CassetteCat/fonts/silkscreen_bold.ttf",
        ":/CassetteCat/fonts/vt323_regular.ttf",
        ":/CassetteCat/fonts/monocraft.ttf"
    };

    for (const QString &fontPath : fontFiles) {
        QFontDatabase::addApplicationFont(fontPath);
    }

    QFont defaultFont("Space Grotesk");
    defaultFont.setStyleHint(QFont::SansSerif);
    app.setFont(defaultFont);

    LibraryController library(&app);
    PlayerController player(&app);
    ServicesController services(&app);
    SettingsController appSettings(&app);
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("player", &player);
    engine.rootContext()->setContextProperty("services", &services);
    engine.rootContext()->setContextProperty("appSettings", &appSettings);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [](const QUrl &url) {
            qWarning() << "Failed to create QML root object from URL:" << url;
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
    );
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::warnings,
        [](const QList<QQmlError> &warnings) {
            for (const auto &w : warnings) {
                qWarning() << "QML warning:" << w.toString();
            }
        }
    );

    engine.loadFromModule("CassetteCat", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "FATAL: engine.rootObjects() is empty after loading Main module!";
#ifdef Q_OS_WIN
        MessageBoxA(NULL, "FATAL: QML root object creation failed. Check debug.log for details.", "CassetteCat Error", MB_OK | MB_ICONERROR);
#endif
        return 1;
    }


#ifdef Q_OS_WIN
    for (auto *rootObj : engine.rootObjects()) {
        if (auto *quickWin = qobject_cast<QQuickWindow *>(rootObj)) {
            quickWin->setIcon(appIcon);
            quickWin->show();
            setupWindowsFrameless(quickWin);
            quickWin->raise();
            quickWin->requestActivate();
            break;
        }
    }
#endif

    return app.exec();
}

#include "main.moc"
