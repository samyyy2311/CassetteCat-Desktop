#include "library_controller.h"

#include "app_paths.h"
#include "app_settings.h"
#include "audio_metadata.h"
#include "library_scanner.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QJsonDocument>
#include <QRegularExpression>
#include <QSettings>
#include <QTimer>

#include <algorithm>
#include <utility>

namespace {

QString normalizedPath(QString path) {
    path = QDir::cleanPath(path.replace('\\', '/'));
#ifdef Q_OS_WIN
    path = path.toLower();
#endif
    return path;
}

QString primaryArtist(const QString &artist) {
    static const QRegularExpression separator("[,&;/]|\\bfeat\\.?\\b|\\bft\\.?\\b",
                                              QRegularExpression::CaseInsensitiveOption);
    const QString value = artist.trimmed();
    if (value.isEmpty())
        return "Unknown Artist";
    const QStringList parts = value.split(separator, Qt::SkipEmptyParts);
    return parts.isEmpty() ? value : parts.first().trimmed();
}

} // namespace

LibraryController::LibraryController(QObject *parent)
    : QAbstractListModel(parent), m_folderWatcher(this), m_watchDebounce(this), m_scanProcess(this) {
    m_watchDebounce.setSingleShot(true);
    m_watchDebounce.setInterval(750);
    connect(&m_folderWatcher, &QFileSystemWatcher::directoryChanged, this, [this] { m_watchDebounce.start(); });
    connect(&m_watchDebounce, &QTimer::timeout, this, &LibraryController::rescanFolder);
    connect(&m_scanProcess, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        const bool completed =
            m_activeScanGeneration == m_scanGeneration && exitStatus == QProcess::NormalExit && exitCode == 0;
        if (completed) {
            const QJsonDocument document = QJsonDocument::fromJson(m_scanProcess.readAllStandardOutput());
            if (document.isArray())
                m_scannedTracks += document.toVariant().toList();
        }
        if (!m_pendingScanPaths.isEmpty()) {
            startScan();
            return;
        }
        if (!completed)
            return;

        QSet<QString> seenPaths;
        QVariantList tracks;
        tracks.reserve(m_scannedTracks.size());
        for (const QVariant &value : std::as_const(m_scannedTracks)) {
            QVariantMap track = value.toMap();
            const QString path = track.value("filePath").toString();
            if (!path.isEmpty() && !seenPaths.contains(path)) {
                seenPaths.insert(path);
                const QString custom = SettingsController::globalValue("artwork/custom/" + path).toString();
                if (!custom.isEmpty()) {
                    track.insert("artworkUrl", custom);
                }
                tracks.append(track);
            }
        }

        beginResetModel();
        m_tracks = tracks;
        rebuildVisibleRows();
        endResetModel();
        updateFolderWatch();
        emit changed();
        emit tracksChanged();
        emit visibleTracksChanged();
    });

    QStringList savedFolders = SettingsController::globalValue("library/folders").toStringList();
    if (savedFolders.isEmpty())
        savedFolders = {SettingsController::globalValue("library/folder").toString()};
    savedFolders.removeAll(QString());
    if (!savedFolders.isEmpty()) {
        QTimer::singleShot(100, this, [this, savedFolders] { setFolderPaths(savedFolders); });
    }
}

QStringList LibraryController::folders() const {
    return m_folders;
}

int LibraryController::rowCount(const QModelIndex &parent) const {
    return parent.isValid() ? 0 : m_visibleRows.size();
}

QVariant LibraryController::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visibleRows.size())
        return {};
    if (role == TrackRole)
        return m_tracks.at(m_visibleRows.at(index.row()));
    return {};
}

QHash<int, QByteArray> LibraryController::roleNames() const {
    return {{TrackRole, "track"}};
}

bool LibraryController::selfCheck() {
    LibraryController library;
    const auto fail = [](const char *check) {
        qWarning().noquote() << "Library self-check failed:" << check;
        return false;
    };
    const std::pair<QString, QString> folderUrls[] = {
        {"file:///home/music/Live%20Sets", "/home/music/Live Sets"},
        {"file:///home/music/%2520", "/home/music/%20"},
        {"https://example.com/music", ""},
        {"", ""},
    };
    for (const auto &[url, expected] : folderUrls) {
        QString path;
        if (!QMetaObject::invokeMethod(&library, "localPath", Q_RETURN_ARG(QString, path), Q_ARG(QUrl, QUrl(url))) ||
            path != expected)
            return fail("local path");
    }
    library.m_tracks = {
        QVariantMap{
            {"filePath", "C:/Music/keep.flac"}, {"title", "Keep"}, {"format", "FLAC"}, {"durationSeconds", 180}},
        QVariantMap{
            {"filePath", "C:/Music/hidden/song.mp3"}, {"title", "Hidden"}, {"format", "MP3"}, {"durationSeconds", 180}},
        QVariantMap{{"filePath", "C:/Music/clip.aac"}, {"title", "Clip"}, {"format", "AAC"}, {"durationSeconds", 10}},
        QVariantMap{{"filePath", "C:/Music/alternate.wav"},
                    {"title", "Alternate"},
                    {"format", "WAV"},
                    {"durationSeconds", 180}},
    };

    library.setLibraryFilter({}, "ALL", {}, "title", true, {"C:/Music/hidden"}, true);
    if (library.trackCount() != 2 || library.visibleTrackCount() != 2)
        return fail("library filter");
    if (library.data(library.index(0, 0), TrackRole).toMap().value("filePath").toString() != "C:/Music/alternate.wav")
        return fail("library sort");

    library.setSearchFilter({}, "FLAC", {}, false);
    const QVariantMap groups = library.catalogGroups();
    if (!(library.trackCount() == 4 && library.visibleTrackCount() == 2 &&
          library.firstPlayableTrack().value("filePath").toString() == "C:/Music/keep.flac" &&
          groups.value("artists").toList().size() == 1 && groups.value("albums").toList().size() == 1))
        return fail("search filter");

    library.m_tracks = {
        QVariantMap{{"filePath", "/Music/Live/song.flac"}},
        QVariantMap{{"filePath", "/Music/Live/Encore/song.flac"}},
        QVariantMap{{"filePath", "/Music/Live Sessions/song.flac"}},
        QVariantMap{{"filePath", "/Music/live/song.flac"}},
    };
    for (const QString &folder : {QString("/Music/Live"), QString("/Music/Live/")}) {
        library.setSearchFilter({}, "ALL", {folder}, false);
#ifdef Q_OS_WIN
        if (library.trackCount() != 1)
            return fail("folder filter");
#else
        if (library.trackCount() != 2)
            return fail("folder filter");
#endif
        if (library.firstPlayableTrack().value("filePath").toString() != "/Music/Live Sessions/song.flac")
            return fail("folder sort");
        if (library.playbackTracks().size() != library.trackCount())
            return fail("playback tracks");
    }
    library.setSearchFilter({}, "ALL", {"/"}, false);
    return library.trackCount() == 0;
}

QString LibraryController::localPath(const QUrl &url) const {
    return url.toLocalFile();
}

/// @copydoc LibraryController::parseM3u
QVariantList LibraryController::parseM3u(const QString &filePath) const {
    return parseM3uPlaylist(filePath);
}

void LibraryController::loadFolder(const QUrl &url) {
    QString path = localPath(url);

    if (path.isEmpty()) {
        return;
    }
    const QFileInfo info(path);
    if (info.isFile())
        path = info.absolutePath();
    if (!QDir(path).exists())
        return;

    QStringList paths = m_folders;
    if (!paths.contains(path))
        paths.append(path);
    setFolderPaths(paths);
}

void LibraryController::removeFolder(const QString &path) {
    QStringList paths = m_folders;
    paths.removeAll(path);
    setFolderPaths(paths);
}

QString LibraryController::artworkFor(const QString &filePath) {
    const auto cached = m_artworkUrls.constFind(filePath);
    if (cached != m_artworkUrls.cend())
        return *cached;
    const QString custom = SettingsController::globalValue("artwork/custom/" + filePath).toString();
    const QString local = custom.startsWith("file:") ? QUrl(custom).toLocalFile() : custom;
    if (!custom.isEmpty() && QFileInfo::exists(local)) {
        m_artworkUrls.insert(filePath, custom);
        return custom;
    }
    const QString artworkUrl = extractEmbeddedArtwork(filePath);
    m_artworkUrls.insert(filePath, artworkUrl);
    return artworkUrl;
}

void LibraryController::setCustomArtwork(const QString &filePath, const QString &artworkPath) {
    if (filePath.isEmpty() || artworkPath.isEmpty())
        return;
    m_artworkUrls.insert(filePath, artworkPath);
    SettingsController::setGlobalValue("artwork/custom/" + filePath, artworkPath);
    for (int i = 0; i < m_tracks.size(); ++i) {
        QVariantMap track = m_tracks[i].toMap();
        if (track.value("filePath").toString() == filePath) {
            track.insert("artworkUrl", artworkPath);
            m_tracks[i] = track;
            break;
        }
    }
    emit tracksChanged();
}

void LibraryController::setAlbumArtwork(const QString &album, const QString &artist, const QString &artworkPath) {
    if (album.isEmpty() || artworkPath.isEmpty())
        return;
    bool changed = false;
    SettingsController::setGlobalValue("artwork/album/" + album.trimmed().toLower(), artworkPath);
    for (int i = 0; i < m_tracks.size(); ++i) {
        QVariantMap track = m_tracks[i].toMap();
        if (track.value("album").toString().trimmed().compare(album.trimmed(), Qt::CaseInsensitive) == 0) {
            if (artist.isEmpty() ||
                track.value("artist").toString().trimmed().compare(artist.trimmed(), Qt::CaseInsensitive) == 0) {
                const QString path = track.value("filePath").toString();
                track.insert("artworkUrl", artworkPath);
                m_artworkUrls.insert(path, artworkPath);
                SettingsController::setGlobalValue("artwork/custom/" + path, artworkPath);
                m_tracks[i] = track;
                changed = true;
            }
        }
    }
    if (changed)
        emit tracksChanged();
}

QVariantMap LibraryController::trackForPath(const QString &filePath) const {
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        if (track.value("filePath").toString() == filePath)
            return track;
    }
    return {};
}

QVariantMap LibraryController::updateTrackMetadata(const QVariantMap &metadata) {
    const QString filePath = metadata.value("filePath").toString();
    if (filePath.isEmpty() || filePath.contains(':') && !QFileInfo::exists(filePath))
        return {};

    QString error;
    if (!writeTrackInfo(metadata, &error)) {
        qWarning().noquote() << "METADATA_UPDATE_FAILED:" << error;
        return {};
    }

    const TrackInfo info = readTrackInfo(filePath);
    for (int i = 0; i < m_tracks.size(); ++i) {
        QVariantMap track = m_tracks.at(i).toMap();
        if (track.value("filePath").toString() != filePath)
            continue;
        const QString artwork = track.value("artworkUrl").toString();
        track = info.toMap();
        if (!artwork.isEmpty())
            track.insert("artworkUrl", artwork);
        m_tracks[i] = track;
        beginResetModel();
        rebuildVisibleRows();
        endResetModel();
        emit changed();
        emit tracksChanged();
        emit visibleTracksChanged();
        return track;
    }
    return info.toMap();
}

QVariantMap LibraryController::firstPlayableTrack() const {
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        if (isAvailable(track))
            return track;
    }
    return {};
}

QVariantList LibraryController::playbackTracks() const {
    QVariantList result;
    result.reserve(m_trackCount);
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        if (isAvailable(track))
            result.append(track);
    }
    return result;
}

QVariantMap LibraryController::catalogGroups() const {
    QHash<QString, QVariantMap> artists;
    QHash<QString, QVariantMap> albums;
    QHash<QString, QVariantMap> genres;
    QHash<QString, QVariantMap> folders;
    const auto add = [](QHash<QString, QVariantMap> &groups, const QString &key, const QVariantMap &track,
                        const QVariantMap &initial) {
        auto it = groups.find(key);
        if (it == groups.end()) {
            QVariantMap group = initial;
            group.insert("track", track);
            group.insert("count", 1);
            groups.insert(key, group);
            return;
        }
        it->insert("count", it->value("count").toInt() + 1);
    };

    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        if (!isAvailable(track))
            continue;

        const QString artist = primaryArtist(track.value("artist").toString());
        add(artists, artist, track, {{"name", artist}});

        const QString album =
            track.value("album").toString().isEmpty() ? QString("Unknown Album") : track.value("album").toString();
        add(albums, album, track, {{"name", album}});

        const QString genre = track.value("genre").toString().trimmed().isEmpty()
                                  ? QString("Soundtrack")
                                  : track.value("genre").toString().trimmed();
        add(genres, genre, track, {{"name", genre}});

        const QString path = track.value("filePath").toString().replace('\\', '/');
        if (path.isEmpty())
            continue;
        const int slash = path.lastIndexOf('/');
        const QString folderPath = slash < 0 ? QString("Music") : path.left(slash);
        const QString folderName =
            folderPath.section('/', -1).isEmpty() ? QString("Music") : folderPath.section('/', -1);
        add(folders, folderPath, track, {{"name", folderName}, {"path", folderPath}});
    }

    const auto values = [](const QHash<QString, QVariantMap> &groups) {
        QVariantList result;
        result.reserve(groups.size());
        for (auto it = groups.cbegin(); it != groups.cend(); ++it)
            result.append(it.value());
        return result;
    };
    return {{"artists", values(artists)},
            {"albums", values(albums)},
            {"genres", values(genres)},
            {"folders", values(folders)}};
}

void LibraryController::setLibraryFilter(const QString &query, const QString &filter, const QVariantMap &favorites,
                                         const QString &sortMetric, bool ascending, const QVariantList &excludedFolders,
                                         bool ignoreShortClips) {
    setFilter(query, filter, true, filter == "FAVORITES", favorites, sortMetric, ascending, excludedFolders,
              ignoreShortClips);
}

void LibraryController::setSearchFilter(const QString &query, const QString &format,
                                        const QVariantList &excludedFolders, bool ignoreShortClips) {
    setFilter(query, format, false, false, {}, {}, true, excludedFolders, ignoreShortClips);
}

void LibraryController::setFilter(const QString &query, const QString &format, bool strictFormat, bool favoritesOnly,
                                  const QVariantMap &favorites, const QString &sortMetric, bool ascending,
                                  const QVariantList &excludedFolders, bool ignoreShortClips) {
    QStringList folders;
    folders.reserve(excludedFolders.size());
    for (const QVariant &value : excludedFolders) {
        if (value.toString().isEmpty())
            continue;
        QString path = normalizedPath(value.toString());
        if (!path.endsWith('/'))
            path += '/';
        folders.append(path);
    }

    QSet<QString> favoritePaths;
    for (auto it = favorites.cbegin(); it != favorites.cend(); ++it) {
        if (it.value().toBool())
            favoritePaths.insert(it.key());
    }

    const bool availabilityChanged = m_excludedFolders != folders || m_ignoreShortClips != ignoreShortClips;
    if (m_query == query && m_format == format && m_strictFormat == strictFormat && m_favoritesOnly == favoritesOnly &&
        m_favorites == favoritePaths && m_sortMetric == sortMetric && m_sortAscending == ascending &&
        m_excludedFolders == folders && m_ignoreShortClips == ignoreShortClips) {
        return;
    }

    m_query = query;
    m_format = format;
    m_strictFormat = strictFormat;
    m_favoritesOnly = favoritesOnly;
    m_favorites = std::move(favoritePaths);
    m_sortMetric = sortMetric;
    m_sortAscending = ascending;
    m_excludedFolders = std::move(folders);
    m_ignoreShortClips = ignoreShortClips;

    beginResetModel();
    rebuildVisibleRows();
    endResetModel();
    if (availabilityChanged)
        emit tracksChanged();
    emit visibleTracksChanged();
}

bool LibraryController::isAvailable(const QVariantMap &track) const {
    const QString filePath = track.value("filePath").toString();
    if (filePath.isEmpty())
        return false;
    if (m_ignoreShortClips) {
        const int duration = track.value("durationSeconds").toInt();
        if (duration > 0 && duration < 30)
            return false;
    }

    const QString path = normalizedPath(filePath);
    for (const QString &folder : m_excludedFolders) {
        if (path.startsWith(folder))
            return false;
    }
    return true;
}

bool LibraryController::matchesVisibleFilter(const QVariantMap &track) const {
    const QString format = track.value("format").toString().toUpper();
    if (m_favoritesOnly && !m_favorites.contains(track.value("filePath").toString()))
        return false;
    if (m_format != "ALL" && !m_format.isEmpty()) {
        if (m_format == "FLAC") {
            if (format != "FLAC" && (m_strictFormat || (format != "WAV" && format != "ALAC")))
                return false;
        } else if (m_format == "MP3" && format != "MP3") {
            return false;
        } else if (m_format == "AAC" && format != "AAC" && format != "M4A") {
            return false;
        }
    }
    if (m_query.trimmed().isEmpty())
        return true;

    const QString query = m_query.trimmed().toLower();
    return track.value("title").toString().toLower().contains(query) ||
           track.value("fileName").toString().toLower().contains(query) ||
           track.value("artist").toString().toLower().contains(query) ||
           track.value("album").toString().toLower().contains(query);
}

void LibraryController::rebuildVisibleRows() {
    m_visibleRows.clear();
    m_visibleRows.reserve(m_tracks.size());
    m_trackCount = 0;
    for (int row = 0; row < m_tracks.size(); ++row) {
        const QVariantMap track = m_tracks.at(row).toMap();
        if (!isAvailable(track))
            continue;
        ++m_trackCount;
        if (matchesVisibleFilter(track))
            m_visibleRows.append(row);
    }

    if (m_sortMetric.isEmpty())
        return;
    std::sort(m_visibleRows.begin(), m_visibleRows.end(), [this](int left, int right) {
        const QVariantMap a = m_tracks.at(left).toMap();
        const QVariantMap b = m_tracks.at(right).toMap();
        int result = 0;
        if (m_sortMetric == "duration") {
            result = a.value("durationSeconds").toInt() - b.value("durationSeconds").toInt();
        } else if (m_sortMetric == "artist") {
            result = QString::localeAwareCompare(a.value("artist").toString(), b.value("artist").toString());
        } else if (m_sortMetric == "album") {
            result = QString::localeAwareCompare(a.value("album").toString(), b.value("album").toString());
        } else {
            const QString aTitle =
                a.value("title").toString().isEmpty() ? a.value("fileName").toString() : a.value("title").toString();
            const QString bTitle =
                b.value("title").toString().isEmpty() ? b.value("fileName").toString() : b.value("title").toString();
            result = QString::localeAwareCompare(aTitle, bTitle);
        }
        return m_sortAscending ? result < 0 : result > 0;
    });
}

void LibraryController::setFolderPaths(QStringList paths) {
    for (auto it = paths.begin(); it != paths.end();) {
        const QFileInfo info(*it);
        if (!info.isDir())
            it = paths.erase(it);
        else {
            *it = info.absoluteFilePath();
            ++it;
        }
    }
    paths.removeDuplicates();
    ++m_scanGeneration;
    m_folders = std::move(paths);
    beginResetModel();
    m_tracks.clear();
    rebuildVisibleRows();
    endResetModel();
    m_artworkUrls.clear();
    updateFolderWatch();
    emit changed();
    emit tracksChanged();
    emit visibleTracksChanged();

    m_scannedTracks.clear();
    m_pendingScanPaths = m_folders;
    SettingsController::setGlobalValue("library/folders", m_folders);
    SettingsController::setGlobalValue("library/folder", m_folders.isEmpty() ? QString() : m_folders.first());
    if (m_scanProcess.state() != QProcess::NotRunning)
        m_scanProcess.kill();
    else if (!m_pendingScanPaths.isEmpty())
        startScan();
}

void LibraryController::rescanFolder() {
    if (m_folders.isEmpty())
        return;
    ++m_scanGeneration;
    m_scannedTracks.clear();
    m_pendingScanPaths = m_folders;
    if (m_scanProcess.state() != QProcess::NotRunning)
        m_scanProcess.kill();
    else
        startScan();
}

void LibraryController::updateFolderWatch() {
    const QStringList watchedDirectories = m_folderWatcher.directories();
    if (!watchedDirectories.isEmpty())
        m_folderWatcher.removePaths(watchedDirectories);
    QStringList directories;
    for (const QString &path : std::as_const(m_folders)) {
        directories.append(path);
        QDirIterator iterator(path, QDir::Dirs | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
        while (iterator.hasNext())
            directories.append(iterator.next());
    }
    m_folderWatcher.addPaths(directories);
}

void LibraryController::startScan() {
    if (m_pendingScanPaths.isEmpty())
        return;
    m_activeScanGeneration = m_scanGeneration;
    m_scanProcess.start(QCoreApplication::applicationFilePath(), {"--scan-library", m_pendingScanPaths.takeFirst()});
}
