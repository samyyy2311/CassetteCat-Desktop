import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Effects

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    minimumWidth: 720
    minimumHeight: 480
    title: "CassetteCat"
    color: surfaceBase
    flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint

    Material.theme: Material.Dark
    Material.accent: recordRed

    readonly property color recordRed: "#C23B30"
    readonly property color recordRedHover: "#D64337"
    readonly property color surfaceBase: "#0E0D0C"
    readonly property color surfaceSidebar: "#131211"
    readonly property color surfaceDock: "#151412"
    readonly property color surfaceCard: "#181715"
    readonly property color surfaceCardHover: "#22201D"
    readonly property color surfaceElevated: "#282623"
    readonly property color surfaceInput: "#1A1917"
    readonly property color surfaceTag: "#22201E"
    readonly property color silver: "#C4C4C0"
    readonly property color silverDim: "#6E6C68"
    readonly property color textPrimary: "#F5F0EC"
    readonly property color textSecondary: "#8E8A84"
    readonly property color borderSubtle: "#22201D"
    readonly property color borderVariant: "#2C2926"

    readonly property string displayFont: "Space Grotesk"
    readonly property string bodyFont: "IBM Plex Sans"
    readonly property string monoFont: "IBM Plex Mono"

    property bool settingsInitialized: false
    property string page: "home"
    property string libraryTab: "songs"
    property string libraryViewMode: "grid"
    property string songFilterMode: "ALL"
    property string songSortMetric: "title"
    property bool songSortAscending: true
    property string artistSortMetric: "name"
    property bool artistSortAscending: true
    property string albumSortMetric: "album"
    property bool albumSortAscending: true
    property string genreSortMetric: "count"
    property bool genreSortAscending: false
    property string folderSortMetric: "name"
    property bool folderSortAscending: true
    property bool refineSheetOpen: false
    property string libSearchQuery: ""
    property bool libSearchVisible: false
    property string searchQuery: ""
    property string activeFormatFilter: "ALL"
    property bool nowPlayingOpen: false
    property bool catalogDetailOpen: false
    property string catalogDetailMode: "artist"
    property string catalogDetailTitle: ""
    property var catalogDetailTracks: []
    property var catalogDetailHeroTrack: ({})
    property string nowPlayingMode: "controls" // "controls", "lyrics", "queue"
    property bool sidebarCollapsed: false
    property var favoriteTracks: ({})
    property int repeatMode: 0 // 0: Off, 1: Repeat All, 2: Repeat One
    property var playbackQueue: []
    property var originalPlaybackQueue: []
    property bool playbackQueueRestored: false
    property var playbackHistory: []
    property bool playbackHistoryRestored: false
    property var historyTrackedTrack: null
    property double historyAccumulatedMs: 0
    property double historyPlayingSince: 0
    property bool historyRecordedForTrack: false
    property int queueRevision: 0
    property bool playbackPending: false
    readonly property bool playerVisuallyPlaying: player.isPlaying || playbackPending

    readonly property bool miniPlayerMode: miniPlayerWindow ? miniPlayerWindow.visible : false
    property bool miniPlayerAlwaysOnTop: true
    property bool resumeQueueOnLaunch: true
    property int lyricsFontSize: 28
    property bool lastTrackRestored: false
    property bool playerStateDirty: false

    property var parsedLyrics: parseLrc(player.currentLyrics)
    property int activeLyricIndex: -1
    property var lyricDisplayItems: buildLyricDisplayItems(parsedLyrics)
    property int activeLyricDisplayIndex: -1
    property string lyricsProvider: ""
    property int lyricsSyncOffsetMs: 0
    property bool lyricSearchOpen: false
    property bool lyricSearchLoading: false
    property var lyricSearchResults: []
    property string lyricSearchQuery: ""
    property bool lyricCustomEditorOpen: false
    property string lyricCustomText: ""

    function trackIdentity(track) {
        if (!track) return ""
        const title = String(track.title || track.fileName || "").trim().toLowerCase()
        const artist = String(track.artist || "").trim().toLowerCase()
        const album = String(track.album || "").trim().toLowerCase()
        return title ? title + "\u001f" + artist + "\u001f" + album : String(track.filePath || "")
    }

    function uniqueTracks(source) {
        const seen = {}
        return (source || []).filter(track => {
            const key = trackIdentity(track)
            if (!key || seen[key]) return false
            seen[key] = true
            return true
        })
    }

    readonly property var queueEntries: {
        queueRevision
        const entries = []
        if (playbackHistory.length) {
            entries.push({ type: "header", title: "HISTORY" })
            playbackHistory.slice().reverse().forEach(track => entries.push({ type: "track", track: track, title: track.title, fileName: track.fileName, filePath: track.filePath, artist: track.artist, album: track.album, duration: track.duration }))
        }
        if (player.currentTrack && player.currentTrack.filePath) {
            entries.push({ type: "header", title: "NOW PLAYING" })
            entries.push({ type: "current", track: player.currentTrack, title: player.currentTrack.title, fileName: player.currentTrack.fileName, filePath: player.currentTrack.filePath, artist: player.currentTrack.artist, album: player.currentTrack.album, duration: player.currentTrack.duration })
        }
        const queue = playbackQueue.length ? playbackQueue : uniqueTracks(tracks)
        const currentIndex = currentQueueIndex()
        const upcoming = currentIndex >= 0 ? queue.slice(currentIndex + 1) : queue
        if (upcoming.length) {
            entries.push({ type: "header", title: "UP NEXT" })
            upcoming.forEach(track => entries.push({ type: "track", track: track, title: track.title, fileName: track.fileName, filePath: track.filePath, artist: track.artist, album: track.album, duration: track.duration }))
        }
        return entries
    }

    property var radioStations: []
    property string radioSearchQuery: ""
    property string radioActiveTag: "ALL"
    property string radioCountryFilter: ""
    property string radioLanguageFilter: ""
    property string radioSortOrder: "votes"
    property bool radioSortDescending: true
    property bool radioRefineOpen: false
    readonly property bool radioIsCustomized: radioActiveTag !== "ALL" || radioCountryFilter.length > 0 || radioLanguageFilter.length > 0 || radioSortOrder !== "votes" || !radioSortDescending

    Connections {
        target: services
        function onLyricsFetched(title, artist, lyrics, provider) {
            if (player.currentTrack) {
                const curTitle = player.currentTrack.title || player.currentTrack.fileName || ""
                if (curTitle.toLowerCase() === title.toLowerCase() || (player.currentTrack.artist && player.currentTrack.artist.toLowerCase() === artist.toLowerCase())) {
                    applyLyrics(lyrics, provider)
                }
            }
        }
        function onLyricsSearchResultsReady(results) {
            lyricSearchLoading = false
            lyricSearchResults = results || []
        }
        function onRadioStationsLoaded(stations) {
            radioStations = stations
        }
    }

    Component.onCompleted: {
        const savedW = appSettings.value("window/width", 1120)
        const savedH = appSettings.value("window/height", 720)
        if (savedW > 400) window.width = savedW
        if (savedH > 300) window.height = savedH

        const isMaximized = appSettings.value("window/maximized", false)
        if (isMaximized) {
            window.showMaximized()
        }

        page = appSettings.value("ui/page", "home")
        window.libraryTab = appSettings.value("ui/libraryTab", "songs")
        libraryViewMode = appSettings.value("ui/libraryViewMode", "grid")
        sidebarCollapsed = appSettings.value("ui/sidebarCollapsed", false)
        libSearchQuery = appSettings.value("library/searchQuery", "")
        searchQuery = appSettings.value("search/query", "")
        activeFormatFilter = appSettings.value("search/formatFilter", "ALL")
        radioSearchQuery = appSettings.value("radio/searchQuery", "")
        radioActiveTag = appSettings.value("radio/activeTag", "ALL")
        radioCountryFilter = appSettings.value("radio/country", "")
        radioLanguageFilter = appSettings.value("radio/language", "")
        radioSortOrder = appSettings.value("radio/sortOrder", "votes")
        radioSortDescending = appSettings.value("radio/sortDescending", true)
        nowPlayingOpen = appSettings.value("player/nowPlayingOpen", false)
        nowPlayingMode = appSettings.value("player/nowPlayingMode", "controls")
        miniPlayerAlwaysOnTop = appSettings.value("ui/miniPlayerAlwaysOnTop", true)
        resumeQueueOnLaunch = appSettings.value("player/resumeQueueOnLaunch", true)
        lyricsFontSize = appSettings.value("lyrics/fontSize", 28)

        songSortMetric = appSettings.value("sort/songMetric", "title")
        songSortAscending = appSettings.value("sort/songAscending", true)
        artistSortMetric = appSettings.value("sort/artistMetric", "name")
        artistSortAscending = appSettings.value("sort/artistAscending", true)
        albumSortMetric = appSettings.value("sort/albumMetric", "album")
        albumSortAscending = appSettings.value("sort/albumAscending", true)
        genreSortMetric = appSettings.value("sort/genreMetric", "count")
        genreSortAscending = appSettings.value("sort/genreAscending", false)
        folderSortMetric = appSettings.value("sort/folderMetric", "name")
        folderSortAscending = appSettings.value("sort/folderAscending", true)
        songFilterMode = appSettings.value("sort/songFilterMode", "ALL")

        repeatMode = appSettings.value("player/repeatMode", 0)
        if (typeof player.setVolume !== "undefined") {
            player.setVolume(appSettings.value("player/volume", 1.0))
        }
        if (typeof player.setShuffleEnabled !== "undefined") {
            player.setShuffleEnabled(appSettings.value("player/shuffleEnabled", false))
        }

        try {
            const favStr = appSettings.value("library/favorites", "{}")
            favoriteTracks = JSON.parse(favStr || "{}")
        } catch (e) {
            favoriteTracks = {}
        }



        refreshHomeRecommendations()
        settingsInitialized = true

        restoreLastPlayedTrack()
        restorePlaybackQueue()
        restorePlaybackHistory()
        Qt.callLater(refreshRadio)
    }

    function restoreLastPlayedTrack() {
        if (!resumeQueueOnLaunch || lastTrackRestored || !library.tracks || library.tracks.length === 0) return
        lastTrackRestored = true

        const lastTrackPath = appSettings.value("player/lastTrack", "")
        if (lastTrackPath) {
            for (let i = 0; i < library.tracks.length; i++) {
                if (library.tracks[i].filePath === lastTrackPath) {
                    const lastPos = appSettings.value("player/lastPosition", 0)
                    player.restoreTrack(library.tracks[i], lastPos)
                    break
                }
            }
        }
    }

    function persistPlayerState() {
        if (!settingsInitialized || !player.currentTrack || !player.currentTrack.filePath) return
        appSettings.setValues({
            "player/lastTrack": player.currentTrack.filePath,
            "player/lastPosition": Math.max(0, player.position)
        })
    }

    function restorePlaybackHistory() {
        if (playbackHistoryRestored || !tracks.length) return
        playbackHistoryRestored = true
        playbackHistory = restoredTracks("player/history").slice(0, 50)
    }

    function restorePlaybackQueue() {
        if (!resumeQueueOnLaunch || playbackQueueRestored || !tracks.length) return
        playbackQueueRestored = true
        playbackQueue = restoredTracks("player/queue")
        originalPlaybackQueue = restoredTracks("player/originalQueue")
        if (!originalPlaybackQueue.length) originalPlaybackQueue = playbackQueue.slice()
    }

    function restoredTracks(key) {
        try {
            const savedPaths = JSON.parse(appSettings.value(key, "[]") || "[]")
            const tracksByPath = {}
            tracks.forEach(track => tracksByPath[track.filePath] = track)
            return uniqueTracks(savedPaths.map(path => tracksByPath[path]).filter(track => !!track))
        } catch (e) {
            return []
        }
    }

    function savedTrackPaths(trackList) {
        return JSON.stringify((trackList || []).map(track => track.filePath).filter(path => !!path))
    }

    function resetHistoryTracking(track) {
        historyTrackedTrack = track && track.filePath ? track : null
        historyAccumulatedMs = 0
        historyPlayingSince = player.isPlaying && historyTrackedTrack ? Date.now() : 0
        historyRecordedForTrack = false
    }

    function pauseHistoryTracking() {
        if (historyPlayingSince > 0) historyAccumulatedMs += Date.now() - historyPlayingSince
        historyPlayingSince = 0
        recordHistoryIfQualified()
    }

    function resumeHistoryTracking() {
        const current = player.currentTrack
        if (!current || !current.filePath) return
        if (!historyTrackedTrack || historyTrackedTrack.filePath !== current.filePath) resetHistoryTracking(current)
        if (!historyRecordedForTrack) historyPlayingSince = Date.now()
    }

    function recordHistoryIfQualified() {
        if (historyRecordedForTrack || !historyTrackedTrack || historyAccumulatedMs < 30000) return
        historyRecordedForTrack = true
        playbackHistory = [historyTrackedTrack].concat(playbackHistory.filter(track => track.filePath !== historyTrackedTrack.filePath)).slice(0, 50)
    }

    function finishHistoryTracking() {
        pauseHistoryTracking()
        historyTrackedTrack = null
    }

    function refreshRadio() {
        services.fetchRadioStations(
            radioSearchQuery,
            radioCountryFilter,
            radioLanguageFilter,
            radioActiveTag === "ALL" ? "" : radioActiveTag,
            radioSortOrder,
            radioSortDescending)
    }

    function dismissSearchFocus(point) {
        const contains = function(item) {
            return item.visible && item.contains(item.mapFromItem(appArea, point.x, point.y))
        }
        if (contains(searchInputBox) || contains(pageSearchBox) || contains(radioSearchBox)) return
        libSearchInput.focus = false
        pageSearchInput.focus = false
        radSearchInput.focus = false
    }

    onPageChanged: {
        if (settingsInitialized) appSettings.setValue("ui/page", page)
        dismissSearchFocus(Qt.point(-1, -1))
    }
    onLibraryTabChanged: if (settingsInitialized) {
        appSettings.setValue("ui/libraryTab", window.libraryTab)
        if (typeof libSearchInput !== "undefined") libSearchInput.focus = false
    }
    onLibraryViewModeChanged: if (settingsInitialized) appSettings.setValue("ui/libraryViewMode", libraryViewMode)
    onSidebarCollapsedChanged: if (settingsInitialized) appSettings.setValue("ui/sidebarCollapsed", sidebarCollapsed)
    onLibSearchQueryChanged: if (settingsInitialized) appSettings.setValue("library/searchQuery", libSearchQuery)
    onSearchQueryChanged: if (settingsInitialized) appSettings.setValue("search/query", searchQuery)
    onActiveFormatFilterChanged: if (settingsInitialized) appSettings.setValue("search/formatFilter", activeFormatFilter)
    onRadioSearchQueryChanged: if (settingsInitialized) appSettings.setValue("radio/searchQuery", radioSearchQuery)
    onRadioActiveTagChanged: if (settingsInitialized) appSettings.setValue("radio/activeTag", radioActiveTag)
    onRadioCountryFilterChanged: if (settingsInitialized) appSettings.setValue("radio/country", radioCountryFilter)
    onRadioLanguageFilterChanged: if (settingsInitialized) appSettings.setValue("radio/language", radioLanguageFilter)
    onRadioSortOrderChanged: if (settingsInitialized) appSettings.setValue("radio/sortOrder", radioSortOrder)
    onRadioSortDescendingChanged: if (settingsInitialized) appSettings.setValue("radio/sortDescending", radioSortDescending)
    onMiniPlayerAlwaysOnTopChanged: {
        if (settingsInitialized) appSettings.setValue("ui/miniPlayerAlwaysOnTop", miniPlayerAlwaysOnTop)
        if (miniPlayerWindow && miniPlayerWindow.visible) player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
    }
    onResumeQueueOnLaunchChanged: if (settingsInitialized) appSettings.setValue("player/resumeQueueOnLaunch", resumeQueueOnLaunch)
    onLyricsFontSizeChanged: if (settingsInitialized) appSettings.setValue("lyrics/fontSize", lyricsFontSize)
    onLyricsSyncOffsetMsChanged: if (settingsInitialized) {
        if (player.currentTrack && player.currentTrack.filePath) appSettings.setValue(lyricsSyncKey(player.currentTrack), lyricsSyncOffsetMs)
        parsedLyrics = parseLrc(player.currentLyrics)
        updateActiveLyric()
    }

    onSongSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/songMetric", songSortMetric)
    onSongSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/songAscending", songSortAscending)
    onArtistSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/artistMetric", artistSortMetric)
    onArtistSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/artistAscending", artistSortAscending)
    onAlbumSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/albumMetric", albumSortMetric)
    onAlbumSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/albumAscending", albumSortAscending)
    onGenreSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/genreMetric", genreSortMetric)
    onGenreSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/genreAscending", genreSortAscending)
    onFolderSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/folderMetric", folderSortMetric)
    onFolderSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/folderAscending", folderSortAscending)
    onSongFilterModeChanged: if (settingsInitialized) appSettings.setValue("sort/songFilterMode", songFilterMode)

    onFavoriteTracksChanged: if (settingsInitialized) appSettings.setValue("library/favorites", JSON.stringify(favoriteTracks))
    onPlaybackQueueChanged: if (settingsInitialized) appSettings.setValue("player/queue", savedTrackPaths(playbackQueue))
    onOriginalPlaybackQueueChanged: if (settingsInitialized) appSettings.setValue("player/originalQueue", savedTrackPaths(originalPlaybackQueue))
    onPlaybackHistoryChanged: {
        if (settingsInitialized) appSettings.setValue("player/history", savedTrackPaths(playbackHistory))
        refreshHomeRecommendations()
    }
    onRepeatModeChanged: if (settingsInitialized) appSettings.setValue("player/repeatMode", repeatMode)

    onVisibilityChanged: {
        if (settingsInitialized) {
            const isMax = (window.visibility === Window.Maximized)
            appSettings.setValue("window/maximized", isMax)
            if (!isMax && window.width > 400 && window.height > 300) {
                appSettings.setValue("window/width", window.width)
                appSettings.setValue("window/height", window.height)
            }
        }
    }

    onWidthChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.width > 400) {
        appSettings.setValue("window/width", window.width)
    }
    onHeightChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.height > 300) {
        appSettings.setValue("window/height", window.height)
    }
    onClosing: {
        finishHistoryTracking()
        persistPlayerState()
        appSettings.sync()
    }

    function toggleMiniPlayer() {
        if (!miniPlayerWindow.visible) {
            miniPlayerWindow.x = Math.max(20, window.x + Math.round((window.width - miniPlayerWindow.width) / 2))
            miniPlayerWindow.y = Math.max(20, window.y + Math.round((window.height - miniPlayerWindow.height) / 2))
            miniPlayerWindow.visible = true
            player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
            miniPlayerWindow.requestActivate()
            window.showMinimized()
        } else {
            miniPlayerWindow.visible = false
            window.showNormal()
            window.raise()
            window.requestActivate()
        }
    }

    Shortcut {
        sequence: "Ctrl+Shift+M"
        onActivated: toggleMiniPlayer()
    }

    Shortcut {
        sequence: "Ctrl+M"
        onActivated: toggleMiniPlayer()
    }

    Shortcut {
        sequence: "Ctrl+B"
        onActivated: {
            if (!miniPlayerMode) sidebarCollapsed = !sidebarCollapsed
        }
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            if (!miniPlayerMode) {
                nowPlayingOpen = false
                page = "search"
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (miniPlayerMode) {
                toggleMiniPlayer()
            } else if (nowPlayingOpen) {
                nowPlayingOpen = false
            }
        }
    }

    Shortcut {
        sequence: "Space"
        onActivated: {
            if (!player.currentTrack.filePath && tracks.length > 0) {
                shuffleAll()
            } else {
                player.togglePlay()
            }
        }
    }

    function toggleMaximize() {
        if (miniPlayerMode) return
        if (window.visibility === Window.Maximized) {
            window.showNormal()
        } else {
            window.showMaximized()
        }
    }

    function toggleFavorite(filePath) {
        if (!filePath) return
        const favs = Object.assign({}, favoriteTracks)
        if (favs[filePath]) {
            delete favs[filePath]
        } else {
            favs[filePath] = true
        }
        favoriteTracks = favs
    }

    function isFavorite(filePath) {
        return !!favoriteTracks[filePath]
    }

    function toggleRepeat() {
        repeatMode = (repeatMode + 1) % 3
    }

    function parseLrc(rawLyrics) {
        if (!rawLyrics || typeof rawLyrics !== "string") return []
        const lines = rawLyrics.split(/\r?\n/)
        const result = []

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue

            // Metadata tags look timed, but do not belong in the lyric list.
            if (/^\[[a-zA-Z]+:.*\]$/.test(line)) continue

            const m = line.match(/^\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\](.*)$/)
            if (m) {
                const mins = parseInt(m[1], 10) || 0
                const secs = parseInt(m[2], 10) || 0
                let ms = 0
                if (m[3]) {
                    const frac = m[3]
                    if (frac.length === 1) ms = parseInt(frac, 10) * 100
                    else if (frac.length === 2) ms = parseInt(frac, 10) * 10
                    else ms = parseInt(frac.substring(0, 3), 10)
                }
                const timeMs = Math.max(0, (mins * 60 + secs) * 1000 + ms + lyricsSyncOffsetMs)
                const text = (m[4] || "").trim()
                if (text.length > 0) {
                    result.push({ timeMs: timeMs, text: text })
                }
            } else {
                result.push({ timeMs: -1, text: line })
            }
        }

        if (result.length > 0 && result[0].timeMs >= 0) {
            result.sort(function(a, b) { return a.timeMs - b.timeMs })
        }
        return result
    }

    function lyricsSyncKey(track) {
        return "lyrics/sync/" + encodeURIComponent((track && track.filePath) || "")
    }

    function buildLyricDisplayItems(lines) {
        if (!lines || lines.length === 0 || lines[0].timeMs < 0) return []
        const items = []
        if (lines[0].timeMs >= 4500) items.push({ type: "gap", startMs: 0, endMs: lines[0].timeMs - 150 })
        for (let i = 0; i < lines.length; ++i) {
            const line = lines[i]
            const next = lines[i + 1]
            items.push({ type: "line", lineIndex: i, startMs: line.timeMs, text: line.text })
            const words = String(line.text || "").trim().split(/\s+/).filter(word => word.length > 0).length
            if (next && next.timeMs - line.timeMs >= 8000) {
                const vocalMs = Math.min(Math.max(1500, Math.min(5000, words * 280 + 600)), Math.max(1500, next.timeMs - line.timeMs - 2000))
                const gapStart = line.timeMs + vocalMs + 300
                const gapEnd = next.timeMs - 150
                if (gapEnd - gapStart >= 4000) items.push({ type: "gap", startMs: gapStart, endMs: gapEnd })
            } else if (!next && player.duration > 0) {
                const gapStart = line.timeMs + Math.max(1800, Math.min(4500, words * 260 + 500)) + 400
                const gapEnd = player.duration - 500
                if (gapEnd - gapStart >= 6000) items.push({ type: "gap", startMs: gapStart, endMs: gapEnd })
            }
        }
        return items
    }

    function updateActiveLyric() {
        if (!parsedLyrics || parsedLyrics.length === 0) {
            activeLyricIndex = -1
            activeLyricDisplayIndex = -1
            return
        }
        if (parsedLyrics[0].timeMs < 0) {
            activeLyricIndex = -1
            activeLyricDisplayIndex = -1
            return
        }

        const pos = player.position
        let idx = -1
        for (let i = 0; i < parsedLyrics.length; i++) {
            if (pos >= parsedLyrics[i].timeMs - 200) {
                idx = i
            } else {
                break
            }
        }
        activeLyricIndex = idx
        let displayIndex = -1
        for (let i = 0; i < lyricDisplayItems.length; ++i) {
            if (pos >= lyricDisplayItems[i].startMs) displayIndex = i
            else break
        }
        if (displayIndex !== activeLyricDisplayIndex) {
            activeLyricDisplayIndex = displayIndex
            if (lyricsListView && displayIndex >= 0) lyricsListView.currentIndex = displayIndex
        }
    }

    function lyricHtml(text) {
        return String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    function karaokeLyricHtml(index, text) {
        if (index !== activeLyricIndex || !parsedLyrics[index] || parsedLyrics[index].timeMs < 0) return lyricHtml(text)
        const words = String(text || "").split(/(\s+)/)
        const start = parsedLyrics[index].timeMs
        const next = parsedLyrics[index + 1] && parsedLyrics[index + 1].timeMs >= 0 ? parsedLyrics[index + 1].timeMs : start + 3000
        const progress = Math.max(0, Math.min(1, (player.position - start) / Math.max(800, next - start)))
        const characters = Math.max(1, String(text || "").replace(/\s/g, "").length)
        let consumed = 0
        return words.map(function(word) {
            if (/^\s+$/.test(word)) return word
            const middle = (consumed + word.length * 0.5) / characters
            consumed += word.length
            const t = Math.max(0, Math.min(1, (progress - middle + 0.16) / 0.16))
            const eased = t * t * (3 - 2 * t)
            const alpha = 0.42 + eased * 0.58
            return "<span style=\"color:rgba(255,255,255," + alpha.toFixed(2) + ")\">" + lyricHtml(word) + "</span>"
        }).join("")
    }

    function applyLyrics(lyrics, provider) {
        player.setCurrentLyrics(lyrics || "")
        lyricsProvider = provider || ""
        parsedLyrics = parseLrc(lyrics || "")
        activeLyricIndex = -1
        activeLyricDisplayIndex = -1
        if (lyricsListView) {
            lyricsListView.currentIndex = -1
            lyricsListView.contentY = 0
        }
        updateActiveLyric()
    }

    function loadLyricsForTrack(track) {
        lyricsSyncOffsetMs = appSettings.value(lyricsSyncKey(track), 0)
        const local = services.localLyricsFor(track.filePath)
        const embedded = track.lyrics || player.getLyrics(track.filePath)
        if (local && local.trim().length) {
            applyLyrics(local, "Local file")
        } else if (embedded && embedded.trim().length) {
            applyLyrics(embedded, "Embedded metadata")
        } else {
            applyLyrics("", "")
            services.fetchLyrics(track.title || track.fileName || "", track.artist || "", track.album || "", track.durationSeconds || 0)
        }
    }

    function searchLyricsOnline() {
        const query = lyricSearchQuery.trim()
        if (!query) return
        lyricSearchLoading = true
        lyricSearchResults = []
        const currentTitle = String(player.currentTrack.title || player.currentTrack.fileName || "").trim().toLowerCase()
        services.searchLyrics(query, query.toLowerCase() === currentTitle ? (player.currentTrack.artist || "") : "")
    }

    function openLyricsSearch() {
        lyricSearchOpen = true
        lyricCustomEditorOpen = false
        lyricCustomText = ""
        lyricSearchQuery = player.currentTrack.title || player.currentTrack.fileName || ""
        searchLyricsOnline()
    }

    onNowPlayingOpenChanged: {
        if (settingsInitialized) appSettings.setValue("player/nowPlayingOpen", nowPlayingOpen)
        if (nowPlayingOpen) {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
    }

    onNowPlayingModeChanged: {
        if (settingsInitialized) appSettings.setValue("player/nowPlayingMode", nowPlayingMode)
        if (nowPlayingMode === "lyrics") {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
            if (lyricsListView && activeLyricIndex >= 0) {
                lyricsListView.currentIndex = activeLyricIndex
            }
        }
    }

    function getDynamicGreeting() {
        const hour = new Date().getHours()
        if (hour >= 4 && hour < 7) return "Early dawn"
        if (hour >= 7 && hour < 11) return "Good morning"
        if (hour >= 11 && hour < 14) return "Midday groove"
        if (hour >= 14 && hour < 17) return "Afternoon flow"
        if (hour >= 17 && hour < 20) return "Good evening"
        if (hour >= 20 && hour < 23) return "Night listening"
        return "Midnight vibes"
    }

    function getDynamicGreetingSubtitle() {
        const hour = new Date().getHours()
        if (hour >= 4 && hour < 7) return "Quiet hours and mellow tunes"
        if (hour >= 7 && hour < 11) return "Start your day with high-fidelity sound"
        if (hour >= 11 && hour < 14) return "Your midday listening session"
        if (hour >= 14 && hour < 17) return "Focus mode and soundtrack for work"
        if (hour >= 17 && hour < 20) return "Unwind with your favorite albums"
        if (hour >= 20 && hour < 23) return "Evening warmth and deep cuts"
        return "Late night tracks in rotation"
    }

    readonly property string greeting: getDynamicGreeting()
    readonly property string greetingSubtitle: getDynamicGreetingSubtitle()
    readonly property var tracks: library.tracks || []

    property var spotlightTrack: null
    property var quickPicks: []
    property var heavyRotation: []

    function refreshSpotlight(source) {
        const candidates = source || uniqueTracks(tracks)
        if (candidates.length > 0) {
            spotlightTrack = candidates[Math.floor(Math.random() * candidates.length)]
        } else {
            spotlightTrack = null
        }
    }

    function refreshHomeRecommendations() {
        if (!tracks || tracks.length === 0) {
            quickPicks = []
            heavyRotation = []
            spotlightTrack = null
            return
        }

        const played = {}
        playbackHistory.forEach(track => played[trackIdentity(track)] = true)
        const candidates = uniqueTracks(tracks).filter(track => !played[trackIdentity(track)])
        refreshSpotlight(candidates)

        const shuffled = candidates.slice()
        for (let i = shuffled.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1))
            const temp = shuffled[i]
            shuffled[i] = shuffled[j]
            shuffled[j] = temp
        }

        quickPicks = shuffled.slice(0, Math.min(8, shuffled.length))

        if (shuffled.length > 8) {
            heavyRotation = shuffled.slice(8, Math.min(24, shuffled.length))
        } else {
            heavyRotation = shuffled.slice(0, shuffled.length)
        }
    }

    onTracksChanged: {
        refreshHomeRecommendations()
        restoreLastPlayedTrack()
        restorePlaybackQueue()
        restorePlaybackHistory()
    }

    readonly property var filteredTracks: {
        const query = searchQuery.trim().toLowerCase()
        return tracks.filter(track => {
            if (activeFormatFilter !== "ALL") {
                const fmt = (track.format || "").toUpperCase()
                if (activeFormatFilter === "FLAC" && fmt !== "FLAC" && fmt !== "WAV" && fmt !== "ALAC") return false
                if (activeFormatFilter === "MP3" && fmt !== "MP3") return false
                if (activeFormatFilter === "AAC" && fmt !== "AAC" && fmt !== "M4A") return false
            }
            if (!query) return true
            return (track.title || "").toLowerCase().includes(query)
                || (track.artist || "").toLowerCase().includes(query)
                || (track.album || "").toLowerCase().includes(query)
        })
    }

    function extractPrimaryArtist(raw) {
        if (!raw) return "Unknown Artist"
        const str = raw.trim()
        if (!str) return "Unknown Artist"
        const match = str.split(/[,&;/]|\bfeat\.?\b|\bft\.?\b/i)
        if (match && match.length > 0 && match[0].trim().length > 0) {
            return match[0].trim()
        }
        return str
    }

    function getArtistGroups() {
        const groups = {}
        tracks.forEach(track => {
            const primaryName = extractPrimaryArtist(track.artist)
            if (!groups[primaryName]) {
                groups[primaryName] = { name: primaryName, count: 0, track: track }
            }
            groups[primaryName].count++
        })
        return Object.keys(groups).map(name => groups[name])
    }

    function getAlbumGroups() {
        const groups = {}
        tracks.forEach(track => {
            const name = track.album || "Unknown Album"
            if (!groups[name]) groups[name] = { name: name, count: 0, track: track }
            groups[name].count++
        })
        return Object.keys(groups).map(name => groups[name])
    }

    function minimizeWindow() {
        window.showMinimized()
    }

    function openCatalogDetail(mode, title, heroTrack) {
        catalogDetailMode = mode
        catalogDetailTitle = title
        catalogDetailHeroTrack = heroTrack
        catalogDetailTracks = tracks.filter(track => mode === "artist"
            ? extractPrimaryArtist(track.artist) === title
            : (track.album || "Unknown Album") === title)
        catalogDetailOpen = true
    }


    function getGenreGroups() {
        const groups = {}
        tracks.forEach(track => {
            const gName = (track.genre && track.genre.trim().length > 0) ? track.genre.trim() : "Soundtrack"
            if (!groups[gName]) {
                groups[gName] = { name: gName, count: 0, track: track }
            }
            groups[gName].count++
        })
        return Object.keys(groups).map(name => groups[name])
    }

    function getFolderGroups() {
        const groups = {}
        tracks.forEach(track => {
            if (!track.filePath) return
            const cleanPath = track.filePath.replace(/\\/g, "/")
            const lastSlash = cleanPath.lastIndexOf("/")
            const folderPath = lastSlash !== -1 ? cleanPath.substring(0, lastSlash) : "Music"
            const fName = folderPath.substring(folderPath.lastIndexOf("/") + 1) || "Music"
            if (!groups[folderPath]) {
                groups[folderPath] = { name: fName, path: folderPath, count: 0, track: track }
            }
            groups[folderPath].count++
        })
        return Object.keys(groups).map(path => groups[path])
    }

    function getFilteredSongs() {
        let result = tracks.slice()

        if (songFilterMode === "FAVORITES") {
            result = result.filter(t => favoriteTracks && favoriteTracks[t.filePath])
        } else if (songFilterMode === "FLAC") {
            result = result.filter(t => (t.format || "").toUpperCase() === "FLAC")
        } else if (songFilterMode === "MP3") {
            result = result.filter(t => (t.format || "").toUpperCase() === "MP3")
        } else if (songFilterMode === "AAC") {
            result = result.filter(t => {
                const f = (t.format || "").toUpperCase()
                return f === "AAC" || f === "M4A"
            })
        }

        if (libSearchQuery.trim().length > 0) {
            const q = libSearchQuery.toLowerCase().trim()
            result = result.filter(t => {
                const title = (t.title || t.fileName || "").toLowerCase()
                const artist = (t.artist || "").toLowerCase()
                const album = (t.album || "").toLowerCase()
                return title.includes(q) || artist.includes(q) || album.includes(q)
            })
        }

        result.sort((a, b) => {
            let res = 0
            if (songSortMetric === "title") {
                res = (a.title || a.fileName || "").localeCompare(b.title || b.fileName || "")
            } else if (songSortMetric === "artist") {
                res = (a.artist || "").localeCompare(b.artist || "")
            } else if (songSortMetric === "album") {
                res = (a.album || "").localeCompare(b.album || "")
            } else if (songSortMetric === "duration") {
                res = (a.durationSeconds || 0) - (b.durationSeconds || 0)
            }
            return songSortAscending ? res : -res
        })

        return result
    }

    readonly property var artists: getArtistGroups().sort((a, b) => a.name.localeCompare(b.name))
    readonly property var albums: getAlbumGroups().sort((a, b) => a.name.localeCompare(b.name))
    readonly property var artistsRotation: getArtistGroups().sort((a, b) => b.count - a.count).slice(0, 12)
    readonly property var albumsRotation: getAlbumGroups().sort((a, b) => b.count - a.count).slice(0, 12)

    function playTrack(track) {
        if (!track) return
        const index = tracks.findIndex(candidate => candidate.filePath === track.filePath)
        startPlayback(tracks, index >= 0 ? index : 0, player.shuffleEnabled)
    }

    function shuffledTracks(source) {
        const result = source.slice()
        for (let i = result.length - 1; i > 0; --i) {
            const j = Math.floor(Math.random() * (i + 1))
            const item = result[i]
            result[i] = result[j]
            result[j] = item
        }
        return result
    }

    function startPlayback(source, startIndex, shuffle) {
        if (!source || source.length === 0) return
        const requested = source[Math.max(0, Math.min(startIndex, source.length - 1))]
        const queue = uniqueTracks(source)
        if (!queue.length) return
        const index = Math.max(0, queue.findIndex(track => trackIdentity(track) === trackIdentity(requested)))
        originalPlaybackQueue = queue.slice()
        playbackQueue = shuffle
            ? [queue[index]].concat(shuffledTracks(queue.filter((_, candidateIndex) => candidateIndex !== index)))
            : queue.slice()
        playQueuedTrack(playbackQueue[shuffle ? 0 : index])
    }

    function currentQueueIndex() {
        const queue = playbackQueue.length ? playbackQueue : uniqueTracks(tracks)
        const filePath = player.currentTrack ? player.currentTrack.filePath : ""
        return queue.findIndex(track => track.filePath === filePath)
    }

    function playQueuedTrack(track) {
        if (!track) return
        if (!player.currentTrack || player.currentTrack.filePath !== track.filePath) finishHistoryTracking()
        playbackPending = true
        player.playTrack(track)
        loadLyricsForTrack(track)
        queueRevision++
    }

    function playFromQueue(track) {
        if (!track || !track.filePath) return
        playQueuedTrack(track)
    }

    function toggleQueueShuffle() {
        const queue = playbackQueue.length ? playbackQueue : uniqueTracks(tracks)
        if (queue.length < 2) return
        const currentIndex = currentQueueIndex()
        player.toggleShuffle()
        if (currentIndex < 0) return

        if (player.shuffleEnabled) {
            playbackQueue = queue.slice(0, currentIndex + 1).concat(shuffledTracks(queue.slice(currentIndex + 1)))
        } else {
            playbackQueue = originalPlaybackQueue.length ? originalPlaybackQueue.slice() : queue.slice()
        }
        queueRevision++
    }

    function playNext() {
        const queue = playbackQueue.length ? playbackQueue : uniqueTracks(tracks)
        if (!queue.length) return
        const currentIndex = currentQueueIndex()
        if (currentIndex < 0) {
            playQueuedTrack(queue[0])
        } else if (currentIndex < queue.length - 1) {
            playQueuedTrack(queue[currentIndex + 1])
        } else if (repeatMode === 1) {
            playQueuedTrack(queue[0])
        }
    }

    function playPrevious() {
        if (player.position > 5000) {
            player.seek(0)
            return
        }
        const queue = playbackQueue.length ? playbackQueue : uniqueTracks(tracks)
        const currentIndex = currentQueueIndex()
        if (currentIndex > 0) playQueuedTrack(queue[currentIndex - 1])
        else player.seek(0)
    }

    function shuffleAll() {
        const queue = uniqueTracks(tracks)
        if (!queue.length) return
        const randomIdx = Math.floor(Math.random() * queue.length)
        player.setShuffleEnabled(true)
        startPlayback(queue, randomIdx, true)
        refreshSpotlight()
    }

    Connections {
        target: player
        function onTrackEnded() {
            if (repeatMode === 2) {
                player.seek(0)
                player.play()
            } else {
                playNext()
            }
        }
        function onPositionChanged() {
            updateActiveLyric()
            playerStateDirty = true
        }
        function onCurrentLyricsChanged() {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
        function onCurrentTrackChanged() {
            resetHistoryTracking(player.currentTrack)
            lyricsSyncOffsetMs = appSettings.value(lyricsSyncKey(player.currentTrack), 0)
            parsedLyrics = parseLrc(player.currentLyrics)
            activeLyricIndex = -1
            activeLyricDisplayIndex = -1
            if (lyricsListView) {
                lyricsListView.currentIndex = -1
                lyricsListView.contentY = 0
            }
            updateActiveLyric()
            playerStateDirty = true
            persistPlayerState()
        }
        function onIsPlayingChanged() {
            if (player.isPlaying) playbackPending = false
            if (player.isPlaying) resumeHistoryTracking()
            else pauseHistoryTracking()
        }
        function onVolumeChanged() {
            if (settingsInitialized) appSettings.setValue("player/volume", player.volume)
        }
        function onShuffleEnabledChanged() {
            if (settingsInitialized) appSettings.setValue("player/shuffleEnabled", player.shuffleEnabled)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: player.isPlaying && !historyRecordedForTrack
        onTriggered: {
            if (historyPlayingSince > 0) historyAccumulatedMs += Date.now() - historyPlayingSince
            historyPlayingSince = Date.now()
            recordHistoryIfQualified()
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: playerStateDirty
        onTriggered: {
            persistPlayerState()
            playerStateDirty = false
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Choose your music folder"
        onAccepted: library.loadFolder(selectedFolder)
    }



    component NavItem: Item {
        id: navItem
        property string destination: "home"
        property string iconName: ""
        property string label: ""
        implicitWidth: sidebarPanel.width
        implicitHeight: 40
        width: sidebarPanel.width
        height: 40
        readonly property bool selected: page === destination && !nowPlayingOpen

        Rectangle {
            id: navCard
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: sidebarCollapsed ? 44 : 180
            height: 40
            radius: 8
            color: navItem.selected
                ? surfaceElevated
                : (navMouse.containsMouse ? surfaceCardHover : "transparent")
            border.width: navItem.selected ? 1 : 0
            border.color: navItem.selected ? borderVariant : "transparent"

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }

            // Active indicator pill on left edge
            Rectangle {
                visible: navItem.selected
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 16
                radius: 1.5
                color: recordRed
            }

            // In collapsed state (44px card): 12 + 20 + 12 = 44px (mathematically centered)
            // In expanded state (180px card): 14px left margin, text to right
            LucideIcon {
                id: navIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: sidebarCollapsed ? 12 : 14
                width: 20
                height: 20
                icon: navItem.iconName
                color: navItem.selected ? textPrimary : (navMouse.containsMouse ? textPrimary : silverDim)

                Behavior on anchors.leftMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Label {
                anchors.left: navIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: navItem.label
                color: navItem.selected ? textPrimary : (navMouse.containsMouse ? textPrimary : textSecondary)
                font.family: displayFont
                font.pixelSize: 13
                font.weight: navItem.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                visible: !sidebarCollapsed && opacity > 0.01
                opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 90) / (200 - 90)))
            }
        }

        MouseArea {
            id: navMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                nowPlayingOpen = false
                page = destination
            }
        }
    }

    component OutlineButton: Rectangle {
        id: outlineBtn
        property string text: ""
        property string iconName: ""
        property bool isPrimary: false
        property bool isActive: false
        signal clicked()

        implicitWidth: buttonContent.implicitWidth + 24
        implicitHeight: 34
        radius: height / 2
        color: outlineBtn.isActive
            ? surfaceElevated
            : (buttonMouse.containsMouse
                ? (isPrimary ? "#281816" : surfaceElevated)
                : (isPrimary ? "#1F1413" : surfaceCard))
        border.width: isPrimary || outlineBtn.isActive ? 1.5 : 1.0
        border.color: isPrimary
            ? (buttonMouse.containsMouse ? recordRedHover : recordRed)
            : (outlineBtn.isActive ? recordRed : (buttonMouse.containsMouse ? borderVariant : borderSubtle))

        Row {
            id: buttonContent
            anchors.centerIn: parent
            spacing: 8

            LucideIcon {
                visible: outlineBtn.iconName.length > 0
                width: 15
                height: 15
                anchors.verticalCenter: parent.verticalCenter
                icon: outlineBtn.iconName
                color: outlineBtn.isPrimary || outlineBtn.isActive ? recordRed : silver
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: outlineBtn.text
                color: outlineBtn.isPrimary
                    ? (buttonMouse.containsMouse ? "#FFFFFF" : recordRed)
                    : (outlineBtn.isActive ? textPrimary : (buttonMouse.containsMouse ? textPrimary : silver))
                font.family: displayFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: outlineBtn.clicked()
        }
    }

    component SectionHeader: Item {
        id: sectionHeaderRoot
        property string title: ""
        property string subtitle: ""
        signal playClicked()
        signal shuffleClicked()

        width: parent.width
        height: Math.max(38, headerCol.implicitHeight)

        ColumnLayout {
            id: headerCol
            anchors.left: parent.left
            anchors.right: buttonRow.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: sectionHeaderRoot.title
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 20
                font.weight: Font.Bold
                font.letterSpacing: -0.2
            }

            Label {
                Layout.fillWidth: true
                text: sectionHeaderRoot.subtitle
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 12
            }
        }

        Row {
            id: buttonRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            TransportButton {
                buttonSize: 36
                iconName: "play"
                accented: true
                iconColor: recordRed
                onClicked: sectionHeaderRoot.playClicked()
            }

            TransportButton {
                buttonSize: 36
                iconName: "shuffle"
                iconColor: textPrimary
                onClicked: sectionHeaderRoot.shuffleClicked()
            }
        }
    }

    MiniPlayerWindow {
        id: miniPlayerWindow
        playerVisuallyPlaying: window.playerVisuallyPlaying
        repeatMode: window.repeatMode
        favoriteTracks: window.favoriteTracks
        alwaysOnTop: miniPlayerAlwaysOnTop
        displayFont: window.displayFont
        bodyFont: window.bodyFont
        monoFont: window.monoFont
        tracksCount: window.tracks.length
        onRestoreRequested: toggleMiniPlayer()
        onCloseRequested: toggleMiniPlayer()
        onPlayPrevious: playPrevious()
        onPlayNext: playNext()
        onToggleRepeat: toggleRepeat()
        onToggleFavorite: filePath => toggleFavorite(filePath)
        onToggleAlwaysOnTop: {
            miniPlayerAlwaysOnTop = !miniPlayerAlwaysOnTop
            player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
        }
    }

    Rectangle {
        id: customTitleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 60
        color: surfaceSidebar
        z: 200

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: borderSubtle
        }

        MouseArea {
            anchors.left: topSidebarHeader.right
            anchors.right: headerActionRow.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            z: 0
            property point pressPos
            onPressed: mouse => {
                pressPos = Qt.point(mouse.x, mouse.y)
            }
            onPositionChanged: mouse => {
                const deltaX = Math.abs(mouse.x - pressPos.x)
                const deltaY = Math.abs(mouse.y - pressPos.y)
                if (deltaX > 4 || deltaY > 4) {
                    window.startSystemMove()
                }
            }
            onDoubleClicked: toggleMaximize()
        }

        Rectangle {
            id: topSidebarHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: sidebarPanel.width
            color: surfaceSidebar
            visible: !catalogDetailOpen

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: borderSubtle
            }

            Item {
                anchors.fill: parent

                Image {
                    id: brandLogo
                    anchors.verticalCenter: parent.verticalCenter
                    x: sidebarCollapsed ? Math.round((sidebarPanel.width - width) / 2) : 16
                    width: 28
                    height: 28
                    source: "qrc:/CassetteCat/assets/cassettecat_icon.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true

                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    MouseArea {
                        id: brandMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            nowPlayingOpen = false
                            page = "home"
                        }
                    }
                }

                Label {
                    anchors.left: brandLogo.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CassetteCat"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    font.letterSpacing: -0.2
                    elide: Text.ElideRight
                    visible: !sidebarCollapsed && opacity > 0.01
                    opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 90) / (200 - 90)))
                }
            }
        }

        Item {
            anchors.left: topSidebarHeader.right
            anchors.right: headerActionRow.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            visible: !catalogDetailOpen
            z: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 16

                Label {
                    text: page === "home" ? "Home" : page === "library" ? "Library" : page === "radio" ? "Radio" : page === "search" ? "Search" : "Settings"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
            }
        }

        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: headerActionRow.left
            anchors.rightMargin: 16
            spacing: 14
            visible: catalogDetailOpen
            z: 20

            PressDepthIconButton {
                boxSize: 34
                iconSize: 17
                iconName: "chevron-down"
                rotation: 90
                tint: textPrimary
                tooltipText: "Back"
                onClicked: catalogDetailOpen = false
            }

            Label {
                Layout.fillWidth: true
                text: catalogDetailTitle
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 20
                font.weight: Font.Bold
                font.letterSpacing: -0.3
                elide: Text.ElideRight
            }
        }

        Row {
            id: headerActionRow
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            z: 10

            Row {
                id: winControlRow
                height: 60

                Rectangle {
                    id: minBtn
                    width: 48
                    height: 60
                    color: minBtnMouse.containsMouse ? surfaceElevated : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "—"
                        color: minBtnMouse.containsMouse ? textPrimary : silverDim
                        font.family: displayFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: minBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: window.showMinimized()
                    }
                }

                Rectangle {
                    id: maxBtn
                    width: 48
                    height: 60
                    color: maxBtnMouse.containsMouse ? surfaceElevated : "transparent"

                    Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10

                        Rectangle {
                            anchors.fill: parent
                            visible: window.visibility !== Window.Maximized
                            color: "transparent"
                            border.width: 1.2
                            border.color: maxBtnMouse.containsMouse ? textPrimary : silverDim
                            radius: 1
                        }

                        Item {
                            anchors.fill: parent
                            visible: window.visibility === Window.Maximized

                            Rectangle {
                                x: 2
                                y: 0
                                width: 8
                                height: 8
                                color: "transparent"
                                border.width: 1.2
                                border.color: maxBtnMouse.containsMouse ? textPrimary : silverDim
                                radius: 1
                            }

                            Rectangle {
                                x: 0
                                y: 2
                                width: 8
                                height: 8
                                color: maxBtnMouse.containsMouse ? surfaceElevated : surfaceSidebar
                                border.width: 1.2
                                border.color: maxBtnMouse.containsMouse ? textPrimary : silverDim
                                radius: 1
                            }
                        }
                    }

                    MouseArea {
                        id: maxBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: toggleMaximize()
                    }
                }

                Rectangle {
                    id: closeBtn
                    width: 48
                    height: 60
                    color: closeBtnMouse.containsMouse ? recordRed : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeBtnMouse.containsMouse ? "#FFFFFF" : silverDim
                        font.family: displayFont
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.ArrowCursor
                        onClicked: window.close()
                    }
                }
            }
        }
    }

    Item {
        visible: window.visibility !== Window.Maximized
        anchors.fill: parent
        z: 300

        MouseArea {
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; height: 4
            cursorShape: Qt.SizeVerCursor
            onPressed: window.startSystemResize(Qt.TopEdge)
        }
        MouseArea {
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 4
            cursorShape: Qt.SizeVerCursor
            onPressed: window.startSystemResize(Qt.BottomEdge)
        }
        MouseArea {
            anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4
            cursorShape: Qt.SizeHorCursor
            onPressed: window.startSystemResize(Qt.LeftEdge)
        }
        MouseArea {
            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; width: 4
            cursorShape: Qt.SizeHorCursor
            onPressed: window.startSystemResize(Qt.RightEdge)
        }
        MouseArea {
            anchors.left: parent.left; anchors.top: parent.top; width: 8; height: 8
            cursorShape: Qt.SizeFDiagCursor
            onPressed: window.startSystemResize(Qt.TopEdge | Qt.LeftEdge)
        }
        MouseArea {
            anchors.right: parent.right; anchors.top: parent.top; width: 8; height: 8
            cursorShape: Qt.SizeBDiagCursor
            onPressed: window.startSystemResize(Qt.TopEdge | Qt.RightEdge)
        }
        MouseArea {
            anchors.left: parent.left; anchors.bottom: parent.bottom; width: 8; height: 8
            cursorShape: Qt.SizeBDiagCursor
            onPressed: window.startSystemResize(Qt.BottomEdge | Qt.LeftEdge)
        }
        MouseArea {
            anchors.right: parent.right; anchors.bottom: parent.bottom; width: 8; height: 8
            cursorShape: Qt.SizeFDiagCursor
            onPressed: window.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }

    Item {
        id: appArea
        anchors.top: customTitleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Item {
            id: mainBodyArea
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: miniPlayerDock.top

            Rectangle {
                id: sidebarPanel
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: sidebarCollapsed ? 64 : 200
                color: surfaceSidebar
                clip: true

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    width: 1
                    color: borderSubtle
                }

                // Top Navigation Group
                Column {
                    id: navTopColumn
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    NavItem { destination: "home"; iconName: "house"; label: "Home" }
                    NavItem { destination: "library"; iconName: "music"; label: "Library" }
                    NavItem { destination: "radio"; iconName: "radio"; label: "Radio" }
                    NavItem { destination: "search"; iconName: "search"; label: "Search" }
                }

                // Bottom Controls Group
                Column {
                    id: navBottomColumn
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: sidebarCollapsed ? 28 : 170
                        height: 1
                        color: borderSubtle
                        opacity: 0.6
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    Item { width: 1; height: 2 }

                    NavItem { destination: "settings"; iconName: "settings"; label: "Settings" }

                    Item {
                        id: bottomToggleItem
                        width: sidebarPanel.width
                        height: 40

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: sidebarCollapsed ? 44 : 180
                            height: 40
                            radius: 8
                            color: toggleMouse.containsMouse ? surfaceCardHover : "transparent"

                            Behavior on color { ColorAnimation { duration: 120 } }

                            LucideIcon {
                                anchors.left: parent.left
                                anchors.leftMargin: sidebarCollapsed ? 12 : 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20
                                height: 20
                                icon: "panel-left"
                                color: toggleMouse.containsMouse ? textPrimary : silverDim

                                Behavior on anchors.leftMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 46
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Collapse"
                                color: toggleMouse.containsMouse ? textPrimary : textSecondary
                                font.family: displayFont
                                font.pixelSize: 13
                                visible: !sidebarCollapsed && opacity > 0.01
                                opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 90) / (200 - 90)))

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                        }

                        MouseArea {
                            id: toggleMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sidebarCollapsed = !sidebarCollapsed
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: contentPanel
                anchors.top: parent.top
                anchors.left: sidebarPanel.right
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                color: surfaceBase
                clip: true

                StackLayout {
                    anchors.fill: parent
                    currentIndex: page === "home" ? 0 : (page === "library" ? 1 : (page === "search" ? 2 : (page === "radio" ? 3 : 4)))

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScrollView {
                            id: homeScrollView
                            anchors.fill: parent
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical: SleekScrollBar {}
                            contentWidth: availableWidth
                            contentHeight: homeContentCol.implicitHeight + 48

                        Column {
                            id: homeContentCol
                            width: homeScrollView.availableWidth
                            spacing: 32
                            topPadding: 24
                            bottomPadding: 36

                            ColumnLayout {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                spacing: 4

                                Label {
                                    text: greeting.toUpperCase()
                                    color: recordRed
                                    font.family: monoFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.0
                                }

                                Label {
                                    text: greetingSubtitle
                                    color: textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.4
                                }

                                Label {
                                    text: tracks.length
                                        ? (tracks.length + " songs • " + artists.length + " artists • " + albums.length + " albums")
                                        : "Scan a music folder to populate your library"
                                    color: silverDim
                                    font.family: monoFont
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                id: heroCard
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                height: 175
                                radius: 12
                                color: surfaceCard
                                border.width: 1
                                border.color: heroCardMouse.containsMouse ? borderVariant : borderSubtle
                                visible: tracks.length > 0
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: heroMask
                                }

                                Item {
                                    id: heroMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "white"
                                    }
                                }

                                Cover {
                                    anchors.fill: parent
                                    track: spotlightTrack || (tracks.length ? tracks[0] : null)
                                    radius: 12
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#40000000" }
                                        GradientStop { position: 0.45; color: "#A00E0D0C" }
                                        GradientStop { position: 1.0; color: "#F00E0D0C" }
                                    }
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 22
                                    z: 2

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.right: heroShuffleBtn.left
                                        anchors.rightMargin: 16
                                        anchors.bottom: parent.bottom
                                        spacing: 3

                                        Label {
                                            text: "Shuffle your library"
                                            color: "#FFFFFF"
                                            font.family: displayFont
                                            font.pixelSize: 22
                                            font.weight: Font.Bold
                                        }

                                        Label {
                                            text: "Play something different from " + tracks.length + " songs"
                                            color: silver
                                            font.family: bodyFont
                                            font.pixelSize: 13
                                        }
                                    }

                                    TransportButton {
                                        id: heroShuffleBtn
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        buttonSize: 46
                                        iconName: "shuffle"
                                        accented: true
                                        iconColor: recordRed
                                        onClicked: shuffleAll()
                                    }
                                }

                                MouseArea {
                                    id: heroCardMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 200
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: 1
                                    onClicked: shuffleAll()
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: quickPicks.length > 0
                                spacing: 16

                                SectionHeader {
                                    title: "Start here"
                                    subtitle: "Handpicked from your library"
                                    onPlayClicked: {
                                        if (quickPicks.length > 0) playTrack(quickPicks[0])
                                    }
                                    onShuffleClicked: {
                                        refreshHomeRecommendations()
                                        if (quickPicks.length > 0) playTrack(quickPicks[0])
                                    }
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: quickPicks

                                    delegate: Item {
                                        width: 150
                                        height: 225

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 8

                                            Rectangle {
                                                id: qpCoverBox
                                                Layout.preferredWidth: 150
                                                Layout.preferredHeight: 150
                                                radius: 12
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1
                                                border.color: qpCardMouse.containsMouse ? borderVariant : borderSubtle
                                                scale: qpCardMouse.containsMouse ? 1.03 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData
                                                    radius: 12
                                                }

                                                TransportButton {
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    anchors.margins: 8
                                                    buttonSize: 38
                                                    iconName: "play"
                                                    accented: true
                                                    iconColor: recordRed
                                                    opacity: qpCardMouse.containsMouse ? 1.0 : 0.0
                                                    scale: qpCardMouse.containsMouse ? 1.0 : 0.6
                                                    z: 10

                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                    onClicked: playTrack(modelData)
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.title || modelData.fileName
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.artist || "Unknown Artist"
                                                color: textSecondary
                                                font.family: bodyFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }

                                            Item { Layout.fillHeight: true }
                                        }

                                        MouseArea {
                                            id: qpCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData)
                                        }
                                    }
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: heavyRotation.length > 0
                                spacing: 16

                                SectionHeader {
                                    title: "Heavy Rotation"
                                    subtitle: "Your most played tracks"
                                    onPlayClicked: {
                                        if (heavyRotation.length > 0) playTrack(heavyRotation[0])
                                    }
                                    onShuffleClicked: shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: heavyRotation

                                    delegate: Item {
                                        width: 150
                                        height: 225

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 8

                                            Rectangle {
                                                id: rotCoverBox
                                                Layout.preferredWidth: 150
                                                Layout.preferredHeight: 150
                                                radius: 12
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1
                                                border.color: songCardMouse.containsMouse ? borderVariant : borderSubtle
                                                scale: songCardMouse.containsMouse ? 1.03 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData
                                                    radius: 12
                                                }

                                                TransportButton {
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    anchors.margins: 8
                                                    buttonSize: 38
                                                    iconName: "play"
                                                    accented: true
                                                    iconColor: recordRed
                                                    opacity: songCardMouse.containsMouse ? 1.0 : 0.0
                                                    scale: songCardMouse.containsMouse ? 1.0 : 0.6
                                                    z: 10

                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                    onClicked: playTrack(modelData)
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.title || modelData.fileName
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.artist || "Unknown Artist"
                                                color: textSecondary
                                                font.family: bodyFont
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }

                                            Item { Layout.fillHeight: true }
                                        }

                                        MouseArea {
                                            id: songCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData)
                                        }
                                    }
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: albumsRotation.length > 0
                                spacing: 16

                                SectionHeader {
                                    title: "Albums in Rotation"
                                    subtitle: albums.length + " Total albums in library"
                                    onPlayClicked: {
                                        if (albumsRotation.length > 0) playTrack(albumsRotation[0].track)
                                    }
                                    onShuffleClicked: shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: albumsRotation

                                    delegate: Item {
                                        width: 150
                                        height: 225

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 8

                                            Rectangle {
                                                id: albCoverBox
                                                Layout.preferredWidth: 150
                                                Layout.preferredHeight: 150
                                                radius: 12
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1
                                                border.color: albumCardMouse.containsMouse ? borderVariant : borderSubtle
                                                scale: albumCardMouse.containsMouse ? 1.03 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData.track
                                                    radius: 12
                                                }

                                                TransportButton {
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    anchors.margins: 8
                                                    buttonSize: 38
                                                    iconName: "play"
                                                    accented: true
                                                    iconColor: recordRed
                                                    opacity: albumCardMouse.containsMouse ? 1.0 : 0.0
                                                    scale: albumCardMouse.containsMouse ? 1.0 : 0.6
                                                    z: 10

                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                    onClicked: playTrack(modelData.track)
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.count + " songs"
                                                color: silverDim
                                                font.family: monoFont
                                                font.pixelSize: 10
                                            }

                                            Item { Layout.fillHeight: true }
                                        }

                                        MouseArea {
                                            id: albumCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData.track)
                                        }
                                    }
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: artistsRotation.length > 0
                                spacing: 16

                                SectionHeader {
                                    title: "Artists"
                                    subtitle: artists.length + " Total artists in library"
                                    onPlayClicked: {
                                        if (artistsRotation.length > 0) playTrack(artistsRotation[0].track)
                                    }
                                    onShuffleClicked: shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 195
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: artistsRotation

                                    delegate: ArtistCard {
                                        cardWidth: 120
                                        cardHeight: 185
                                        name: modelData.name
                                        count: modelData.count
                                        track: modelData.track
                                        onClicked: openCatalogDetail("artist", modelData.name, modelData.track)
                                    }
                                }
                            }
                        }
                    }

                    AutoScroller {
                        id: homeAutoScroller
                        targetView: homeScrollView
                    }

                    MouseArea {
                        anchors.fill: homeScrollView
                        acceptedButtons: Qt.MiddleButton
                        cursorShape: Qt.ArrowCursor
                        z: 9998
                        onPressed: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                if (homeAutoScroller.active) homeAutoScroller.stop()
                                else homeAutoScroller.start(mouse.x, mouse.y)
                            }
                }
                        }
                    }

                    Item {
                        id: libraryRoot

                        readonly property var filteredSongsList: {
                            const filter = songFilterMode
                            const sortM = songSortMetric
                            const asc = songSortAscending
                            const q = libSearchQuery.toLowerCase().trim()
                            const favs = favoriteTracks
                            let list = tracks.slice()

                            if (filter === "FAVORITES") {
                                list = list.filter(t => favs && favs[t.filePath])
                            } else if (filter === "FLAC") {
                                list = list.filter(t => (t.format || "").toUpperCase() === "FLAC")
                            } else if (filter === "MP3") {
                                list = list.filter(t => (t.format || "").toUpperCase() === "MP3")
                            } else if (filter === "AAC") {
                                list = list.filter(t => {
                                    const f = (t.format || "").toUpperCase()
                                    return f === "AAC" || f === "M4A"
                                })
                            }

                            if (q.length > 0) {
                                list = list.filter(t => {
                                    const title = (t.title || t.fileName || "").toLowerCase()
                                    const artist = (t.artist || "").toLowerCase()
                                    const album = (t.album || "").toLowerCase()
                                    return title.includes(q) || artist.includes(q) || album.includes(q)
                                })
                            }

                            list.sort((a, b) => {
                                let res = 0
                                if (sortM === "title") {
                                    res = (a.title || a.fileName || "").localeCompare(b.title || b.fileName || "")
                                } else if (sortM === "artist") {
                                    res = (a.artist || "").localeCompare(b.artist || "")
                                } else if (sortM === "album") {
                                    res = (a.album || "").localeCompare(b.album || "")
                                } else if (sortM === "duration") {
                                    res = (a.durationSeconds || 0) - (b.durationSeconds || 0)
                                }
                                return asc ? res : -res
                            })
                            return list
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            RowLayout {
                                z: 100
                                Layout.fillWidth: true
                                Layout.leftMargin: 28
                                Layout.rightMargin: 28
                                Layout.topMargin: 16
                                Layout.bottomMargin: 14
                                spacing: 16

                                Row {
                                    spacing: 22
                                    Repeater {
                                        model: [
                                            { id: "songs", label: "Songs" },
                                            { id: "artists", label: "Artists" },
                                            { id: "albums", label: "Albums" },
                                            { id: "genres", label: "Genres" }
                                        ]

                                        Item {
                                            width: tabLbl.implicitWidth
                                            height: 32

                                            Label {
                                                id: tabLbl
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: libraryTab === modelData.id ? textPrimary : textSecondary
                                                font.family: displayFont
                                                font.pixelSize: 15
                                                font.weight: libraryTab === modelData.id ? Font.Bold : Font.Medium
                                            }

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.width
                                                height: 2.5
                                                radius: 1.25
                                                color: recordRed
                                                visible: libraryTab === modelData.id
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: window.libraryTab = modelData.id
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 22
                                    Layout.preferredWidth: countTagLbl.implicitWidth + 14
                                    radius: 11
                                    color: surfaceTag
                                    border.width: 1
                                    border.color: borderSubtle

                                    Label {
                                        id: countTagLbl
                                        anchors.centerIn: parent
                                        text: tracks.length + " songs"
                                        color: silverDim
                                        font.family: monoFont
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Row {
                                    spacing: 8
                                    visible: libraryTab === "songs"

                                    Repeater {
                                        model: [
                                            { id: "ALL", label: "ALL" },
                                            { id: "FAVORITES", label: "♥ FAVORITES" },
                                            { id: "FLAC", label: "FLAC" },
                                            { id: "MP3", label: "MP3" },
                                            { id: "AAC", label: "AAC" }
                                        ]

                                        Rectangle {
                                            id: qPill
                                            property bool isSelected: songFilterMode === modelData.id
                                            width: qPillLbl.implicitWidth + 20
                                            height: 28
                                            radius: 14
                                            color: "transparent"
                                            border.width: isSelected ? 1.5 : 1
                                            border.color: isSelected ? recordRed : (qPillMouse.containsMouse ? "#45FFFFFF" : "#282828")

                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            Label {
                                                id: qPillLbl
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: qPill.isSelected ? recordRedHover : (qPillMouse.containsMouse ? textPrimary : textSecondary)
                                                font.family: monoFont
                                                font.pixelSize: 11
                                                font.weight: qPill.isSelected ? Font.Bold : Font.DemiBold
                                            }

                                            MouseArea {
                                                id: qPillMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: songFilterMode = modelData.id
                                            }
                                        }
                                    }
                                }

                                PressDepthIconButton {
                                    visible: libraryTab === "songs"
                                    boxSize: 34
                                    iconSize: 16
                                    iconName: libraryViewMode === "grid" ? "grid-2x2" : "list-music"
                                    tint: textPrimary
                                    tooltipText: libraryViewMode === "grid" ? "Detailed Grid View (Click for List)" : "List View (Click for Grid)"
                                    onClicked: libraryViewMode = (libraryViewMode === "grid" ? "list" : "grid")
                                }

                                Rectangle {
                                    id: searchInputBox
                                    visible: libSearchVisible || libSearchQuery.length > 0
                                    Layout.preferredWidth: (libSearchVisible || libSearchQuery.length > 0) ? 175 : 0
                                    Layout.preferredHeight: 34
                                    radius: 17
                                    clip: true
                                    color: surfaceCard
                                    border.width: 1
                                    border.color: libSearchInput.activeFocus ? "#70FFFFFF" : (libSearchQuery.length > 0 ? "#45FFFFFF" : borderSubtle)
                                    z: 110

                                    Behavior on Layout.preferredWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 6

                                        LucideIcon {
                                            Layout.preferredWidth: 14
                                            Layout.preferredHeight: 14
                                            icon: "search"
                                            color: libSearchInput.activeFocus ? textPrimary : (libSearchQuery.length > 0 ? textPrimary : silverDim)
                                        }

                                        TextInput {
                                            id: libSearchInput
                                            Layout.fillWidth: true
                                            color: textPrimary
                                            font.family: displayFont
                                            font.pixelSize: 12
                                            selectByMouse: true
                                            text: libSearchQuery
                                            onTextChanged: libSearchQuery = text
                                            Keys.onEscapePressed: {
                                                libSearchInput.focus = false
                                                if (libSearchQuery.length === 0) libSearchVisible = false
                                            }
                                            Keys.onReturnPressed: {
                                                libSearchInput.focus = false
                                            }

                                            Text {
                                                anchors.fill: parent
                                                visible: !libSearchInput.text && !libSearchInput.activeFocus
                                                text: "Search library..."
                                                color: textSecondary
                                                font.family: displayFont
                                                font.pixelSize: 12
                                            }
                                        }

                                        Label {
                                            visible: libSearchInput.text.length > 0
                                            text: "×"
                                            color: textPrimary
                                            font.pixelSize: 15
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    libSearchInput.text = ""
                                                    libSearchQuery = ""
                                                    libSearchInput.focus = false
                                                    libSearchVisible = false
                                                }
                                            }
                                        }
                                    }
                                }

                                PressDepthIconButton {
                                    visible: !libSearchVisible && libSearchQuery.length === 0
                                    boxSize: 34
                                    iconSize: 16
                                    iconName: "search"
                                    tint: textPrimary
                                    tooltipText: "Search Library"
                                    highlighted: false
                                    onClicked: {
                                        libSearchVisible = true
                                        libSearchInput.forceActiveFocus()
                                    }
                                }

                                PressDepthIconButton {
                                    boxSize: 34
                                    iconSize: 16
                                    iconName: "sliders-horizontal"
                                    tint: textPrimary
                                    tooltipText: "Refine & Sort"
                                    highlighted: {
                                        if (refineSheetOpen) return true
                                        if (songFilterMode !== "ALL") return true
                                        if (libraryTab === "songs") return !songSortAscending || songSortMetric !== "title"
                                        if (libraryTab === "artists") return !artistSortAscending || artistSortMetric !== "name"
                                        if (libraryTab === "albums") return !albumSortAscending || albumSortMetric !== "album"
                                        if (libraryTab === "genres") return genreSortAscending || genreSortMetric !== "count"
                                        return false
                                    }
                                    onClicked: refineSheetOpen = !refineSheetOpen
                                }
                            }

                            StackLayout {
                                id: libraryStack
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                currentIndex: libraryTab === "songs" ? 0 : (libraryTab === "artists" ? 1 : (libraryTab === "albums" ? 2 : 3))

                                Item {
                                    GridView {
                                        id: songsGridView
                                        visible: libraryViewMode === "grid"
                                        anchors.fill: parent
                                        anchors.leftMargin: 24
                                        anchors.rightMargin: 8
                                        bottomMargin: 32
                                        clip: true
                                        model: libraryRoot.filteredSongsList
                                        readonly property int cols: Math.max(2, Math.floor((width - 8) / 180))
                                        cellWidth: Math.floor((width - 8) / cols)
                                        cellHeight: 240
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: SleekScrollBar {}
                                        

                                        delegate: Item {
                                            width: songsGridView.cellWidth
                                            height: 230

                                            SongCard {
                                                anchors.centerIn: parent
                                                cardWidth: parent.width - 14
                                                cardHeight: 220
                                                track: modelData
                                                onClicked: playTrack(modelData)
                                                onFavoriteClicked: toggleFavorite(modelData.filePath)
                                            }
                                        }
                                    }

                                    ListView {
                                        id: songsListView
                                        visible: libraryViewMode === "list"
                                        anchors.fill: parent
                                        anchors.leftMargin: 24
                                        anchors.rightMargin: 24
                                        clip: true
                                        model: libraryRoot.filteredSongsList
                                        spacing: 4
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: SleekScrollBar {}
                                        

                                        delegate: SongRow {
                                            width: songsListView.width
                                            track: modelData
                                            onClicked: playTrack(modelData)
                                            onFavoriteClicked: toggleFavorite(modelData.filePath)
                                        }
                                    }

                                    EmptyState {
                                        anchors.fill: parent
                                        visible: libraryRoot.filteredSongsList.length === 0
                                        catImage: "qrc:/CassetteCat/assets/01-orange-headphones.png"
                                        title: "No Songs Found"
                                        subtitle: "Try resetting format filters or changing search keywords"
                                        actionLabel: "Reset Filters"
                                        onActionClicked: {
                                            songFilterMode = "ALL"
                                            libSearchQuery = ""
                                            songSortAscending = true
                                            songSortMetric = "title"
                                        }
                                    }
                                }

                                Item {
                                    readonly property var curArtists: {
                                        const q = libSearchQuery.toLowerCase().trim()
                                        const sortM = artistSortMetric
                                        const asc = artistSortAscending
                                        let list = getArtistGroups()
                                        if (q.length > 0) {
                                            list = list.filter(a => a.name.toLowerCase().includes(q))
                                        }
                                        list.sort((a, b) => {
                                            let res = sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name)
                                            return asc ? res : -res
                                        })
                                        return list
                                    }

                                    GridView {
                                        id: artistGrid
                                        anchors.fill: parent
                                        anchors.leftMargin: 24
                                        anchors.rightMargin: 8
                                        bottomMargin: 32
                                        clip: true
                                        model: parent.curArtists
                                        readonly property int cols: Math.max(2, Math.floor((width - 8) / 190))
                                        cellWidth: Math.floor((width - 8) / cols)
                                        cellHeight: 245
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: SleekScrollBar {}
                                        

                                        delegate: Item {
                                            width: artistGrid.cellWidth
                                            height: 235

                                            ArtistCard {
                                                anchors.centerIn: parent
                                                cardWidth: parent.width - 16
                                                cardHeight: 225
                                                name: modelData.name
                                                count: modelData.count
                                                track: modelData.track
                                                onClicked: {
                                                    openCatalogDetail("artist", modelData.name, modelData.track)
                                                }
                                            }
                                        }
                                    }

                                    EmptyState {
                                        anchors.fill: parent
                                        visible: parent.curArtists.length === 0
                                        catImage: "qrc:/CassetteCat/assets/04-gray-dancing-headphones.png"
                                        title: "No Artists Found"
                                        subtitle: "No artists match your current search query"
                                        actionLabel: "Clear Search"
                                        onActionClicked: libSearchQuery = ""
                                    }
                                }

                                Item {
                                    readonly property var curAlbums: {
                                        const q = libSearchQuery.toLowerCase().trim()
                                        const sortM = albumSortMetric
                                        const asc = albumSortAscending
                                        let list = getAlbumGroups()
                                        if (q.length > 0) {
                                            list = list.filter(a => a.name.toLowerCase().includes(q) || (a.track && a.track.artist && a.track.artist.toLowerCase().includes(q)))
                                        }
                                        list.sort((a, b) => {
                                            let res = sortM === "artist" ? ((a.track ? a.track.artist : "").localeCompare(b.track ? b.track.artist : "")) : (sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name))
                                            return asc ? res : -res
                                        })
                                        return list
                                    }

                                    GridView {
                                        id: albumGrid
                                        anchors.fill: parent
                                        anchors.leftMargin: 24
                                        anchors.rightMargin: 8
                                        bottomMargin: 32
                                        clip: true
                                        model: parent.curAlbums
                                        readonly property int cols: Math.max(2, Math.floor((width - 8) / 195))
                                        cellWidth: Math.floor((width - 8) / cols)
                                        cellHeight: 255
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: SleekScrollBar {}
                                        

                                        delegate: Item {
                                            width: albumGrid.cellWidth
                                            height: 245

                                            AlbumCard {
                                                anchors.centerIn: parent
                                                cardWidth: parent.width - 16
                                                cardHeight: 235
                                                name: modelData.name
                                                artist: modelData.track ? modelData.track.artist : "Various Artists"
                                                count: modelData.count
                                                track: modelData.track
                                                onClicked: {
                                                    openCatalogDetail("album", modelData.name, modelData.track)
                                                }
                                            }
                                        }
                                    }

                                    EmptyState {
                                        anchors.fill: parent
                                        visible: parent.curAlbums.length === 0
                                        catImage: "qrc:/CassetteCat/assets/02-black-cat-cassette.png"
                                        title: "No Albums Found"
                                        subtitle: "No albums match your current search query"
                                        actionLabel: "Clear Search"
                                        onActionClicked: libSearchQuery = ""
                                    }
                                }

                                Item {
                                    readonly property var curGenres: {
                                        const q = libSearchQuery.toLowerCase().trim()
                                        const sortM = genreSortMetric
                                        const asc = genreSortAscending
                                        let list = getGenreGroups()
                                        if (q.length > 0) {
                                            list = list.filter(g => g.name.toLowerCase().includes(q))
                                        }
                                        list.sort((a, b) => {
                                            let res = sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name)
                                            return asc ? res : -res
                                        })
                                        return list
                                    }

                                    GridView {
                                        id: genreGrid
                                        anchors.fill: parent
                                        anchors.leftMargin: 24
                                        anchors.rightMargin: 8
                                        bottomMargin: 32
                                        clip: true
                                        model: parent.curGenres
                                        readonly property int cols: Math.max(2, Math.floor((width - 8) / 210))
                                        cellWidth: Math.floor((width - 8) / cols)
                                        cellHeight: 125
                                        boundsBehavior: Flickable.StopAtBounds
                                        ScrollBar.vertical: SleekScrollBar {}
                                        

                                        delegate: Item {
                                            width: genreGrid.cellWidth
                                            height: 115

                                            GenreCard {
                                                anchors.centerIn: parent
                                                cardWidth: parent.width - 16
                                                cardHeight: 110
                                                name: modelData.name
                                                count: modelData.count
                                                onClicked: {
                                                    libSearchQuery = modelData.name
                                                    window.libraryTab = "songs"
                                                }
                                            }
                                        }
                                    }

                                    EmptyState {
                                        anchors.fill: parent
                                        visible: parent.curGenres.length === 0
                                        catImage: "qrc:/CassetteCat/assets/03-cream-cassette-hug.png"
                                        title: "No Genres Found"
                                        subtitle: "No audio genres matched your search"
                                        actionLabel: "Clear Search"
                                        onActionClicked: libSearchQuery = ""
                                    }
                                }
                            }
                        }

                        AutoScroller {
                            id: libAutoScroller
                            targetView: {
                                if (libraryTab === "songs") return (libraryViewMode === "grid" ? songsGridView : songsListView)
                                if (libraryTab === "artists") return artistGrid
                                if (libraryTab === "albums") return albumGrid
                                return genreGrid
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.MiddleButton
                            cursorShape: Qt.ArrowCursor
                            z: 9998
                            onPressed: mouse => {
                                if (mouse.button === Qt.MiddleButton) {
                                    if (libAutoScroller.active) libAutoScroller.stop()
                                    else libAutoScroller.start(mouse.x, mouse.y)
                                }
                            }
                        }
                    }

                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                ColumnLayout {
                                    spacing: 2

                                    Label {
                                        text: "SEARCH YOUR LIBRARY"
                                        color: recordRed
                                        font.family: monoFont
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.1
                                    }

                                    Label {
                                        text: "Find the track you want"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                    }

                                    Label {
                                        text: searchQuery.trim().length > 0
                                            ? filteredTracks.length + " matching tracks"
                                            : tracks.length + " tracks in your library"
                                        color: silverDim
                                        font.family: monoFont
                                        font.pixelSize: 11
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                PressDepthIconButton {
                                    visible: searchQuery.length > 0 || activeFormatFilter !== "ALL"
                                    boxSize: 32
                                    iconSize: 15
                                    iconName: "rotate-ccw"
                                    tint: recordRedHover
                                    tooltipText: "Clear Search"
                                    onClicked: {
                                        searchQuery = ""
                                        activeFormatFilter = "ALL"
                                    }
                                }
                            }

                            Rectangle {
                                id: pageSearchBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 56
                                radius: 16
                                color: pageSearchInput.activeFocus ? surfaceElevated : surfaceCard
                                border.width: pageSearchInput.activeFocus ? 1.5 : 1
                                border.color: pageSearchInput.activeFocus ? recordRed : borderVariant

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    LucideIcon { Layout.preferredWidth: 22; Layout.preferredHeight: 22; icon: "search"; color: pageSearchInput.activeFocus ? recordRed : silverDim }

                                    TextInput {
                                        id: pageSearchInput
                                        Layout.fillWidth: true
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                        selectByMouse: true
                                        text: searchQuery
                                        onTextChanged: searchQuery = text
                                        Keys.onEscapePressed: focus = false

                                        Text {
                                            anchors.fill: parent
                                            visible: !pageSearchInput.text && !pageSearchInput.activeFocus
                                            text: "Search songs, artists, albums, or audio formats..."
                                            color: silverDim
                                            font.family: displayFont
                                            font.pixelSize: 15
                                        }
                                    }

                                    Label {
                                        visible: pageSearchInput.text.length > 0
                                        text: "✕"
                                        color: textSecondary
                                        font.pixelSize: 16
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                pageSearchInput.text = ""
                                                searchQuery = ""
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Label {
                                    text: "FORMAT"
                                    color: silverDim
                                    font.family: monoFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }

                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: [
                                            { id: "ALL", label: "All formats" },
                                            { id: "FLAC", label: "Lossless" },
                                            { id: "MP3", label: "MP3" },
                                            { id: "AAC", label: "AAC / M4A" }
                                        ]

                                        Rectangle {
                                            property bool isSelected: activeFormatFilter === modelData.id
                                            width: formatLabel.implicitWidth + 24
                                            height: 30
                                            radius: 15
                                            color: "transparent"
                                            border.width: isSelected ? 1.2 : 1
                                            border.color: isSelected ? recordRed : (formatMouse.containsMouse ? "#45FFFFFF" : borderSubtle)

                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Behavior on border.color { ColorAnimation { duration: 120 } }

                                            Label {
                                                id: formatLabel
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: parent.isSelected ? recordRedHover : (formatMouse.containsMouse ? textPrimary : textSecondary)
                                                font.family: monoFont
                                                font.pixelSize: 10
                                                font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                                            }

                                            MouseArea {
                                                id: formatMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: activeFormatFilter = modelData.id
                                            }
                                        }
                                    }
                                }

                                Label {
                                    text: filteredTracks.length + " results"
                                    color: textSecondary
                                    font.family: monoFont
                                    font.pixelSize: 11
                                }
                            }

                            ListView {
                                id: searchResults
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: filteredTracks
                                spacing: 6
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: SleekScrollBar {
                                    anchors.rightMargin: 8
                                }

                                header: Item {
                                    width: searchResults.width - 24
                                    height: 38

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.rightMargin: 12

                                        Label {
                                            text: "RESULTS"
                                            color: silverDim
                                            font.family: monoFont
                                            font.pixelSize: 10
                                            font.weight: Font.Bold
                                            font.letterSpacing: 1
                                        }

                                        Item { Layout.fillWidth: true }

                                        Label {
                                            text: searchQuery.length > 0 ? "Best matches first" : "All tracks"
                                            color: silverDim
                                            font.family: monoFont
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                                

                                delegate: Rectangle {
                                    width: ListView.view.width - 24
                                    height: 64
                                    radius: 12
                                    color: searchRowMouse.containsMouse ? surfaceElevated : (player.currentTrack.filePath === modelData.filePath ? surfaceCard : "#121110")
                                    border.width: player.currentTrack.filePath === modelData.filePath ? 1 : 0
                                    border.color: recordRed

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        spacing: 12

                                        Cover {
                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 44
                                            radius: 8
                                            track: modelData
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.title || modelData.fileName
                                                color: player.currentTrack.filePath === modelData.filePath ? recordRed : textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 15
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                            Label {
                                                Layout.fillWidth: true
                                                text: (modelData.artist || "Unknown Artist") + " • " + (modelData.album || "Unknown Album")
                                                color: textSecondary
                                                font.family: bodyFont
                                                font.pixelSize: 12
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            visible: !!modelData.format
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: formatText.implicitWidth + 10
                                            radius: 4
                                            color: "#18FFFFFF"
                                            border.width: 1
                                            border.color: "#30FFFFFF"

                                            Label {
                                                id: formatText
                                                anchors.centerIn: parent
                                                text: (modelData.format || "").toUpperCase()
                                                color: textSecondary
                                                font.family: monoFont
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Label {
                                            text: modelData.duration || "—"
                                            color: silverDim
                                            font.family: monoFont
                                            font.pixelSize: 11
                                        }
                                    }

                                    MouseArea {
                                        id: searchRowMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: playTrack(modelData)
                                    }
                                }

                                EmptyState {
                                    anchors.centerIn: parent
                                    visible: !filteredTracks.length
                                    catImage: "qrc:/CassetteCat/assets/01-orange-headphones.png"
                                    title: searchQuery.length > 0 || activeFormatFilter !== "ALL" ? "No matching tracks" : "Your library is empty"
                                    subtitle: searchQuery.length > 0 || activeFormatFilter !== "ALL"
                                        ? "Try a different search or clear the format filter"
                                        : "Choose a music folder in Settings to start searching"
                                    actionLabel: searchQuery.length > 0 || activeFormatFilter !== "ALL" ? "Clear Search" : ""
                                    onActionClicked: {
                                        searchQuery = ""
                                        activeFormatFilter = "ALL"
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: radioRoot

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 20

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                ColumnLayout {
                                    spacing: 2
                                    Label {
                                        text: "Radio Broadcast"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 26
                                        font.weight: Font.Bold
                                    }
                                    Label {
                                        text: radioStations.length > 0
                                            ? (radioIsCustomized ? (radioStations.length + " filtered live stations") : (radioStations.length + " global live stations (Radio Browser API)"))
                                            : "Discover online radio streams"
                                        color: textSecondary
                                        font.family: monoFont
                                        font.pixelSize: 12
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    id: radioSearchBox
                                    Layout.preferredWidth: 240
                                    Layout.preferredHeight: 36
                                    radius: 18
                                    color: surfaceCard
                                    border.width: 1
                                    border.color: radSearchInput.activeFocus ? recordRed : borderSubtle

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        LucideIcon {
                                            Layout.preferredWidth: 16
                                            Layout.preferredHeight: 16
                                            icon: "search"
                                            color: radSearchInput.activeFocus ? recordRedHover : silverDim
                                        }

                                        TextInput {
                                            id: radSearchInput
                                            Layout.fillWidth: true
                                            color: textPrimary
                                            font.family: displayFont
                                            font.pixelSize: 13
                                            selectByMouse: true
                                            text: radioSearchQuery
                                            onTextChanged: radioSearchQuery = text
                                            onAccepted: {
                                                refreshRadio()
                                                focus = false
                                            }

                                            Text {
                                                anchors.fill: parent
                                                visible: !radSearchInput.text && !radSearchInput.activeFocus
                                                text: "Search live stations..."
                                                color: textSecondary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                            }
                                        }

                                        Label {
                                            visible: radSearchInput.text.length > 0
                                            text: "×"
                                            color: textPrimary
                                            font.pixelSize: 16
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    radSearchInput.text = ""
                                                    radioSearchQuery = ""
                                                    refreshRadio()
                                                }
                                            }
                                        }
                                    }
                                }

                                PressDepthIconButton {
                                    boxSize: 36
                                    iconSize: 18
                                    iconName: "refresh-cw"
                                    tint: textPrimary
                                    tooltipText: "Refresh Stations"
                                    onClicked: refreshRadio()
                                }

                                PressDepthIconButton {
                                    boxSize: 36
                                    iconSize: 18
                                    iconName: "sliders-horizontal"
                                    tint: textPrimary
                                    highlighted: radioIsCustomized
                                    tooltipText: "Refine & Sort Stations"
                                    onClicked: radioRefineOpen = true
                                }
                            }

                            GridView {
                                id: radGrid
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: radioStations
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: SleekScrollBar {}
                                readonly property int cols: Math.max(2, Math.floor(width / 260))
                                cellWidth: Math.floor(width / cols)
                                cellHeight: 110
                                

                                delegate: Item {
                                    width: radGrid.cellWidth
                                    height: 100

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: parent.width - 12
                                        height: parent.height
                                        radius: 16
                                        color: radCardMouse.containsMouse ? surfaceElevated : surfaceCard
                                        border.width: player.currentTrack && player.currentTrack.filePath === modelData.streamUrl ? 1.5 : 1
                                        border.color: player.currentTrack && player.currentTrack.filePath === modelData.streamUrl ? recordRed : (radCardMouse.containsMouse ? borderVariant : borderSubtle)

                                        Behavior on color { ColorAnimation { duration: 120 } }
                                        Behavior on border.color { ColorAnimation { duration: 120 } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 14
                                            spacing: 12

                                            Rectangle {
                                                Layout.preferredWidth: 48
                                                Layout.preferredHeight: 48
                                                radius: 12
                                                color: "#181818"
                                                border.width: 1
                                                border.color: "#30FFFFFF"
                                                clip: true

                                                Image {
                                                    anchors.fill: parent
                                                    anchors.margins: 4
                                                    source: modelData.favicon || ""
                                                    fillMode: Image.PreserveAspectFit
                                                    visible: status === Image.Ready
                                                }

                                                LucideIcon {
                                                    anchors.centerIn: parent
                                                    width: 24
                                                    height: 24
                                                    icon: "radio"
                                                    color: recordRedHover
                                                    visible: !modelData.favicon || modelData.favicon.length === 0
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 3

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.name || "Live Station"
                                                    color: player.currentTrack && player.currentTrack.filePath === modelData.streamUrl ? recordRed : textPrimary
                                                    font.family: displayFont
                                                    font.pixelSize: 14
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }

                                                Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.country ? (modelData.country + (modelData.bitrate ? (" • " + modelData.bitrate + " kbps") : "")) : (modelData.tags || "Live Broadcast")
                                                    color: textSecondary
                                                    font.family: bodyFont
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            TransportButton {
                                                buttonSize: 36
                                                iconName: (player.currentTrack && player.currentTrack.filePath === modelData.streamUrl && player.isPlaying) ? "pause" : "play"
                                                accented: player.currentTrack && player.currentTrack.filePath === modelData.streamUrl
                                                onClicked: {
                                                    const stTrack = {
                                                        title: modelData.name || "Live Radio Stream",
                                                        artist: modelData.country || "Radio Browser",
                                                        album: "Internet Radio Broadcast",
                                                        filePath: modelData.streamUrl,
                                                        format: "STREAM",
                                                        duration: "LIVE",
                                                        artworkUrl: modelData.favicon || ""
                                                    }
                                                    playTrack(stTrack)
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: radCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const stTrack = {
                                                    title: modelData.name || "Live Radio Stream",
                                                    artist: modelData.country || "Radio Browser",
                                                    album: "Internet Radio Broadcast",
                                                    filePath: modelData.streamUrl,
                                                    format: "STREAM",
                                                    duration: "LIVE",
                                                    artworkUrl: modelData.favicon || ""
                                                }
                                                playTrack(stTrack)
                                            }
                                        }
                                    }
                                }
                            }

                            EmptyState {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: radioStations.length === 0
                                catImage: "qrc:/CassetteCat/assets/06-calico-player.png"
                                title: "Loading Radio Stations..."
                                subtitle: "Connecting to the global Radio Browser directory"
                                actionLabel: "Retry Connection"
                                onActionClicked: refreshRadio()
                            }
                        }
                    }

                    SettingsPage {
                        id: settingsRoot
                        anchors.fill: parent
                        trackCount: tracks.length
                        resumeQueueOnLaunch: window.resumeQueueOnLaunch
                        miniPlayerAlwaysOnTop: window.miniPlayerAlwaysOnTop
                        lyricsFontSize: window.lyricsFontSize
                        onChooseFolderRequested: folderDialog.open()
                        onBackRequested: page = "home"
                        onResumeQueueOnLaunchSelected: value => window.resumeQueueOnLaunch = value
                        onMiniPlayerAlwaysOnTopSelected: value => window.miniPlayerAlwaysOnTop = value
                        onLyricsFontSizeSelected: value => window.lyricsFontSize = value


                    }
                }
            }
        }

        CatalogDetail {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: miniPlayerDock.top
            visible: catalogDetailOpen
            z: 350
            appWindow: window
            mode: catalogDetailMode
            title: catalogDetailTitle
            tracks: catalogDetailTracks
            heroTrack: catalogDetailHeroTrack
            onBackRequested: catalogDetailOpen = false
            onAlbumRequested: function(name, track) {
                openCatalogDetail("album", name, track)
            }
        }

        Rectangle {
            id: miniPlayerDock
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 88
            color: surfaceDock

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: borderSubtle
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 20
                spacing: 20

                RowLayout {
                    Layout.preferredWidth: 320
                    Layout.maximumWidth: 320
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        radius: 10
                        clip: true
                        color: surfaceCard
                        border.width: 1
                        border.color: borderVariant

                        Cover {
                            anchors.fill: parent
                            track: player.currentTrack
                            radius: 10
                            keepPreviousArtwork: true
                            cacheArtwork: true
                            visible: !!player.currentTrack.filePath
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            source: "qrc:/CassetteCat/assets/06-calico-player.png"
                            fillMode: Image.PreserveAspectFit
                            visible: !player.currentTrack.filePath
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (player.currentTrack.filePath) {
                                    nowPlayingOpen = !nowPlayingOpen
                                } else if (tracks.length > 0) {
                                    playTrack(tracks[0])
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: player.currentTrack.title || (tracks.length > 0 ? "CassetteCat Audio" : "Library Empty")
                            color: textPrimary
                            font.family: displayFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (player.currentTrack.filePath) {
                                        nowPlayingOpen = !nowPlayingOpen
                                    } else if (tracks.length > 0) {
                                        playTrack(tracks[0])
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: player.currentTrack.artist || (tracks.length > 0 ? "Pick a track to start playback" : "Choose a music folder to begin")
                            color: player.currentTrack.artist ? recordRed : (tracks.length > 0 ? recordRed : textSecondary)
                            font.family: bodyFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 2

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14

                        TransportButton {
                            buttonSize: 34
                            iconName: "shuffle"
                            accented: player.shuffleEnabled
                            onClicked: toggleQueueShuffle()
                        }

                        TransportButton {
                            buttonSize: 34
                            iconName: "quote"
                            accented: nowPlayingOpen && nowPlayingMode === "lyrics"
                            iconColor: nowPlayingMode === "lyrics" ? recordRed : textPrimary
                            onClicked: {
                                nowPlayingMode = "lyrics"
                                nowPlayingOpen = true
                            }
                        }

                        TransportButton {
                            buttonSize: 38
                            iconName: "skip-back"
                            iconColor: textPrimary
                            onClicked: playPrevious()
                        }

                        TransportButton {
                            buttonSize: 46
                            iconName: playerVisuallyPlaying ? "pause" : "play"
                            accented: true
                            iconColor: recordRed
                            onClicked: {
                                if (!player.currentTrack.filePath && tracks.length > 0) {
                                    shuffleAll()
                                } else {
                                    player.togglePlay()
                                }
                            }
                        }

                        TransportButton {
                            buttonSize: 38
                            iconName: "skip-forward"
                            iconColor: textPrimary
                            onClicked: playNext()
                        }

                        TransportButton {
                            buttonSize: 34
                            iconName: "list-music"
                            accented: nowPlayingOpen && nowPlayingMode === "queue"
                            iconColor: nowPlayingMode === "queue" ? recordRed : textPrimary
                            onClicked: {
                                nowPlayingMode = "queue"
                                nowPlayingOpen = true
                            }
                        }

                        TransportButton {
                            buttonSize: 34
                            iconName: repeatMode === 2 ? "repeat-1" : "repeat"
                            accented: repeatMode > 0
                            iconColor: repeatMode > 0 ? recordRed : textPrimary
                            onClicked: toggleRepeat()
                        }
                    }

                    AudioSeeker {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 580
                        Layout.alignment: Qt.AlignHCenter
                        position: player.position
                        duration: player.duration
                        onSeekRequested: posMs => player.seek(posMs)
                    }
                }

                RowLayout {
                    Layout.preferredWidth: 320
                    Layout.maximumWidth: 320
                    Layout.alignment: Qt.AlignRight
                    spacing: 10

                    PressDepthIconButton {
                        boxSize: 36
                        iconSize: 18
                        iconName: "heart"
                        tint: isFavorite(player.currentTrack.filePath) ? recordRed : silverDim
                        onClicked: toggleFavorite(player.currentTrack.filePath)
                    }

                    VolumeControl {
                        Layout.preferredWidth: 140
                        volume: player.volume
                        onVolumeAdjusted: newVol => {
                            player.setVolume(newVol)
                        }
                    }

                    PressDepthIconButton {
                        boxSize: 36
                        iconSize: 18
                        iconName: "pip"
                        tint: silverDim
                        tooltipText: "Mini Player (Ctrl+M)"
                        onClicked: toggleMiniPlayer()
                    }

                    PressDepthIconButton {
                        boxSize: 36
                        iconSize: 18
                        iconName: nowPlayingOpen ? "chevron-down" : "audio-lines"
                        tint: nowPlayingOpen ? recordRed : silverDim
                        onClicked: nowPlayingOpen = !nowPlayingOpen
                    }
                }
            }
        }

        TapHandler {
            target: null
            onTapped: function(eventPoint) { window.dismissSearchFocus(eventPoint.position) }
        }
    }



    Rectangle {
        id: nowPlayingOverlay
        anchors.fill: parent
        color: "#0A0908"
        visible: nowPlayingOpen
        opacity: nowPlayingOpen ? 1.0 : 0.0
        z: 500

        Behavior on opacity {
            NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: true
            acceptedButtons: Qt.AllButtons
            onPressed: mouse => mouse.accepted = true
            onReleased: mouse => mouse.accepted = true
            onClicked: mouse => mouse.accepted = true
            onDoubleClicked: mouse => mouse.accepted = true
            onWheel: wheel => wheel.accepted = true
        }

        Item {
            anchors.fill: parent
            clip: true
            opacity: 0.35

            Cover {
                anchors.centerIn: parent
                width: parent.width * 1.3
                height: parent.height * 1.3
                track: player.currentTrack
                keepPreviousArtwork: true
                cacheArtwork: false
                stableSourceSize: 720
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    saturation: 0.25
                    brightness: -0.25
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#50000000" }
                    GradientStop { position: 0.45; color: "#C00A0908" }
                    GradientStop { position: 1.0; color: "#F80A0908" }
                }
            }
        }

        Item {
            id: npTopBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            z: 10

            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: 19
                color: backMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
                border.width: 1
                border.color: backMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF"

                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on border.color { ColorAnimation { duration: 160 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    icon: "chevron-down"
                    color: backMouse.containsMouse ? textPrimary : silverDim
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: nowPlayingOpen = false
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: npPipMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
                    border.width: 1
                    border.color: npPipMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF"

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        icon: "pip"
                        color: npPipMouse.containsMouse ? textPrimary : silverDim
                    }

                    MouseArea {
                        id: npPipMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: toggleMiniPlayer()
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: lyricsBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
                    border.width: 1.0
                    border.color: nowPlayingMode === "lyrics"
                        ? recordRed
                        : (lyricsBtnMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF")

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        icon: "quote"
                        color: nowPlayingMode === "lyrics" ? recordRedHover : (lyricsBtnMouse.containsMouse ? textPrimary : silverDim)
                    }

                    MouseArea {
                        id: lyricsBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            nowPlayingMode = (nowPlayingMode === "lyrics") ? "controls" : "lyrics"
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: queueBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
                    border.width: 1.0
                    border.color: nowPlayingMode === "queue"
                        ? recordRed
                        : (queueBtnMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF")

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        icon: "list-music"
                        color: nowPlayingMode === "queue" ? recordRedHover : (queueBtnMouse.containsMouse ? textPrimary : silverDim)
                    }

                    MouseArea {
                        id: queueBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            nowPlayingMode = (nowPlayingMode === "queue") ? "controls" : "queue"
                        }
                    }
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: closeNpMouse.containsMouse ? "#45C23B30" : "#10FFFFFF"
                    border.width: 1.0
                    border.color: closeNpMouse.containsMouse ? "#65C23B30" : "#14FFFFFF"

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        icon: "x"
                        color: closeNpMouse.containsMouse ? "#FFFFFF" : silverDim
                    }

                    MouseArea {
                        id: closeNpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: nowPlayingOpen = false
                    }
                }
            }
        }

        Item {
            anchors.top: npTopBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.bottomMargin: 32
            clip: true

            Item {
                id: npLeftColumn
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Math.min(420, Math.round(parent.width * 0.38))

                readonly property int normalArtSize: Math.min(width - 20, Math.min(parent.height * 0.58, 360))
                readonly property int lyricsArtSize: 260
                readonly property bool compactPlayerMode: nowPlayingMode === "lyrics" || nowPlayingMode === "queue"
                readonly property int currentArtSize: compactPlayerMode ? lyricsArtSize : normalArtSize
                readonly property int normalArtY: Math.round((parent.height - normalArtSize) / 2)
                readonly property int lyricsArtY: Math.max(10, Math.round((parent.height - (lyricsArtSize + 16 + 160)) / 2))
                readonly property int targetArtY: compactPlayerMode ? lyricsArtY : normalArtY

                Rectangle {
                    id: npArtworkCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: npLeftColumn.targetArtY
                    width: npLeftColumn.currentArtSize
                    height: npLeftColumn.currentArtSize
                    radius: npLeftColumn.compactPlayerMode ? 16 : 22
                    clip: true
                    color: surfaceCard
                    border.width: 1
                    border.color: "#25FFFFFF"

                    Behavior on y {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    Behavior on width {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    Behavior on height {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }
                    Behavior on radius {
                        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                    }

                    Cover {
                        anchors.fill: parent
                        track: player.currentTrack
                        radius: npArtworkCard.radius
                        keepPreviousArtwork: true
                        cacheArtwork: true
                        stableSourceSize: 360
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: toggleFavorite(player.currentTrack.filePath)
                    }
                }

                Item {
                    id: underArtControls
                    anchors.top: npArtworkCard.bottom
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 24, 320)
                    height: 160
                    visible: opacity > 0.001
                    opacity: npLeftColumn.compactPlayerMode ? 1.0 : 0.0
                    scale: npLeftColumn.compactPlayerMode ? 1.0 : 0.95

                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                Layout.fillWidth: true
                                text: player.currentTrack.title || "No Track Selected"
                                color: "#FFFFFF"
                                font.family: displayFont
                                font.pixelSize: 17
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: {
                                    let a = player.currentTrack.artist || "Unknown Artist"
                                    if (player.currentTrack.album) a += " • " + player.currentTrack.album
                                    return a
                                }
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }
                        }

                        AudioSeeker {
                            Layout.fillWidth: true
                            position: player.position
                            duration: player.duration
                            onSeekRequested: posMs => player.seek(posMs)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            TransportButton {
                                buttonSize: 32
                                iconName: "shuffle"
                                accented: player.shuffleEnabled
                                onClicked: toggleQueueShuffle()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                buttonSize: 38
                                iconName: "skip-back"
                                iconColor: textPrimary
                                onClicked: playPrevious()
                            }

                            TransportButton {
                                buttonSize: 48
                                iconName: playerVisuallyPlaying ? "pause" : "play"
                                accented: true
                                iconColor: recordRed
                                onClicked: player.togglePlay()
                            }

                            TransportButton {
                                buttonSize: 38
                                iconName: "skip-forward"
                                iconColor: textPrimary
                                onClicked: playNext()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                buttonSize: 32
                                iconName: repeatMode === 2 ? "repeat-1" : "repeat"
                                accented: repeatMode > 0
                                iconColor: repeatMode > 0 ? recordRed : textPrimary
                                onClicked: toggleRepeat()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Item { Layout.fillWidth: true }
                            VolumeControl {
                                Layout.preferredWidth: 160
                                volume: player.volume
                                onVolumeAdjusted: newVol => player.setVolume(newVol)
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }

            Item {
                id: npRightColumn
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: npLeftColumn.right
                anchors.leftMargin: 48
                anchors.right: parent.right
                clip: true

                Item {
                    id: deckControlsView
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, 480)
                    height: 310
                    visible: opacity > 0.001
                    opacity: nowPlayingMode === "controls" ? 1.0 : 0.0
                    scale: nowPlayingMode === "controls" ? 1.0 : 0.96

                    Behavior on opacity {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        id: metadataHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 76
                        spacing: 4

                        Label {
                            Layout.fillWidth: true
                            text: player.currentTrack.title || "No Track Selected"
                            color: "#FFFFFF"
                            font.family: displayFont
                            font.pixelSize: 30
                            font.weight: Font.Bold
                            font.letterSpacing: -0.5
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            text: {
                                let a = player.currentTrack.artist || "CassetteCat Audio"
                                if (player.currentTrack.album) a += " • " + player.currentTrack.album
                                return a
                            }
                            color: recordRed
                            font.family: displayFont
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }

                    AudioSeeker {
                        id: deckSeeker
                        anchors.top: metadataHeader.bottom
                        anchors.topMargin: 20
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        position: player.position
                        duration: player.duration
                        onSeekRequested: posMs => player.seek(posMs)
                    }

                    RowLayout {
                        id: deckTransportRow
                        anchors.top: deckSeeker.bottom
                        anchors.topMargin: 24
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 18

                            TransportButton {
                                buttonSize: 42
                                iconName: "shuffle"
                                accented: player.shuffleEnabled
                                onClicked: toggleQueueShuffle()
                            }

                            TransportButton {
                                buttonSize: 52
                                iconName: "skip-back"
                                iconColor: textPrimary
                                onClicked: playPrevious()
                            }

                            TransportButton {
                                buttonSize: 72
                                iconName: playerVisuallyPlaying ? "pause" : "play"
                                accented: true
                                iconColor: recordRed
                                onClicked: player.togglePlay()
                            }

                            TransportButton {
                                buttonSize: 52
                                iconName: "skip-forward"
                                iconColor: textPrimary
                                onClicked: playNext()
                            }

                            TransportButton {
                                buttonSize: 42
                                iconName: repeatMode === 2 ? "repeat-1" : "repeat"
                                accented: repeatMode > 0
                                iconColor: repeatMode > 0 ? recordRed : textPrimary
                                onClicked: toggleRepeat()
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        anchors.top: deckTransportRow.bottom
                        anchors.topMargin: 20
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        Item { Layout.fillWidth: true }

                        VolumeControl {
                            Layout.preferredWidth: 200
                            volume: player.volume
                            onVolumeAdjusted: newVol => player.setVolume(newVol)
                        }

                        Item { Layout.fillWidth: true }
                    }
                }

                Item {
                    id: lyricsView
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: nowPlayingMode === "lyrics" ? 1.0 : 0.0
                    scale: nowPlayingMode === "lyrics" ? 1.0 : 0.98

                    Behavior on opacity {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }

                    ListView {
                        id: lyricsListView
                        anchors.fill: parent
                        clip: true
                        model: lyricDisplayItems
                        currentIndex: activeLyricDisplayIndex
                        spacing: 26
                        interactive: lyricDisplayItems.length > 0
                        topMargin: Math.round(height * 0.38)
                        bottomMargin: Math.round(height * 0.45)
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: Math.round(height * 0.36)
                        preferredHighlightEnd: Math.round(height * 0.38)
                        highlightMoveDuration: 550
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: SleekScrollBar { visible: lyricDisplayItems.length > 0 }

                        delegate: Item {
                            id: lyricItem
                            width: ListView.view.width
                            readonly property bool isGap: modelData.type === "gap"
                            readonly property bool isCurrent: !isGap && modelData.lineIndex === activeLyricIndex && lyricDisplayItems[activeLyricDisplayIndex] && lyricDisplayItems[activeLyricDisplayIndex].type === "line"
                            readonly property bool isSynced: !isGap
                            readonly property bool gapActive: isGap && player.position >= modelData.startMs && player.position <= modelData.endMs
                            height: isGap ? 72 : lyricTextLabel.implicitHeight + 14

                            Label {
                                id: lyricTextLabel
                                width: Math.min(parent.width - 72, 920)
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !lyricItem.isGap
                                wrapMode: Text.WordWrap
                                textFormat: Text.RichText
                                text: lyricItem.isGap ? "" : karaokeLyricHtml(modelData.lineIndex, modelData.text)
                                color: isCurrent ? "#FFFFFF" : (lyricLineMouse.containsMouse ? textPrimary : (isSynced ? "#7E7A74" : textPrimary))
                                horizontalAlignment: Text.AlignLeft
                                font.family: displayFont
                                font.pixelSize: lyricsFontSize
                                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                                font.letterSpacing: -0.3
                                lineHeight: 1.35
                                transformOrigin: Item.Center
                                scale: isCurrent ? 1.03 : (lyricLineMouse.containsMouse ? 1.01 : 0.96)
                                opacity: isCurrent ? 1.0 : (lyricLineMouse.containsMouse ? 0.75 : (isSynced ? 0.28 : 0.85))

                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 10
                                visible: lyricItem.isGap
                                opacity: lyricItem.gapActive ? 1.0 : 0.22

                                Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                                Repeater {
                                    model: 3
                                    delegate: Rectangle {
                                        width: 7
                                        height: 7
                                        radius: 4
                                        color: recordRedHover
                                        y: 0
                                        SequentialAnimation on y {
                                            running: lyricItem.gapActive && player.isPlaying
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: index * 150 }
                                            NumberAnimation { to: -6; duration: 260; easing.type: Easing.OutSine }
                                            NumberAnimation { to: 0; duration: 260; easing.type: Easing.InSine }
                                            PauseAnimation { duration: (2 - index) * 150 }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: lyricLineMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: player.seek(modelData.startMs)
                            }
                        }

                        Item {
                            anchors.fill: parent
                            visible: !parsedLyrics || parsedLyrics.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 18

                                Row {
                                    id: waveRow
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.minimumHeight: 64
                                    Layout.preferredHeight: 64
                                    Layout.maximumHeight: 64
                                    spacing: 7
                                    height: 64

                                    Repeater {
                                        model: [0.42, 0.72, 0.56, 1.0, 0.62, 0.82, 0.46]
                                        delegate: Rectangle {
                                            required property real modelData
                                            width: 6
                                            radius: 3
                                            color: recordRedHover
                                            anchors.verticalCenter: parent.verticalCenter
                                            height: 10 + (player.isPlaying ? player.audioLevel * 52 * modelData : 0)
                                            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "Instrumental"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 28
                                        font.weight: Font.Medium
                                        font.letterSpacing: -0.3
                                    }

                                    Label {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: player.currentTrack.artist ? ("Composed by " + player.currentTrack.artist) : (player.currentTrack.title ? ("Track by " + (player.currentTrack.artist || "Unknown Artist")) : "No lyrics available")
                                        color: textSecondary
                                        font.family: bodyFont
                                        font.pixelSize: 14
                                    }
                                }

                                Item { height: 6; width: 1 }

                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 12

                                    Rectangle {
                                        implicitWidth: searchRow.implicitWidth + 32
                                        implicitHeight: 40
                                        radius: 20
                                        color: searchPillMouse.containsMouse ? surfaceElevated : surfaceCard
                                        border.width: 1
                                        border.color: searchPillMouse.containsMouse ? borderVariant : borderSubtle

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        RowLayout {
                                            id: searchRow
                                            anchors.centerIn: parent
                                            spacing: 8

                                            LucideIcon {
                                                width: 15
                                                height: 15
                                                icon: "search"
                                                color: recordRedHover
                                            }

                                            Label {
                                                text: "Choose lyrics"
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }

                                        MouseArea {
                                            id: searchPillMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: openLyricsSearch()
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: artRow.implicitWidth + 32
                                        implicitHeight: 40
                                        radius: 20
                                        color: artPillMouse.containsMouse ? surfaceElevated : surfaceCard
                                        border.width: 1
                                        border.color: artPillMouse.containsMouse ? borderVariant : borderSubtle

                                        Behavior on color { ColorAnimation { duration: 150 } }

                                        RowLayout {
                                            id: artRow
                                            anchors.centerIn: parent
                                            spacing: 8

                                            LucideIcon {
                                                width: 15
                                                height: 15
                                                icon: "disc"
                                                color: silverDim
                                            }

                                            Label {
                                                text: "Album Art"
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                            }
                                        }

                                        MouseArea {
                                            id: artPillMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                nowPlayingMode = "controls"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: 18
                        anchors.bottomMargin: 14
                        spacing: 8
                        visible: parsedLyrics.length > 0

                        Rectangle {
                            width: chooseLyricsLabel.implicitWidth + 20
                            height: 26
                            radius: 13
                            color: chooseLyricsMouse.containsMouse ? surfaceElevated : surfaceCard
                            border.width: 1
                            border.color: chooseLyricsMouse.containsMouse ? borderVariant : borderSubtle

                            Label {
                                id: chooseLyricsLabel
                                anchors.centerIn: parent
                                text: "Choose lyrics"
                                color: chooseLyricsMouse.containsMouse ? textPrimary : textSecondary
                                font.family: displayFont
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: chooseLyricsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: openLyricsSearch()
                            }
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: lyricsProvider
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }

                        Rectangle {
                            width: 28; height: 26; radius: 13
                            color: offsetBack.containsMouse ? surfaceElevated : surfaceCard
                            Label { anchors.centerIn: parent; text: "−"; color: textSecondary; font.pixelSize: 16 }
                            MouseArea { id: offsetBack; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lyricsSyncOffsetMs -= 100 }
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (lyricsSyncOffsetMs >= 0 ? "+" : "") + (lyricsSyncOffsetMs / 1000).toFixed(1) + "s"
                            color: textSecondary
                            font.family: monoFont
                            font.pixelSize: 10
                        }
                        Rectangle {
                            width: 28; height: 26; radius: 13
                            color: offsetForward.containsMouse ? surfaceElevated : surfaceCard
                            Label { anchors.centerIn: parent; text: "+"; color: textSecondary; font.pixelSize: 16 }
                            MouseArea { id: offsetForward; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: lyricsSyncOffsetMs += 100 }
                        }
                    }
                }

                Item {
                    id: queueView
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: nowPlayingMode === "queue" ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 14

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: queueEntries
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: SleekScrollBar { anchors.rightMargin: 8 }

                            delegate: Rectangle {
                                width: ListView.view.width - 24
                                height: modelData.type === "header" ? 30 : 52
                                radius: 8
                                color: modelData.type === "header" ? "transparent" : (qRowMouse.containsMouse
                                    ? surfaceElevated
                                    : (modelData.type === "current" ? "#1C1A18" : "transparent"))
                                border.width: 0

                                Label {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: modelData.type === "header"
                                    text: modelData.title || ""
                                    color: modelData.title === "NOW PLAYING" ? recordRed : silverDim
                                    font.family: monoFont
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.0
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 14
                                    spacing: 12
                                    visible: modelData.type !== "header"

                                    Cover {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 6
                                        track: modelData
                                        cacheArtwork: true
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.title || modelData.fileName
                                            color: modelData.type === "current" ? recordRed : textPrimary
                                            font.family: displayFont
                                            font.pixelSize: 13
                                            font.weight: modelData.type === "current" ? Font.Bold : Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Label {
                                            Layout.fillWidth: true
                                            text: (modelData.artist || "Unknown Artist") + " • " + (modelData.album || "Unknown Album")
                                            color: textSecondary
                                            font.family: bodyFont
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Label {
                                        text: modelData.duration || "—"
                                        color: silverDim
                                        font.family: monoFont
                                        font.pixelSize: 11
                                    }
                                }

                                MouseArea {
                                    id: qRowMouse
                                    anchors.fill: parent
                                    enabled: modelData.type !== "header" && modelData.type !== "current"
                                    hoverEnabled: true
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: playFromQueue(modelData.track)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: lyricSearchPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        visible: lyricSearchOpen
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(parent.width - 80, 620)
        height: lyricCustomEditorOpen
            ? Math.min(parent.height - 100, 560)
            : Math.min(parent.height - 100, lyricSearchLoading || lyricSearchResults.length ? 560 : 300)
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        onClosed: lyricSearchOpen = false

        Overlay.modal: Rectangle {
            color: "#B8000000"
        }

        background: Rectangle {
            radius: 14
            color: surfaceCard
            border.width: 1
            border.color: borderSubtle
        }

        contentItem: ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 10
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Label {
                        text: lyricSearchLoading ? "Searching LRCLIB…" : "Choose lyrics"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                    Label {
                        Layout.fillWidth: true
                        visible: !lyricCustomEditorOpen
                        text: (player.currentTrack.title || player.currentTrack.fileName || "") + (player.currentTrack.artist ? " • " + player.currentTrack.artist : "")
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
                Label {
                    visible: !lyricCustomEditorOpen
                    text: "Add custom"
                    color: recordRedHover
                    font.family: displayFont
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: lyricCustomEditorOpen = true }
                }
                TransportButton {
                    buttonSize: 30
                    iconName: "x"
                    onClicked: lyricSearchOpen = false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.bottomMargin: 12
                visible: !lyricCustomEditorOpen

                RefineTextInput {
                    Layout.fillWidth: true
                    placeholder: "Track title"
                    text: lyricSearchQuery
                    onEdited: lyricSearchQuery = text
                    onSubmitted: searchLyricsOnline()
                }
                TransportButton {
                    buttonSize: 36
                    iconName: "search"
                    accented: true
                    onClicked: searchLyricsOnline()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.bottomMargin: 8
                visible: !lyricCustomEditorOpen && !lyricSearchLoading && lyricSearchResults.length > 0

                Label {
                    Layout.fillWidth: true
                    text: lyricSearchResults.length + (lyricSearchResults.length === 1 ? " version found" : " versions found")
                    color: recordRedHover
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
                Label {
                    text: "Choose the closest match"
                    color: silverDim
                    font.family: bodyFont
                    font.pixelSize: 10
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: !lyricCustomEditorOpen && (lyricSearchLoading || lyricSearchResults.length > 0)
                clip: true
                visible: !lyricCustomEditorOpen
                model: lyricSearchResults
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar {}

                delegate: Item {
                    width: ListView.view.width
                    height: 82

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        radius: 8
                        color: resultMouse.containsMouse ? surfaceElevated : "transparent"
                        border.width: 0

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Row {
                                width: parent.width
                                spacing: 7
                                Label { width: parent.width - lyricType.implicitWidth - parent.spacing; text: modelData.title || "Unknown track"; color: textPrimary; font.family: displayFont; font.pixelSize: 13; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Label { id: lyricType; text: modelData.syncedLyrics ? "SYNCED" : "PLAIN"; color: modelData.syncedLyrics ? recordRedHover : textSecondary; font.family: monoFont; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Label { width: parent.width; text: (modelData.artist || "Unknown artist") + (modelData.album ? " • " + modelData.album : ""); color: textSecondary; font.family: bodyFont; font.pixelSize: 11; elide: Text.ElideRight }
                            Label {
                                width: parent.width
                                height: 16
                                text: parseLrc(modelData.syncedLyrics || modelData.plainLyrics || "").slice(0, 1).map(line => line.text).join("") || (modelData.plainLyrics || "").split(/\r?\n/).filter(line => line.trim().length).slice(0, 1).join("")
                                color: silverDim
                                font.family: bodyFont
                                font.pixelSize: 10
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }
                        }

                    }
                    MouseArea {
                        id: resultMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const lyrics = modelData.syncedLyrics || modelData.plainLyrics || ""
                            services.cacheLyrics(player.currentTrack.title || player.currentTrack.fileName || "", player.currentTrack.artist || "", player.currentTrack.album || "", modelData.syncedLyrics || "", modelData.plainLyrics || "", "LRCLIB")
                            applyLyrics(lyrics, "LRCLIB")
                            lyricSearchOpen = false
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: !lyricCustomEditorOpen && !lyricSearchLoading && lyricSearchResults.length === 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                visible: !lyricCustomEditorOpen && !lyricSearchLoading && lyricSearchResults.length === 0
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "No lyrics found\nTry the track title, or add custom lyrics"
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 14
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: lyricCustomEditorOpen = true }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: lyricCustomEditorOpen
                Layout.margins: 18
                visible: lyricCustomEditorOpen
                spacing: 12

                Label {
                    Layout.fillWidth: true
                    text: (player.currentTrack.title || "") + " • " + (player.currentTrack.artist || "")
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                TextArea {
                    id: lyricCustomInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    text: lyricCustomText
                    placeholderText: "Paste synchronized LRC or plain lyrics…"
                    wrapMode: TextArea.Wrap
                    color: textPrimary
                    font.family: monoFont
                    font.pixelSize: 12
                    selectByMouse: true
                    onTextChanged: lyricCustomText = text
                    background: Rectangle { radius: 10; color: surfaceInput; border.width: 1; border.color: lyricCustomInput.activeFocus ? recordRed : borderSubtle }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; text: "Timestamped LRC becomes synced lyrics."; color: silverDim; font.family: bodyFont; font.pixelSize: 11 }
                    Label {
                        text: "Cancel"
                        color: textSecondary
                        font.family: displayFont
                        font.pixelSize: 13
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: lyricCustomEditorOpen = false }
                    }
                    Label {
                        text: "Save & apply"
                        color: lyricCustomText.trim().length ? recordRedHover : silverDim
                        font.family: displayFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        MouseArea {
                            anchors.fill: parent
                            enabled: lyricCustomText.trim().length > 0
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                const synced = parseLrc(lyricCustomText).length > 0
                                services.cacheLyrics(player.currentTrack.title || player.currentTrack.fileName || "", player.currentTrack.artist || "", player.currentTrack.album || "", synced ? lyricCustomText : "", synced ? "" : lyricCustomText, synced ? "Custom LRC" : "Custom plain")
                                applyLyrics(lyricCustomText, synced ? "Custom LRC" : "Custom plain")
                                lyricSearchOpen = false
                            }
                        }
                    }
                }
            }
        }
    }

    LibraryRefineSheet {
        isOpen: refineSheetOpen
        activeTab: libraryTab
        currentFilter: songFilterMode
        currentSongSort: songSortMetric
        currentArtistSort: artistSortMetric
        currentAlbumSort: albumSortMetric
        currentGenreSort: genreSortMetric
        currentFolderSort: folderSortMetric
        currentSortAscending: {
            if (libraryTab === "songs") return songSortAscending
            if (libraryTab === "artists") return artistSortAscending
            if (libraryTab === "albums") return albumSortAscending
            if (libraryTab === "genres") return genreSortAscending
            return folderSortAscending
        }
        onFilterSelected: function(fId) {
            songFilterMode = fId
        }
        onSortSelected: function(sId) {
            if (libraryTab === "songs") {
                songSortMetric = sId
                songSortAscending = (sId === "duration") ? false : true
            } else if (libraryTab === "artists") {
                artistSortMetric = sId
                artistSortAscending = (sId === "count") ? false : true
            } else if (libraryTab === "albums") {
                albumSortMetric = sId
                albumSortAscending = (sId === "count") ? false : true
            } else if (libraryTab === "genres") {
                genreSortMetric = sId
                genreSortAscending = (sId === "count") ? false : true
            } else {
                folderSortMetric = sId
                folderSortAscending = (sId === "count") ? false : true
            }
        }
        onSortDirectionToggled: {
            if (libraryTab === "songs") songSortAscending = !songSortAscending
            else if (libraryTab === "artists") artistSortAscending = !artistSortAscending
            else if (libraryTab === "albums") albumSortAscending = !albumSortAscending
            else if (libraryTab === "genres") genreSortAscending = !genreSortAscending
            else folderSortAscending = !folderSortAscending
        }
        onResetRequested: {
            songFilterMode = "ALL"
            libSearchQuery = ""
            songSortMetric = "title"
            songSortAscending = true
            artistSortMetric = "name"
            artistSortAscending = true
            albumSortMetric = "album"
            albumSortAscending = true
            genreSortMetric = "count"
            genreSortAscending = false
            folderSortMetric = "name"
            folderSortAscending = true
        }
        onClosed: refineSheetOpen = false
    }

    LibraryRefineSheet {
        isOpen: radioRefineOpen
        activeTab: "radio"
        currentRadioSort: radioSortOrder
        currentSortAscending: !radioSortDescending
        radioCountry: radioCountryFilter
        radioLanguage: radioLanguageFilter
        radioTag: radioActiveTag
        onRadioCountrySelected: function(country) { radioCountryFilter = country }
        onRadioLanguageSelected: function(language) { radioLanguageFilter = language }
        onRadioTagSelected: function(tag) {
            radioActiveTag = tag
            refreshRadio()
        }
        onRadioFiltersSubmitted: refreshRadio()
        onSortSelected: function(sort) {
            radioSortOrder = sort
            radioSortDescending = true
            refreshRadio()
        }
        onSortDirectionToggled: {
            radioSortDescending = !radioSortDescending
            refreshRadio()
        }
        onResetRequested: {
            radioCountryFilter = ""
            radioLanguageFilter = ""
            radioActiveTag = "ALL"
            radioSortOrder = "votes"
            radioSortDescending = true
            refreshRadio()
        }
        onClosed: radioRefineOpen = false
    }
}
