import QtQuick
import QtQuick.Controls
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

    property string accentName: "recordRed"
    property string customAccentColor: "#C23B30"
    readonly property var accentColorMap: ({
        "recordRed": { base: "#C23B30", hover: "#D64337" },
        "amber": { base: "#F59E0B", hover: "#FBBF24" },
        "cyan": { base: "#06B6D4", hover: "#22D3EE" },
        "emerald": { base: "#10B981", hover: "#34D399" },
        "magenta": { base: "#EC4899", hover: "#F472B6" },
        "silver": { base: "#C4C4C0", hover: "#E5E5E3" }
    })
    readonly property color recordRed: accentName === "custom"
        ? Qt.color(customAccentColor)
        : (accentColorMap[accentName] || accentColorMap["recordRed"]).base
    readonly property color recordRedHover: accentName === "custom"
        ? Qt.lighter(Qt.color(customAccentColor), 1.15)
        : (accentColorMap[accentName] || accentColorMap["recordRed"]).hover
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
    readonly property color borderSubtle: Qt.rgba(1, 1, 1, 0.05)
    readonly property color borderVariant: Qt.rgba(1, 1, 1, 0.09)
    readonly property color borderCard: borderVariant

    readonly property string displayFont: (typeof displayFontFamily !== "undefined" && displayFontFamily.length > 0) ? displayFontFamily : "Space Grotesk"
    readonly property string bodyFont: (typeof bodyFontFamily !== "undefined" && bodyFontFamily.length > 0) ? bodyFontFamily : "IBM Plex Sans"
    readonly property string monoFont: (typeof monoFontFamily !== "undefined" && monoFontFamily.length > 0) ? monoFontFamily : "IBM Plex Mono"

    property bool settingsInitialized: false
    property int libraryRevision: 0
    property bool appQuitting: false
    property string page: "home"
    property real homeScrollPosition: 0
    property var libraryScrollPositions: ({})
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
    // What the detail view is filtered by; differs from the title for playlists, which are keyed by id.
    property string catalogDetailKey: ""
    property var catalogDetailTracks: []
    property var catalogDetailHeroTrack: ({})
    property var catalogDetailHistory: []
    property string nowPlayingMode: "controls" // "controls", "lyrics", "queue"
    property var lyricsListView: null
    property bool nowPlayingLoaded: false
    property bool sidebarCollapsed: false
    property var favoriteTracks: ({})
    property var playlists: []
    property string playlistStatus: ""
    property var playlistPendingExport: null
    property var playCounts: ({})
    property var seenAt: ({})
    property int repeatMode: 0 // 0: Off, 1: Repeat All, 2: Repeat One
    property var playbackQueue: []
    property var originalPlaybackQueue: []
    property var radioPlaybackQueue: []
    property var originalRadioPlaybackQueue: []
    property bool playbackQueueRestored: false
    property var playbackHistory: []
    property var selectedTrackPaths: ({})
    property bool playbackHistoryRestored: false
    property var historyTrackedTrack: null
    property double historyAccumulatedMs: 0
    property double historyPlayingSince: 0
    property bool historyRecordedForTrack: false
    property var lastHandledTrack: null
    property int queueRevision: 0
    property bool playbackPending: false
    readonly property bool playerVisuallyPlaying: player.isPlaying || playbackPending

    property var miniPlayerWindow: miniPlayerLoader.item
    readonly property bool miniPlayerMode: miniPlayerWindow ? miniPlayerWindow.visible : false
    property bool miniPlayerAlwaysOnTop: true
    property bool closeToTray: true
    property bool startMinimizedToTray: false
    property string nowPlayingNotifications: "minimized"
    property bool resumeQueueOnLaunch: true
    property bool globalShortcutsEnabled: false
    readonly property bool globalShortcutsSupported: globalShortcuts.supported
    readonly property string globalShortcutStatus: globalShortcuts.status
    readonly property var globalShortcutBindings: globalShortcuts.shortcuts
    property var inAppShortcutBindings: ({})
    property string inAppShortcutStatus: ""
    property bool accessHintsVisible: false
    property int lyricsFontSize: 28
    property string defaultLaunchPage: "last"
    property string settingsSection: "library"
    property var excludedFolders: []
    property bool ignoreShortClips: false
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true
    property int albumArtRadius: 16
    property string nowPlayingBackdrop: "tinted"
    property bool showRemainingTime: true
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: "Off"
    property bool sleepFadeOut: true
    property int sleepTimerRemainingSeconds: 0
    property bool autoplayEnabled: false
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80
    property string replayGainMode: "off"
    property bool preferLocalLyrics: true
    property string lyricsAlignment: "left"
    property string lyricsActiveStyle: "white"
    property bool offlineBlackout: false
    property bool svcLrclib: true
    property bool svcRadio: true
    property bool svcDeezer: true
    property bool svcAudiodb: true
    property bool svcWiki: true
    property bool svcArchive: true
    property bool scrobbleListenBrainzEnabled: false
    property string scrobbleListenBrainzUser: ""
    property bool scrobbleListenBrainzConnected: false
    property bool scrobbleLibreFmEnabled: false
    property string scrobbleLibreFmUser: ""
    property bool scrobbleLibreFmConnected: false
    property bool lastTrackRestored: false
    property bool playerStateDirty: false
    property bool jellyfinConnecting: false
    property string jellyfinError: ""
    property bool subsonicConnecting: false
    property string subsonicError: ""

    ShortcutDefinitions {
        id: shortcutDefinitions
    }

    Binding {
        target: player
        property: "audioMeterEnabled"
        value: (nowPlayingLoader.item !== null && nowPlayingLoader.item.audioMeterVisible)
            || (miniPlayerWindow !== null && miniPlayerWindow.audioMeterVisible)
    }

    Connections {
        target: streaming
        function onServerConnected(protocol, displayName) {
            if (protocol === "jellyfin") {
                jellyfinConnecting = false
                jellyfinError = ""
            } else if (protocol === "subsonic") {
                subsonicConnecting = false
                subsonicError = ""
            }
        }
        function onServerFailed(protocol, message) {
            if (protocol === "jellyfin") {
                jellyfinConnecting = false
                jellyfinError = message
            } else if (protocol === "subsonic") {
                subsonicConnecting = false
                subsonicError = message
            }
        }
        function onRemoteLibraryLoadingChanged() {
            if (!streaming.remoteLibraryLoading) {
                restoreLastPlayedTrack()
                restorePlaybackQueue()
                restorePlaybackHistory()
            }
        }
        function onJellyfinLyricsFetched(filePath, lyrics) {
            if (!player.currentTrack || player.currentTrack.filePath !== filePath) return
            if (lyrics && lyrics.trim().length) {
                applyLyrics(lyrics, "Jellyfin")
            } else if (!offlineBlackout && svcLrclib) {
                services.fetchLyrics(player.currentTrack.title || player.currentTrack.fileName || "", player.currentTrack.artist || "", player.currentTrack.album || "", player.currentTrack.durationSeconds || 0)
            }
        }
    }

    Connections {
        target: library
        function onTracksChanged() {
            libraryRevision++
            refreshLibraryState()
            reconcileTrackSnapshots()
            reconcileLibraryMaps()
        }
    }

    property var parsedLyrics: parseLrc(player.currentLyrics)
    property int activeLyricIndex: -1
    property var lyricDisplayItems: buildLyricDisplayItems(parsedLyrics)
    property int activeLyricDisplayIndex: -1
    property string lyricsProvider: ""
    property int lyricsSyncOffsetMs: 0
    property bool lyricSearchOpen: false
    property bool lyricSearchLoading: false
    property var lyricSearchResults: []
    property var lyricsSelectionCallback: null
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

    function availableTracks() {
        return library.playbackTracks()
    }

    function playbackTracks() {
        return availableTracks().concat(streaming.remoteTracks || [])
    }

    // Resolves saved paths in C++ instead of converting the whole library; server tracks are matched here.
    // The result is aligned with paths, with undefined where no track matches.
    function tracksForPaths(paths) {
        const remoteByPath = {}
        const remoteTracks = streaming.remoteTracks || []
        remoteTracks.forEach(track => remoteByPath[normalizedPlaylistPath(track.filePath)] = track)
        return library.tracksForPaths(paths).map((track, index) =>
            track.filePath ? track : remoteByPath[normalizedPlaylistPath(paths[index])])
    }

    function updateVisibleLibrary() {
        if (page === "search") {
            library.setSearchFilter(searchQuery, activeFormatFilter, excludedFolders, ignoreShortClips)
        } else {
            library.setLibraryFilter(libSearchQuery, songFilterMode, favoriteTracks, songSortMetric,
                                     songSortAscending, excludedFolders, ignoreShortClips)
        }
    }

    readonly property bool queueEntriesNeeded: (nowPlayingOpen && nowPlayingMode === "queue")
        || (miniPlayerWindow && miniPlayerWindow.visible && miniPlayerWindow.mode === "queue")
    readonly property var queueEntries: queueEntriesNeeded ? buildQueueEntries() : []

    function buildQueueEntries() {
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
        const queue = activePlaybackQueue()
        const currentIndex = currentQueueIndex()
        const upcoming = currentIndex >= 0 ? queue.slice(currentIndex + 1) : queue
        if (upcoming.length) {
            entries.push({ type: "header", title: "UP NEXT" })
            const baseOffset = currentIndex >= 0 ? currentIndex + 1 : 0
            upcoming.forEach((track, idx) => entries.push({
                type: "track",
                track: track,
                title: track.title,
                fileName: track.fileName,
                filePath: track.filePath,
                artist: track.artist,
                album: track.album,
                duration: track.duration,
                queueEditable: true,
                queueIndex: baseOffset + idx
            }))
        }
        return entries
    }

    property var radioStations: []
    property var radioFavoriteStations: []
    property var radioRecentStations: []
    property var radioCustomStations: []
    property string radioSearchQuery: ""
    property string radioActiveTag: "ALL"
    property string radioCountryFilter: ""
    property string radioLanguageFilter: ""
    property string radioSortOrder: "votes"
    property bool radioSortDescending: true
    property string radioViewMode: "grid"
    property bool radioRefineOpen: false
    property bool radioLoading: false
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
            radioLoading = false
            radioStations = stations
        }
        function onListenBrainzValidationFinished(valid, userName, error) {
            if (valid) {
                window.scrobbleListenBrainzUser = userName
                window.scrobbleListenBrainzConnected = true
                window.scrobbleListenBrainzEnabled = true
                appSettings.setValue("scrobble/listenbrainz_user", userName)
                appSettings.setValue("scrobble/listenbrainz_enabled", true)
            }
        }
        function onLibreFmAuthFinished(success, userName, sessionKey, error) {
            if (success) {
                window.scrobbleLibreFmUser = userName
                window.scrobbleLibreFmConnected = true
                window.scrobbleLibreFmEnabled = true
                appSettings.setValue("scrobble/librefm_user", userName)
                appSettings.setValue("scrobble/librefm_enabled", true)
            }
        }
        function onCoverApplied(album, artist, artworkPath, filePath) {
            library.setAlbumArtwork(album, artist, artworkPath)
            if (filePath) {
                library.setCustomArtwork(filePath, artworkPath)
            }
            if (player.currentTrack) {
                const trackAlbum = player.currentTrack.album || ""
                const trackArtist = player.currentTrack.artist || ""
                const trackFile = player.currentTrack.filePath || ""
                const sameArtist = !artist || trackArtist.trim().toLowerCase() === artist.trim().toLowerCase()
                if ((filePath && trackFile === filePath) || (album && sameArtist && trackAlbum.trim().toLowerCase() === album.trim().toLowerCase())) {
                    player.updateCurrentTrackArtwork(artworkPath)
                }
            }
        }
        function onUpdateCheckFinished(updateAvailable, latestVersion, releaseUrl, releaseNotes, manual) {
            updateChecking = false
            updateAvailableState = updateAvailable
            updateUrl = releaseUrl
            if (updateAvailable) {
                updateStatusText = "Update available: v" + latestVersion
            } else {
                updateStatusText = "CassetteCat is up to date (v0.6.0)"
            }
        }
        function onUpdateCheckFailed(error, manual) {
            updateChecking = false
            updateStatusText = "Update check failed: " + error
        }
    }

    property string updateStatusText: "Current version: v0.6.0"
    property bool updateChecking: false
    property bool updateAvailableState: false
    property string updateUrl: ""

    function checkForUpdates() {
        updateChecking = true
        updateStatusText = "Checking for updates..."
        services.checkForUpdates(true)
    }

    function downloadUpdate() {
        if (updateUrl) services.openExternalUrl(updateUrl)
    }

    // Flickables do not follow keyboard focus, so scroll every enclosing one to reveal the focused item.
    onActiveFocusItemChanged: {
        const item = activeFocusItem
        if (!item || item.mouseFocused) return
        for (let view = item.parent; view; view = view.parent) {
            if (view.flickableDirection === undefined) continue
            const r = item.mapToItem(view.contentItem, 0, 0, item.width, item.height)
            if (view.contentHeight > view.height) {
                const top = Math.min(r.y, Math.max(view.contentY, r.y + r.height - view.height))
                view.contentY = Math.max(view.originY, Math.min(top, view.originY + view.contentHeight - view.height))
            }
            if (view.contentWidth > view.width) {
                const left = Math.min(r.x, Math.max(view.contentX, r.x + r.width - view.width))
                view.contentX = Math.max(view.originX, Math.min(left, view.originX + view.contentWidth - view.width))
            }
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
        homeScrollPosition = appSettings.value("ui/homeScrollPosition", 0)
        window.libraryTab = appSettings.value("ui/libraryTab", "songs")
        libraryViewMode = appSettings.value("ui/libraryViewMode", "grid")
        sidebarCollapsed = appSettings.value("ui/sidebarCollapsed", false)
        libSearchQuery = ""
        searchQuery = ""
        activeFormatFilter = appSettings.value("search/formatFilter", "ALL")
        radioSearchQuery = ""
        radioActiveTag = appSettings.value("radio/activeTag", "ALL")
        radioCountryFilter = appSettings.value("radio/country", "")
        radioLanguageFilter = appSettings.value("radio/language", "")
        radioSortOrder = appSettings.value("radio/sortOrder", "votes")
        radioSortDescending = appSettings.value("radio/sortDescending", true)
        radioViewMode = appSettings.value("radio/viewMode", "grid")
        nowPlayingOpen = false
        nowPlayingMode = appSettings.value("player/nowPlayingMode", "controls")
        miniPlayerAlwaysOnTop = appSettings.value("ui/miniPlayerAlwaysOnTop", true)
        resumeQueueOnLaunch = appSettings.value("player/resumeQueueOnLaunch", true)
        player.setAudioDevice(appSettings.value("player/audioDeviceId", ""))
        try {
            const savedShortcuts = appSettings.value("ui/inAppShortcuts", "{}")
            const parsedShortcuts = typeof savedShortcuts === "string" ? JSON.parse(savedShortcuts) : savedShortcuts
            inAppShortcutBindings = normalizeInAppShortcutBindings(parsedShortcuts)
        } catch (error) {
            inAppShortcutBindings = ({})
        }
        appSettings.setValue("ui/inAppShortcuts", JSON.stringify(inAppShortcutBindings))
        const defaultGlobalShortcuts = {
            playPause: "Ctrl+Alt+Space",
            previous: "Ctrl+Alt+Left",
            next: "Ctrl+Alt+Right",
            favorite: "Ctrl+Alt+F",
            search: "Ctrl+Alt+S",
            miniPlayer: "Ctrl+Alt+M"
        }
        for (const action in defaultGlobalShortcuts) {
            const key = appSettings.value("ui/globalShortcut/" + action, defaultGlobalShortcuts[action])
            if (!globalShortcuts.supported) continue
            if (globalShortcuts.setShortcut(action, key)) {
                appSettings.setValue("ui/globalShortcut/" + action, globalShortcuts.shortcuts[action])
            } else {
                appSettings.setValue("ui/globalShortcut/" + action, defaultGlobalShortcuts[action])
            }
        }
        globalShortcutsEnabled = appSettings.value("ui/globalShortcutsEnabled", false)
        closeToTray = appSettings.value("ui/closeToTray", false)
        startMinimizedToTray = appSettings.value("ui/startMinimizedToTray", false)
        nowPlayingNotifications = appSettings.value("ui/nowPlayingNotifications", "minimized")
        if (startMinimizedToTray && tray.available) {
            window.hide()
        }
        lyricsFontSize = appSettings.value("lyrics/fontSize", 28)
        accentName = appSettings.value("ui/accentName", "recordRed")
        customAccentColor = appSettings.value("ui/customAccentColor", "#C23B30")
        albumArtRadius = appSettings.value("ui/albumArtRadius", 16)
        nowPlayingBackdrop = appSettings.value("player/nowPlayingBackdrop", "tinted")
        showRemainingTime = appSettings.value("player/showRemainingTime", true)
        trackDensity = appSettings.value("ui/trackDensity", "comfortable")
        showFormatBadges = appSettings.value("ui/showFormatBadges", true)
        ignoreShortClips = appSettings.value("library/ignoreShortClips", false)
        defaultLaunchPage = appSettings.value("ui/defaultLaunchPage", "last")
        settingsSection = appSettings.value("ui/settingsSection", "library")
        try {
            const exc = appSettings.value("library/excludedFolders", [])
            excludedFolders = Array.isArray(exc) ? exc : []
        } catch (e) {
            excludedFolders = []
        }
        autoplayEnabled = appSettings.value("player/autoplayEnabled", false)
        sleepFadeOut = appSettings.value("player/sleepFadeOut", true)
        sleepTimerMode = appSettings.value("player/sleepTimerMode", "off")
        volumeLimitEnabled = appSettings.value("player/volumeLimitEnabled", false)
        maxVolumePercent = appSettings.value("player/maxVolumePercent", 80)
        replayGainMode = appSettings.value("player/replayGainMode", "off")
        player.setReplayGainMode(replayGainMode)
        lyricsAlignment = appSettings.value("lyrics/alignment", "left")
        lyricsActiveStyle = appSettings.value("lyrics/activeStyle", "white")
        preferLocalLyrics = appSettings.value("lyrics/preferLocal", true)
        offlineBlackout = appSettings.value("network/offlineBlackout", false)
        svcLrclib = appSettings.value("services/lrclib", true)
        svcRadio = appSettings.value("services/radio", true)
        svcDeezer = appSettings.value("services/deezer", true)
        svcAudiodb = appSettings.value("services/audiodb", true)
        svcWiki = appSettings.value("services/wiki", true)
        svcArchive = appSettings.value("services/archive", true)
        scrobbleListenBrainzEnabled = appSettings.value("scrobble/listenbrainz_enabled", false)
        scrobbleListenBrainzUser = appSettings.value("scrobble/listenbrainz_user", "")
        scrobbleListenBrainzConnected = services.hasListenBrainzSession()
        scrobbleLibreFmEnabled = appSettings.value("scrobble/librefm_enabled", false)
        scrobbleLibreFmUser = appSettings.value("scrobble/librefm_user", "")
        scrobbleLibreFmConnected = services.hasLibreFmSession()

        if (defaultLaunchPage && defaultLaunchPage !== "last") {
            page = defaultLaunchPage
        } else {
            page = appSettings.value("ui/page", "home")
        }

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
            setPlayerVolume(appSettings.value("player/volume", 1.0))
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
        try {
            radioFavoriteStations = JSON.parse(appSettings.value("radio/favorites", "[]") || "[]")
        } catch (e) {
            radioFavoriteStations = []
        }
        try {
            radioRecentStations = JSON.parse(appSettings.value("radio/recents", "[]") || "[]")
        } catch (e) {
            radioRecentStations = []
        }
        try {
            radioCustomStations = JSON.parse(appSettings.value("radio/customStations", "[]") || "[]")
        } catch (e) {
            radioCustomStations = []
        }
        restorePlaylists()
        playCounts = numberMapFromSetting("library/playCounts")
        seenAt = numberMapFromSetting("library/seenAt")
        settingsInitialized = true
        reconcileLibraryMaps()
        refreshHomeRecommendations()
        updateVisibleLibrary()

        if (streaming.subsonicConnected || streaming.jellyfinConnected) {
            streaming.refreshLibrary()
        }
        restoreLastPlayedTrack()
        restorePlaybackQueue()
        restorePlaybackHistory()
        if (page === "radio") Qt.callLater(refreshRadio)
        if (!startMinimizedToTray) {
            Qt.callLater(function() {
                if (!isMaximized) {
                    window.showNormal()
                    const savedX = appSettings.value("window/x", -1)
                    const savedY = appSettings.value("window/y", -1)
                    const validX = (savedX >= 0 && savedX < Screen.width - 100)
                    const validY = (savedY >= 0 && savedY < Screen.height - 100)
                    window.x = validX ? savedX : Math.max(0, Math.round((Screen.width - window.width) / 2))
                    window.y = validY ? savedY : Math.max(0, Math.round((Screen.height - window.height) / 2))
                }
                window.raise()
                window.requestActivate()
            })
        }
    }

    function restoreLastPlayedTrack() {
        if (!resumeQueueOnLaunch || lastTrackRestored) return
        const lastTrackPath = appSettings.value("player/lastTrack", "")
        if (!lastTrackPath) {
            lastTrackRestored = true
            return
        }
        const track = tracksForPaths([lastTrackPath])[0]
        if (track && track.filePath) {
            lastTrackRestored = true
            player.restoreTrack(track, appSettings.value("player/lastPosition", 0))
        } else if (!streaming.remoteLibraryLoading && library.trackCount > 0) {
            lastTrackRestored = true
        }
    }

    function persistPlayerState() {
        if (!settingsInitialized || !player.currentTrack || !player.currentTrack.filePath) return
        appSettings.setValues({
            "player/lastTrack": player.currentTrack.filePath,
            "player/lastPosition": Math.max(0, player.position)
        })
        appSettings.sync()
    }

    function restorePlaybackHistory() {
        if (playbackHistoryRestored) return
        if (library.trackCount === 0 && streaming.remoteTracks.length === 0) return
        const tracks = restoredTracks("player/history")
        if (tracks.length > 0 || (!streaming.remoteLibraryLoading && library.trackCount > 0)) {
            playbackHistoryRestored = true
            playbackHistory = tracks.slice(0, 50)
        }
    }

    function restorePlaybackQueue() {
        if (!resumeQueueOnLaunch || playbackQueueRestored) return
        if (library.trackCount === 0 && streaming.remoteTracks.length === 0) return
        const queue = restoredTracks("player/queue")
        if (queue.length > 0 || (!streaming.remoteLibraryLoading && library.trackCount > 0)) {
            playbackQueueRestored = true
            playbackQueue = queue
            originalPlaybackQueue = restoredTracks("player/originalQueue")
            if (!originalPlaybackQueue.length) originalPlaybackQueue = playbackQueue.slice()
        }
    }

    function restoredTracks(key) {
        try {
            const savedPaths = JSON.parse(appSettings.value(key, "[]") || "[]")
            return uniqueTracks(tracksForPaths(savedPaths).filter(track => !!track))
        } catch (e) {
            return []
        }
    }

    function savedTrackPaths(trackList) {
        return JSON.stringify((trackList || []).map(track => track.filePath).filter(path => !!path))
    }

    function restorePlaylists() {
        try {
            const saved = JSON.parse(appSettings.value("library/playlists", "[]") || "[]")
            playlists = Array.isArray(saved) ? saved.filter(item => item && item.id && item.name && Array.isArray(item.trackPaths)) : []
        } catch (e) {
            playlists = []
        }
    }

    function playlistTracks(playlist) {
        if (!playlist) return []
        if (typeof playlist === "string") {
            // Built-in names win over a custom playlist that happens to share one.
            const builtIn = ["Favorites", "Most Played", "Recently Added", "Never Played"].includes(playlist)
            const pl = playlists.find(p => p.id === playlist) || (builtIn ? null : playlists.find(p => p.name === playlist))
            playlist = pl || { name: playlist }
        }
        if (Array.isArray(playlist.trackPaths)) {
            return tracksForPaths(playlist.trackPaths).filter(track => !!track)
        }
        if (playlist.name === "Favorites") {
            return availableTracks().filter(track => isFavorite(track.filePath))
        }
        if (playlist.name === "Most Played") {
            return heavyRotation.length > 0 ? heavyRotation : availableTracks().filter(track => (playCounts[track.filePath] || 0) > 0)
        }
        if (playlist.name === "Recently Added") {
            return recentlyAdded
        }
        if (playlist.name === "Never Played") {
            return availableTracks().filter(track => !playCounts[track.filePath])
        }
        return []
    }

    function createPlaylist(name, tracks) {
        const title = String(name || "").trim()
        if (!title) return false
        const trackPaths = [...new Set((tracks || []).map(track => track.filePath).filter(path => !!path))]
        playlists = playlists.concat([{ id: Date.now().toString(36), name: title, trackPaths: trackPaths }])
        return true
    }

    function clearListeningRecord() {
        playCounts = {}
        playbackHistory = []
        historyRecordedForTrack = false
    }

    function isTrackSelected(path) {
        return !!(path && selectedTrackPaths[path])
    }

    function toggleTrackSelection(path) {
        if (!path) return
        const next = Object.assign({}, selectedTrackPaths)
        if (next[path]) delete next[path]
        else next[path] = true
        selectedTrackPaths = next
    }

    function clearTrackSelection() {
        selectedTrackPaths = {}
    }

    function selectedTracks() {
        return playbackTracks().filter(track => isTrackSelected(track.filePath))
    }

    function addSelectedTracksToQueue() {
        selectedTracks().forEach(track => appendToQueue(track))
        clearTrackSelection()
    }

    function favoriteSelectedTracks() {
        const next = Object.assign({}, favoriteTracks)
        selectedTracks().forEach(track => { if (track.filePath) next[track.filePath] = true })
        favoriteTracks = next
        clearTrackSelection()
    }

    function createSmartPlaylist(name, tracks) {
        const paths = [...new Set((tracks || []).map(track => track.filePath).filter(path => !!path))]
        if (!paths.length) return false
        const existing = playlists.find(playlist => playlist.name === name)
        playlists = existing
            ? playlists.map(playlist => playlist.id === existing.id ? Object.assign({}, playlist, { trackPaths: paths }) : playlist)
            : playlists.concat([{ id: Date.now().toString(36), name: name, trackPaths: paths }])
        playlistStatus = name + " updated"
        return true
    }

    function libraryHealth() {
        const tracks = availableTracks().filter(track => track && track.format !== "STREAM")
        const keys = {}
        tracks.forEach(track => {
            const key = [track.title, track.artist, track.album].map(value => String(value || "").trim().toLowerCase()).join("\u001f")
            keys[key] = (keys[key] || 0) + 1
        })
        return {
            total: tracks.length,
            noFolderArtwork: tracks.filter(track => !track.artworkUrl).length,
            metadataGaps: tracks.filter(track => !track.title || !track.artist || !track.album).length,
            duplicateMetadata: Object.keys(keys).filter(key => key && keys[key] > 1).reduce((total, key) => total + keys[key] - 1, 0)
        }
    }

    function deletePlaylist(id) {
        playlists = playlists.filter(playlist => playlist.id !== id)
    }

    function playPlaylist(playlist) {
        const tracks = playlistTracks(playlist)
        if (tracks.length) startPlayback(tracks, 0, false)
    }

    function saveQueueAsPlaylist(name) {
        const queue = activePlaybackQueue().filter(track => track.format !== "STREAM")
        return queue.length > 0 && createPlaylist(name, queue)
    }

    function addTrackToPlaylist(id, track) {
        if (!id || !track || !track.filePath || track.format === "STREAM") return false
        let added = false
        playlists = playlists.map(playlist => {
            if (playlist.id !== id || playlist.trackPaths.includes(track.filePath)) return playlist
            added = true
            return Object.assign({}, playlist, { trackPaths: playlist.trackPaths.concat([track.filePath]) })
        })
        if (added) playlistStatus = "Added to playlist"
        return added
    }

    function appendToQueue(track) {
        if (!track || !track.filePath || track.format === "STREAM"
                || (player.currentTrack && player.currentTrack.format === "STREAM")) return false
        if (playbackQueue.some(candidate => trackIdentity(candidate) === trackIdentity(track))) return false
        playbackQueue = playbackQueue.concat([track])
        if (!originalPlaybackQueue.some(candidate => trackIdentity(candidate) === trackIdentity(track))) {
            originalPlaybackQueue = originalPlaybackQueue.concat([track])
        }
        queueRevision++
        return true
    }

    function insertTrackNext(track) {
        if (!track || !track.filePath || track.format === "STREAM"
                || (player.currentTrack && player.currentTrack.format === "STREAM")) return false
        if (!playbackQueue.length || !player.currentTrack.filePath) return playTrack(track)
        const currentIdx = playbackQueue.findIndex(candidate => trackIdentity(candidate) === trackIdentity(player.currentTrack))
        const insertAt = currentIdx >= 0 ? currentIdx + 1 : 0
        const filtered = playbackQueue.filter(candidate => trackIdentity(candidate) !== trackIdentity(track))
        playbackQueue = filtered.slice(0, insertAt).concat([track]).concat(filtered.slice(insertAt))
        if (!originalPlaybackQueue.some(candidate => trackIdentity(candidate) === trackIdentity(track))) {
            originalPlaybackQueue = originalPlaybackQueue.concat([track])
        }
        queueRevision++
        return true
    }

    function requestPlaylistImport() {
        playlistImportDialog.open()
    }

    function requestPlaylistExport(playlist) {
        playlistPendingExport = playlist
        playlistExportDialog.open()
    }

    function normalizedPlaylistPath(path) {
        let value = String(path || "").trim()
        if (!value || value.startsWith("#")) return ""
        if (value.startsWith("file://")) value = decodeURIComponent(value.replace(/^file:\/\/\/?/i, ""))
        return value.replace(/\\/g, "/").replace(/^\/+([A-Za-z]:\/)/, "$1").toLowerCase()
    }

    function importM3u(url) {
        const sourcePath = library.localPath(url)
        if (!sourcePath) {
            playlistStatus = "Could not read playlist"
            return
        }
        const parsedTracks = library.parseM3u(sourcePath)
        if (!parsedTracks || !parsedTracks.length) {
            playlistStatus = "No playable tracks found in playlist"
            return
        }
        const tracks = tracksForPaths(parsedTracks.map(track => track.filePath))
            .filter(track => !!track && track.format !== "STREAM")
        if (!tracks.length) {
            playlistStatus = "No library tracks found in playlist"
            return
        }
        const fileName = sourcePath.replace(/\\/g, "/").split("/").pop()
        const name = fileName.replace(/\.[^.]+$/, "") || "Imported playlist"
        createPlaylist(name, tracks)
        playlistStatus = "Imported " + tracks.length + " track" + (tracks.length === 1 ? "" : "s")
    }

    function exportM3u(url) {
        const playlist = playlistPendingExport
        playlistPendingExport = null
        if (!playlist) return
        const tracks = playlistTracks(playlist)
        const text = "#EXTM3U\n" + tracks.map(track => track.filePath).join("\n") + (tracks.length ? "\n" : "")
        playlistStatus = appSettings.exportTextFile(url, text)
            ? "Exported " + tracks.length + " track" + (tracks.length === 1 ? "" : "s")
            : "Could not export playlist"
    }

    function numberMap(value) {
        const result = {}
        if (!value || typeof value !== "object" || Array.isArray(value)) return result
        Object.keys(value).forEach(path => {
            const number = value[path]
            if (typeof number === "number" && isFinite(number) && number > 0) result[path] = number
        })
        return result
    }

    function numberMapFromSetting(key) {
        try {
            return numberMap(JSON.parse(appSettings.value(key, "{}") || "{}"))
        } catch (e) {
            return {}
        }
    }

    function sameNumberMap(left, right) {
        const leftKeys = Object.keys(left)
        const rightKeys = Object.keys(right)
        if (leftKeys.length !== rightKeys.length) return false
        return leftKeys.every(path => left[path] === right[path])
    }

    function reconcileLibraryMaps() {
        if (!settingsInitialized || library.trackCount === 0) return
        const nextCounts = Object.assign({}, playCounts)
        const nextSeenAt = Object.assign({}, seenAt)
        const now = Date.now()
        library.availablePaths().forEach(path => {
            if (!nextSeenAt[path]) nextSeenAt[path] = now
        })
        if (!sameNumberMap(playCounts, nextCounts)) playCounts = nextCounts
        if (!sameNumberMap(seenAt, nextSeenAt)) seenAt = nextSeenAt
    }

    function reconcileTrackSnapshots() {
        const snapshotKey = path => String(path || "").replace(/\\/g, "/")
        const snapshots = [].concat(playbackHistory, playbackQueue, originalPlaybackQueue, radioPlaybackQueue,
                                    originalRadioPlaybackQueue, catalogDetailTracks, historyTrackedTrack,
                                    catalogDetailHeroTrack, (catalogDetailHistory || []).map(entry => entry && entry.heroTrack))
        const snapshotPaths = [...new Set(snapshots.filter(track => track && track.filePath)
                                                   .map(track => snapshotKey(track.filePath)))]
        const tracksByPath = {}
        tracksForPaths(snapshotPaths).forEach((track, index) => {
            if (track) tracksByPath[snapshotPaths[index]] = track
        })

        const snapshotChanged = (left, right) => {
            if (!left || !right) return left !== right
            return ["filePath", "title", "fileName", "artist", "album", "genre", "artworkUrl",
                    "duration", "durationSeconds", "format", "source", "remoteId"]
                .some(key => left[key] !== right[key])
        }
        const refreshTrack = track => {
            if (!track || !track.filePath) return track
            const replacement = tracksByPath[snapshotKey(track.filePath)]
            return replacement && snapshotChanged(track, replacement) ? replacement : track
        }

        let changed = false
        const refreshList = list => {
            const source = list || []
            let listChanged = false
            const next = source.map(track => {
                const refreshed = refreshTrack(track)
                if (refreshed !== track) listChanged = true
                return refreshed
            })
            if (listChanged) changed = true
            return listChanged ? next : source
        }

        playbackHistory = refreshList(playbackHistory)
        playbackQueue = refreshList(playbackQueue)
        originalPlaybackQueue = refreshList(originalPlaybackQueue)
        radioPlaybackQueue = refreshList(radioPlaybackQueue)
        originalRadioPlaybackQueue = refreshList(originalRadioPlaybackQueue)
        if (catalogDetailOpen) {
            catalogDetailTracks = filterCatalogDetailTracks(catalogDetailMode, catalogDetailKey, catalogDetailHeroTrack)
            changed = true
        } else {
            catalogDetailTracks = refreshList(catalogDetailTracks)
        }

        const refreshedHistoryTrack = refreshTrack(historyTrackedTrack)
        if (refreshedHistoryTrack !== historyTrackedTrack)
            historyTrackedTrack = refreshedHistoryTrack

        const refreshedHero = refreshTrack(catalogDetailHeroTrack)
        if (refreshedHero !== catalogDetailHeroTrack) {
            catalogDetailHeroTrack = refreshedHero
            changed = true
        }

        let historyChanged = false
        const nextHistory = (catalogDetailHistory || []).map(entry => {
            if (!entry || !entry.heroTrack) return entry
            const heroTrack = refreshTrack(entry.heroTrack)
            if (heroTrack === entry.heroTrack) return entry
            historyChanged = true
            return Object.assign({}, entry, { heroTrack: heroTrack })
        })
        if (historyChanged) {
            catalogDetailHistory = nextHistory
            changed = true
        }
        if (changed) queueRevision++
    }

    function resetHistoryTracking(track) {
        historyTrackedTrack = track && track.filePath ? track : null
        historyAccumulatedMs = 0
        historyPlayingSince = player.isPlaying && historyTrackedTrack ? Date.now() : 0
        historyRecordedForTrack = false
        if (track && track.format !== "STREAM") {
            services.scrobbleNowPlaying(track)
        }
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
        const counts = Object.assign({}, playCounts)
        counts[historyTrackedTrack.filePath] = (counts[historyTrackedTrack.filePath] || 0) + 1
        playCounts = counts
        playbackHistory = [historyTrackedTrack].concat(playbackHistory.filter(track => track.filePath !== historyTrackedTrack.filePath)).slice(0, 50)
        if (historyTrackedTrack.format !== "STREAM") {
            services.scrobbleTrack(historyTrackedTrack, Math.floor(Date.now() / 1000))
        }
    }

    function finishHistoryTracking() {
        pauseHistoryTracking()
        historyTrackedTrack = null
    }

    function refreshRadio() {
        if (!settingsInitialized || page !== "radio" || offlineBlackout || !svcRadio) return
        radioLoading = true
        services.fetchRadioStations(
            radioSearchQuery,
            radioCountryFilter,
            radioLanguageFilter,
            radioActiveTag === "ALL" ? "" : radioActiveTag,
            radioSortOrder,
            radioSortDescending)
    }

    function saveSetting(key, value) {
        if (settingsInitialized) appSettings.setValue(key, value)
    }

    function normalizeInAppShortcutBindings(bindings) {
        const source = bindings || {}
        const normalized = {}
        const used = {}
        for (const item of shortcutDefinitions.inAppActions) {
            const defaultSequence = shortcutDefinitions.toSequence(item.defaultKey)
            if (!defaultSequence) continue
            if (!Object.prototype.hasOwnProperty.call(source, item.action)) {
                used[defaultSequence] = true
                continue
            }
            // A cleared or reassigned action frees its default key; an invalid override falls back to it.
            const raw = source[item.action]
            const sequence = raw === "" ? "" : shortcutDefinitions.toSequence(raw)
            if (raw !== "" && (!sequence || sequence === defaultSequence)) used[defaultSequence] = true
        }
        for (const item of shortcutDefinitions.inAppActions) {
            if (!Object.prototype.hasOwnProperty.call(source, item.action)) continue
            const raw = source[item.action]
            if (raw === "") {
                normalized[item.action] = ""
                continue
            }
            const sequence = shortcutDefinitions.toSequence(raw)
            if (!sequence || sequence === shortcutDefinitions.toSequence(item.defaultKey) || used[sequence]) continue
            normalized[item.action] = sequence
            used[sequence] = true
        }
        return normalized
    }

    function inAppShortcut(action) {
        if (inAppShortcutBindings && inAppShortcutBindings.hasOwnProperty(action)) {
            return shortcutDefinitions.toSequence(inAppShortcutBindings[action])
        }
        return shortcutDefinitions.toSequence(shortcutDefinitions.defaultKey(action))
    }

    function setInAppShortcut(action, shortcut) {
        const matching = shortcutDefinitions.inAppActions.find(item => item.action === action)
        if (!matching) return
        const sequence = shortcutDefinitions.toSequence(shortcut)
        if (sequence.length > 0) {
            for (const item of shortcutDefinitions.inAppActions) {
                if (item.action !== action && inAppShortcut(item.action) === sequence) {
                    inAppShortcutStatus = shortcut + " is already assigned to " + item.label
                    return
                }
            }
        }
        const updated = Object.assign({}, inAppShortcutBindings)
        const defaultSequence = shortcutDefinitions.toSequence(matching.defaultKey)
        if (shortcut === matching.defaultKey || sequence === defaultSequence) delete updated[action]
        else updated[action] = sequence
        inAppShortcutBindings = updated
        inAppShortcutStatus = shortcut === "" ? "Shortcut cleared" : "Shortcut saved"
    }

    function isInputActive() {
        const item = window.activeFocusItem
        if (!item) return false
        if (item.isShortcutCapture === true) return true
        if (typeof item.cursorPosition !== "undefined" || typeof item.selectedText !== "undefined") return true
        return false
    }

    function focusSearchInput() {
        searchPageLoader.item.searchInput.forceActiveFocus()
        searchPageLoader.item.searchInput.selectAll()
    }

    function dismissSearchFocus(point) {
        const contains = function(item) {
            return item && item.visible && item.contains(item.mapFromItem(appArea, point.x, point.y))
        }
        const libraryPage = libraryPageLoader.item
        const searchPage = searchPageLoader.item
        const radioPage = radioPageLoader.item
        const jellyfinPage = jellyfinPageLoader.item
        const subsonicPage = subsonicPageLoader.item
        if (contains(libraryPage ? libraryPage.searchBox : null) || contains(searchPage ? searchPage.searchBox : null) || contains(radioPage ? radioPage.searchBox : null) || contains(jellyfinPage ? jellyfinPage.searchBox : null) || contains(subsonicPage ? subsonicPage.searchBox : null)) return
        if (libraryPage) {
            libraryPage.searchInput.focus = false
            if (!libraryPage.appWindow.libSearchQuery.length && libraryPage.searchBox) libraryPage.searchBox.collapse()
        }
        if (searchPage) searchPage.searchInput.focus = false
        if (radioPage) {
            radioPage.searchInput.focus = false
            if (!radioPage.appWindow.radioSearchQuery.length && radioPage.searchBox) radioPage.searchBox.collapse()
        }
        if (jellyfinPage) {
            jellyfinPage.searchInput.focus = false
            if (!jellyfinPage.searchQuery.length && jellyfinPage.searchBox) jellyfinPage.searchBox.collapse()
        }
        if (subsonicPage) {
            subsonicPage.searchInput.focus = false
            if (!subsonicPage.searchQuery.length && subsonicPage.searchBox) subsonicPage.searchBox.collapse()
        }
    }

    onPageChanged: {
        if (settingsInitialized) appSettings.setValue("ui/page", page)
        updateVisibleLibrary()
        if (page === "library") refreshLibraryGroups(library.catalogGroups())
        else clearLibraryGroups()
        if (settingsInitialized && page === "radio" && radioStations.length === 0) Qt.callLater(refreshRadio)
        if (page !== "radio") services.cancelRadioRequests()
        dismissSearchFocus(Qt.point(-1, -1))
    }
    onLibraryTabChanged: if (settingsInitialized) {
        appSettings.setValue("ui/libraryTab", window.libraryTab)
        if (libraryPageLoader.item) libraryPageLoader.item.searchInput.focus = false
    }
    onLibraryViewModeChanged: if (settingsInitialized) appSettings.setValue("ui/libraryViewMode", libraryViewMode)
    onRadioViewModeChanged: if (settingsInitialized) appSettings.setValue("radio/viewMode", radioViewMode)
    onSidebarCollapsedChanged: if (settingsInitialized) appSettings.setValue("ui/sidebarCollapsed", sidebarCollapsed)
    onSettingsSectionChanged: if (settingsInitialized) appSettings.setValue("ui/settingsSection", settingsSection)
    onLibSearchQueryChanged: {
        updateVisibleLibrary()
    }
    onSearchQueryChanged: {
        updateVisibleLibrary()
    }
    onActiveFormatFilterChanged: {
        if (settingsInitialized) appSettings.setValue("search/formatFilter", activeFormatFilter)
        updateVisibleLibrary()
    }
    onRadioSearchQueryChanged: {}
    onRadioActiveTagChanged: if (settingsInitialized) appSettings.setValue("radio/activeTag", radioActiveTag)
    onRadioCountryFilterChanged: if (settingsInitialized) appSettings.setValue("radio/country", radioCountryFilter)
    onRadioLanguageFilterChanged: if (settingsInitialized) appSettings.setValue("radio/language", radioLanguageFilter)
    onRadioSortOrderChanged: if (settingsInitialized) appSettings.setValue("radio/sortOrder", radioSortOrder)
    onRadioSortDescendingChanged: if (settingsInitialized) appSettings.setValue("radio/sortDescending", radioSortDescending)
    onMiniPlayerAlwaysOnTopChanged: {
        saveSetting("ui/miniPlayerAlwaysOnTop", miniPlayerAlwaysOnTop)
        if (miniPlayerWindow && miniPlayerWindow.visible) player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
    }
    onResumeQueueOnLaunchChanged: saveSetting("player/resumeQueueOnLaunch", resumeQueueOnLaunch)
    onOfflineBlackoutChanged: {
        saveSetting("network/offlineBlackout", offlineBlackout)
        streaming.setBlackoutEnabled(offlineBlackout)
        services.setBlackoutEnabled(offlineBlackout)
        const path = player.currentTrack ? player.currentTrack.filePath || "" : ""
        if (offlineBlackout && (/^(subsonic|jellyfin):/.test(path) || /^https?:/i.test(path))) player.stop()
    }
    onGlobalShortcutsEnabledChanged: {
        globalShortcuts.setEnabled(globalShortcutsEnabled)
        if (globalShortcuts.enabled !== globalShortcutsEnabled) {
            globalShortcutsEnabled = globalShortcuts.enabled
            return
        }
        saveSetting("ui/globalShortcutsEnabled", globalShortcutsEnabled)
    }
    onInAppShortcutBindingsChanged: {
        const normalized = normalizeInAppShortcutBindings(inAppShortcutBindings)
        if (JSON.stringify(normalized) !== JSON.stringify(inAppShortcutBindings)) {
            inAppShortcutBindings = normalized
            return
        }
        if (settingsInitialized) saveSetting("ui/inAppShortcuts", JSON.stringify(inAppShortcutBindings))
    }
    onLyricsFontSizeChanged: saveSetting("lyrics/fontSize", lyricsFontSize)
    onAccentNameChanged: saveSetting("ui/accentName", accentName)
    onCustomAccentColorChanged: saveSetting("ui/customAccentColor", customAccentColor)
    onAlbumArtRadiusChanged: saveSetting("ui/albumArtRadius", albumArtRadius)
    onNowPlayingBackdropChanged: saveSetting("player/nowPlayingBackdrop", nowPlayingBackdrop)
    onShowRemainingTimeChanged: {
        saveSetting("player/showRemainingTime", showRemainingTime)
        if (miniPlayerWindow && miniPlayerWindow.showRemainingTime !== showRemainingTime) {
            miniPlayerWindow.showRemainingTime = showRemainingTime
        }
    }
    onDefaultLaunchPageChanged: saveSetting("ui/defaultLaunchPage", defaultLaunchPage)
    onTrackDensityChanged: saveSetting("ui/trackDensity", trackDensity)
    onShowFormatBadgesChanged: saveSetting("ui/showFormatBadges", showFormatBadges)
    onIgnoreShortClipsChanged: {
        saveSetting("library/ignoreShortClips", ignoreShortClips)
        updateVisibleLibrary()
    }
    onSleepFadeOutChanged: saveSetting("player/sleepFadeOut", sleepFadeOut)
    onSleepTimerModeChanged: saveSetting("player/sleepTimerMode", sleepTimerMode)
    onAutoplayEnabledChanged: saveSetting("player/autoplayEnabled", autoplayEnabled)
    onVolumeLimitEnabledChanged: saveSetting("player/volumeLimitEnabled", volumeLimitEnabled)
    onMaxVolumePercentChanged: saveSetting("player/maxVolumePercent", maxVolumePercent)
    onReplayGainModeChanged: {
        player.setReplayGainMode(replayGainMode)
        saveSetting("player/replayGainMode", replayGainMode)
    }
    onPreferLocalLyricsChanged: saveSetting("lyrics/preferLocal", preferLocalLyrics)
    onLyricsAlignmentChanged: saveSetting("lyrics/alignment", lyricsAlignment)
    onLyricsActiveStyleChanged: saveSetting("lyrics/activeStyle", lyricsActiveStyle)
    onCloseToTrayChanged: saveSetting("ui/closeToTray", closeToTray)
    onStartMinimizedToTrayChanged: saveSetting("ui/startMinimizedToTray", startMinimizedToTray)
    onNowPlayingNotificationsChanged: saveSetting("ui/nowPlayingNotifications", nowPlayingNotifications)
    onSvcLrclibChanged: saveSetting("services/lrclib", svcLrclib)
    onSvcRadioChanged: {
        saveSetting("services/radio", svcRadio)
        if (!svcRadio) services.cancelRadioRequests()
    }
    onSvcDeezerChanged: saveSetting("services/deezer", svcDeezer)
    onSvcAudiodbChanged: saveSetting("services/audiodb", svcAudiodb)
    onSvcWikiChanged: saveSetting("services/wiki", svcWiki)
    onSvcArchiveChanged: saveSetting("services/archive", svcArchive)
    onScrobbleListenBrainzEnabledChanged: saveSetting("scrobble/listenbrainz_enabled", scrobbleListenBrainzEnabled)
    onScrobbleLibreFmEnabledChanged: saveSetting("scrobble/librefm_enabled", scrobbleLibreFmEnabled)
    onLyricsSyncOffsetMsChanged: if (settingsInitialized) {
        if (player.currentTrack && player.currentTrack.filePath) appSettings.setValue(lyricsSyncKey(player.currentTrack), lyricsSyncOffsetMs)
        parsedLyrics = parseLrc(player.currentLyrics)
        updateActiveLyric()
    }

    onSongSortMetricChanged: {
        if (settingsInitialized) appSettings.setValue("sort/songMetric", songSortMetric)
        updateVisibleLibrary()
    }
    onSongSortAscendingChanged: {
        if (settingsInitialized) appSettings.setValue("sort/songAscending", songSortAscending)
        updateVisibleLibrary()
    }
    onArtistSortMetricChanged: {
        saveSetting("sort/artistMetric", artistSortMetric)
        refreshVisibleLibraryGroups()
    }
    onArtistSortAscendingChanged: {
        saveSetting("sort/artistAscending", artistSortAscending)
        refreshVisibleLibraryGroups()
    }
    onAlbumSortMetricChanged: {
        saveSetting("sort/albumMetric", albumSortMetric)
        refreshVisibleLibraryGroups()
    }
    onAlbumSortAscendingChanged: {
        saveSetting("sort/albumAscending", albumSortAscending)
        refreshVisibleLibraryGroups()
    }
    onGenreSortMetricChanged: {
        saveSetting("sort/genreMetric", genreSortMetric)
        refreshVisibleLibraryGroups()
    }
    onGenreSortAscendingChanged: {
        saveSetting("sort/genreAscending", genreSortAscending)
        refreshVisibleLibraryGroups()
    }
    onFolderSortMetricChanged: if (settingsInitialized) appSettings.setValue("sort/folderMetric", folderSortMetric)
    onFolderSortAscendingChanged: if (settingsInitialized) appSettings.setValue("sort/folderAscending", folderSortAscending)
    onSongFilterModeChanged: {
        if (settingsInitialized) appSettings.setValue("sort/songFilterMode", songFilterMode)
        updateVisibleLibrary()
    }

    onFavoriteTracksChanged: {
        if (settingsInitialized) appSettings.setValue("library/favorites", JSON.stringify(favoriteTracks))
        if (songFilterMode === "FAVORITES") updateVisibleLibrary()
        if (quickPicks.length > 0)
            forgottenFavs = library.homeRecommendations(playCounts, seenAt, favoriteTracks, playbackHistory).forgottenFavs
    }
    onPlaylistsChanged: if (settingsInitialized) appSettings.setValue("library/playlists", JSON.stringify(playlists))
    onPlayCountsChanged: {
        if (settingsInitialized) appSettings.setValue("library/playCounts", JSON.stringify(playCounts))
        refreshHomeRecommendations()
    }
    onSeenAtChanged: {
        if (settingsInitialized) appSettings.setValue("library/seenAt", JSON.stringify(seenAt))
        refreshHomeRecommendations()
    }
    onExcludedFoldersChanged: {
        saveSetting("library/excludedFolders", excludedFolders)
        updateVisibleLibrary()
    }
    onPlaybackQueueChanged: if (settingsInitialized) appSettings.setValue("player/queue", savedTrackPaths(playbackQueue))
    onOriginalPlaybackQueueChanged: if (settingsInitialized) appSettings.setValue("player/originalQueue", savedTrackPaths(originalPlaybackQueue))
    onPlaybackHistoryChanged: {
        if (settingsInitialized) appSettings.setValue("player/history", savedTrackPaths(playbackHistory))
        refreshHomeRecommendations()
    }
    onRepeatModeChanged: {
        if (settingsInitialized) appSettings.setValue("player/repeatMode", repeatMode)
        if (typeof mpris !== "undefined" && mpris && mpris.repeatMode !== repeatMode) {
            mpris.repeatMode = repeatMode
        }
    }

    onVisibilityChanged: {
        if (window.visibility === Window.Hidden || window.visibility === Window.Minimized)
            window.releaseResources()
        if (settingsInitialized) {
            const isMax = (window.visibility === Window.Maximized)
            appSettings.setValue("window/maximized", isMax)
            if (!isMax && window.width > 400 && window.height > 300) {
                appSettings.setValue("window/width", window.width)
                appSettings.setValue("window/height", window.height)
                if (window.x >= 0) appSettings.setValue("window/x", window.x)
                if (window.y >= 0) appSettings.setValue("window/y", window.y)
            }
        }
    }

    onWidthChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.width > 400) {
        appSettings.setValue("window/width", window.width)
    }
    onHeightChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.height > 300) {
        appSettings.setValue("window/height", window.height)
    }
    onXChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.x >= 0) {
        appSettings.setValue("window/x", window.x)
    }
    onYChanged: if (settingsInitialized && window.visibility !== Window.Maximized && window.y >= 0) {
        appSettings.setValue("window/y", window.y)
    }
    onClosing: function(close) {
        persistBeforeExit()
        if (!appQuitting && closeToTray && tray.available) {
            close.accepted = false
            window.hide()
            tray.notifyHidden()
        } else if (!appQuitting) {
            appQuitting = true
            Qt.quit()
        }
    }

    function persistBeforeExit() {
        finishHistoryTracking()
        persistPlayerState()
        if (window.visibility !== Window.Maximized) {
            if (window.width > 400) appSettings.setValue("window/width", window.width)
            if (window.height > 300) appSettings.setValue("window/height", window.height)
            if (window.x >= 0) appSettings.setValue("window/x", window.x)
            if (window.y >= 0) appSettings.setValue("window/y", window.y)
        }
        appSettings.setValue("window/maximized", window.visibility === Window.Maximized)
        appSettings.setValues({
            "ui/page": page,
            "ui/homeScrollPosition": homeScrollPosition,
            "ui/libraryTab": libraryTab,
            "ui/libraryViewMode": libraryViewMode,
            "ui/sidebarCollapsed": sidebarCollapsed,
            "ui/accentName": accentName,
            "ui/customAccentColor": customAccentColor,
            "ui/albumArtRadius": albumArtRadius,
            "search/formatFilter": activeFormatFilter,
            "radio/activeTag": radioActiveTag,
            "radio/country": radioCountryFilter,
            "radio/language": radioLanguageFilter,
            "radio/sortOrder": radioSortOrder,
            "radio/sortDescending": radioSortDescending,
            "radio/viewMode": radioViewMode,
            "ui/miniPlayerAlwaysOnTop": miniPlayerAlwaysOnTop,
            "ui/globalShortcutsEnabled": globalShortcutsEnabled,
            "ui/inAppShortcuts": JSON.stringify(inAppShortcutBindings),
            "ui/nowPlayingNotifications": nowPlayingNotifications,
            "player/resumeQueueOnLaunch": resumeQueueOnLaunch,
            "player/nowPlayingMode": nowPlayingMode,
            "player/audioDeviceId": player.audioDeviceId,
            "ui/closeToTray": closeToTray,
            "ui/startMinimizedToTray": startMinimizedToTray,
            "ui/defaultLaunchPage": defaultLaunchPage,
            "ui/settingsSection": settingsSection,
            "ui/trackDensity": trackDensity,
            "ui/showFormatBadges": showFormatBadges,
            "library/ignoreShortClips": ignoreShortClips,
            "lyrics/fontSize": lyricsFontSize,
            "player/nowPlayingBackdrop": nowPlayingBackdrop,
            "player/showRemainingTime": showRemainingTime,
            "lyrics/alignment": lyricsAlignment,
            "lyrics/activeStyle": lyricsActiveStyle,
            "lyrics/preferLocal": preferLocalLyrics,
            "player/autoplayEnabled": autoplayEnabled,
            "player/sleepFadeOut": sleepFadeOut,
            "player/sleepTimerMode": sleepTimerMode,
            "player/volumeLimitEnabled": volumeLimitEnabled,
            "player/maxVolumePercent": maxVolumePercent,
            "player/replayGainMode": replayGainMode,
            "network/offlineBlackout": offlineBlackout,
            "services/lrclib": svcLrclib,
            "services/radio": svcRadio,
            "services/deezer": svcDeezer,
            "services/audiodb": svcAudiodb,
            "services/wiki": svcWiki,
            "services/archive": svcArchive,
            "scrobble/listenbrainz_enabled": scrobbleListenBrainzEnabled,
            "scrobble/listenbrainz_user": scrobbleListenBrainzUser,
            "scrobble/librefm_enabled": scrobbleLibreFmEnabled,
            "scrobble/librefm_user": scrobbleLibreFmUser,
            "sort/songMetric": songSortMetric,
            "sort/songAscending": songSortAscending,
            "sort/artistMetric": artistSortMetric,
            "sort/artistAscending": artistSortAscending,
            "sort/albumMetric": albumSortMetric,
            "sort/albumAscending": albumSortAscending,
            "sort/genreMetric": genreSortMetric,
            "sort/genreAscending": genreSortAscending,
            "sort/folderMetric": folderSortMetric,
            "sort/folderAscending": folderSortAscending,
            "sort/songFilterMode": songFilterMode,
            "player/repeatMode": repeatMode,
            "player/volume": fadeOutTimer.running ? fadeOutTimer.preFadeVolume : player.volume,
            "player/shuffleEnabled": player.shuffleEnabled,
            "library/excludedFolders": Array.isArray(excludedFolders) ? excludedFolders : [],
            "library/favorites": JSON.stringify(favoriteTracks),
            "library/playlists": JSON.stringify(playlists)
        })
        appSettings.sync()
    }

    function setBackupStatus(message) {
        if (settingsLoader.item) settingsLoader.item.backupStatus = message
    }

    function toggleMiniPlayer() {
        if (!miniPlayerWindow) {
            miniPlayerLoader.active = true
            return
        }
        if (!miniPlayerWindow.visible) {
            showMiniPlayer()
        } else {
            miniPlayerWindow.visible = false
            window.showNormal()
            window.raise()
            window.requestActivate()
        }
    }

    function showMiniPlayer() {
        if (!miniPlayerWindow) return
        miniPlayerWindow.x = Math.max(20, window.x + Math.round((window.width - miniPlayerWindow.width) / 2))
        miniPlayerWindow.y = Math.max(20, window.y + Math.round((window.height - miniPlayerWindow.height) / 2))
        miniPlayerWindow.visible = true
        player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
        miniPlayerWindow.requestActivate()
        window.showMinimized()
    }

    Shortcut {
        sequence: inAppShortcut("toggleMiniPlayer")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: toggleMiniPlayer()
    }

    Shortcut {
        sequence: inAppShortcut("toggleSidebar")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: {
            if (!miniPlayerMode) sidebarCollapsed = !sidebarCollapsed
        }
    }

    Shortcut {
        sequence: inAppShortcut("search")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: {
            if (!miniPlayerMode) {
                nowPlayingOpen = false
                page = "search"
            }
        }
    }

    Shortcut {
        sequence: inAppShortcut("quickSwitcher")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: {
            if (miniPlayerMode) return
            nowPlayingOpen = false
            page = "search"
            if (searchPageLoader.item) focusSearchInput()
            else searchPageLoader.focusOnLoad = true
        }
    }

    Shortcut {
        sequence: inAppShortcut("closePlayerView")
        // An open sheet handles Escape itself; two enabled shortcuts on one key would both be ignored as ambiguous.
        enabled: sequence.length > 0 && !isInputActive() && !refineSheetOpen && !radioRefineOpen && !trackActionSheet.isOpen
        onActivated: {
            if (miniPlayerMode) {
                toggleMiniPlayer()
            } else if (nowPlayingOpen) {
                nowPlayingOpen = false
            }
        }
    }

    Shortcut {
        sequence: inAppShortcut("playPause")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: {
            if (!player.currentTrack.filePath && library.trackCount > 0) {
                shuffleAll()
            } else {
                player.togglePlay()
            }
        }
    }

    Shortcut {
        sequence: inAppShortcut("volumeUp")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: setPlayerVolume(player.volume + 0.05)
    }

    Shortcut {
        sequence: inAppShortcut("volumeDown")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: setPlayerVolume(player.volume - 0.05)
    }

    Shortcut {
        sequence: inAppShortcut("seekForward")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: player.seek(Math.min(player.duration, player.position + 5000))
    }

    Shortcut {
        sequence: inAppShortcut("seekBackward")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: player.seek(Math.max(0, player.position - 5000))
    }

    Shortcut {
        sequence: inAppShortcut("nowPlayingNext")
        enabled: sequence.length > 0 && nowPlayingOpen && !isInputActive()
        onActivated: window.playNext()
    }

    Shortcut {
        sequence: inAppShortcut("nowPlayingPrevious")
        enabled: sequence.length > 0 && nowPlayingOpen && !isInputActive()
        onActivated: window.playPrevious()
    }

    Shortcut {
        sequence: inAppShortcut("mute")
        enabled: sequence.length > 0 && !isInputActive()
        onActivated: setPlayerVolume(player.volume > 0.001 ? 0.0 : 0.8)
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
        const norm = normalizedPlaylistPath(filePath)
        const favs = Object.assign({}, favoriteTracks)
        if (favs[norm] || favs[filePath]) {
            delete favs[norm]
            delete favs[filePath]
        } else {
            favs[norm] = true
        }
        favoriteTracks = favs
    }

    function isFavorite(filePath) {
        if (!filePath) return false
        return !!(favoriteTracks[filePath] || favoriteTracks[normalizedPlaylistPath(filePath)])
    }

    function isRadioFavorite(streamUrl) {
        if (!streamUrl) return false
        return radioFavoriteStations.some(s => s.streamUrl === streamUrl)
    }

    function toggleRadioFavorite(station) {
        if (!station || !station.streamUrl) return
        const favs = (radioFavoriteStations || []).slice()
        const idx = favs.findIndex(s => s.streamUrl === station.streamUrl)
        if (idx >= 0) {
            favs.splice(idx, 1)
        } else {
            favs.unshift({
                id: station.id || "",
                name: station.name || "Radio Station",
                streamUrl: station.streamUrl,
                favicon: station.favicon || "",
                tags: station.tags || "",
                country: station.country || "",
                language: station.language || "",
                bitrate: station.bitrate || 0
            })
        }
        radioFavoriteStations = favs
        if (settingsInitialized) appSettings.setValue("radio/favorites", JSON.stringify(favs))
    }

    function recordRadioRecent(station) {
        if (!station || !station.streamUrl) return
        const recents = (radioRecentStations || []).slice()
        const idx = recents.findIndex(s => s.streamUrl === station.streamUrl)
        if (idx >= 0) recents.splice(idx, 1)
        recents.unshift({
            id: station.id || "",
            name: station.name || "Radio Station",
            streamUrl: station.streamUrl,
            favicon: station.favicon || "",
            tags: station.tags || "",
            country: station.country || "",
            language: station.language || "",
            bitrate: station.bitrate || 0
        })
        if (recents.length > 30) recents.length = 30
        radioRecentStations = recents
        if (settingsInitialized) appSettings.setValue("radio/recents", JSON.stringify(recents))
    }

    function isRadioCustom(streamUrl) {
        if (!streamUrl) return false
        return radioCustomStations.some(s => s.streamUrl === streamUrl)
    }

    function addCustomRadioStation(station) {
        if (!station || !station.streamUrl) return
        const custom = (radioCustomStations || []).slice()
        const idx = custom.findIndex(s => s.streamUrl === station.streamUrl)
        const entry = {
            id: station.id || ("custom-" + Date.now()),
            name: station.name || "Custom Stream",
            streamUrl: station.streamUrl,
            favicon: station.favicon || "",
            tags: station.tags || "Custom",
            country: station.country || "Direct Stream",
            language: station.language || "",
            bitrate: station.bitrate || 0
        }
        if (idx >= 0) custom[idx] = entry
        else custom.unshift(entry)
        radioCustomStations = custom
        if (settingsInitialized) appSettings.setValue("radio/customStations", JSON.stringify(custom))
    }

    function removeCustomRadioStation(streamUrl) {
        if (!streamUrl) return
        const custom = (radioCustomStations || []).filter(s => s.streamUrl !== streamUrl)
        radioCustomStations = custom
        if (settingsInitialized) appSettings.setValue("radio/customStations", JSON.stringify(custom))
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
        const base = window.lyricsActiveStyle === "accent" ? recordRedHover : Qt.color("#FFFFFF")
        const baseR = Math.round(base.r * 255)
        const baseG = Math.round(base.g * 255)
        const baseB = Math.round(base.b * 255)
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
            return "<span style=\"color:rgba(" + baseR + "," + baseG + "," + baseB + "," + alpha.toFixed(2) + ")\">" + lyricHtml(word) + "</span>"
        }).join("")
    }

    function applyLyrics(lyrics, provider) {
        player.setCurrentLyrics(lyrics || "")
        if (lyricsSelectionCallback) {
            const callback = lyricsSelectionCallback
            lyricsSelectionCallback = null
            callback(lyrics || "")
        }
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
        if (preferLocalLyrics && local && local.trim().length) {
            applyLyrics(local, "Local file")
        } else if (embedded && embedded.trim().length) {
            applyLyrics(embedded, "Embedded metadata")
        } else if (!preferLocalLyrics && local && local.trim().length) {
            applyLyrics(local, "Local file")
        } else if (!offlineBlackout && track.source === "jellyfin" && track.remoteId) {
            applyLyrics("", "")
            streaming.fetchJellyfinLyrics(track.filePath, track.remoteId)
        } else if (!offlineBlackout && svcLrclib) {
            applyLyrics("", "")
            services.fetchLyrics(track.title || track.fileName || "", track.artist || "", track.album || "", track.durationSeconds || 0)
        } else {
            applyLyrics("", "")
        }
    }

    function searchLyricsOnline() {
        if (offlineBlackout || !svcLrclib) {
            lyricSearchLoading = false
            return
        }
        const query = lyricSearchQuery.trim()
        if (!query) return
        lyricSearchLoading = true
        lyricSearchResults = []
        const currentTitle = String(player.currentTrack.title || player.currentTrack.fileName || "").trim().toLowerCase()
        services.searchLyrics(query, query.toLowerCase() === currentTitle ? (player.currentTrack.artist || "") : "")
    }

    function openLyricsSearch(onSelected) {
        lyricsSelectionCallback = onSelected || null
        lyricSearchOpen = true
        lyricCustomEditorOpen = false
        lyricCustomText = ""
        lyricSearchQuery = player.currentTrack.title || player.currentTrack.fileName || ""
        searchLyricsOnline()
    }

    function openCoverSearch(album, artist, filePath) {
        coverSearchPopup.openFor(album, artist, filePath)
    }

    function openTrackMetadataEditor() {
        if (player.currentTrack && player.currentTrack.filePath) metadataDialog.openFor(player.currentTrack)
    }

    function openTrackActionSheet(targetTrack) {
        const t = targetTrack || player.currentTrack
        if (t && trackActionSheet) trackActionSheet.openFor(t)
    }

    onNowPlayingOpenChanged: {
        if (nowPlayingOpen) {
            nowPlayingLoaded = true
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
    }

    onCatalogDetailOpenChanged: {
        if (!catalogDetailOpen) {
            catalogDetailTracks = []
            catalogDetailHeroTrack = ({})
            catalogDetailHistory = []
        }
    }

    Timer {
        id: nowPlayingWarmupTimer
        interval: 800
        running: true
        repeat: false
        onTriggered: window.nowPlayingLoaded = true
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

    property var spotlightTrack: null
    property var quickPicks: []
    property var heavyRotation: []
    property var recentlyPlayed: []
    property var recentlyAdded: []
    property var forgottenFavs: []
    property int artistCount: 0
    property int albumCount: 0
    property var artists: []
    property var albums: []
    property var artistsRotation: []
    property var albumsRotation: []
    property var genreGroups: []
    property var folderGroups: []

    function refreshSpotlight(candidates) {
        if (candidates.length > 0) {
            spotlightTrack = candidates[Math.floor(Math.random() * candidates.length)]
        } else {
            spotlightTrack = null
        }
    }

    function refreshHomeRecommendations() {
        const home = library.homeRecommendations(playCounts, seenAt, favoriteTracks, playbackHistory)
        spotlightTrack = home.spotlight.filePath ? home.spotlight : null
        quickPicks = home.quickPicks
        heavyRotation = home.heavyRotation
        recentlyPlayed = home.recentlyPlayed
        recentlyAdded = home.recentlyAdded
        forgottenFavs = home.forgottenFavs
    }

    function refreshLibraryState() {
        const groups = library.catalogGroups()
        refreshHomeGroups(groups)
        if (page === "library") refreshLibraryGroups(groups)
        else clearLibraryGroups()
        refreshHomeRecommendations()
        restoreLastPlayedTrack()
        restorePlaybackQueue()
        restorePlaybackHistory()
    }

    function extractPrimaryArtist(raw) {
        if (!raw) return "Unknown Artist"
        const str = raw.trim()
        if (!str) return "Unknown Artist"
        const match = str.split(/[,&;/]|\bfeat\.?\b|\bft\.?\b/i).find(part => part.trim().length > 0)
        return match ? match.trim() : str
    }

    function splitArtists(raw) {
        if (!raw) return ["Unknown Artist"]
        const parts = String(raw).split(/\s*(?:[,&;/]|(?:\b(?:feat|ft)\b\.?)|\bfeaturing\b)\s*/i)
            .map(s => s.trim())
            .filter(s => s.length > 0)
        return parts.length ? parts : [String(raw).trim()]
    }

    // The library controller classifies letters in every script, which QML regular expressions cannot.
    function compareSortKey(a, b) {
        return library.compareNames(String(a || ""), String(b || ""))
    }

    function refreshHomeGroups(groups) {
        const artistGroups = groups.artists || []
        const albumGroups = groups.albums || []
        artistCount = artistGroups.length
        albumCount = albumGroups.length
        artistsRotation = artistGroups.slice().sort((a, b) => (b.count - a.count) || compareSortKey(a.name, b.name)).slice(0, 12)
        albumsRotation = albumGroups.slice().sort((a, b) => (b.count - a.count) || compareSortKey(a.name, b.name)).slice(0, 12)
    }

    function refreshLibraryGroups(groups) {
        artists = (groups.artists || []).slice().sort((a, b) => compareSortKey(a.name, b.name))
        albums = (groups.albums || []).slice().sort((a, b) => compareSortKey(a.name, b.name))
        genreGroups = (groups.genres || []).slice().sort((a, b) => compareSortKey(a.name, b.name))
        folderGroups = (groups.folders || []).slice().sort((a, b) => compareSortKey(a.name, b.name))
    }

    function refreshVisibleLibraryGroups() {
        if (page === "library") refreshLibraryGroups(library.catalogGroups())
    }

    function clearLibraryGroups() {
        artists = []
        albums = []
        genreGroups = []
        folderGroups = []
    }

    function getArtistGroups() { return artists }

    function getAlbumGroups() { return albums }

    function minimizeWindow() {
        window.showMinimized()
    }

    function filterCatalogDetailTracks(mode, title, heroTrack) {
        if (mode === "playlist") return playlistTracks(title)
        const trackPool = (heroTrack && heroTrack.remoteId) ? playbackTracks() : availableTracks()
        const normTitle = (title || "").trim().toLowerCase()
        const result = trackPool.filter(track => {
            if (!track) return false
            if (mode === "artist") {
                const artists = splitArtists(track.artist || "").map(a => a.trim().toLowerCase())
                const rawArtist = (track.artist || "").trim().toLowerCase()
                return artists.includes(normTitle) || rawArtist === normTitle
            }
            if (mode === "genre") {
                const rawGenre = (track.genre || "").trim().toLowerCase()
                return rawGenre === normTitle || (!rawGenre && normTitle === "soundtrack")
            }
            if (mode === "folder") {
                const p = (track.filePath || "").replace(/\\/g, "/")
                const slash = p.lastIndexOf('/')
                const folderPath = slash < 0 ? "Music" : p.substring(0, slash)
                const folderName = folderPath.split('/').pop() || "Music"
                return folderName === title || folderPath === title
            }
            return (track.album || "Unknown Album") === title
        })
        if (mode === "album") {
            result.sort((a, b) => {
                const numA = (a.trackNumber !== undefined && a.trackNumber > 0) ? a.trackNumber : 9999
                const numB = (b.trackNumber !== undefined && b.trackNumber > 0) ? b.trackNumber : 9999
                if (numA !== numB) return numA - numB
                return compareSortKey(a.title || a.fileName, b.title || b.fileName)
            })
        }
        return result
    }

    function openCatalogDetail(mode, title, heroTrack, key) {
        if (catalogDetailOpen) {
            catalogDetailHistory = catalogDetailHistory.concat([{
                mode: catalogDetailMode,
                title: catalogDetailTitle,
                key: catalogDetailKey,
                heroTrack: catalogDetailHeroTrack
            }])
        }
        catalogDetailMode = mode
        catalogDetailTitle = title
        catalogDetailKey = key || title
        catalogDetailHeroTrack = heroTrack
        catalogDetailTracks = filterCatalogDetailTracks(mode, catalogDetailKey, heroTrack)
        catalogDetailOpen = true
    }
    function closeCatalogDetail() {
        if (catalogDetailHistory.length) {
            const previous = catalogDetailHistory[catalogDetailHistory.length - 1]
            catalogDetailHistory = catalogDetailHistory.slice(0, -1)
            openCatalogDetail(previous.mode, previous.title, previous.heroTrack, previous.key)
            catalogDetailHistory = catalogDetailHistory.slice(0, -1)
            return
        }
        catalogDetailOpen = false
    }
    function getGenreGroups() { return genreGroups }
    function getFolderGroups() { return folderGroups }

    function playTrack(track) {
        if (!track) return
        if (track.format === "STREAM") {
            startPlayback([track], 0, false)
            return
        }
        const source = track.remoteId
            ? (streaming.remoteTracks || []).filter(candidate => candidate.source === track.source)
            : availableTracks()
        const index = source.findIndex(candidate => candidate.filePath === track.filePath)
        startPlayback(source, index >= 0 ? index : 0, player.shuffleEnabled)
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
        player.setShuffleEnabled(!!shuffle)
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

    function shufflePlayback(source) {
        const queue = uniqueTracks(source)
        if (!queue.length) return
        startPlayback(queue, Math.floor(Math.random() * queue.length), true)
    }

    function startRadioPlayback(source, startIndex, originalStation) {
        if (!source || source.length === 0) return
        player.setShuffleEnabled(false)
        const queue = uniqueTracks(source)
        if (!queue.length) return
        const index = Math.max(0, Math.min(startIndex, queue.length - 1))
        originalRadioPlaybackQueue = queue.slice()
        radioPlaybackQueue = queue.slice()
        const activeTrack = radioPlaybackQueue[index]
        if (activeTrack) {
            if (originalStation) {
                recordRadioRecent(originalStation)
            } else {
                recordRadioRecent({
                    name: activeTrack.title,
                    streamUrl: activeTrack.filePath,
                    favicon: activeTrack.artworkUrl,
                    country: activeTrack.artist,
                    tags: activeTrack.album
                })
            }
        }
        playQueuedTrack(activeTrack)
    }

    function activePlaybackQueue() {
        if (player.currentTrack && player.currentTrack.format === "STREAM") return radioPlaybackQueue
        return playbackQueue.length ? playbackQueue : uniqueTracks(availableTracks())
    }

    function currentQueueIndex() {
        const queue = activePlaybackQueue()
        const filePath = player.currentTrack ? player.currentTrack.filePath : ""
        return queue.findIndex(track => track.filePath === filePath)
    }

    function playQueuedTrack(track) {
        if (!track) return
        if (!player.currentTrack || player.currentTrack.filePath !== track.filePath)
            finishHistoryTracking()
        lastHandledTrack = null
        playbackPending = true
        if (!player.playTrack(track)) {
            playbackPending = false
            playerStateDirty = true
            return
        }
        loadLyricsForTrack(track)
        queueRevision++
    }

    function playFromQueue(track) {
        if (!track || !track.filePath) return
        playQueuedTrack(track)
    }

    function removeQueuedTrack(track) {
        if (!track || !track.filePath) return
        const queue = activePlaybackQueue()
        const index = queue.findIndex(candidate => trackIdentity(candidate) === trackIdentity(track))
        if (index < 0 || index <= currentQueueIndex()) return
        const nextQueue = queue.slice()
        nextQueue.splice(index, 1)
        if (player.currentTrack && player.currentTrack.format === "STREAM") {
            radioPlaybackQueue = nextQueue
            originalRadioPlaybackQueue = originalRadioPlaybackQueue.filter(candidate => trackIdentity(candidate) !== trackIdentity(track))
        } else {
            playbackQueue = nextQueue
            originalPlaybackQueue = originalPlaybackQueue.filter(candidate => trackIdentity(candidate) !== trackIdentity(track))
        }
        queueRevision++
    }

    function moveQueuedTrackNext(track) {
        if (!track || !track.filePath) return
        const queue = activePlaybackQueue()
        const currentIndex = currentQueueIndex()
        const index = queue.findIndex(candidate => trackIdentity(candidate) === trackIdentity(track))
        if (index < 0 || index <= currentIndex + 1) return
        const nextQueue = queue.slice()
        nextQueue.splice(index, 1)
        nextQueue.splice(currentIndex + 1, 0, track)
        if (player.currentTrack && player.currentTrack.format === "STREAM") radioPlaybackQueue = nextQueue
        else playbackQueue = nextQueue
        queueRevision++
    }

    function reorderQueuedTrack(sourceTrack, targetTrack, sourceIndex, targetIndex) {
        if (!sourceTrack || !targetTrack) return
        const queue = activePlaybackQueue()
        const currentIndex = currentQueueIndex()
        let fromIdx = (sourceIndex !== undefined && sourceIndex >= 0) ? sourceIndex : queue.findIndex(candidate => trackIdentity(candidate) === trackIdentity(sourceTrack))
        let toIdx = (targetIndex !== undefined && targetIndex >= 0) ? targetIndex : queue.findIndex(candidate => trackIdentity(candidate) === trackIdentity(targetTrack))
        if (fromIdx < 0 || toIdx < 0 || fromIdx === toIdx || fromIdx <= currentIndex || toIdx <= currentIndex) return
        const nextQueue = queue.slice()
        const [moved] = nextQueue.splice(fromIdx, 1)
        const insertIdx = fromIdx < toIdx ? toIdx - 1 : toIdx
        nextQueue.splice(insertIdx, 0, moved)
        if (player.currentTrack && player.currentTrack.format === "STREAM") radioPlaybackQueue = nextQueue
        else playbackQueue = nextQueue
        queueRevision++
    }

    function toggleQueueShuffle() {
        const radioQueue = player.currentTrack && player.currentTrack.format === "STREAM"
        const queue = activePlaybackQueue()
        if (queue.length < 2) return
        const currentIndex = currentQueueIndex()
        player.toggleShuffle()
        if (currentIndex < 0) return

        if (player.shuffleEnabled) {
            const shuffled = queue.slice(0, currentIndex + 1).concat(shuffledTracks(queue.slice(currentIndex + 1)))
            if (radioQueue) radioPlaybackQueue = shuffled
            else playbackQueue = shuffled
        } else {
            if (radioQueue) radioPlaybackQueue = originalRadioPlaybackQueue.length ? originalRadioPlaybackQueue.slice() : queue.slice()
            else playbackQueue = originalPlaybackQueue.length ? originalPlaybackQueue.slice() : queue.slice()
        }
        queueRevision++
    }

    function playNext() {
        const queue = activePlaybackQueue()
        if (!queue.length) return
        const currentIndex = currentQueueIndex()
        if (currentIndex < 0) {
            playQueuedTrack(queue[0])
        } else if (currentIndex < queue.length - 1) {
            playQueuedTrack(queue[currentIndex + 1])
        } else if (repeatMode === 1) {
            playQueuedTrack(queue[0])
        } else if (player.currentTrack && player.currentTrack.format !== "STREAM" && autoplayEnabled && library.trackCount > 0) {
            shuffleAll()
        }
    }

    function playPrevious() {
        if (player.position > 5000) {
            player.seek(0)
            return
        }
        const queue = activePlaybackQueue()
        const currentIndex = currentQueueIndex()
        if (currentIndex > 0) playQueuedTrack(queue[currentIndex - 1])
        else player.seek(0)
    }

    function shuffleAll() {
        const queue = uniqueTracks(availableTracks())
        if (!queue.length) return
        shufflePlayback(queue)
        refreshSpotlight(queue)
    }

    Connections {
        target: player
        function onPlaybackRequested(tracks, startIndex) {
            if (!tracks || !tracks.length) return
            const allStream = tracks.every(t => t && t.format === "STREAM")
            if (allStream) {
                const idx = (startIndex >= 0 && startIndex < tracks.length) ? startIndex : 0
                startRadioPlayback(tracks, idx)
                return
            }
            const hasStream = tracks.some(t => t && t.format === "STREAM")
            if (!hasStream) {
                startPlayback(tracks, startIndex, false)
                return
            }
            const targetTrack = (startIndex >= 0 && startIndex < tracks.length) ? tracks[startIndex] : null
            const filtered = tracks.filter(t => t && t.format !== "STREAM")
            if (!filtered.length) return
            let nextIndex = targetTrack ? filtered.indexOf(targetTrack) : 0
            if (nextIndex < 0) nextIndex = 0
            startPlayback(filtered, nextIndex, false)
        }
        function onTrackEnded() {
            if (sleepTimerMode === "track") {
                triggerSleepTimerStop()
            } else if (repeatMode === 2) {
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
        function onErrorChanged() {
            if (playbackPending) {
                playbackPending = false
                playerStateDirty = true
            }
        }
        function onCurrentLyricsChanged() {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
        function onCurrentTrackChanged() {
            const currentTrack = player.currentTrack || ({})
            const sameTrack = lastHandledTrack && currentTrack.filePath
                && lastHandledTrack.filePath === currentTrack.filePath
            lastHandledTrack = currentTrack
            tray.setTrack(currentTrack.title || "", currentTrack.artist || "")
            if (sameTrack) {
                if (historyTrackedTrack) historyTrackedTrack = currentTrack
                return
            }
            if (tray.available && currentTrack.title) {
                const isHiddenOrMinimized = !window.active || window.visibility === Window.Hidden || window.visibility === Window.Minimized
                if (nowPlayingNotifications === "always" || (nowPlayingNotifications === "minimized" && isHiddenOrMinimized)) {
                    tray.showNotification(currentTrack.title, currentTrack.artist || "")
                }
            }
            resetHistoryTracking(currentTrack)
            lyricsSyncOffsetMs = appSettings.value(lyricsSyncKey(currentTrack), 0)
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
            tray.setPlaying(player.isPlaying)
            if (player.isPlaying) {
                playbackPending = false
                resumeHistoryTracking()
            } else {
                pauseHistoryTracking()
                persistPlayerState()
            }
        }
        function onVolumeChanged() {
            if (settingsInitialized && !fadeOutTimer.running) appSettings.setValue("player/volume", player.volume)
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

    FolderDialog {
        id: excludeFolderDialog
        title: "Select Folder to Exclude"
        onAccepted: {
            const clean = library.localPath(selectedFolder)
            if (clean && !excludedFolders.includes(clean)) {
                window.excludedFolders = excludedFolders.concat([clean])
            }
        }
    }

    FileDialog {
        id: exportBackupDialog
        title: "Export CassetteCat Backup"
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "All files (*.*)"]
        defaultSuffix: "json"
        onAccepted: {
            const backupData = {
                version: 2,
                timestamp: new Date().toISOString(),
                accentName: window.accentName,
                customAccentColor: window.customAccentColor,
                albumArtRadius: window.albumArtRadius,
                nowPlayingBackdrop: window.nowPlayingBackdrop,
                showRemainingTime: window.showRemainingTime,
                trackDensity: window.trackDensity,
                showFormatBadges: window.showFormatBadges,
                ignoreShortClips: window.ignoreShortClips,
                defaultLaunchPage: window.defaultLaunchPage,
                excludedFolders: window.excludedFolders,
                resumeQueueOnLaunch: window.resumeQueueOnLaunch,
                globalShortcutsEnabled: window.globalShortcutsEnabled,
                globalShortcutBindings: window.globalShortcutBindings,
                inAppShortcutBindings: window.inAppShortcutBindings,
                miniPlayerAlwaysOnTop: window.miniPlayerAlwaysOnTop,
                autoplayEnabled: window.autoplayEnabled,
                sleepFadeOut: window.sleepFadeOut,
                volumeLimitEnabled: window.volumeLimitEnabled,
                maxVolumePercent: window.maxVolumePercent,
                replayGainMode: window.replayGainMode,
                closeToTray: window.closeToTray,
                startMinimizedToTray: window.startMinimizedToTray,
                nowPlayingNotifications: window.nowPlayingNotifications,
                lyricsFontSize: window.lyricsFontSize,
                lyricsAlignment: window.lyricsAlignment,
                lyricsActiveStyle: window.lyricsActiveStyle,
                preferLocalLyrics: window.preferLocalLyrics,
                offlineBlackout: window.offlineBlackout,
                svcLrclib: window.svcLrclib,
                svcRadio: window.svcRadio,
                svcDeezer: window.svcDeezer,
                svcAudiodb: window.svcAudiodb,
                svcWiki: window.svcWiki,
                svcArchive: window.svcArchive,
                favoriteTracks: window.favoriteTracks,
                playlists: window.playlists,
                playCounts: window.playCounts,
                seenAt: window.seenAt,
                radioFavorites: window.radioFavoriteStations,
                radioCustomStations: window.radioCustomStations
            }
            const jsonText = JSON.stringify(backupData, null, 2)
            if (appSettings.exportTextFile(selectedFile, jsonText)) {
                setBackupStatus("Backup exported successfully")
            } else {
                setBackupStatus("Export failed")
            }
        }
    }

    FileDialog {
        id: importBackupDialog
        title: "Import CassetteCat Backup"
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)", "All files (*.*)"]
        onAccepted: {
            const text = appSettings.readTextFile(selectedFile)
            if (text && text.trim().length > 0) {
                try {
                    const data = JSON.parse(text)
                    if (data.accentName) { window.accentName = data.accentName; appSettings.setValue("ui/accentName", data.accentName) }
                    if (data.customAccentColor) { window.customAccentColor = data.customAccentColor; appSettings.setValue("ui/customAccentColor", data.customAccentColor) }
                    if (data.albumArtRadius !== undefined) { window.albumArtRadius = data.albumArtRadius; appSettings.setValue("ui/albumArtRadius", data.albumArtRadius) }
                    if (data.nowPlayingBackdrop) { window.nowPlayingBackdrop = data.nowPlayingBackdrop; appSettings.setValue("player/nowPlayingBackdrop", data.nowPlayingBackdrop) }
                    if (data.showRemainingTime !== undefined) { window.showRemainingTime = data.showRemainingTime; appSettings.setValue("player/showRemainingTime", data.showRemainingTime) }
                    if (data.trackDensity) { window.trackDensity = data.trackDensity; appSettings.setValue("ui/trackDensity", data.trackDensity) }
                    if (data.showFormatBadges !== undefined) { window.showFormatBadges = data.showFormatBadges; appSettings.setValue("ui/showFormatBadges", data.showFormatBadges) }
                    if (data.ignoreShortClips !== undefined) { window.ignoreShortClips = data.ignoreShortClips; appSettings.setValue("library/ignoreShortClips", data.ignoreShortClips) }
                    if (data.defaultLaunchPage) { window.defaultLaunchPage = data.defaultLaunchPage; appSettings.setValue("ui/defaultLaunchPage", data.defaultLaunchPage) }
                    if (data.excludedFolders) { window.excludedFolders = data.excludedFolders; appSettings.setValue("library/excludedFolders", data.excludedFolders) }
                    if (data.resumeQueueOnLaunch !== undefined) { window.resumeQueueOnLaunch = data.resumeQueueOnLaunch; appSettings.setValue("player/resumeQueueOnLaunch", data.resumeQueueOnLaunch) }
                    if (Array.isArray(data.playlists)) { window.playlists = data.playlists; appSettings.setValue("library/playlists", JSON.stringify(data.playlists)) }
                    if (data.globalShortcutsEnabled !== undefined) { window.globalShortcutsEnabled = data.globalShortcutsEnabled }
                    if (data.globalShortcutBindings) {
                        for (const action in data.globalShortcutBindings) {
                            if (globalShortcuts.setShortcut(action, data.globalShortcutBindings[action])) {
                                appSettings.setValue("ui/globalShortcut/" + action, globalShortcuts.shortcuts[action])
                            }
                        }
                    }
                    if (data.inAppShortcutBindings && typeof data.inAppShortcutBindings === "object") {
                        window.inAppShortcutBindings = normalizeInAppShortcutBindings(
                            Object.assign({}, shortcutDefinitions.defaultBindings(), data.inAppShortcutBindings))
                        appSettings.setValue("ui/inAppShortcuts", JSON.stringify(window.inAppShortcutBindings))
                    }
                    if (data.miniPlayerAlwaysOnTop !== undefined) { window.miniPlayerAlwaysOnTop = data.miniPlayerAlwaysOnTop; appSettings.setValue("ui/miniPlayerAlwaysOnTop", data.miniPlayerAlwaysOnTop) }
                    if (data.autoplayEnabled !== undefined) { window.autoplayEnabled = data.autoplayEnabled; appSettings.setValue("player/autoplayEnabled", data.autoplayEnabled) }
                    if (data.sleepFadeOut !== undefined) { window.sleepFadeOut = data.sleepFadeOut; appSettings.setValue("player/sleepFadeOut", data.sleepFadeOut) }
                    if (data.volumeLimitEnabled !== undefined) { window.volumeLimitEnabled = data.volumeLimitEnabled; appSettings.setValue("player/volumeLimitEnabled", data.volumeLimitEnabled) }
                    if (data.maxVolumePercent !== undefined) { window.maxVolumePercent = data.maxVolumePercent; appSettings.setValue("player/maxVolumePercent", data.maxVolumePercent) }
                    if (data.replayGainMode !== undefined) { window.replayGainMode = data.replayGainMode; appSettings.setValue("player/replayGainMode", data.replayGainMode) }
                    if (data.closeToTray !== undefined) { window.closeToTray = data.closeToTray; appSettings.setValue("ui/closeToTray", data.closeToTray) }
                    if (data.startMinimizedToTray !== undefined) { window.startMinimizedToTray = data.startMinimizedToTray; appSettings.setValue("ui/startMinimizedToTray", data.startMinimizedToTray) }
                    if (data.nowPlayingNotifications) { window.nowPlayingNotifications = data.nowPlayingNotifications; appSettings.setValue("ui/nowPlayingNotifications", data.nowPlayingNotifications) }
                    if (data.lyricsFontSize) { window.lyricsFontSize = data.lyricsFontSize; appSettings.setValue("lyrics/fontSize", data.lyricsFontSize) }
                    if (data.lyricsAlignment) { window.lyricsAlignment = data.lyricsAlignment; appSettings.setValue("lyrics/alignment", data.lyricsAlignment) }
                    if (data.lyricsActiveStyle) { window.lyricsActiveStyle = data.lyricsActiveStyle; appSettings.setValue("lyrics/activeStyle", data.lyricsActiveStyle) }
                    if (data.preferLocalLyrics !== undefined) { window.preferLocalLyrics = data.preferLocalLyrics; appSettings.setValue("lyrics/preferLocal", data.preferLocalLyrics) }
                    if (data.offlineBlackout !== undefined) window.offlineBlackout = data.offlineBlackout
                    if (data.svcLrclib !== undefined) window.svcLrclib = data.svcLrclib
                    if (data.svcRadio !== undefined) window.svcRadio = data.svcRadio
                    if (data.svcDeezer !== undefined) window.svcDeezer = data.svcDeezer
                    if (data.svcAudiodb !== undefined) window.svcAudiodb = data.svcAudiodb
                    if (data.svcWiki !== undefined) window.svcWiki = data.svcWiki
                    if (data.svcArchive !== undefined) window.svcArchive = data.svcArchive
                    if (data.favoriteTracks) {
                        window.favoriteTracks = data.favoriteTracks
                        appSettings.setValue("library/favorites", JSON.stringify(data.favoriteTracks))
                    }
                    if (Array.isArray(data.radioFavorites)) {
                        window.radioFavoriteStations = data.radioFavorites
                        appSettings.setValue("radio/favorites", JSON.stringify(data.radioFavorites))
                    }
                    if (Array.isArray(data.radioCustomStations)) {
                        window.radioCustomStations = data.radioCustomStations
                        appSettings.setValue("radio/customStations", JSON.stringify(data.radioCustomStations))
                    }
                    if (data.playCounts !== undefined) window.playCounts = numberMap(data.playCounts)
                    if (data.seenAt !== undefined) window.seenAt = numberMap(data.seenAt)
                    reconcileLibraryMaps()
                    appSettings.sync()
                    setBackupStatus("Backup restored successfully")
                } catch (err) {
                    setBackupStatus("Import error: Invalid JSON file")
                }
            } else {
                setBackupStatus("Failed to read backup file")
            }
        }
    }

    FileDialog {
        id: playlistImportDialog
        title: "Import M3U Playlist"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Playlist files (*.m3u *.m3u8)"]
        onAccepted: importM3u(selectedFile)
    }

    FileDialog {
        id: playlistExportDialog
        title: "Export M3U Playlist"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Playlist files (*.m3u)"]
        defaultSuffix: "m3u"
        onAccepted: exportM3u(selectedFile)
        onRejected: playlistPendingExport = null
    }

    // Windows 11 Media Controls & Keyboard Media Keys
    Connections {
        target: (typeof smtc !== "undefined") ? smtc : null
        function onPlayRequested() { player.play() }
        function onPauseRequested() {
            console.log("[PLAYER] pause source=SMTC")
            player.pause()
        }
        function onNextRequested() { window.playNext() }
        function onPreviousRequested() { window.playPrevious() }
    }

    // Linux MPRIS Media Controls & Keyboard Media Keys
    Connections {
        target: (typeof mpris !== "undefined") ? mpris : null
        function onPlayRequested() { player.play() }
        function onPauseRequested() { player.pause() }
        function onPlayPauseRequested() { player.togglePlay() }
        function onNextRequested() { window.playNext() }
        function onPreviousRequested() { window.playPrevious() }
        function onRepeatModeChanged(mode) {
            if (window.repeatMode !== mode) window.repeatMode = mode
        }
        function onShuffleRequested(shuffle) {
            if (player.shuffleEnabled === shuffle) return
            const q = window.activePlaybackQueue ? window.activePlaybackQueue() : []
            if (q.length < 2) player.shuffleEnabled = shuffle
            else window.toggleQueueShuffle()
        }
        function onVolumeRequested(volume) {
            window.setPlayerVolume(volume)
        }
        function onQuitRequested() {
            appQuitting = true
            persistBeforeExit()
            Qt.quit()
        }
    }

    Connections {
        target: globalShortcuts
        function onPlayPauseRequested() { player.togglePlay() }
        function onNextRequested() { window.playNext() }
        function onPreviousRequested() { window.playPrevious() }
        function onFavoriteRequested() {
            if (player.currentTrack && player.currentTrack.filePath) {
                window.toggleFavorite(player.currentTrack.filePath)
            }
        }
        function onSearchRequested() {
            if (window.miniPlayerMode) window.toggleMiniPlayer()
            window.nowPlayingOpen = false
            window.page = "search"
            window.showNormal()
            window.raise()
            window.requestActivate()
        }
        function onMiniPlayerRequested() {
            window.toggleMiniPlayer()
        }
        function onAccessHintsRequested(visible) {
            window.accessHintsVisible = visible
        }
        function onAccessKeyRequested(key) {
            const destinations = ({ H: "home", L: "library", I: "stats", J: "jellyfin", U: "subsonic", R: "radio", S: "search", T: "settings" })
            if (destinations[key] === undefined) return
            window.nowPlayingOpen = false
            window.page = destinations[key]
        }
    }

    Connections {
        target: tray
        function onShowRequested() {
            window.show()
            window.showNormal()
            window.raise()
            window.requestActivate()
        }
        function onPlayPauseRequested() { player.togglePlay() }
        function onNextRequested() { window.playNext() }
        function onPreviousRequested() { window.playPrevious() }
        function onQuitRequested() {
            appQuitting = true
            persistBeforeExit()
            Qt.quit()
        }
    }

    // Sleep timer helpers
    Timer {
        id: sleepCountdownTimer
        interval: 1000
        repeat: true
        running: window.sleepTimerMode !== "off" && window.sleepTimerMode !== "track"
        onTriggered: {
            if (window.sleepTimerRemainingSeconds <= 1) {
                stop()
                triggerSleepTimerStop()
            } else {
                window.sleepTimerRemainingSeconds--
                const m = Math.floor(window.sleepTimerRemainingSeconds / 60)
                const s = window.sleepTimerRemainingSeconds % 60
                window.sleepTimerStatus = m + "m " + (s < 10 ? "0" : "") + s + "s"
            }
        }
    }

    function startSleepTimer(mode) {
        window.sleepTimerMode = mode
        if (mode === "off") {
            cancelSleepTimer()
            return
        }
        if (mode === "track") {
            window.sleepTimerStatus = "End of track"
            return
        }
        const mins = parseInt(mode, 10) || 15
        window.sleepTimerRemainingSeconds = mins * 60
        window.sleepTimerStatus = mins + "m"
        sleepCountdownTimer.restart()
    }

    function cancelSleepTimer() {
        window.sleepTimerMode = "off"
        window.sleepTimerStatus = "Off"
        window.sleepTimerRemainingSeconds = 0
        sleepCountdownTimer.stop()
    }

    function triggerSleepTimerStop() {
        if (sleepFadeOut && player.volume > 0.05) {
            fadeOutTimer.preFadeVolume = player.volume
            fadeOutTimer.restart()
        } else {
            console.log("[PLAYER] pause source=sleep-timer")
            player.pause()
            cancelSleepTimer()
        }
    }

    Timer {
        id: fadeOutTimer
        interval: 80
        repeat: true
        property real targetStep: 0.05
        property real preFadeVolume: 1.0
        onTriggered: {
            if (player.volume > targetStep) {
                player.setVolume(Math.max(0.0, player.volume - targetStep))
            } else {
                stop()
                console.log("[PLAYER] pause source=sleep-timer")
                player.pause()
                player.setVolume(preFadeVolume)
                cancelSleepTimer()
            }
        }
    }

    function setPlayerVolume(val) {
        let v = Math.max(0.0, Math.min(1.0, val))
        if (volumeLimitEnabled) {
            const limit = Math.max(0.05, maxVolumePercent / 100.0)
            if (v > limit) v = limit
        }
        player.setVolume(v)
    }

    function enforceVolumeLimit() {
        let v = player.volume
        if (volumeLimitEnabled) v = Math.min(v, Math.max(0.05, maxVolumePercent / 100.0))
        player.setVolume(v)
    }

    Component {
        id: miniPlayerComponent

        MiniPlayerWindow {
            playerVisuallyPlaying: window.playerVisuallyPlaying
            albumArtRadius: window.albumArtRadius
            repeatMode: window.repeatMode
            favoriteTracks: window.favoriteTracks
            alwaysOnTop: miniPlayerAlwaysOnTop
            displayFont: window.displayFont
            bodyFont: window.bodyFont
            monoFont: window.monoFont
            tracksCount: library.trackCount
            accentColor: window.recordRed
            accentHover: window.recordRedHover
            lyricsActiveStyle: window.lyricsActiveStyle
            lyricsAlignment: window.lyricsAlignment
            lyricsFontSize: window.lyricsFontSize
            volumeLimitEnabled: window.volumeLimitEnabled
            maxVolumePercent: window.maxVolumePercent
            queueEntries: window.queueEntries
            parsedLyrics: window.parsedLyrics
            activeLyricIndex: window.activeLyricIndex
            lyricDisplayItems: window.lyricDisplayItems
            activeLyricDisplayIndex: window.activeLyricDisplayIndex
            showRemainingTime: window.showRemainingTime
            onShowRemainingTimeChanged: {
                if (window.showRemainingTime !== miniPlayerWindow.showRemainingTime) {
                    window.showRemainingTime = miniPlayerWindow.showRemainingTime
                }
            }
            onRestoreRequested: {
                miniPlayerWindow.visible = false
                if (window.visibility === Window.Minimized) {
                    window.showNormal()
                }
                window.raise()
                window.requestActivate()
            }
            onCloseRequested: {
                miniPlayerWindow.visible = false
            }
            onPlayPrevious: window.playPrevious()
            onPlayNext: window.playNext()
            onToggleRepeat: window.toggleRepeat()
            onToggleFavorite: filePath => window.toggleFavorite(filePath)
            onToggleShuffle: window.toggleQueueShuffle()
            onPlayTrack: track => window.playTrack(track)
            onToggleAlwaysOnTop: {
                miniPlayerAlwaysOnTop = !miniPlayerAlwaysOnTop
                player.setWindowAlwaysOnTop(miniPlayerWindow, miniPlayerAlwaysOnTop)
            }
        }
    }

    Loader {
        id: miniPlayerLoader
        active: false
        sourceComponent: miniPlayerComponent
        onLoaded: window.showMiniPlayer()
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
                    source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
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
                    text: page === "home" ? "Home" : page === "library" ? "Library" : page === "radio" ? "Radio" : page === "search" ? "Search" : page === "stats" ? "Listening Record" : page === "jellyfin" ? "Jellyfin" : page === "subsonic" ? "Subsonic" : "Settings"
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
                iconName: "chevron-left"
                tint: textPrimary
                tooltipText: "Back"
                onClicked: closeCatalogDetail()
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

                Column {
                    id: navTopColumn
                    anchors.top: parent.top
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 4

                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "home"; iconName: "house"; label: "Home"; accessHintsVisible: window.accessHintsVisible; accessKey: "H" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "library"; iconName: "music"; label: "Library"; accessHintsVisible: window.accessHintsVisible; accessKey: "L" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "jellyfin"; iconName: "jellyfin"; label: "Jellyfin"; preserveIconColor: true; accessHintsVisible: window.accessHintsVisible; accessKey: "J" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "subsonic"; iconName: "subsonic"; label: "Subsonic"; preserveIconColor: true; accessHintsVisible: window.accessHintsVisible; accessKey: "U" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "radio"; iconName: "radio"; label: "Radio"; accessHintsVisible: window.accessHintsVisible; accessKey: "R" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "search"; iconName: "search"; label: "Search"; accessHintsVisible: window.accessHintsVisible; accessKey: "S" }
                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "stats"; iconName: "clock"; label: "Listening Record"; accessHintsVisible: window.accessHintsVisible; accessKey: "I" }
                }

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

                    NavItem { appWindow: window; sidebarWidth: sidebarPanel.width; sidebarCollapsed: window.sidebarCollapsed; destination: "settings"; iconName: "settings"; label: "Settings"; accessHintsVisible: window.accessHintsVisible; accessKey: "T" }

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
                    id: mainStack
                    anchors.fill: parent
                    currentIndex: page === "home" ? 0 : (page === "library" ? 1 : (page === "search" ? 2 : (page === "radio" ? 3 : (page === "jellyfin" ? 4 : (page === "subsonic" ? 5 : (page === "stats" ? 6 : 7))))))

                    layer.enabled: pageSwitchAnim.running
                    layer.smooth: true

                    transform: Translate {
                        id: pageTranslate
                        y: 0
                    }

                    onCurrentIndexChanged: {
                        pageSwitchAnim.restart()
                        pageSlideAnim.restart()
                    }

                    NumberAnimation {
                        id: pageSwitchAnim
                        target: mainStack
                        property: "opacity"
                        from: 0.85
                        to: 1.0
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        id: pageSlideAnim
                        target: pageTranslate
                        property: "y"
                        from: 5
                        to: 0
                        duration: 160
                        easing.type: Easing.OutCubic
                    }

                    Loader {
                        id: homePageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        // Wait for the saved page, or Home is built and discarded when launching elsewhere.
                        active: settingsInitialized && page === "home"

                        sourceComponent: Component {
                            HomePage {
                                appWindow: window
                                libraryModel: library
                                spotlightTrack: window.spotlightTrack
                                quickPicks: window.quickPicks
                                heavyRotation: window.heavyRotation
                                recentlyPlayed: window.recentlyPlayed
                                recentlyAdded: window.recentlyAdded
                                forgottenFavs: window.forgottenFavs
                                albumsRotation: window.albumsRotation
                                artistsRotation: window.artistsRotation
                                greeting: window.greeting
                                greetingSubtitle: window.greetingSubtitle
                                albumCount: window.albumCount
                                artistCount: window.artistCount
                                initialScrollPosition: window.homeScrollPosition
                                onScrollPositionChanged: position => window.homeScrollPosition = position
                            }
                        }
                    }

                    Loader {
                        id: libraryPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "library"

                        LoadingBar {
                            anchors.fill: parent
                            visible: libraryPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            LibraryPage {
                                appWindow: window
                                libraryModel: library
                            }
                        }
                    }

                    Loader {
                        id: searchPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "search"
                        property bool focusOnLoad: false
                        onLoaded: if (focusOnLoad) {
                            focusOnLoad = false
                            focusSearchInput()
                        }

                        LoadingBar {
                            anchors.fill: parent
                            visible: searchPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            SearchPage {
                                appWindow: window
                                libraryModel: library
                                playerController: player
                            }
                        }
                    }

                    Loader {
                        id: radioPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "radio"

                        LoadingBar {
                            anchors.fill: parent
                            visible: radioPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            RadioPage {
                                appWindow: window
                                playerController: player
                            }
                        }
                    }

                    Loader {
                        id: jellyfinPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "jellyfin"

                        LoadingBar {
                            anchors.fill: parent
                            visible: jellyfinPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            JellyfinPage {
                                appWindow: window
                                streamingController: streaming
                            }
                        }
                    }

                    Loader {
                        id: subsonicPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "subsonic"

                        LoadingBar {
                            anchors.fill: parent
                            visible: subsonicPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            SubsonicPage {
                                appWindow: window
                                streamingController: streaming
                            }
                        }
                    }

                    Loader {
                        id: listeningRecordPageLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "stats"

                        LoadingBar {
                            anchors.fill: parent
                            visible: listeningRecordPageLoader.status === Loader.Loading
                        }

                        sourceComponent: Component {
                            ListeningRecordPage {
                                appWindow: window
                                tracks: {
                                    libraryRevision
                                    return window.availableTracks()
                                }
                                playCounts: window.playCounts
                                playbackHistory: window.playbackHistory
                            }
                        }
                    }

                    Loader {
                        id: settingsLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        asynchronous: true
                        active: page === "settings"

                        LoadingBar {
                            anchors.fill: parent
                            visible: settingsLoader.status === Loader.Loading
                        }
                        sourceComponent: Component {
                            SettingsPage {
                                id: settingsRoot
                                anchors.fill: parent
                                currentSection: window.settingsSection
                                trackCount: library.trackCount
                                libraryFolders: library.folders
                                closeToTray: window.closeToTray
                                startMinimizedToTray: window.startMinimizedToTray
                                nowPlayingNotifications: window.nowPlayingNotifications
                                trayAvailable: tray.available
                                audioOutputs: player.audioOutputs
                                audioDeviceId: player.audioDeviceId
                                resumeQueueOnLaunch: window.resumeQueueOnLaunch
                                globalShortcutsEnabled: window.globalShortcutsEnabled
                                globalShortcutsSupported: window.globalShortcutsSupported
                                globalShortcutStatus: window.globalShortcutStatus
                                globalShortcutBindings: window.globalShortcutBindings
                                inAppShortcutBindings: window.inAppShortcutBindings
                                inAppShortcutActions: shortcutDefinitions.inAppActions
                                inAppShortcutStatus: window.inAppShortcutStatus
                                miniPlayerAlwaysOnTop: window.miniPlayerAlwaysOnTop
                                lyricsFontSize: window.lyricsFontSize
                                defaultLaunchPage: window.defaultLaunchPage
                                excludedFolders: window.excludedFolders
                                ignoreShortClips: window.ignoreShortClips
                                songSortMetric: window.songSortMetric
                                trackDensity: window.trackDensity
                                showFormatBadges: window.showFormatBadges
                                accentName: window.accentName
                                customAccentColor: window.customAccentColor
                                albumArtRadius: window.albumArtRadius
                                nowPlayingBackdrop: window.nowPlayingBackdrop
                                showRemainingTime: window.showRemainingTime
                                sleepTimerMode: window.sleepTimerMode
                                sleepTimerStatus: window.sleepTimerStatus
                                sleepFadeOut: window.sleepFadeOut
                                autoplayEnabled: window.autoplayEnabled
                                volumeLimitEnabled: window.volumeLimitEnabled
                                maxVolumePercent: window.maxVolumePercent
                                replayGainMode: window.replayGainMode
                                preferLocalLyrics: window.preferLocalLyrics
                                lyricsAlignment: window.lyricsAlignment
                                lyricsActiveStyle: window.lyricsActiveStyle
                                offlineBlackout: window.offlineBlackout
                                svcLrclib: window.svcLrclib
                                svcRadio: window.svcRadio
                                svcDeezer: window.svcDeezer
                                svcAudiodb: window.svcAudiodb
                                svcWiki: window.svcWiki
                                svcArchive: window.svcArchive
                                scrobbleListenBrainzEnabled: window.scrobbleListenBrainzEnabled
                                scrobbleListenBrainzUser: window.scrobbleListenBrainzUser
                                scrobbleListenBrainzConnected: window.scrobbleListenBrainzConnected
                                scrobbleLibreFmEnabled: window.scrobbleLibreFmEnabled
                                scrobbleLibreFmUser: window.scrobbleLibreFmUser
                                scrobbleLibreFmConnected: window.scrobbleLibreFmConnected
                                updateStatusText: window.updateStatusText
                                updateChecking: window.updateChecking
                                updateAvailable: window.updateAvailableState
                                updateUrl: window.updateUrl

                                onAddLibraryFolderRequested: folderDialog.open()
                                onRemoveLibraryFolderRequested: path => library.removeFolder(path)
                                onResumeQueueOnLaunchSelected: value => window.resumeQueueOnLaunch = value
                                onGlobalShortcutsEnabledSelected: value => { window.globalShortcutsEnabled = value }
                                onGlobalShortcutSelected: (action, shortcut) => {
                                    if (globalShortcuts.setShortcut(action, shortcut)) {
                                        appSettings.setValue("ui/globalShortcut/" + action, globalShortcuts.shortcuts[action])
                                    }
                                }
                                onInAppShortcutSelected: (action, shortcut) => window.setInAppShortcut(action, shortcut)
                                onMiniPlayerAlwaysOnTopSelected: value => window.miniPlayerAlwaysOnTop = value
                                onAudioDeviceSelected: value => {
                                    if (player.setAudioDevice(value)) appSettings.setValue("player/audioDeviceId", player.audioDeviceId)
                                }
                                onLyricsFontSizeSelected: value => window.lyricsFontSize = value
                                onDefaultLaunchPageSelected: value => window.defaultLaunchPage = value
                                onAddExcludeRequested: excludeFolderDialog.open()
                                onRemoveExcludeRequested: path => window.excludedFolders = window.excludedFolders.filter(p => p !== path)
                                onIgnoreShortClipsSelected: value => window.ignoreShortClips = value
                                onSongSortSelected: value => window.songSortMetric = value
                                onTrackDensitySelected: value => window.trackDensity = value
                                onShowFormatBadgesSelected: value => window.showFormatBadges = value
                                onAccentSelected: value => window.accentName = value
                                onCustomAccentSelected: hex => {
                                    window.customAccentColor = hex
                                    window.accentName = "custom"
                                }
                                onAlbumArtRadiusSelected: value => window.albumArtRadius = value
                                onNowPlayingBackdropSelected: value => window.nowPlayingBackdrop = value
                                onShowRemainingTimeSelected: value => window.showRemainingTime = value
                                onSleepTimerSelected: mode => window.startSleepTimer(mode)
                                onSleepTimerCancelled: window.cancelSleepTimer()
                                onSleepFadeOutSelected: value => window.sleepFadeOut = value
                                onAutoplaySelected: value => window.autoplayEnabled = value
                                onVolumeLimitSelected: value => { window.volumeLimitEnabled = value; window.enforceVolumeLimit() }
                                onMaxVolumeSelected: value => { window.maxVolumePercent = value; window.enforceVolumeLimit() }
                                onReplayGainModeSelected: value => window.replayGainMode = value
                                onPreferLocalLyricsSelected: value => window.preferLocalLyrics = value
                                onLyricsAlignmentSelected: value => window.lyricsAlignment = value
                                onLyricsActiveStyleSelected: value => window.lyricsActiveStyle = value
                                onOfflineBlackoutSelected: value => {
                                    window.offlineBlackout = value
                                }
                                onServiceToggleRequested: (name, value) => {
                                    if (name === "lrclib") window.svcLrclib = value
                                    else if (name === "radio") window.svcRadio = value
                                    else if (name === "deezer") window.svcDeezer = value
                                    else if (name === "audiodb") window.svcAudiodb = value
                                    else if (name === "wiki") window.svcWiki = value
                                    else if (name === "archive") window.svcArchive = value
                                    if (!value) services.cancelNetworkRequests()
                                }
                                onOpenJellyfinRequested: page = "jellyfin"
                                onOpenSubsonicRequested: page = "subsonic"
                                onExportBackupRequested: exportBackupDialog.open()
                                onImportBackupRequested: importBackupDialog.open()
                                onCloseToTraySelected: value => window.closeToTray = value
                                onStartMinimizedToTraySelected: value => window.startMinimizedToTray = value
                                onNowPlayingNotificationsSelected: value => window.nowPlayingNotifications = value
                                onScrobbleListenBrainzToggled: value => window.scrobbleListenBrainzEnabled = value
                                onDisconnectListenBrainzRequested: {
                                    services.disconnectListenBrainz()
                                    window.scrobbleListenBrainzConnected = false
                                    window.scrobbleListenBrainzUser = ""
                                    window.scrobbleListenBrainzEnabled = false
                                }
                                onScrobbleLibreFmToggled: value => window.scrobbleLibreFmEnabled = value
                                onDisconnectLibreFmRequested: {
                                    services.disconnectLibreFm()
                                    window.scrobbleLibreFmConnected = false
                                    window.scrobbleLibreFmUser = ""
                                    window.scrobbleLibreFmEnabled = false
                                }
                                onCheckUpdatesRequested: window.checkForUpdates()
                                onDownloadUpdateRequested: window.downloadUpdate()
                                onSectionSelected: section => {
                                    window.settingsSection = section
                                    appSettings.setValue("ui/settingsSection", section)
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            id: catalogDetailLoader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: miniPlayerDock.top
            z: 350
            active: catalogDetailOpen
            sourceComponent: Component {
                CatalogDetail {
                    anchors.fill: parent
                    appWindow: window
                    mode: catalogDetailMode
                    title: catalogDetailTitle
                    tracks: catalogDetailTracks
                    heroTrack: catalogDetailHeroTrack
                    onBackRequested: closeCatalogDetail()
                    onAlbumRequested: function(name, track) {
                        openCatalogDetail("album", name, track)
                    }
                }
            }
        }

        Rectangle {
            id: miniPlayerDock
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 88
            color: surfaceDock

            DropArea {
                id: queueDropArea
                anchors.fill: parent
                z: 2
                onEntered: drag => drag.accepted = !!(drag.source && drag.source.track
                    && drag.source.track.format !== "STREAM")
                onDropped: drop => {
                    if (window.appendToQueue(drop.source.track)) drop.accepted = true
                }

                Rectangle {
                    anchors.fill: parent
                    visible: queueDropArea.containsDrag
                    color: "transparent"
                    border.width: 1
                    border.color: recordRed

                    Label {
                        anchors.centerIn: parent
                        text: "Add to queue"
                        color: recordRed
                        font.family: monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                    setPlayerVolume(player.volume + step)
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: borderSubtle
            }

            Rectangle {
                visible: player.error.length > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.top
                height: 26
                color: "#7A241F"
                z: 2

                Label {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    text: player.error
                    color: "#FFE8E5"
                    font.family: bodyFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            TrackContextMenu {
                id: dockTrackMenu
                appWindow: window
                track: player.currentTrack
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 20
                spacing: 20

                RowLayout {
                    Layout.preferredWidth: 340
                    Layout.maximumWidth: 360
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        radius: window.albumArtRadius === 0 ? 0 : (window.albumArtRadius <= 8 ? 6 : 10)
                        clip: true
                        color: surfaceCard
                        border.width: 1
                        border.color: borderVariant

                        Cover {
                            anchors.fill: parent
                            track: player.currentTrack
                            radius: parent.radius
                            keepPreviousArtwork: true
                            cacheArtwork: true
                            visible: !!player.currentTrack.filePath
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 34
                            height: 34
                            source: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
                            fillMode: Image.PreserveAspectFit
                            visible: !player.currentTrack.filePath
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    if (player.currentTrack.filePath) {
                                        dockTrackMenu.popup()
                                    }
                                } else {
                                    if (player.currentTrack.filePath) {
                                        nowPlayingOpen = !nowPlayingOpen
                                    } else if (library.trackCount > 0) {
                                        playTrack(library.firstPlayableTrack())
                                    }
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
                            text: player.currentTrack.title || (library.trackCount > 0 ? "CassetteCat Audio" : "Library Empty")
                            color: textPrimary
                            font.family: displayFont
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (player.currentTrack.filePath) {
                                            dockTrackMenu.popup()
                                        }
                                    } else {
                                        if (player.currentTrack.filePath) {
                                            nowPlayingOpen = !nowPlayingOpen
                                        } else if (library.trackCount > 0) {
                                            playTrack(library.firstPlayableTrack())
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            id: dockArtistLabel
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: player.currentTrack.artist || (library.trackCount > 0 ? "Pick a track to start playback" : "Choose a music folder to begin")
                            color: dockArtistMouse.containsMouse && player.currentTrack.artist ? textPrimary : textSecondary
                            font.family: bodyFont
                            font.pixelSize: 12
                            font.underline: dockArtistMouse.containsMouse && !!player.currentTrack.artist
                            elide: Text.ElideRight

                            MouseArea {
                                id: dockArtistMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: player.currentTrack.artist ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (player.currentTrack.filePath) {
                                            dockTrackMenu.popup()
                                        }
                                    } else if (player.currentTrack.artist) {
                                        openCatalogDetail("artist", player.currentTrack.artist, player.currentTrack)
                                    }
                                }
                            }
                        }
                    }

                    PressDepthIconButton {
                        Layout.alignment: Qt.AlignVCenter
                        boxSize: 32
                        iconSize: 16
                        iconName: "heart"
                        visible: !!player.currentTrack.filePath
                        tint: isFavorite(player.currentTrack.filePath) ? recordRed : silverDim
                        tooltipText: isFavorite(player.currentTrack.filePath) ? "Remove from Favorites" : "Add to Favorites"
                        onClicked: toggleFavorite(player.currentTrack.filePath)
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
                            Layout.alignment: Qt.AlignVCenter
                            buttonSize: 34
                            paletteSource: window
                            iconName: "shuffle"
                            accented: player.shuffleEnabled
                            tooltipText: player.shuffleEnabled ? "Shuffle On" : "Shuffle Off"
                            onClicked: toggleQueueShuffle()
                        }

                        TransportButton {
                            Layout.alignment: Qt.AlignVCenter
                            buttonSize: 38
                            paletteSource: window
                            iconName: "skip-back"
                            iconColor: textPrimary
                            tooltipText: "Previous"
                            onClicked: playPrevious()
                        }

                        TransportButton {
                            Layout.alignment: Qt.AlignVCenter
                            buttonSize: 46
                            paletteSource: window
                            iconName: playerVisuallyPlaying ? "pause" : "play"
                            accented: true
                            iconColor: recordRed
                            tooltipText: playerVisuallyPlaying ? "Pause" : "Play"
                            onClicked: {
                                if (!player.currentTrack.filePath && library.trackCount > 0) {
                                    shuffleAll()
                                } else {
                                    player.togglePlay()
                                }
                            }
                        }

                        TransportButton {
                            Layout.alignment: Qt.AlignVCenter
                            buttonSize: 38
                            paletteSource: window
                            iconName: "skip-forward"
                            iconColor: textPrimary
                            tooltipText: "Next"
                            onClicked: playNext()
                        }

                        TransportButton {
                            Layout.alignment: Qt.AlignVCenter
                            buttonSize: 34
                            paletteSource: window
                            iconName: repeatMode === 2 ? "repeat-1" : "repeat"
                            accented: repeatMode > 0
                            iconColor: repeatMode > 0 ? recordRed : textPrimary
                            tooltipText: repeatMode === 2 ? "Repeat Track" : (repeatMode === 1 ? "Repeat All" : "Repeat Off")
                            onClicked: toggleRepeat()
                        }
                    }

                    AudioSeeker {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 580
                        Layout.alignment: Qt.AlignHCenter
                        position: player.position
                        duration: player.duration
                        showRemainingTime: window.showRemainingTime
                        paletteSource: window
                        onSeekRequested: posMs => player.seek(posMs)
                        onRemainingToggled: val => { window.showRemainingTime = val; appSettings.setValue("player/showRemainingTime", val) }
                    }
                }

                RowLayout {
                    Layout.preferredWidth: 340
                    Layout.maximumWidth: 360
                    Layout.alignment: Qt.AlignRight
                    spacing: 8

                    PressDepthIconButton {
                        Layout.alignment: Qt.AlignVCenter
                        boxSize: 34
                        iconSize: 17
                        iconName: "quote"
                        tint: (nowPlayingOpen && nowPlayingMode === "lyrics") ? recordRed : silverDim
                        highlighted: nowPlayingOpen && nowPlayingMode === "lyrics"
                        tooltipText: (nowPlayingOpen && nowPlayingMode === "lyrics") ? "Hide Lyrics" : "Lyrics"
                        onClicked: {
                            if (nowPlayingOpen && nowPlayingMode === "lyrics") {
                                nowPlayingOpen = false
                            } else {
                                nowPlayingMode = "lyrics"
                                nowPlayingOpen = true
                            }
                        }
                    }

                    PressDepthIconButton {
                        Layout.alignment: Qt.AlignVCenter
                        boxSize: 34
                        iconSize: 17
                        iconName: "list"
                        tint: (nowPlayingOpen && nowPlayingMode === "queue") ? recordRed : silverDim
                        highlighted: nowPlayingOpen && nowPlayingMode === "queue"
                        tooltipText: (nowPlayingOpen && nowPlayingMode === "queue") ? "Hide Queue" : "Queue"
                        onClicked: {
                            if (nowPlayingOpen && nowPlayingMode === "queue") {
                                nowPlayingOpen = false
                            } else {
                                nowPlayingMode = "queue"
                                nowPlayingOpen = true
                            }
                        }
                    }

                    PressDepthIconButton {
                        Layout.alignment: Qt.AlignVCenter
                        boxSize: 34
                        iconSize: 17
                        iconName: "pip"
                        tint: silverDim
                        tooltipText: "Mini Player (Ctrl+M)"
                        onClicked: toggleMiniPlayer()
                    }

                    PressDepthIconButton {
                        Layout.alignment: Qt.AlignVCenter
                        boxSize: 34
                        iconSize: 17
                        iconName: nowPlayingOpen ? "chevron-down" : "audio-lines"
                        tint: nowPlayingOpen ? recordRed : silverDim
                        highlighted: nowPlayingOpen
                        tooltipText: nowPlayingOpen ? "Collapse Now Playing" : "Now Playing Deck"
                        onClicked: nowPlayingOpen = !nowPlayingOpen
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: 2
                        Layout.rightMargin: 4
                        width: 1
                        height: 18
                        color: borderSubtle
                    }

                    VolumeControl {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 135
                        volume: player.volume
                        paletteSource: window
                        onVolumeAdjusted: newVol => {
                            setPlayerVolume(newVol)
                        }
                    }
                }
            }
        }

        TapHandler {
            target: null
            onTapped: function(eventPoint) { window.dismissSearchFocus(eventPoint.position) }
        }
    }



    Loader {
        id: nowPlayingLoader
        anchors.fill: parent
        z: 500
        active: nowPlayingLoaded || nowPlayingOpen
        sourceComponent: Component {
            Rectangle {
                id: nowPlayingOverlay
                readonly property bool audioMeterVisible: nowPlayingOpen && nowPlayingLyricsView.meterVisible
                    && window.visible && window.visibility !== Window.Minimized
                anchors.fill: parent
                color: "#0A0908"
                visible: opacity > 0.001
                opacity: nowPlayingOpen ? 1.0 : 0.0
                layer.enabled: opacity < 0.999 && opacity > 0.001
                layer.smooth: true

        transform: Translate {
            y: nowPlayingOpen ? 0 : 28
            Behavior on y {
                NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd }
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
            onWheel: wheel => {
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                setPlayerVolume(player.volume + step)
            }
        }

        Item {
            anchors.fill: parent
            clip: true
            opacity: window.nowPlayingBackdrop === "clean" ? 0.0 : 0.35

            Behavior on opacity {
                NumberAnimation { duration: 240 }
            }

            Cover {
                anchors.centerIn: parent
                width: parent.width * 1.3
                height: parent.height * 1.3
                track: player.currentTrack
                keepPreviousArtwork: true
                cacheArtwork: true
                stableSourceSize: 280
                layer.enabled: true
                layer.textureSize: Qt.size(240, 240)
                layer.smooth: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.85
                    blurMax: 32
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

        NowPlayingTopBar {
            id: npTopBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            appWindow: window
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
                    radius: window.albumArtRadius === 0 ? 0 : (window.albumArtRadius <= 8 ? (npLeftColumn.compactPlayerMode ? 8 : 10) : (npLeftColumn.compactPlayerMode ? 16 : 22))
                    clip: true
                    color: surfaceCard
                    border.width: 1
                    border.color: "#25FFFFFF"

                    Behavior on y {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }
                    Behavior on width {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }
                    Behavior on height {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }

                    Cover {
                        anchors.fill: parent
                        track: player.currentTrack
                        radius: npArtworkCard.radius
                        keepPreviousArtwork: true
                        cacheArtwork: true
                        showTonearm: true
                        stableSourceSize: 512
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: (nowPlayingMode === "lyrics" || nowPlayingMode === "queue") ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (nowPlayingMode === "lyrics" || nowPlayingMode === "queue") {
                                nowPlayingMode = "controls"
                            }
                        }
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
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
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
                                    if (!player.currentTrack.title && !player.currentTrack.filePath) {
                                        return "Select a track to start playback"
                                    }
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
                            showRemainingTime: window.showRemainingTime
                            paletteSource: window
                            onSeekRequested: posMs => player.seek(posMs)
                            onRemainingToggled: val => { window.showRemainingTime = val; appSettings.setValue("player/showRemainingTime", val) }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            TransportButton {
                                Accessible.name: "Shuffle"
                                buttonSize: 32
                                paletteSource: window
                                iconName: "shuffle"
                                accented: player.shuffleEnabled
                                onClicked: toggleQueueShuffle()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                Accessible.name: "Previous track"
                                buttonSize: 38
                                paletteSource: window
                                iconName: "skip-back"
                                iconColor: textPrimary
                                onClicked: playPrevious()
                            }

                            TransportButton {
                                Accessible.name: playerVisuallyPlaying ? "Pause" : "Play"
                                buttonSize: 48
                                paletteSource: window
                                iconName: playerVisuallyPlaying ? "pause" : "play"
                                accented: true
                                iconColor: recordRed
                                onClicked: player.togglePlay()
                            }

                            TransportButton {
                                Accessible.name: "Next track"
                                buttonSize: 38
                                paletteSource: window
                                iconName: "skip-forward"
                                iconColor: textPrimary
                                onClicked: playNext()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                Accessible.name: "Repeat"
                                buttonSize: 32
                                paletteSource: window
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
                                paletteSource: window
                                onVolumeAdjusted: newVol => setPlayerVolume(newVol)
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

                NowPlayingDeckControls {
                    id: deckControlsView
                    anchors.centerIn: parent
                    width: Math.min(parent.width - 24, 480)
                    height: 310
                    appWindow: window
                    playerController: player
                    visible: opacity > 0.001
                    opacity: nowPlayingMode === "controls" ? 1.0 : 0.0
                    scale: nowPlayingMode === "controls" ? 1.0 : 0.96
                    enabled: nowPlayingMode === "controls"

                    Behavior on opacity {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
                    }

                    onRemainingTimeToggled: value => {
                        window.showRemainingTime = value
                        appSettings.setValue("player/showRemainingTime", value)
                    }
                }

                NowPlayingLyricsView {
                    id: nowPlayingLyricsView
                    anchors.fill: parent
                    appWindow: window
                }

                NowPlayingQueueView {
                    appWindow: window
                    playerController: player
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
        onClosed: {
            lyricSearchOpen = false
            lyricsSelectionCallback = null
        }

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
                    Accessible.name: "Close lyrics search"
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
                    Accessible.name: "Search lyrics online"
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
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                cacheBuffer: UiConstants.cacheBuffer
                pixelAligned: UiConstants.pixelAligned
                reuseItems: true
                ScrollBar.vertical: AutoHideScrollBar {}

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

    CoverSearchPopup {
        id: coverSearchPopup
    }

    TrackMetadataDialog {
        id: metadataDialog
        appWindow: window
    }

    TrackActionSheet {
        id: trackActionSheet
        appWindow: window
        onOpenMetadataEditor: targetTrack => {
            if (metadataDialog) metadataDialog.openFor(targetTrack || player.currentTrack)
        }
    }
}
