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
    flags: Qt.Window | Qt.FramelessWindowHint

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

    property string page: "home"
    property string libraryTab: "songs"
    property string searchQuery: ""
    property string activeFormatFilter: "ALL"
    property bool nowPlayingOpen: false
    property string nowPlayingMode: "controls" // "controls", "lyrics", "queue"
    property bool sidebarCollapsed: false
    property var favoriteTracks: ({})
    property int repeatMode: 0 // 0: Off, 1: Repeat All, 2: Repeat One

    // MiniPlayer Desktop Dual-Window State
    readonly property bool miniPlayerMode: miniPlayerWindow ? miniPlayerWindow.visible : false
    property bool miniPlayerAlwaysOnTop: true

    property var parsedLyrics: parseLrc(player.currentLyrics)
    property int activeLyricIndex: -1

    Component.onCompleted: {
        refreshHomeRecommendations()
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

    // ==========================================
    // EXACT CASSETTECAT ANDROID-MATCHING LRC ENGINE
    // ==========================================
    function parseLrc(rawLyrics) {
        if (!rawLyrics || typeof rawLyrics !== "string") return []
        const lines = rawLyrics.split(/\r?\n/)
        const result = []

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (!line) continue

            // Ignore header metadata tags [ar: ...], [ti: ...], [al: ...]
            if (/^\[[a-zA-Z]+:.*\]$/.test(line)) continue

            // Match timestamp: [00:11.54] or [0:11.54] or [00:11]
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
                const timeMs = (mins * 60 + secs) * 1000 + ms
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

    function updateActiveLyric() {
        if (!parsedLyrics || parsedLyrics.length === 0) {
            activeLyricIndex = -1
            return
        }
        if (parsedLyrics[0].timeMs < 0) {
            activeLyricIndex = -1
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
        if (idx !== activeLyricIndex) {
            activeLyricIndex = idx
            if (lyricsListView && activeLyricIndex >= 0) {
                lyricsListView.currentIndex = activeLyricIndex
            }
        }
    }

    onNowPlayingOpenChanged: {
        if (nowPlayingOpen) {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
    }

    onNowPlayingModeChanged: {
        if (nowPlayingMode === "lyrics") {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
            if (lyricsListView && activeLyricIndex >= 0) {
                lyricsListView.currentIndex = activeLyricIndex
            }
        }
    }

    // ==========================================
    // TIME-BASED GREETINGS & SUBTEXTS
    // ==========================================
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

    function refreshSpotlight() {
        if (tracks.length > 0) {
            spotlightTrack = tracks[Math.floor(Math.random() * tracks.length)]
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

        refreshSpotlight()

        const shuffled = tracks.slice()
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

    readonly property var artists: getArtistGroups().sort((a, b) => a.name.localeCompare(b.name))
    readonly property var albums: getAlbumGroups().sort((a, b) => a.name.localeCompare(b.name))
    readonly property var artistsRotation: getArtistGroups().sort((a, b) => b.count - a.count).slice(0, 12)
    readonly property var albumsRotation: getAlbumGroups().sort((a, b) => b.count - a.count).slice(0, 12)

    function playTrack(track) {
        if (track) {
            player.playTrack(track)
            parsedLyrics = parseLrc(track.lyrics || player.getLyrics(track.filePath))
            updateActiveLyric()
        }
    }

    function playNext() {
        if (!tracks.length) return
        if (player.shuffleEnabled && tracks.length > 1) {
            let nextIdx = Math.floor(Math.random() * tracks.length)
            if (tracks[nextIdx].filePath === player.currentTrack.filePath) {
                nextIdx = (nextIdx + 1) % tracks.length
            }
            playTrack(tracks[nextIdx])
            return
        }
        let currentIdx = -1
        for (let i = 0; i < tracks.length; i++) {
            if (tracks[i].filePath === player.currentTrack.filePath) {
                currentIdx = i
                break
            }
        }
        const nextIdx = (currentIdx + 1) % tracks.length
        playTrack(tracks[nextIdx])
    }

    function playPrevious() {
        if (!tracks.length) return
        if (player.position > 3000) {
            player.seek(0)
            return
        }
        if (player.shuffleEnabled && tracks.length > 1) {
            let prevIdx = Math.floor(Math.random() * tracks.length)
            if (tracks[prevIdx].filePath === player.currentTrack.filePath) {
                prevIdx = (prevIdx - 1 + tracks.length) % tracks.length
            }
            playTrack(tracks[prevIdx])
            return
        }
        let currentIdx = -1
        for (let i = 0; i < tracks.length; i++) {
            if (tracks[i].filePath === player.currentTrack.filePath) {
                currentIdx = i
                break
            }
        }
        const prevIdx = (currentIdx - 1 + tracks.length) % tracks.length
        playTrack(tracks[prevIdx])
    }

    function shuffleAll() {
        if (!tracks || tracks.length === 0) return
        player.shuffleEnabled = true
        const randomIdx = Math.floor(Math.random() * tracks.length)
        playTrack(tracks[randomIdx])
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
        }
        function onCurrentLyricsChanged() {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
        function onCurrentTrackChanged() {
            parsedLyrics = parseLrc(player.currentLyrics)
            updateActiveLyric()
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Choose your music folder"
        onAccepted: library.loadFolder(selectedFolder)
    }

    component SleekScrollBar: ScrollBar {
        id: sbar
        policy: ScrollBar.AsNeeded
        width: 8
        padding: 2
        hoverEnabled: true
        z: 100

        contentItem: Rectangle {
            implicitWidth: 5
            radius: 2.5
            color: sbar.pressed ? recordRed : (sbar.hovered ? "#EDE8E3" : "#6E6B65")
            opacity: sbar.active || sbar.hovered || sbar.pressed ? 0.9 : 0.45

            Behavior on color {
                ColorAnimation { duration: 120 }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        background: Rectangle {
            implicitWidth: 8
            color: "transparent"
        }
    }

    component NavItem: Item {
        id: navItem
        property string destination: "home"
        property string iconName: ""
        property string label: ""
        width: parent ? parent.width : 190
        height: 42
        readonly property bool selected: page === destination && !nowPlayingOpen

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.topMargin: 2
            anchors.bottomMargin: 2
            radius: 8
            color: navItem.selected
                ? surfaceElevated
                : (navMouse.containsMouse ? surfaceCardHover : "transparent")

            Rectangle {
                visible: navItem.selected
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 2
                width: 3
                height: 18
                radius: 1.5
                color: recordRed
            }

            LucideIcon {
                id: navIcon
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 11
                width: 20
                height: 20
                icon: navItem.iconName
                color: navItem.selected ? recordRed : (navMouse.containsMouse ? textPrimary : textSecondary)
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 42
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: navItem.label
                color: navItem.selected ? textPrimary : (navMouse.containsMouse ? textPrimary : textSecondary)
                font.family: displayFont
                font.pixelSize: 13
                font.weight: navItem.selected ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 75) / (190 - 75)))
                visible: opacity > 0.01
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

    // =========================================================================
    // STANDALONE FLOATING MINIPLAYER WINDOW (APPLE MUSIC DUAL-WINDOW ARCHITECTURE)
    // =========================================================================
    Window {
        id: miniPlayerWindow
        title: "CassetteCat MiniPlayer"
        width: 450
        height: 160
        minimumWidth: 380
        minimumHeight: 140
        maximumHeight: 200
        color: "transparent"
        flags: Qt.Window | Qt.FramelessWindowHint
        visible: false

        Rectangle {
            id: miniPlayerCard
            anchors.fill: parent
            anchors.margins: 4
            radius: 16
            color: "#141311"
            border.width: 1
            border.color: "#2C2926"
            clip: true

            // Top edge glow / highlight
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#35322E"
            }

            // Top drag bar for moving the floating MiniPlayer
            Item {
                id: miniPlayerDragHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 30

                MouseArea {
                    anchors.fill: parent
                    property point pressPos
                    onPressed: mouse => { pressPos = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: mouse => {
                        const deltaX = Math.abs(mouse.x - pressPos.x)
                        const deltaY = Math.abs(mouse.y - pressPos.y)
                        if (deltaX > 3 || deltaY > 3) miniPlayerWindow.startSystemMove()
                    }
                    onDoubleClicked: toggleMiniPlayer()
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 7

                    Image {
                        width: 18
                        height: 18
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/CassetteCat/assets/cassettecat_icon.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "CassetteCat"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.5
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    // Restore / Expand Full Player Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: restoreMouse.containsMouse ? surfaceElevated : "transparent"

                        LucideIcon {
                            anchors.centerIn: parent
                            width: 13
                            height: 13
                            icon: "maximize-2"
                            color: restoreMouse.containsMouse ? textPrimary : silverDim
                        }

                        MouseArea {
                            id: restoreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: toggleMiniPlayer()
                        }
                    }

                    // Close MiniPlayer Button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: closeMiniMouse.containsMouse ? recordRed : "transparent"

                        Label {
                            anchors.centerIn: parent
                            text: "✕"
                            color: closeMiniMouse.containsMouse ? "#FFFFFF" : silverDim
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: closeMiniMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                miniPlayerWindow.visible = false
                                window.showNormal()
                                window.raise()
                                window.requestActivate()
                            }
                        }
                    }
                }
            }

            // MiniPlayer Main Body
            Item {
                anchors.top: miniPlayerDragHeader.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.bottomMargin: 8

                RowLayout {
                    anchors.fill: parent
                    spacing: 12

                    // Cover Artwork (Curved Modern Card)
                    Rectangle {
                        Layout.preferredWidth: 68
                        Layout.preferredHeight: 68
                        Layout.alignment: Qt.AlignVCenter
                        radius: 10
                        clip: true
                        color: surfaceCard
                        border.width: 1
                        border.color: borderVariant

                        Cover {
                            anchors.fill: parent
                            track: player.currentTrack
                            radius: 10
                            visible: !!player.currentTrack.filePath
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 44
                            height: 44
                            source: "qrc:/CassetteCat/assets/cassettecat_icon.png"
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            visible: !player.currentTrack.filePath
                        }

                        MouseArea {
                            id: coverMiniMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onDoubleClicked: toggleMiniPlayer()
                        }
                    }

                    // Title, Seeker, Controls Column
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        // Title & Artist
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Label {
                                    Layout.fillWidth: true
                                    text: player.currentTrack.title || "CassetteCat Audio"
                                    color: textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: player.currentTrack.artist || "Pick a track to start playback"
                                    color: recordRedHover
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            PressDepthIconButton {
                                boxSize: 26
                                iconSize: 13
                                iconName: "heart"
                                tint: isFavorite(player.currentTrack.filePath) ? recordRed : silverDim
                                onClicked: toggleFavorite(player.currentTrack.filePath)
                            }
                        }

                        // Seeker Progress Line
                        AudioSeeker {
                            Layout.fillWidth: true
                            position: player.position
                            duration: player.duration
                            onSeekRequested: posMs => player.seek(posMs)
                        }

                        // Bottom Controls Row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TransportButton {
                                buttonSize: 26
                                iconName: "shuffle"
                                accented: player.shuffleEnabled
                                onClicked: player.toggleShuffle()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                buttonSize: 30
                                iconName: "skip-back"
                                iconColor: textPrimary
                                onClicked: playPrevious()
                            }

                            TransportButton {
                                buttonSize: 36
                                iconName: player.isPlaying ? "pause" : "play"
                                accented: true
                                iconColor: recordRed
                                onClicked: player.togglePlay()
                            }

                            TransportButton {
                                buttonSize: 30
                                iconName: "skip-forward"
                                iconColor: textPrimary
                                onClicked: playNext()
                            }

                            Item { Layout.fillWidth: true }

                            TransportButton {
                                buttonSize: 26
                                iconName: repeatMode === 2 ? "repeat-1" : "repeat"
                                accented: repeatMode > 0
                                iconColor: repeatMode > 0 ? recordRed : textPrimary
                                onClicked: toggleRepeat()
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // CLEAN SPACIOUS UNIFIED TOP BAR (HEIGHT: 60PX)
    // =========================================================================
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

        Item {
            id: topSidebarHeader
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: sidebarPanel.width
            z: 10
            clip: true

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
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    source: "qrc:/CassetteCat/assets/02-black-cat-cassette.png"
                    fillMode: Image.PreserveAspectFit

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (sidebarCollapsed) sidebarCollapsed = false
                        }
                    }
                }

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.leftMargin: 52
                    anchors.right: collapseBtn.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: -2
                    opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 80) / (190 - 80)))
                    visible: opacity > 0.01

                    Label {
                        text: "CassetteCat"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                    Label {
                        text: "DESKTOP AUDIO"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                    }
                }

                PressDepthIconButton {
                    id: collapseBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    boxSize: 28
                    iconSize: 15
                    iconName: "panel-left"
                    tint: silverDim
                    opacity: Math.max(0.0, Math.min(1.0, (sidebarPanel.width - 120) / (190 - 120)))
                    visible: opacity > 0.01
                    onClicked: sidebarCollapsed = true
                }
            }
        }

        Item {
            anchors.left: topSidebarHeader.right
            anchors.right: headerActionRow.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            z: 10

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 16
                spacing: 16

                PressDepthIconButton {
                    boxSize: 32
                    iconSize: 17
                    iconName: "panel-left"
                    tint: silverDim
                    opacity: Math.max(0.0, Math.min(1.0, (110 - sidebarPanel.width) / (110 - 64)))
                    visible: opacity > 0.01
                    onClicked: sidebarCollapsed = false
                }

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

                    Label {
                        anchors.centerIn: parent
                        text: window.visibility === Window.Maximized ? "❐" : "▢"
                        color: maxBtnMouse.containsMouse ? textPrimary : silverDim
                        font.family: displayFont
                        font.pixelSize: 13
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

    // ==========================================
    // WINDOW RESIZING EDGES & CORNERS
    // ==========================================
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

    // ==========================================
    // MAIN APP BODY
    // ==========================================
    Item {
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
                width: sidebarCollapsed ? 64 : 190
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
                    anchors.fill: parent
                    anchors.margins: 0
                    anchors.topMargin: 12
                    spacing: 2

                    NavItem { destination: "home"; iconName: "house"; label: "Home" }
                    NavItem { destination: "library"; iconName: "music"; label: "Library" }
                    NavItem { destination: "radio"; iconName: "radio"; label: "Radio" }
                    NavItem { destination: "search"; iconName: "search"; label: "Search" }
                    NavItem { destination: "settings"; iconName: "settings"; label: "Settings" }
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
                    currentIndex: page === "home" ? 0 : page === "library" ? 1 : page === "search" ? 2 : 3

                    // ==========================================
                    // VIEW 0: HOME
                    // ==========================================
                    ScrollView {
                        id: homeScrollView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
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

                            // Hero Banner Card
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
                                    anchors.rightMargin: 80
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: 1
                                    onClicked: shuffleAll()
                                }
                            }

                            // Section 1: Quick Picks
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

                            // Section 2: Heavy Rotation
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

                            // Section 3: Albums in Rotation
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

                            // Section 4: Artists
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
                                    height: 165
                                    orientation: ListView.Horizontal
                                    spacing: 18
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: artistsRotation

                                    delegate: Item {
                                        width: 105
                                        height: 165

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Rectangle {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: 105
                                                Layout.preferredHeight: 105
                                                radius: 53
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1.5
                                                border.color: artistMouse.containsMouse ? recordRed : borderSubtle
                                                scale: artistMouse.containsMouse ? 1.04 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData.track
                                                    radius: 53
                                                }

                                                TransportButton {
                                                    anchors.centerIn: parent
                                                    buttonSize: 36
                                                    iconName: "play"
                                                    accented: true
                                                    iconColor: recordRed
                                                    opacity: artistMouse.containsMouse ? 1.0 : 0.0
                                                    scale: artistMouse.containsMouse ? 1.0 : 0.6
                                                    z: 10

                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                    onClicked: playTrack(modelData.track)
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.name
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.count + " tracks"
                                                color: silverDim
                                                font.family: monoFont
                                                font.pixelSize: 9
                                            }
                                        }

                                        MouseArea {
                                            id: artistMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData.track)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // VIEW 1: LIBRARY (INTEGRATED FILTER & SEARCH TOOLBAR)
                    // =========================================================
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Integrated Library Filter Bar
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.rightMargin: 32
                                Layout.topMargin: 16
                                Layout.bottomMargin: 12
                                spacing: 20

                                // Left: Tabs (Songs | Artists | Albums)
                                Row {
                                    spacing: 24
                                    Repeater {
                                        model: [
                                            { id: "songs", label: "Songs" },
                                            { id: "artists", label: "Artists" },
                                            { id: "albums", label: "Albums" }
                                        ]
                                        delegate: Item {
                                            width: tabLabel.implicitWidth
                                            height: 34

                                            Label {
                                                id: tabLabel
                                                text: modelData.label
                                                color: libraryTab === modelData.id ? recordRed : silver
                                                font.family: displayFont
                                                font.pixelSize: 15
                                                font.weight: Font.Bold
                                            }

                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: parent.width
                                                height: 2
                                                radius: 1
                                                color: recordRed
                                                visible: libraryTab === modelData.id
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: libraryTab = modelData.id
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                // Format Filter Pills
                                Row {
                                    spacing: 6
                                    Repeater {
                                        model: ["ALL", "FLAC", "MP3", "AAC"]
                                        delegate: Rectangle {
                                            implicitHeight: 28
                                            implicitWidth: fmtLabel.implicitWidth + 16
                                            radius: 14
                                            color: activeFormatFilter === modelData ? surfaceElevated : surfaceCard
                                            border.width: 1
                                            border.color: activeFormatFilter === modelData ? recordRed : borderSubtle

                                            Label {
                                                id: fmtLabel
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: activeFormatFilter === modelData ? textPrimary : silverDim
                                                font.family: monoFont
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: activeFormatFilter = modelData
                                            }
                                        }
                                    }
                                }

                                // Clean In-Library Search Input Pill
                                Rectangle {
                                    Layout.preferredWidth: 240
                                    Layout.preferredHeight: 34
                                    radius: 8
                                    color: libSearchInput.activeFocus ? surfaceElevated : surfaceInput
                                    border.width: 1
                                    border.color: libSearchInput.activeFocus ? recordRed : borderSubtle

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        LucideIcon { Layout.preferredWidth: 14; Layout.preferredHeight: 14; icon: "search"; color: silverDim }

                                        TextInput {
                                            id: libSearchInput
                                            Layout.fillWidth: true
                                            color: textPrimary
                                            font.family: displayFont
                                            font.pixelSize: 13
                                            selectByMouse: true
                                            text: searchQuery
                                            onTextChanged: searchQuery = text

                                            Text {
                                                anchors.fill: parent
                                                visible: !libSearchInput.text && !libSearchInput.activeFocus
                                                text: "Filter library..."
                                                color: silverDim
                                                font.family: displayFont
                                                font.pixelSize: 13
                                            }
                                        }

                                        Label {
                                            visible: libSearchInput.text.length > 0
                                            text: "×"
                                            color: textSecondary
                                            font.pixelSize: 14
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    libSearchInput.text = ""
                                                    searchQuery = ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            StackLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                currentIndex: libraryTab === "songs" ? 0 : libraryTab === "artists" ? 1 : 2

                                ListView {
                                    clip: true
                                    model: filteredTracks
                                    leftMargin: 32
                                    rightMargin: 32
                                    topMargin: 4
                                    bottomMargin: 16
                                    spacing: 4
                                    boundsBehavior: Flickable.StopAtBounds
                                    ScrollBar.vertical: SleekScrollBar {}

                                    delegate: Rectangle {
                                        width: ListView.view.width
                                        height: 52
                                        radius: 8
                                        color: rowMouse.containsMouse ? surfaceElevated : (player.currentTrack.filePath === modelData.filePath ? surfaceCard : "transparent")
                                        border.width: player.currentTrack.filePath === modelData.filePath ? 1 : 0
                                        border.color: borderSubtle

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 3
                                            width: 3
                                            height: 18
                                            radius: 1.5
                                            color: recordRed
                                            visible: player.currentTrack.filePath === modelData.filePath
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 14
                                            spacing: 12

                                            Cover {
                                                Layout.preferredWidth: 38
                                                Layout.preferredHeight: 38
                                                radius: 6
                                                track: modelData
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Label {
                                                    Layout.fillWidth: true
                                                    text: modelData.title || modelData.fileName
                                                    color: player.currentTrack.filePath === modelData.filePath ? recordRed : textPrimary
                                                    font.family: displayFont
                                                    font.pixelSize: 13
                                                    font.weight: player.currentTrack.filePath === modelData.filePath ? Font.Bold : Font.Medium
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
                                            id: rowMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData)
                                        }
                                    }

                                    Label {
                                        anchors.centerIn: parent
                                        visible: !filteredTracks.length
                                        text: searchQuery ? ("No tracks matching '" + searchQuery + "'") : "No audio files found"
                                        color: silverDim
                                        font.family: displayFont
                                        font.pixelSize: 14
                                    }
                                }

                                GridView {
                                    clip: true
                                    model: artists
                                    cellWidth: 160
                                    cellHeight: 185
                                    leftMargin: 32
                                    rightMargin: 32
                                    topMargin: 12
                                    bottomMargin: 12
                                    boundsBehavior: Flickable.StopAtBounds
                                    ScrollBar.vertical: SleekScrollBar {}

                                    delegate: Item {
                                        width: 140
                                        height: 175

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Rectangle {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: 105
                                                Layout.preferredHeight: 105
                                                radius: 53
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1.5
                                                border.color: libArtistGridMouse.containsMouse ? recordRed : borderSubtle
                                                scale: libArtistGridMouse.containsMouse ? 1.04 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData.track
                                                    radius: 53
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.name
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                horizontalAlignment: Text.AlignHCenter
                                                text: modelData.count + " songs"
                                                color: silverDim
                                                font.family: monoFont
                                                font.pixelSize: 10
                                            }
                                        }

                                        MouseArea {
                                            id: libArtistGridMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData.track)
                                        }
                                    }
                                }

                                GridView {
                                    clip: true
                                    model: albums
                                    cellWidth: 160
                                    cellHeight: 195
                                    leftMargin: 32
                                    rightMargin: 32
                                    topMargin: 12
                                    bottomMargin: 12
                                    boundsBehavior: Flickable.StopAtBounds
                                    ScrollBar.vertical: SleekScrollBar {}

                                    delegate: Item {
                                        width: 140
                                        height: 185

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 6

                                            Rectangle {
                                                Layout.preferredWidth: 140
                                                Layout.preferredHeight: 140
                                                radius: 10
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1
                                                border.color: libAlbumGridMouse.containsMouse ? borderVariant : borderSubtle
                                                scale: libAlbumGridMouse.containsMouse ? 1.03 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData.track
                                                    radius: 10
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
                                        }

                                        MouseArea {
                                            id: libAlbumGridMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: playTrack(modelData.track)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // =========================================================
                    // VIEW 2: DEDICATED SEARCH PAGE WITH PROMINENT HERO SEARCH
                    // =========================================================
                    Item {
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 32
                            spacing: 24

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.maximumWidth: 680
                                Layout.preferredHeight: 52
                                radius: 12
                                color: pageSearchInput.activeFocus ? surfaceElevated : surfaceCard
                                border.width: 1.5
                                border.color: pageSearchInput.activeFocus ? recordRed : borderVariant

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12

                                    LucideIcon { Layout.preferredWidth: 20; Layout.preferredHeight: 20; icon: "search"; color: pageSearchInput.activeFocus ? recordRed : silverDim }

                                    TextInput {
                                        id: pageSearchInput
                                        Layout.fillWidth: true
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 16
                                        font.weight: Font.Medium
                                        selectByMouse: true
                                        text: searchQuery
                                        onTextChanged: searchQuery = text

                                        Text {
                                            anchors.fill: parent
                                            visible: !pageSearchInput.text && !pageSearchInput.activeFocus
                                            text: "Search songs, artists, albums, or audio formats..."
                                            color: silverDim
                                            font.family: displayFont
                                            font.pixelSize: 16
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

                            // Search Results List
                            ListView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: filteredTracks
                                spacing: 6
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: SleekScrollBar {}

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 56
                                    radius: 8
                                    color: searchRowMouse.containsMouse ? surfaceElevated : (player.currentTrack.filePath === modelData.filePath ? surfaceCard : "transparent")
                                    border.width: player.currentTrack.filePath === modelData.filePath ? 1 : 0
                                    border.color: recordRed

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 16
                                        spacing: 14

                                        Cover {
                                            Layout.preferredWidth: 40
                                            Layout.preferredHeight: 40
                                            radius: 6
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
                                                font.pixelSize: 14
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

                                Label {
                                    anchors.centerIn: parent
                                    visible: !filteredTracks.length
                                    text: searchQuery ? ("No matching tracks found for '" + searchQuery + "'") : "Type in the search bar above to find music"
                                    color: silverDim
                                    font.family: displayFont
                                    font.pixelSize: 15
                                }
                            }
                        }
                    }

                    // ==========================================
                    // VIEW 3: RADIO / SETTINGS
                    // ==========================================
                    Item {
                        ColumnLayout {
                            anchors.centerIn: parent
                            Layout.preferredWidth: 380
                            spacing: 14

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 72
                                Layout.preferredHeight: 72
                                source: "qrc:/CassetteCat/assets/02-black-cat-cassette.png"
                                fillMode: Image.PreserveAspectFit
                            }

                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: page === "radio" ? "Radio Broadcast" : "Settings"
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 22
                                font.weight: Font.Bold
                            }

                            Label {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                text: page === "radio" ? "Online radio stations and stream sources." : "Manage audio directories and audio preferences."
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 13
                            }

                            Item { Layout.preferredHeight: 4 }

                            OutlineButton {
                                visible: page === "settings"
                                Layout.alignment: Qt.AlignHCenter
                                text: "Select Music Folder"
                                iconName: "folder"
                                onClicked: folderDialog.open()
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // MINIPLAYER BOTTOM DOCK (HEIGHT: 88PX - CLUTTER FREE)
        // ==========================================
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
                anchors.rightMargin: 24
                spacing: 20

                // Track Info
                RowLayout {
                    Layout.preferredWidth: 320
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
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
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
                            text: player.currentTrack.artist || (tracks.length > 0 ? "Pick a track to start playback" : "Choose a music folder to begin")
                            color: player.currentTrack.artist ? recordRed : (tracks.length > 0 ? recordRed : textSecondary)
                            font.family: bodyFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                // Transport & AudioSeeker
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
                            onClicked: player.toggleShuffle()
                        }

                        TransportButton {
                            buttonSize: 38
                            iconName: "skip-back"
                            iconColor: textPrimary
                            onClicked: playPrevious()
                        }

                        TransportButton {
                            buttonSize: 46
                            iconName: player.isPlaying ? "pause" : "play"
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

                // Volume & Action Buttons
                RowLayout {
                    Layout.preferredWidth: 280
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

                    // MiniPlayer Mode Switcher Button
                    PressDepthIconButton {
                        boxSize: 36
                        iconSize: 18
                        iconName: "pip"
                        tint: silverDim
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
    }

    // =========================================================================
    // CASSETTECAT ANDROID-MATCHING NOW PLAYING OVERLAY (LYRICS & CONTROLS)
    // =========================================================================
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

        // Full-screen event blocker: prevents any clicks from passing through
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

        // Ambient blurred album art backdrop
        Item {
            anchors.fill: parent
            clip: true
            opacity: 0.35

            Cover {
                anchors.centerIn: parent
                width: parent.width * 1.3
                height: parent.height * 1.3
                track: player.currentTrack
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

        // Minimal Clean Top Navigation Bar
        Item {
            id: npTopBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            z: 10

            // Left: Minimal Glass Collapse Button
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

            // Right: MiniPlayer Mode / Lyrics / Queue / Close
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                // Switch to MiniPlayer
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

                // Lyrics Microphone Button (Soft glowing glass active state)
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: nowPlayingMode === "lyrics"
                        ? "#30C23B30"
                        : (lyricsBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF")
                    border.width: 1.0
                    border.color: nowPlayingMode === "lyrics"
                        ? "#55C23B30"
                        : (lyricsBtnMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF")

                    Behavior on color { ColorAnimation { duration: 160 } }
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        icon: "mic"
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

                // Queue Button (Soft glowing glass active state)
                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: nowPlayingMode === "queue"
                        ? "#30C23B30"
                        : (queueBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF")
                    border.width: 1.0
                    border.color: nowPlayingMode === "queue"
                        ? "#55C23B30"
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

                // Close Button
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

        // Main Body Content (Smooth, Fluid, Jitter-Free Transition between Modes)
        Item {
            anchors.top: npTopBar.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 56
            anchors.rightMargin: 56
            anchors.bottomMargin: 32
            clip: true

            // Fixed Left Column (Direct, pure, single-motion album cover transition)
            Item {
                id: npLeftColumn
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Math.min(420, Math.round(parent.width * 0.38))

                readonly property int normalArtSize: Math.min(width - 20, Math.min(parent.height * 0.58, 360))
                readonly property int lyricsArtSize: 260
                readonly property int currentArtSize: nowPlayingMode === "lyrics" ? lyricsArtSize : normalArtSize
                readonly property int normalArtY: Math.round((parent.height - normalArtSize) / 2)
                readonly property int lyricsArtY: Math.max(10, Math.round((parent.height - (lyricsArtSize + 16 + 160)) / 2))
                readonly property int targetArtY: nowPlayingMode === "lyrics" ? lyricsArtY : normalArtY

                // Album Artwork Card (Pure direct motion: slides up and scales down smoothly)
                Rectangle {
                    id: npArtworkCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: npLeftColumn.targetArtY
                    width: npLeftColumn.currentArtSize
                    height: npLeftColumn.currentArtSize
                    radius: nowPlayingMode === "lyrics" ? 16 : 22
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

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#90000000"
                        shadowBlur: 0.7
                        shadowVerticalOffset: 16
                    }

                    Cover {
                        anchors.fill: parent
                        track: player.currentTrack
                        radius: npArtworkCard.radius
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: npArtworkCard.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#18FFFFFF" }
                            GradientStop { position: 0.3; color: "#00FFFFFF" }
                            GradientStop { position: 1.0; color: "#25000000" }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: toggleFavorite(player.currentTrack.filePath)
                    }
                }

                // Compact Under-Art Controls Dock (Fades in/out smoothly without jerking)
                Item {
                    id: underArtControls
                    anchors.top: npArtworkCard.bottom
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width - 24, 320)
                    height: 160
                    visible: opacity > 0.001
                    opacity: nowPlayingMode === "lyrics" ? 1.0 : 0.0
                    scale: nowPlayingMode === "lyrics" ? 1.0 : 0.95

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
                                onClicked: player.toggleShuffle()
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
                                iconName: player.isPlaying ? "pause" : "play"
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

            // Fixed Right Column (smooth cross-fade between controls, lyrics, and queue)
            Item {
                id: npRightColumn
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: npLeftColumn.right
                anchors.leftMargin: 48
                anchors.right: parent.right
                clip: true

                // =========================================================
                // VIEW A: DEFAULT CONTROLS DECK (ROCK-SOLID UNIFORM PLACEMENT)
                // =========================================================
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

                    // Title & Artist Header (Fixed baseline so controls never jump)
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

                    // Audio Seeker Bar (Fixed distance below metadata)
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

                    // Symmetrical Transport Controls (Fixed vertical placement)
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
                                onClicked: player.toggleShuffle()
                            }

                            TransportButton {
                                buttonSize: 52
                                iconName: "skip-back"
                                iconColor: textPrimary
                                onClicked: playPrevious()
                            }

                            TransportButton {
                                buttonSize: 72
                                iconName: player.isPlaying ? "pause" : "play"
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

                    // Volume Slider (Perfectly aligned below transport)
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

                // =========================================================
                // VIEW B: SEAMLESS TIME-SYNCED LYRICS VIEW (NO BOXES, PURE TEXT)
                // =========================================================
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
                        model: parsedLyrics
                        currentIndex: activeLyricIndex
                        spacing: 26
                        topMargin: Math.round(height * 0.38)
                        bottomMargin: Math.round(height * 0.45)
                        highlightRangeMode: ListView.ApplyRange
                        preferredHighlightBegin: Math.round(height * 0.36)
                        preferredHighlightEnd: Math.round(height * 0.38)
                        highlightMoveDuration: 550
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: SleekScrollBar {}

                        delegate: Item {
                            id: lyricItem
                            width: ListView.view.width
                            height: lyricTextLabel.implicitHeight + 14

                            readonly property bool isCurrent: index === activeLyricIndex
                            readonly property bool isSynced: modelData.timeMs >= 0

                            Label {
                                id: lyricTextLabel
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                wrapMode: Text.WordWrap
                                text: modelData.text || ""
                                color: isCurrent ? "#FFFFFF" : (lyricLineMouse.containsMouse ? textPrimary : (isSynced ? "#7E7A74" : textPrimary))
                                font.family: displayFont
                                font.pixelSize: 28
                                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                                font.letterSpacing: -0.3
                                lineHeight: 1.35
                                transformOrigin: Item.Left
                                scale: isCurrent ? 1.08 : (lyricLineMouse.containsMouse ? 1.01 : 0.95)
                                opacity: isCurrent ? 1.0 : (lyricLineMouse.containsMouse ? 0.75 : (isSynced ? 0.28 : 0.85))

                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                id: lyricLineMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: isSynced ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: {
                                    if (isSynced && modelData.timeMs >= 0) {
                                        player.seek(modelData.timeMs)
                                    }
                                }
                            }
                        }

                        // Instrumental / No Lyrics Animated State (Matching CassetteCat Android)
                        Item {
                            anchors.fill: parent
                            visible: !parsedLyrics || parsedLyrics.length === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 18

                                // Animated Audio Waveform (7 Pulse Bars)
                                Row {
                                    id: waveRow
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 7
                                    height: 64

                                    readonly property bool isAnimating: player.isPlaying && nowPlayingMode === "lyrics" && (!parsedLyrics || parsedLyrics.length === 0)

                                    // Bar 1
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 14
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 36; duration: 440; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 12; duration: 440; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 2
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 22
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 52; duration: 380; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 16; duration: 380; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 3
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 18
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 44; duration: 490; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 14; duration: 490; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 4 (Center Peak Bar)
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 28
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 60; duration: 340; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 20; duration: 340; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 5
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 18
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 46; duration: 460; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 14; duration: 460; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 6
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 24
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 54; duration: 370; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 16; duration: 370; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }

                                    // Bar 7
                                    Rectangle {
                                        width: 6; radius: 3; color: recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 12
                                        SequentialAnimation on height {
                                            running: waveRow.isAnimating; loops: Animation.Infinite
                                            NumberAnimation { to: 34; duration: 420; easing.type: Easing.InOutSine }
                                            NumberAnimation { to: 10; duration: 420; easing.type: Easing.InOutSine }
                                        }
                                        Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                                    }
                                }

                                // Title & Subtitle
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

                                // Action Pill Buttons
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 12

                                    // Search Online Pill
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
                                                text: "Search Online"
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
                                            onClicked: {
                                                const query = (player.currentTrack.title || "") + " " + (player.currentTrack.artist || "") + " lyrics"
                                                Qt.openUrlExternally("https://www.google.com/search?q=" + encodeURIComponent(query.trim()))
                                            }
                                        }
                                    }

                                    // Album Art Pill
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
                }

                // =========================================================
                // VIEW C: CLEAN UP NEXT QUEUE PANEL
                // =========================================================
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

                        Label {
                            text: "UP NEXT IN QUEUE"
                            color: recordRed
                            font.family: monoFont
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 1.0
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: tracks
                            spacing: 4
                            boundsBehavior: Flickable.StopAtBounds
                            ScrollBar.vertical: SleekScrollBar {}

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 52
                                radius: 8
                                color: qRowMouse.containsMouse
                                    ? surfaceElevated
                                    : (player.currentTrack.filePath === modelData.filePath ? surfaceCard : "transparent")
                                border.width: player.currentTrack.filePath === modelData.filePath ? 1 : 0
                                border.color: recordRed

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Cover {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        radius: 6
                                        track: modelData
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Label {
                                            Layout.fillWidth: true
                                            text: modelData.title || modelData.fileName
                                            color: player.currentTrack.filePath === modelData.filePath ? recordRed : textPrimary
                                            font.family: displayFont
                                            font.pixelSize: 13
                                            font.weight: player.currentTrack.filePath === modelData.filePath ? Font.Bold : Font.DemiBold
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
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: playTrack(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
