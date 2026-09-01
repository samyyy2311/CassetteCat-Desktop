#include <QAudioOutput>
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
#ifdef _WIN32
#include <windows.h>
#endif

#include <algorithm>
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

void writeDebugLog(QtMsgType, const QMessageLogContext &, const QString &message)
{
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

    // 1. M4A / MP4 / ALAC
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

    // 2. FLAC
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

    // 3. MP3 (ID3v2)
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

    // 4. Vorbis / Opus / Ogg
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

    // 1. Check sidecar .lrc or .txt file in same directory
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

    // 2. M4A / MP4 embedded lyrics
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

    // 3. MP3 (ID3v2) USLT / SYLT
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

    // 4. Generic TagLib PropertyMap (FLAC, OGG, etc.)
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
                const QString tagTitle = QString::fromStdWString(tag->title().toWString()).trimmed();
                if (!tagTitle.isEmpty()) {
                    info.title = tagTitle;
                }

                const QString tagArtist = QString::fromStdWString(tag->artist().toWString()).trimmed();
                if (!tagArtist.isEmpty()) {
                    info.artist = tagArtist;
                }

                const QString tagAlbum = QString::fromStdWString(tag->album().toWString()).trimmed();
                if (!tagAlbum.isEmpty()) {
                    info.album = tagAlbum;
                }
            }

            if (const TagLib::AudioProperties *props = fileRef.audioProperties()) {
                info.durationSeconds = props->lengthInSeconds();
                info.duration = formatDuration(info.durationSeconds);
            }
        }

        // Lyrics are loaded on-demand when playing or viewing lyrics
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

QVariantList addEmbeddedArtwork(QVariantList tracks)
{
    QHash<QString, QString> artworkByAlbum;
    QHash<QString, QString> filesToExtract;

    for (const QVariant &value : tracks) {
        const QVariantMap track = value.toMap();
        if (!track.value("artworkUrl").toString().isEmpty()) {
            continue;
        }
        const QString albumKey = track.value("artist").toString() + '\x1f' + track.value("album").toString();
        const QString filePath = track.value("filePath").toString();
        if (!filesToExtract.contains(albumKey)) {
            filesToExtract.insert(albumKey, filePath);
        }
    }

    // Extract unique albums
    for (auto it = filesToExtract.constBegin(); it != filesToExtract.constEnd(); ++it) {
        artworkByAlbum.insert(it.key(), extractEmbeddedArtwork(it.value()));
    }

    for (QVariant &value : tracks) {
        QVariantMap track = value.toMap();
        if (!track.value("artworkUrl").toString().isEmpty()) {
            continue;
        }
        const QString albumKey = track.value("artist").toString() + '\x1f' + track.value("album").toString();
        const QString art = artworkByAlbum.value(albumKey);
        if (!art.isEmpty()) {
            track.insert("artworkUrl", art);
            value = track;
        }
    }
    return tracks;
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
        , m_artworkWatcher(this)
    {
        connect(&m_scanWatcher, &QFutureWatcher<QVariantList>::finished, this, [this] {
            m_tracks = m_scanWatcher.result();
            emit changed();
            m_artworkWatcher.setFuture(QtConcurrent::run([tracks = m_tracks] {
                return addEmbeddedArtwork(tracks);
            }));
        });
        connect(&m_artworkWatcher, &QFutureWatcher<QVariantList>::finished, this, [this] {
            m_tracks = m_artworkWatcher.result();
            emit changed();
        });

        QSettings settings;
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

        QSettings settings;
        settings.setValue("library/folder", path);
    }

signals:
    void changed();

private:
    void setFolderPath(const QString &path)
    {
        m_folder = path;
        m_tracks.clear();
        emit changed();
        m_scanWatcher.setFuture(QtConcurrent::run([path] {
            return scanTracks(path);
        }));
    }

    QString m_folder;
    QVariantList m_tracks;
    QFutureWatcher<QVariantList> m_scanWatcher;
    QFutureWatcher<QVariantList> m_artworkWatcher;
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

    Q_PROPERTY(QString currentLyrics READ currentLyrics NOTIFY currentLyricsChanged)

public:
    explicit PlayerController(QObject *parent = nullptr)
        : QObject(parent)
        , m_audioOutput(new QAudioOutput(this))
        , m_player(new QMediaPlayer(this))
    {
        m_player->setAudioOutput(m_audioOutput);
        m_audioOutput->setVolume(1.0f);

        connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState state) {
            const bool playing = (state == QMediaPlayer::PlayingState);
            if (m_isPlaying != playing) {
                m_isPlaying = playing;
                emit isPlayingChanged();
            }
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
    qint64 position() const { return m_position; }
    qint64 duration() const { return m_duration; }
    QString formattedPosition() const { return formatDuration(static_cast<int>(m_position / 1000)); }
    QString formattedDuration() const { return formatDuration(static_cast<int>(m_duration / 1000)); }
    float volume() const { return m_audioOutput ? m_audioOutput->volume() : 1.0f; }

    Q_INVOKABLE QString getLyrics(const QString &filePath) const
    {
        return extractEmbeddedLyrics(filePath);
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

    Q_INVOKABLE void playTrack(const QVariantMap &track)
    {
        const QString filePath = track.value("filePath").toString();
        if (filePath.isEmpty()) {
            return;
        }

        m_currentTrack = track;
        m_currentLyrics = track.value("lyrics").toString();
        if (m_currentLyrics.isEmpty()) {
            m_currentLyrics = extractEmbeddedLyrics(filePath);
        }
        emit currentTrackChanged();
        emit currentLyricsChanged();

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
    void trackEnded();

private:
    QAudioOutput *m_audioOutput = nullptr;
    QMediaPlayer *m_player = nullptr;
    QVariantMap m_currentTrack;
    QString m_currentLyrics;
    bool m_isPlaying = false;
    bool m_shuffleEnabled = false;
    qint64 m_position = 0;
    qint64 m_duration = 0;
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

    MARGINS margins = { 1, 1, 1, 1 };
    DwmExtendFrameIntoClientArea(hwnd, &margins);
}
#endif

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

    // Load bundled brand fonts from resources
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
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("library", &library);
    engine.rootContext()->setContextProperty("player", &player);

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

#ifdef Q_OS_WIN
    for (auto *rootObj : engine.rootObjects()) {
        if (auto *quickWin = qobject_cast<QQuickWindow *>(rootObj)) {
            quickWin->setIcon(appIcon);
            QSettings settings;
            const int w = settings.value("window/width", 1280).toInt();
            const int h = settings.value("window/height", 800).toInt();
            const int x = settings.value("window/x", -1).toInt();
            const int y = settings.value("window/y", -1).toInt();
            if (w >= 720 && h >= 480 && w <= 7680 && h <= 4320) {
                quickWin->resize(w, h);
            }
            if (x >= 0 && y >= 0 && x < 5000 && y < 3000) {
                quickWin->setPosition(QPoint(x, y));
            }
            if (settings.value("window/maximized", false).toBool()) {
                quickWin->showMaximized();
            } else {
                quickWin->showNormal();
            }
            quickWin->show();
            quickWin->raise();
            quickWin->requestActivate();

            QObject::connect(quickWin, &QWindow::visibilityChanged, [quickWin](QWindow::Visibility v) {
                QSettings settings;
                if (v == QWindow::Maximized) {
                    settings.setValue("window/maximized", true);
                } else if (v == QWindow::Windowed) {
                    if (quickWin->width() >= 720 && quickWin->height() >= 480) {
                        settings.setValue("window/maximized", false);
                        settings.setValue("window/width", quickWin->width());
                        settings.setValue("window/height", quickWin->height());
                        settings.setValue("window/x", quickWin->x());
                        settings.setValue("window/y", quickWin->y());
                    }
                }
            });

            setupWindowsFrameless(quickWin);

            HWND hwnd = (HWND)quickWin->winId();
            if (hwnd) {
                ShowWindow(hwnd, SW_SHOW);
                SetForegroundWindow(hwnd);
            }
            break;
        }
    }
#endif

    return app.exec();
}

#include "main.moc"
