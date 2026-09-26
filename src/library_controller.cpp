#include "library_controller.h"

#include "app_paths.h"
#include "app_settings.h"
#include "audio_metadata.h"
#include "image_cache.h"
#include "library_scanner.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRandomGenerator>
#include <QRegularExpression>
#include <QSaveFile>
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

// A custom cover whose image was deleted is ignored so the track falls back to its own artwork.
QString customArtwork(const QString &filePath) {
    const QString custom = SettingsController::globalValue("artwork/custom/" + filePath).toString();
    const QString local = custom.startsWith("file:") ? QUrl(custom).toLocalFile() : custom;
    return !custom.isEmpty() && QFileInfo::exists(local) ? custom : QString();
}

// Adds a trailing separator so a folder does not also match siblings that share its name as a prefix.
QString folderPrefix(const QString &folder) {
    QString prefix = normalizedPath(folder);
    if (!prefix.endsWith('/'))
        prefix += '/';
    return prefix;
}

QVariantList tracksInFolders(const QVariantList &tracks, const QStringList &folders) {
    QStringList prefixes;
    for (const QString &folder : folders)
        prefixes.append(folderPrefix(folder));
    QVariantList result;
    for (const QVariant &track : tracks) {
        const QString path = normalizedPath(track.toMap().value("filePath").toString());
        if (std::any_of(prefixes.cbegin(), prefixes.cend(), [&](const QString &p) { return path.startsWith(p); }))
            result.append(track);
    }
    return result;
}

// Matches saved queue, history, and playlist entries, which may be file URLs or differently separated paths.
QString pathKey(QString path) {
    path = path.trimmed();
    if (path.isEmpty() || path.startsWith('#'))
        return {};
    if (path.startsWith(QStringLiteral("file:"), Qt::CaseInsensitive))
        path = QUrl(path).toLocalFile();
    return normalizedPath(path);
}

// Favorites are stored under the lowercased path QML's toggleFavorite() writes, or under the raw path.
QString favoriteKey(const QString &path) {
    return pathKey(path).toLower();
}

// Same identity the QML queue uses to treat one song in several files as a single entry.
QString trackIdentity(const QVariantMap &track) {
    QString title = track.value("title").toString();
    if (title.isEmpty())
        title = track.value("fileName").toString();
    title = title.trimmed().toLower();
    if (title.isEmpty())
        return track.value("filePath").toString();
    return title + QChar(0x1f) + track.value("artist").toString().trimmed().toLower() + QChar(0x1f) +
           track.value("album").toString().trimmed().toLower();
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

QStringList splitArtists(const QString &artist) {
    static const QRegularExpression separator(
        QStringLiteral("\\s*(?:[,&;/]|(?:\\b(?:feat|ft)\\b\\.?)|\\bfeaturing\\b)\\s*"),
        QRegularExpression::CaseInsensitiveOption);
    const QString value = artist.trimmed();
    if (value.isEmpty())
        return {QStringLiteral("Unknown Artist")};
    const QStringList parts = value.split(separator, Qt::SkipEmptyParts);
    QStringList result;
    for (const QString &p : parts) {
        const QString trimmed = p.trimmed();
        if (!trimmed.isEmpty() && !result.contains(trimmed, Qt::CaseInsensitive))
            result.append(trimmed);
    }
    return result.isEmpty() ? QStringList{value} : result;
}

QString sortKey(const QString &value) {
    static const QRegularExpression leadingArticle(QStringLiteral(R"(^\s*['"\[\({#._-]*(?:the|an|a)['"\]\)}#._-]*\s+)"),
                                                   QRegularExpression::CaseInsensitiveOption);
    QString clean = value;
    const auto match = leadingArticle.match(clean);
    if (match.hasMatch()) {
        clean = clean.mid(match.capturedLength());
    }
    int start = 0;
    while (start < clean.size()) {
        const QChar ch = clean.at(start);
        if (ch == '\'' || ch == '"' || ch == '[' || ch == '(' || ch == '{' || ch == ']' || ch == ')' || ch == '}' ||
            ch == '#' || ch == '.' || ch == '-' || ch == '_' || ch.isSpace()) {
            ++start;
        } else {
            break;
        }
    }
    if (start > 0)
        clean = clean.mid(start);
    int end = clean.size();
    while (end > 0) {
        const QChar ch = clean.at(end - 1);
        if (ch == '\'' || ch == '"' || ch == '[' || ch == '(' || ch == '{' || ch == ']' || ch == ')' || ch == '}' ||
            ch == '#' || ch == '.' || ch == '-' || ch == '_' || ch.isSpace()) {
            --end;
        } else {
            break;
        }
    }
    if (end < clean.size())
        clean = clean.left(end);
    const QString lower = clean.toLower();
    return lower.isEmpty() ? value.toLower() : lower;
}

int symbolOrNumberCategory(const QString &key) {
    if (key.isEmpty())
        return 0;
    return key.at(0).isLetter() ? 1 : 0;
}

int compareSortKeys(const QString &left, const QString &right) {
    const QString keyA = sortKey(left);
    const QString keyB = sortKey(right);
    const int catA = symbolOrNumberCategory(keyA);
    const int catB = symbolOrNumberCategory(keyB);
    if (catA != catB)
        return catA - catB;
    return QString::localeAwareCompare(keyA, keyB);
}

int logYear(const QJsonObject &entry) {
    return QDateTime::fromMSecsSinceEpoch(static_cast<qint64>(entry.value("at").toDouble())).date().year();
}

QList<QJsonObject> readListeningLog(const QByteArray &log) {
    QList<QJsonObject> entries;
    for (const QByteArray &line : log.split('\n')) {
        const QJsonObject entry = QJsonDocument::fromJson(line).object();
        if (!entry.value("path").toString().isEmpty() && entry.value("at").toDouble() > 0)
            entries.append(entry);
    }
    return entries;
}

QVariantMap recapFromLog(const QByteArray &log, int year, int month) {
    struct Tally {
        QVariantMap item;
        int plays = 0;
        qint64 listenedMs = 0;
    };
    const auto add = [](QHash<QString, Tally> &tallies, QList<QString> &order, const QString &key,
                        const QVariantMap &item, qint64 ms) {
        if (!tallies.contains(key)) {
            order.append(key);
            tallies.insert(key, Tally{item});
        }
        Tally &tally = tallies[key];
        ++tally.plays;
        tally.listenedMs += ms;
    };
    const auto ranked = [](const QHash<QString, Tally> &tallies, const QList<QString> &order, int limit) {
        QList<Tally> list;
        for (const QString &key : order)
            list.append(tallies.value(key));
        std::stable_sort(list.begin(), list.end(), [](const Tally &a, const Tally &b) {
            return a.plays != b.plays ? a.plays > b.plays : a.listenedMs > b.listenedMs;
        });
        QVariantList result;
        for (qsizetype i = 0; i < qMin<qsizetype>(limit, list.size()); ++i) {
            QVariantMap item = list[i].item;
            item.insert("plays", list[i].plays);
            item.insert("listenedMs", list[i].listenedMs);
            result.append(item);
        }
        return result;
    };

    QHash<QString, Tally> songs, artists, albums, genres;
    QList<QString> songOrder, artistOrder, albumOrder, genreOrder;
    QVariantList months(12, 0.0);
    int plays = 0;
    qint64 listenedMs = 0;
    qint64 firstListen = 0;
    for (const QJsonObject &entry : readListeningLog(log)) {
        if (logYear(entry) != year)
            continue;
        const qint64 at = static_cast<qint64>(entry.value("at").toDouble());
        const qint64 ms = static_cast<qint64>(entry.value("ms").toDouble());
        // The monthly totals always cover the whole year, so a month view can still offer the others.
        const int entryMonth = QDateTime::fromMSecsSinceEpoch(at).date().month() - 1;
        months[entryMonth] = months[entryMonth].toDouble() + ms;
        if (month >= 0 && entryMonth != month)
            continue;
        const QVariantMap track{{"filePath", entry.value("path").toString()},
                                {"title", entry.value("title").toString()},
                                {"artist", entry.value("artist").toString()},
                                {"album", entry.value("album").toString()},
                                {"genre", entry.value("genre").toString()}};
        ++plays;
        listenedMs += ms;
        firstListen = firstListen == 0 ? at : qMin(firstListen, at);

        add(songs, songOrder, pathKey(track.value("filePath").toString()), {{"track", track}}, ms);
        for (const QString &artist : splitArtists(track.value("artist").toString()))
            add(artists, artistOrder, artist.toLower(), {{"name", artist}, {"track", track}}, ms);
        const QString album = track.value("album").toString().trimmed();
        if (!album.isEmpty())
            add(albums, albumOrder, album.toLower(), {{"name", album}, {"track", track}}, ms);
        const QString genre = track.value("genre").toString().trimmed();
        if (!genre.isEmpty())
            add(genres, genreOrder, genre.toLower(), {{"name", genre}}, ms);
    }

    int busiestMonth = -1;
    for (int i = 0; i < 12; ++i) {
        if (months[i].toDouble() > 0 && (busiestMonth < 0 || months[i].toDouble() > months[busiestMonth].toDouble()))
            busiestMonth = i;
    }
    return {{"year", year},
            {"month", month},
            {"plays", plays},
            {"listenedMs", listenedMs},
            {"songCount", songOrder.size()},
            {"artistCount", artistOrder.size()},
            {"firstListen", firstListen},
            {"topSongs", ranked(songs, songOrder, 10)},
            {"topArtists", ranked(artists, artistOrder, 10)},
            {"topAlbums", ranked(albums, albumOrder, 5)},
            {"topGenres", ranked(genres, genreOrder, 3)},
            {"months", months},
            {"busiestMonth", busiestMonth}};
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
                const QString custom = customArtwork(path);
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
        saveLibraryCache();
        emit changed();
        emit tracksChanged();
        emit visibleTracksChanged();
    });

    QStringList savedFolders = SettingsController::globalValue("library/folders").toStringList();
    if (savedFolders.isEmpty())
        savedFolders = {SettingsController::globalValue("library/folder").toString()};
    savedFolders.removeAll(QString());
    m_folders = savedFolders;

    loadLibraryCache();

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

    if (splitArtists(QStringLiteral("21 Savage & Metro Boomin")) !=
        QStringList{QStringLiteral("21 Savage"), QStringLiteral("Metro Boomin")})
        return fail("splitArtists collaborate");
    if (splitArtists(QStringLiteral("A feat. B, C; D / E featuring F")) !=
        QStringList{QStringLiteral("A"), QStringLiteral("B"), QStringLiteral("C"), QStringLiteral("D"),
                    QStringLiteral("E"), QStringLiteral("F")})
        return fail("splitArtists delimiters");
    if (sortKey(QStringLiteral("The Beatles")) != QStringLiteral("beatles") ||
        sortKey(QStringLiteral("\"A\" Hero")) != QStringLiteral("hero"))
        return fail("sortKey stripping");
    if (compareSortKeys(QStringLiteral("1989"), QStringLiteral("Abbey Road")) >= 0 ||
        compareSortKeys(QStringLiteral("The Beatles"), QStringLiteral("Bee Gees")) >= 0)
        return fail("compareSortKeys order");
    if (compareSortKeys(QStringLiteral("Émile"), QStringLiteral("1989")) <= 0 ||
        compareSortKeys(QStringLiteral("Кино"), QStringLiteral("#1 Hits")) <= 0)
        return fail("compareSortKeys unicode letters");
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
    const QVariantList found =
        library.tracksForPaths({"C:\\Music\\keep.flac", "C:/Music/hidden/song.mp3", "#comment", "C:/Music/keep.flac"});
    if (found.size() != 4 || found[0].toMap().value("title") != "Keep" || !found[1].toMap().isEmpty() ||
        !found[2].toMap().isEmpty() || found[3].toMap().value("title") != "Keep")
        return fail("tracks for paths");
#ifdef Q_OS_WIN
    if (library.tracksForPaths({"file:///C:/Music/ALTERNATE.wav"}).value(0).toMap().value("title") != "Alternate")
        return fail("tracks for file urls");
#endif
    if (library.availablePaths() != QStringList{"C:/Music/keep.flac", "C:/Music/alternate.wav"})
        return fail("available paths");
    const QVariantMap home = library.homeRecommendations(
        {{"C:/Music/keep.flac", 3}}, {{"C:/Music/keep.flac", 50}, {"C:/Music/alternate.wav", 100}},
        {{"C:/Music/alternate.wav", true}}, {QVariantMap{{"filePath", "C:\\Music\\keep.flac"}, {"title", "Keep"}}});
    const auto titles = [&](const char *shelf) {
        QStringList result;
        for (const QVariant &track : home.value(shelf).toList())
            result.append(track.toMap().value("title").toString());
        return result;
    };
    if (titles("quickPicks") != QStringList{"Alternate"} || titles("heavyRotation") != QStringList{"Keep"})
        return fail("home shelves");
    if (titles("recentlyPlayed") != QStringList{"Keep"} || titles("recentlyAdded") != QStringList{"Alternate", "Keep"})
        return fail("home history shelves");
    if (!titles("forgottenFavs").isEmpty() || home.value("spotlight").toMap().value("title") != "Alternate")
        return fail("home recommendations");
    if (library.data(library.index(0, 0), TrackRole).toMap().value("filePath").toString() != "C:/Music/alternate.wav")
        return fail("library sort");
    library.setLibraryFilter({}, "FAVORITES", {{"c:/music/keep.flac", true}}, "title", true, {"C:/Music/hidden"}, true);
    if (library.visibleTrackCount() != 1)
        return fail("normalized favorites");

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
    const QVariantList candidates = {QVariantMap{{"filePath", "/Music/Live/song.flac"}},
                                     QVariantMap{{"filePath", "/Music/Live Sessions/song.flac"}}};
    const QVariantList inside = tracksInFolders(candidates, {"/Music/Live"});
    if (inside.size() != 1 || inside[0].toMap().value("filePath") != "/Music/Live/song.flac")
        return fail("folder membership");
    const auto logLine = [](const QString &date, const QString &path, const QString &artist, qint64 ms) {
        QJsonObject entry{{"path", path}, {"title", path}, {"artist", artist}, {"album", "Album"}};
        entry.insert("at", QDateTime::fromString(date, Qt::ISODate).toMSecsSinceEpoch());
        entry.insert("genre", "Pop");
        entry.insert("ms", ms);
        return QJsonDocument(entry).toJson(QJsonDocument::Compact) + '\n';
    };
    const QByteArray log = logLine("2026-03-10T12:00:00", "a.flac", "Ann & Bo", 60000) +
                           logLine("2026-03-11T12:00:00", "a.flac", "Ann & Bo", 30000) +
                           logLine("2026-07-01T12:00:00", "b.flac", "Ann", 200000) +
                           logLine("2025-12-31T12:00:00", "c.flac", "Cy", 90000) + "not json\n";
    const QVariantMap recap = recapFromLog(log, 2026, -1);
    const QVariantList topSongs = recap.value("topSongs").toList();
    const QVariantList topArtists = recap.value("topArtists").toList();
    if (recap.value("plays").toInt() != 3 || recap.value("listenedMs").toLongLong() != 290000 ||
        recap.value("songCount").toInt() != 2 || recap.value("artistCount").toInt() != 2 ||
        topSongs.value(0).toMap().value("track").toMap().value("filePath") != "a.flac" ||
        topArtists.value(0).toMap().value("name") != "Ann" || topArtists.value(0).toMap().value("plays") != 3 ||
        recap.value("busiestMonth").toInt() != 6)
        return fail("listening recap");
    const QVariantMap march = recapFromLog(log, 2026, 2);
    if (march.value("plays").toInt() != 2 || march.value("listenedMs").toLongLong() != 90000 ||
        march.value("months").toList().value(6).toDouble() != 200000)
        return fail("monthly listening recap");

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
    const QString custom = customArtwork(filePath);
    if (!custom.isEmpty()) {
        m_artworkUrls.insert(filePath, custom);
        return custom;
    }
    const QString artworkUrl = CoverImageProvider::urlFor(filePath);
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
            for (int r = 0; r < m_visibleRows.size(); ++r) {
                if (m_visibleRows[r] == i) {
                    const QModelIndex idx = index(r, 0);
                    emit dataChanged(idx, idx, {TrackRole});
                    break;
                }
            }
            break;
        }
    }
    emit changed();
    emit tracksChanged();
}

void LibraryController::setAlbumArtwork(const QString &album, const QString &artist, const QString &artworkPath) {
    if (album.isEmpty() || artworkPath.isEmpty())
        return;
    bool hasChanges = false;
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
                hasChanges = true;
                for (int r = 0; r < m_visibleRows.size(); ++r) {
                    if (m_visibleRows[r] == i) {
                        const QModelIndex idx = index(r, 0);
                        emit dataChanged(idx, idx, {TrackRole});
                        break;
                    }
                }
            }
        }
    }
    if (hasChanges) {
        emit changed();
        emit tracksChanged();
    }
}

QVariantList LibraryController::tracksForPaths(const QVariantList &paths) const {
    QHash<QString, QList<int>> wanted;
    for (int i = 0; i < paths.size(); ++i) {
        const QString key = pathKey(paths[i].toString());
        if (!key.isEmpty())
            wanted[key].append(i);
    }
    QVariantList result(paths.size(), QVariantMap());
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        const auto match = wanted.constFind(pathKey(track.value("filePath").toString()));
        if (match == wanted.cend() || !isAvailable(track))
            continue;
        for (int index : *match)
            result[index] = track;
    }
    return result;
}

int LibraryController::compareNames(const QString &left, const QString &right) const {
    return compareSortKeys(left, right);
}

void LibraryController::recordListen(const QVariantMap &track, qint64 listenedMs) {
    const QString path = track.value("filePath").toString();
    if (path.isEmpty() || listenedMs <= 0)
        return;
    const QJsonObject entry{{"at", QDateTime::currentMSecsSinceEpoch()},
                            {"path", path},
                            {"title", track.value("title").toString()},
                            {"artist", track.value("artist").toString()},
                            {"album", track.value("album").toString()},
                            {"genre", track.value("genre").toString()},
                            {"ms", listenedMs}};
    QFile file(listeningLogFilePath());
    if (!file.open(QIODevice::Append)) {
        qWarning() << "Could not record listen:" << file.errorString();
        return;
    }
    file.write(QJsonDocument(entry).toJson(QJsonDocument::Compact) + '\n');
}

QVariantList LibraryController::listeningYears() const {
    QFile file(listeningLogFilePath());
    if (!file.open(QIODevice::ReadOnly))
        return {};
    QList<int> years;
    for (const QJsonObject &entry : readListeningLog(file.readAll())) {
        if (!years.contains(logYear(entry)))
            years.append(logYear(entry));
    }
    std::sort(years.begin(), years.end(), std::greater<>());
    QVariantList result;
    for (int year : years)
        result.append(year);
    return result;
}

QVariantMap LibraryController::listeningRecap(int year, int month) const {
    QFile file(listeningLogFilePath());
    return recapFromLog(file.open(QIODevice::ReadOnly) ? file.readAll() : QByteArray(), year, month);
}

void LibraryController::clearListeningLog() {
    QFile::remove(listeningLogFilePath());
}

QStringList LibraryController::availablePaths() const {
    QStringList paths;
    paths.reserve(m_trackCount);
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        if (isAvailable(track))
            paths.append(track.value("filePath").toString());
    }
    return paths;
}

QVariantMap LibraryController::homeRecommendations(const QVariantMap &playCounts, const QVariantMap &seenAt,
                                                   const QVariantMap &favorites, const QVariantList &history) const {
    const auto path = [](const QVariantMap &track) { return track.value("filePath").toString(); };
    QList<QVariantMap> tracks;
    QHash<QString, QVariantMap> tracksByIdentity;
    // Every available file maps to the one track shown for its identity, keyed like saved history paths.
    QHash<QString, QVariantMap> tracksByPath;
    for (const QVariant &value : m_tracks) {
        const QVariantMap track = value.toMap();
        const QString identity = trackIdentity(track);
        if (!isAvailable(track) || identity.isEmpty())
            continue;
        if (!tracksByIdentity.contains(identity)) {
            tracksByIdentity.insert(identity, track);
            tracks.append(track);
        }
        tracksByPath.insert(pathKey(path(track)), tracksByIdentity.value(identity));
    }

    QSet<QString> played;
    for (const QVariant &value : history)
        played.insert(trackIdentity(value.toMap()));
    QSet<QString> favoriteKeys;
    for (auto it = favorites.cbegin(); it != favorites.cend(); ++it) {
        if (it.value().toBool())
            favoriteKeys.insert(favoriteKey(it.key()));
    }

    QList<QVariantMap> unplayed;
    QList<QVariantMap> ranked;
    QList<QVariantMap> added;
    QList<QVariantMap> forgotten;
    for (const QVariantMap &track : std::as_const(tracks)) {
        const bool wasPlayed = played.contains(trackIdentity(track));
        if (!wasPlayed)
            unplayed.append(track);
        if (playCounts.value(path(track)).toInt() > 0)
            ranked.append(track);
        if (seenAt.value(path(track)).toDouble() > 0)
            added.append(track);
        if (!wasPlayed && favoriteKeys.contains(favoriteKey(path(track))))
            forgotten.append(track);
    }

    QRandomGenerator *random = QRandomGenerator::global();
    std::shuffle(unplayed.begin(), unplayed.end(), *random);
    // Shuffle first so tracks with equal play counts do not always appear in library order.
    std::shuffle(ranked.begin(), ranked.end(), *random);
    std::stable_sort(ranked.begin(), ranked.end(), [&](const QVariantMap &left, const QVariantMap &right) {
        return playCounts.value(path(left)).toInt() > playCounts.value(path(right)).toInt();
    });
    std::stable_sort(added.begin(), added.end(), [&](const QVariantMap &left, const QVariantMap &right) {
        return seenAt.value(path(left)).toDouble() > seenAt.value(path(right)).toDouble();
    });

    QList<QVariantMap> recentlyPlayed;
    QSet<QString> recentIdentities;
    for (const QVariant &value : history) {
        const QVariantMap track = tracksByPath.value(pathKey(path(value.toMap())));
        if (!track.isEmpty() && !recentIdentities.contains(trackIdentity(track))) {
            recentIdentities.insert(trackIdentity(track));
            recentlyPlayed.append(track);
        }
    }

    const auto shelf = [](const QList<QVariantMap> &list, qsizetype limit) {
        QVariantList result;
        for (qsizetype i = 0; i < qMin(limit, list.size()); ++i)
            result.append(list[i]);
        return result;
    };
    return {{"spotlight", unplayed.isEmpty() ? QVariantMap() : unplayed.first()},
            {"quickPicks", shelf(unplayed, 8)},
            {"heavyRotation", shelf(ranked, 10)},
            {"recentlyPlayed", shelf(recentlyPlayed, 10)},
            {"recentlyAdded", shelf(added, 10)},
            {"forgottenFavs", forgotten.size() >= 3 ? shelf(forgotten, 10) : QVariantList()}};
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

        const QStringList trackArtists = splitArtists(track.value("artist").toString());
        for (const QString &artist : trackArtists) {
            add(artists, artist, track, {{"name", artist}});
        }

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
        if (!value.toString().isEmpty())
            folders.append(folderPrefix(value.toString()));
    }

    QSet<QString> favoritePaths;
    for (auto it = favorites.cbegin(); it != favorites.cend(); ++it) {
        if (it.value().toBool())
            favoritePaths.insert(favoriteKey(it.key()));
    }

    const bool availabilityChanged = m_excludedFolders != folders || m_ignoreShortClips != ignoreShortClips;
    const bool favoritesChanged = favoritesOnly && (m_favorites != favoritePaths);
    if (m_query == query && m_format == format && m_strictFormat == strictFormat && m_favoritesOnly == favoritesOnly &&
        !favoritesChanged && m_sortMetric == sortMetric && m_sortAscending == ascending &&
        m_excludedFolders == folders && m_ignoreShortClips == ignoreShortClips) {
        m_favorites = std::move(favoritePaths);
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
    if (m_favoritesOnly && !m_favorites.contains(favoriteKey(track.value("filePath").toString())))
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
            result = compareSortKeys(a.value("artist").toString(), b.value("artist").toString());
            if (result == 0)
                result = compareSortKeys(a.value("title").toString(), b.value("title").toString());
        } else if (m_sortMetric == "album") {
            result = compareSortKeys(a.value("album").toString(), b.value("album").toString());
            if (result == 0) {
                const int trackA = a.value("trackNumber").toInt();
                const int trackB = b.value("trackNumber").toInt();
                if (trackA > 0 && trackB > 0 && trackA != trackB)
                    result = trackA - trackB;
                else
                    result = compareSortKeys(a.value("title").toString(), b.value("title").toString());
            }
        } else {
            const QString aTitle =
                a.value("title").toString().isEmpty() ? a.value("fileName").toString() : a.value("title").toString();
            const QString bTitle =
                b.value("title").toString().isEmpty() ? b.value("fileName").toString() : b.value("title").toString();
            result = compareSortKeys(aTitle, bTitle);
            if (result == 0)
                result = compareSortKeys(a.value("artist").toString(), b.value("artist").toString());
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
    const bool foldersChanged = (m_folders != paths);
    ++m_scanGeneration;
    m_folders = std::move(paths);

    if (m_tracks.isEmpty()) {
        loadLibraryCache();
    } else if (foldersChanged) {
        const QVariantList retained = tracksInFolders(m_tracks, m_folders);
        if (retained.size() != m_tracks.size()) {
            beginResetModel();
            m_tracks = retained;
            rebuildVisibleRows();
            endResetModel();
            saveLibraryCache();
        }
    }

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

void LibraryController::loadLibraryCache() {
    const QString cachePath = libraryCacheFilePath();
    QFile file(cachePath);
    if (!file.open(QIODevice::ReadOnly))
        return;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isArray())
        return;

    // Folders can be removed while tracks are cached, so only tracks inside a current folder are restored.
    QVariantList list = tracksInFolders(doc.toVariant().toList(), m_folders);
    if (list.isEmpty())
        return;

    for (QVariant &item : list) {
        QVariantMap track = item.toMap();
        const QString path = track.value("filePath").toString();
        const QString custom = customArtwork(path);
        const QString cached = track.value("artworkUrl").toString();
        if (!custom.isEmpty())
            track.insert("artworkUrl", custom);
        else if (cached.startsWith("file:") && !QFileInfo::exists(QUrl(cached).toLocalFile()))
            track.remove("artworkUrl");
        item = track;
    }

    beginResetModel();
    m_tracks = list;
    rebuildVisibleRows();
    endResetModel();
    emit tracksChanged();
    emit visibleTracksChanged();
}

void LibraryController::saveLibraryCache() {
    const QString cachePath = libraryCacheFilePath();
    QSaveFile file(cachePath);
    if (!file.open(QIODevice::WriteOnly))
        return;
    const QJsonDocument doc = QJsonDocument::fromVariant(m_tracks);
    file.write(doc.toJson(QJsonDocument::Compact));
    file.commit();
}
