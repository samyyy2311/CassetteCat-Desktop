import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root

    required property var appWindow
    property var tracks: []
    property var playCounts: ({})
    property var playbackHistory: []

    property string currentTab: "overview"

    property int recapYear: new Date().getFullYear()
    property var recapYears: []
    property var recap: ({})
    property var recapSongs: []
    property var recapArtists: []
    property var recapAlbums: []
    property var recapGenres: []
    readonly property bool recapHasPlays: (recap.plays || 0) > 0

    // Lists from C++ arrive as sequence objects; plain arrays keep Array methods available.
    function toArray(list) {
        const result = []
        for (let i = 0; i < (list ? list.length : 0); ++i) result.push(list[i])
        return result
    }

    function refreshRecap() {
        const years = toArray(library.listeningYears())
        const currentYear = new Date().getFullYear()
        if (!years.includes(currentYear)) years.unshift(currentYear)
        recapYears = years
        recap = library.listeningRecap(recapYear)
        recapSongs = toArray(recap.topSongs)
        recapArtists = toArray(recap.topArtists)
        recapAlbums = toArray(recap.topAlbums)
        recapGenres = toArray(recap.topGenres)
    }

    function monthName(index) {
        return Qt.locale().standaloneMonthName(index, Locale.LongFormat)
    }

    onCurrentTabChanged: if (currentTab === "recap") refreshRecap()
    onRecapYearChanged: if (currentTab === "recap") refreshRecap()
    property string searchQuery: ""

    readonly property var playedTracks: {
        const rows = (tracks || []).filter(track => track && track.filePath && (playCounts[track.filePath] || 0) > 0)
            .map(track => ({ track: track, count: playCounts[track.filePath] || 0 }))
        rows.sort((left, right) => right.count - left.count)
        rows.forEach((row, i) => { row.rank = i + 1 })
        return rows
    }
    readonly property var mostPlayed: (playedTracks || []).slice(0, 50)

    readonly property var recentTracks: (playbackHistory || []).slice(0, 50)
    readonly property int totalPlays: Object.keys(playCounts || {}).reduce((total, path) => total + (playCounts[path] || 0), 0)
    readonly property int uniquePlayed: Object.keys(playCounts || {}).filter(path => (playCounts[path] || 0) > 0).length

    readonly property int totalDurationSeconds: (playedTracks || []).reduce((acc, row) => {
        const dur = (row.track && row.track.durationSeconds > 0) ? row.track.durationSeconds : 180
        return acc + (dur * row.count)
    }, 0)

    readonly property int libraryExploredPct: {
        const totalLib = (tracks || []).length
        return totalLib > 0 ? Math.min(100, Math.round(((playedTracks || []).length / totalLib) * 100)) : 0
    }

    readonly property string replayDepth: {
        return uniquePlayed > 0 ? (totalPlays / uniquePlayed).toFixed(1) : "0.0"
    }

    readonly property var spotlightTrack: mostPlayed.length > 0 ? mostPlayed[0] : null

    readonly property var allArtistRanks: {
        const counts = {}
        const sampleTracks = {}
        playedTracks.forEach(row => {
            const artist = (row.track && row.track.artist) ? row.track.artist : "Unknown Artist"
            counts[artist] = (counts[artist] || 0) + row.count
            if (!sampleTracks[artist] && row.track) sampleTracks[artist] = row.track
        })
        return Object.keys(counts).map(artist => ({
            artist: artist,
            name: artist,
            count: counts[artist],
            track: sampleTracks[artist] || ({})
        })).sort((left, right) => right.count - left.count)
    }
    readonly property var artistRanks: (allArtistRanks || []).slice(0, 30)

    readonly property var allAlbumRanks: {
        const groups = {}
        playedTracks.forEach(row => {
            if (!row.track) return
            const album = row.track.album ? row.track.album : "Unknown Album"
            const artist = row.track.albumArtist || row.track.artist || "Unknown Artist"
            const key = album + "\u0000" + artist
            if (!groups[key]) {
                groups[key] = {
                    album: album,
                    name: album,
                    artist: artist,
                    count: 0,
                    track: row.track
                }
            }
            groups[key].count += row.count
        })
        return Object.values(groups).sort((left, right) => right.count - left.count)
    }
    readonly property var albumRanks: (allAlbumRanks || []).slice(0, 30)

    readonly property var genreRanks: {
        const counts = {}
        playedTracks.forEach(row => {
            const raw = (row.track && row.track.genre) ? row.track.genre.trim() : ""
            const genre = (raw.length > 0 && raw.toLowerCase() !== "unknown") ? raw : "Other"
            counts[genre] = (counts[genre] || 0) + row.count
        })
        const rawList = Object.keys(counts).map(g => ({
            genre: g,
            count: counts[g]
        })).sort((a, b) => b.count - a.count).slice(0, 6)

        const recognizedTotal = rawList.reduce((sum, item) => sum + item.count, 0)
        return rawList.map(item => ({
            genre: item.genre,
            count: item.count,
            percentage: recognizedTotal > 0 ? Math.max(1, Math.round((item.count / recognizedTotal) * 100)) : 0
        }))
    }

    readonly property var genreColors: [
        root.appWindow.recordRed,
        "#F59E0B",
        "#10B981",
        "#06B6D4",
        "#EC4899",
        "#8B5CF6",
        "#C4C4C0"
    ]

    readonly property bool hasData: totalPlays > 0 || recentTracks.length > 0


    readonly property var filteredTracks: {
        if (!searchQuery.trim()) return mostPlayed
        const q = searchQuery.toLowerCase().trim()
        return playedTracks.filter(r => {
            const title = (r.track && (r.track.title || r.track.fileName) || "").toLowerCase()
            const artist = (r.track && r.track.artist || "").toLowerCase()
            const album = (r.track && r.track.album || "").toLowerCase()
            return title.includes(q) || artist.includes(q) || album.includes(q)
        })
    }

    readonly property var filteredArtists: {
        if (!searchQuery.trim()) return artistRanks
        const q = searchQuery.toLowerCase().trim()
        return allArtistRanks.filter(r => (r.artist || "").toLowerCase().includes(q))
    }

    readonly property var filteredAlbums: {
        if (!searchQuery.trim()) return albumRanks
        const q = searchQuery.toLowerCase().trim()
        return allAlbumRanks.filter(r => (r.album || "").toLowerCase().includes(q) || (r.artist || "").toLowerCase().includes(q))
    }

    readonly property var filteredHistory: {
        if (!searchQuery.trim()) return recentTracks
        const q = searchQuery.toLowerCase().trim()
        return recentTracks.filter(t => {
            const title = (t && (t.title || t.fileName) || "").toLowerCase()
            const artist = (t && t.artist || "").toLowerCase()
            const album = (t && t.album || "").toLowerCase()
            return title.includes(q) || artist.includes(q) || album.includes(q)
        })
    }

    readonly property var activeTabTracks: {
        if (root.currentTab === "recap") return root.recapSongs.map(row => row.track)
        if (root.currentTab === "history") return root.filteredHistory
        if (root.currentTab === "artists") return root.filteredArtists.map(r => r.track).filter(t => t && t.filePath)
        if (root.currentTab === "albums") return root.filteredAlbums.map(r => r.track).filter(t => t && t.filePath)
        return root.filteredTracks.map(r => r.track).filter(t => t && t.filePath)
    }

    function formatCount(count) {
        return count + (count === 1 ? " play" : " plays")
    }

    function formatDurationTotal(seconds) {
        if (!seconds || seconds <= 0) return "0m"
        const hrs = Math.floor(seconds / 3600)
        const mins = Math.floor((seconds % 3600) / 60)
        if (hrs > 0) {
            return hrs + "h " + (mins < 10 ? "0" : "") + mins + "m"
        }
        return Math.max(1, mins) + "m"
    }



    component StatCard : Rectangle {
        property string label: ""
        property string value: ""
        property string subtitle: ""

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 74
        radius: 12
        color: root.appWindow.surfaceCard
        border.width: 1
        border.color: statHover.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle

        Behavior on border.color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Label {
                text: label.toUpperCase()
                color: root.appWindow.silverDim
                font.family: root.appWindow.monoFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }

            Label {
                Layout.fillWidth: true
                text: value
                color: root.appWindow.textPrimary
                font.family: root.appWindow.displayFont
                font.pixelSize: 20
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Label {
                visible: subtitle.length > 0
                Layout.fillWidth: true
                text: subtitle
                color: root.appWindow.textSecondary
                font.family: root.appWindow.monoFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: statHover
            anchors.fill: parent
            hoverEnabled: true
        }
    }

    component RankedSongRow : RowLayout {
        id: rankedRow
        property var rowItem: null
        property int rankNumber: 1
        // Replaces the all-time play count, for rankings over a shorter period.
        property string countText: ""

        readonly property var trackData: rowItem && rowItem.track ? rowItem.track : ({})

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        implicitHeight: 54
        spacing: 10

        Label {
            text: rankNumber < 10 ? "0" + rankNumber : "" + rankNumber
            color: rankNumber <= 3 ? root.appWindow.recordRed : root.appWindow.silverDim
            font.family: root.appWindow.monoFont
            font.pixelSize: 12
            font.weight: rankNumber <= 3 ? Font.Bold : Font.Normal
            Layout.preferredWidth: 24
            horizontalAlignment: Text.AlignRight
        }

        SongRow {
            Layout.fillWidth: true
            track: rankedRow.trackData
            showPlayCount: rankedRow.countText.length === 0
            showAlbum: true
            onFavoriteClicked: root.appWindow.toggleFavorite(rankedRow.trackData.filePath)
            onClicked: root.appWindow.playTrack(rankedRow.trackData)
        }

        Label {
            visible: rankedRow.countText.length > 0
            Layout.preferredWidth: 60
            horizontalAlignment: Text.AlignRight
            text: rankedRow.countText
            color: root.appWindow.silverDim
            font.family: root.appWindow.monoFont
            font.pixelSize: 11
        }
    }

    component RecapHeading : ColumnLayout {
        property string title: ""
        property string subtitle: ""

        spacing: 2

        Label {
            text: title
            color: root.appWindow.textPrimary
            font.family: root.appWindow.displayFont
            font.pixelSize: 18
            font.weight: Font.Bold
            font.letterSpacing: -0.2
        }

        Label {
            text: subtitle
            color: root.appWindow.textSecondary
            font.family: root.appWindow.bodyFont
            font.pixelSize: 12
        }
    }



    EmptyState {
        anchors.centerIn: parent
        visible: !root.hasData
        catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
        title: "No listening history yet"
        subtitle: "Play songs for at least 30 seconds to record your listening stats and build your personal record"
        actionLabel: "Explore Library"
        onActionClicked: root.appWindow.page = "library"
    }



    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.hasData

        // Top bar
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
                        { id: "overview", label: "Overview" },
                        { id: "tracks", label: "Top Tracks" },
                        { id: "artists", label: "Top Artists" },
                        { id: "albums", label: "Top Albums" },
                        { id: "history", label: "History" },
                        { id: "recap", label: "Recap" }
                    ]

                    Item {
                        width: tabLbl.implicitWidth
                        height: 32

                        Label {
                            id: tabLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.currentTab === modelData.id ? root.appWindow.textPrimary : root.appWindow.textSecondary
                            font.family: root.appWindow.displayFont
                            font.pixelSize: 15
                            font.weight: root.currentTab === modelData.id ? Font.Bold : Font.Medium
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            height: 2.5
                            radius: 1.25
                            color: root.appWindow.recordRed
                            visible: root.currentTab === modelData.id
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentTab = modelData.id
                                root.searchQuery = ""
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: countTagLbl.implicitWidth + 14
                radius: 11
                color: root.appWindow.surfaceTag
                border.width: 1
                border.color: root.appWindow.borderSubtle

                Label {
                    id: countTagLbl
                    anchors.centerIn: parent
                    text: root.totalPlays + " plays • " + root.uniquePlayed + " tracks"
                    color: root.appWindow.silverDim
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }



            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "play"
                    tint: root.appWindow.recordRedHover
                    tooltipText: "Play all"
                    enabled: root.activeTabTracks.length > 0
                    onClicked: {
                        const tracksToPlay = root.activeTabTracks
                        if (tracksToPlay.length > 0) {
                            root.appWindow.startPlayback(tracksToPlay, 0, false)
                        }
                    }
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "shuffle"
                    tint: root.appWindow.textPrimary
                    tooltipText: "Shuffle"
                    enabled: root.activeTabTracks.length > 0
                    onClicked: {
                        const tracksToShuffle = root.activeTabTracks
                        if (tracksToShuffle.length > 0) {
                            root.appWindow.shufflePlayback(tracksToShuffle)
                        }
                    }
                }

                ExpandableSearchBar {
                    id: recordSearchBar
                    boxSize: 34
                    iconSize: 16
                    expandedWidth: 180
                    placeholder: root.currentTab === "artists" ? "Search artists..." : root.currentTab === "albums" ? "Search albums..." : "Search record..."
                    text: root.searchQuery
                    onTextChanged: root.searchQuery = text
                    onCleared: root.searchQuery = ""
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "list-music"
                    tint: root.appWindow.textPrimary
                    tooltipText: "Save as playlist"
                    enabled: root.activeTabTracks.length > 0
                    opacity: root.activeTabTracks.length > 0 ? 1.0 : 0.45
                    onClicked: {
                        const tracksToSave = root.activeTabTracks
                        if (tracksToSave.length === 0) return
                        root.appWindow.createPlaylist("Listening Record", tracksToSave)
                        root.appWindow.playlistStatus = "Listening Record playlist saved"
                    }
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "rotate-ccw"
                    tint: root.appWindow.silverDim
                    tooltipText: "Clear listening record"
                    onClicked: clearPopup.open()
                }
            }
        }


        StackLayout {
            id: recordStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: ["overview", "tracks", "artists", "albums", "history", "recap"].indexOf(root.currentTab)

            // Overview
            Flickable {
                id: overviewScroll
                readonly property real availableWidth: width
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                pixelAligned: UiConstants.pixelAligned
                ScrollBar.vertical: AutoHideScrollBar {}
                contentWidth: availableWidth
                contentHeight: overviewCol.implicitHeight + 48

                ColumnLayout {
                    id: overviewCol
                    x: 28
                    y: 8
                    width: Math.max(100, overviewScroll.availableWidth - 56)
                    spacing: 28

                    // #1 track spotlight
                    Rectangle {
                        id: heroCard
                        Layout.fillWidth: true
                        height: 155
                        radius: 12
                        color: root.appWindow.surfaceCard
                        border.width: 1
                        border.color: heroCardMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle
                        visible: root.spotlightTrack !== null
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
                                radius: (root.appWindow && root.appWindow.albumArtRadius !== undefined) ? root.appWindow.albumArtRadius : 12
                                color: "white"
                            }
                        }

                        Cover {
                            anchors.fill: parent
                            track: root.spotlightTrack ? root.spotlightTrack.track : ({})
                            radius: (root.appWindow && root.appWindow.albumArtRadius !== undefined) ? root.appWindow.albumArtRadius : 12
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: (root.appWindow && root.appWindow.albumArtRadius !== undefined) ? root.appWindow.albumArtRadius : 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#500E0D0C" }
                                GradientStop { position: 0.4; color: "#B80E0D0C" }
                                GradientStop { position: 1.0; color: "#F20E0D0C" }
                            }
                        }

                        Item {
                            anchors.fill: parent
                            anchors.margins: 16
                            z: 2

                            RowLayout {
                                anchors.fill: parent
                                spacing: 16

                                Cover {
                                    Layout.preferredWidth: 120
                                    Layout.preferredHeight: 120
                                    track: root.spotlightTrack ? root.spotlightTrack.track : ({})
                                    radius: (root.appWindow && root.appWindow.albumArtRadius !== undefined)
                                            ? (root.appWindow.albumArtRadius === 0 ? 0 : (root.appWindow.albumArtRadius <= 8 ? 6 : 10))
                                            : 10
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Label {
                                        text: "ALL-TIME #1 TRACK"
                                        color: root.appWindow.recordRed
                                        font.family: root.appWindow.monoFont
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 0.8
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: root.spotlightTrack && root.spotlightTrack.track ? (root.spotlightTrack.track.title || root.spotlightTrack.track.fileName || "Untitled Track") : ""
                                        color: root.appWindow.textPrimary
                                        font.family: root.appWindow.displayFont
                                        font.pixelSize: 20
                                        font.weight: Font.Bold
                                        font.letterSpacing: -0.3
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: {
                                            if (!root.spotlightTrack || !root.spotlightTrack.track) return ""
                                            const art = root.spotlightTrack.track.artist || "Unknown Artist"
                                            const alb = root.spotlightTrack.track.album || ""
                                            return alb.length > 0 ? (art + " • " + alb) : art
                                        }
                                        color: root.appWindow.textSecondary
                                        font.family: root.appWindow.bodyFont
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.topMargin: 2
                                        text: {
                                            if (!root.spotlightTrack || !root.spotlightTrack.track) return ""
                                            const sec = (root.spotlightTrack.track.durationSeconds || 180) * root.spotlightTrack.count
                                            return root.formatCount(root.spotlightTrack.count) + " • " + root.formatDurationTotal(sec) + " on repeat"
                                        }
                                        color: root.appWindow.silverDim
                                        font.family: root.appWindow.monoFont
                                        font.pixelSize: 11
                                    }
                                }

                                RowLayout {
                                    spacing: 10
                                    Layout.alignment: Qt.AlignVCenter

                                    TransportButton {
                                        buttonSize: 42
                                        iconName: "play"
                                        accented: true
                                        iconColor: root.appWindow.recordRed
                                        tooltipText: "Play #1 Track"
                                        onClicked: {
                                            if (root.spotlightTrack && root.spotlightTrack.track) {
                                                root.appWindow.playTrack(root.spotlightTrack.track)
                                            }
                                        }
                                    }

                                    TransportButton {
                                        buttonSize: 42
                                        iconName: "shuffle"
                                        iconColor: root.appWindow.textPrimary
                                        tooltipText: "Shuffle Heavy Rotation"
                                        onClicked: {
                                            if (root.mostPlayed.length > 0) {
                                                root.appWindow.shufflePlayback(root.mostPlayed.map(r => r.track))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: heroCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            z: 1
                            onClicked: {
                                if (root.spotlightTrack && root.spotlightTrack.track) {
                                    root.appWindow.playTrack(root.spotlightTrack.track)
                                }
                            }
                        }
                    }


                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        StatCard {
                            label: "Listening Time"
                            value: root.formatDurationTotal(root.totalDurationSeconds)
                            subtitle: "based on qualified listens"
                        }

                        StatCard {
                            label: "Total Plays"
                            value: "" + root.totalPlays
                            subtitle: root.totalPlays === 1 ? "1 qualified listen" : root.totalPlays + " qualified listens"
                        }

                        StatCard {
                            label: "Library Explored"
                            value: root.libraryExploredPct + "%"
                            subtitle: (root.playedTracks ? root.playedTracks.length : 0) + " of " + (root.tracks ? root.tracks.length : 0) + " songs"
                        }

                        StatCard {
                            label: "Replay Depth"
                            value: root.replayDepth + "x"
                            subtitle: "avg plays per song"
                        }
                    }

                    // Top artists
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.artistRanks.length > 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Top Artists"
                                    color: root.appWindow.textPrimary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.2
                                }

                                Label {
                                    text: "Your most played musical artists"
                                    color: root.appWindow.textSecondary
                                    font.family: root.appWindow.bodyFont
                                    font.pixelSize: 12
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: root.artistRanks.length > 5
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: seeArtistsRow.implicitWidth + 20
                                Layout.alignment: Qt.AlignVCenter
                                radius: height / 2
                                color: seeArtistsMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceTag
                                border.width: 1
                                border.color: seeArtistsMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: seeArtistsRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Label {
                                        text: "See all (" + root.artistRanks.length + ")"
                                        color: seeArtistsMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary
                                        font.family: root.appWindow.monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    LucideIcon {
                                        icon: "chevron-right"
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        color: seeArtistsMouse.containsMouse ? root.appWindow.recordRedHover : root.appWindow.silverDim
                                    }
                                }

                                MouseArea {
                                    id: seeArtistsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = "artists"
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            height: 200
                            orientation: ListView.Horizontal
                            spacing: 16
                            clip: false
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: UiConstants.flickDeceleration
                            maximumFlickVelocity: UiConstants.maximumFlickVelocity
                            cacheBuffer: UiConstants.cacheBuffer
                            pixelAligned: UiConstants.pixelAligned
                            reuseItems: true
                            model: root.artistRanks.slice(0, 10)
                            delegate: ArtistCard {
                                name: modelData.artist
                                count: modelData.count
                                subtitle: modelData.count + (modelData.count === 1 ? " play" : " plays")
                                track: modelData.track
                                cardWidth: 148
                                cardHeight: 200
                                onClicked: root.appWindow.openCatalogDetail("artist", modelData.artist, modelData.track)
                            }
                        }
                    }

                    // Top albums
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.albumRanks.length > 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Top Albums"
                                    color: root.appWindow.textPrimary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.2
                                }

                                Label {
                                    text: "Your highest rotation records"
                                    color: root.appWindow.textSecondary
                                    font.family: root.appWindow.bodyFont
                                    font.pixelSize: 12
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: root.albumRanks.length > 5
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: seeAlbumsRow.implicitWidth + 20
                                Layout.alignment: Qt.AlignVCenter
                                radius: height / 2
                                color: seeAlbumsMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceTag
                                border.width: 1
                                border.color: seeAlbumsMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: seeAlbumsRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Label {
                                        text: "See all (" + root.albumRanks.length + ")"
                                        color: seeAlbumsMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary
                                        font.family: root.appWindow.monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    LucideIcon {
                                        icon: "chevron-right"
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        color: seeAlbumsMouse.containsMouse ? root.appWindow.recordRedHover : root.appWindow.silverDim
                                    }
                                }

                                MouseArea {
                                    id: seeAlbumsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = "albums"
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            height: 205
                            orientation: ListView.Horizontal
                            spacing: 16
                            clip: false
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: UiConstants.flickDeceleration
                            maximumFlickVelocity: UiConstants.maximumFlickVelocity
                            cacheBuffer: UiConstants.cacheBuffer
                            pixelAligned: UiConstants.pixelAligned
                            reuseItems: true
                            model: root.albumRanks.slice(0, 10)
                            delegate: AlbumCard {
                                name: modelData.album
                                artist: modelData.artist
                                count: modelData.count
                                subtitle: (modelData.artist ? (modelData.artist + " • ") : "") + modelData.count + (modelData.count === 1 ? " play" : " plays")
                                track: modelData.track
                                cardWidth: 140
                                cardHeight: 205
                                onClicked: root.appWindow.openCatalogDetail("album", modelData.album, modelData.track)
                            }
                        }
                    }

                    // Genre breakdown
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.genreRanks.length > 0

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "Taste Profile"
                                color: root.appWindow.textPrimary
                                font.family: root.appWindow.displayFont
                                font.pixelSize: 18
                                font.weight: Font.Bold
                                font.letterSpacing: -0.2
                            }

                            Label {
                                text: "Top genres across qualified playback"
                                color: root.appWindow.textSecondary
                                font.family: root.appWindow.bodyFont
                                font.pixelSize: 12
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: tasteCol.implicitHeight + 24
                            radius: 12
                            color: root.appWindow.surfaceCard
                            border.width: 1
                            border.color: root.appWindow.borderSubtle

                            ColumnLayout {
                                id: tasteCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 16
                                spacing: 12


                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 6
                                    radius: 3
                                    color: root.appWindow.surfaceElevated
                                    clip: true

                                    Row {
                                        anchors.fill: parent
                                        spacing: 1

                                        Repeater {
                                            model: root.genreRanks
                                            delegate: Rectangle {
                                                height: parent.height
                                                width: Math.max(4, Math.round(tasteCol.width * (modelData.percentage / 100)))
                                                color: root.genreColors[index % root.genreColors.length]
                                            }
                                        }
                                    }
                                }


                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Repeater {
                                        model: root.genreRanks
                                        delegate: Rectangle {
                                            height: 24
                                            width: genreRow.implicitWidth + 16
                                            radius: 12
                                            color: root.appWindow.surfaceTag
                                            border.width: 1
                                            border.color: root.appWindow.borderSubtle

                                            RowLayout {
                                                id: genreRow
                                                anchors.centerIn: parent
                                                spacing: 6

                                                Rectangle {
                                                    Layout.preferredWidth: 6
                                                    Layout.preferredHeight: 6
                                                    radius: 3
                                                    color: root.genreColors[index % root.genreColors.length]
                                                }

                                                Label {
                                                    text: modelData.genre
                                                    color: root.appWindow.textPrimary
                                                    font.family: root.appWindow.displayFont
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                }

                                                Label {
                                                    text: modelData.percentage + "%"
                                                    color: root.appWindow.silverDim
                                                    font.family: root.appWindow.monoFont
                                                    font.pixelSize: 10
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Heavy rotation — top 5
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.mostPlayed.length > 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 2

                                Label {
                                    text: "Heavy Rotation"
                                    color: root.appWindow.textPrimary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 18
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.2
                                }

                                Label {
                                    text: "Your top tracks in highest rotation"
                                    color: root.appWindow.textSecondary
                                    font.family: root.appWindow.bodyFont
                                    font.pixelSize: 12
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: root.mostPlayed.length > 5
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: seeTracksRow.implicitWidth + 20
                                Layout.alignment: Qt.AlignVCenter
                                radius: height / 2
                                color: seeTracksMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceTag
                                border.width: 1
                                border.color: seeTracksMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: seeTracksRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Label {
                                        text: "See all (" + root.mostPlayed.length + ")"
                                        color: seeTracksMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary
                                        font.family: root.appWindow.monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    LucideIcon {
                                        icon: "chevron-right"
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        color: seeTracksMouse.containsMouse ? root.appWindow.recordRedHover : root.appWindow.silverDim
                                    }
                                }

                                MouseArea {
                                    id: seeTracksMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentTab = "tracks"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Repeater {
                                model: root.mostPlayed.slice(0, 5)
                                delegate: RankedSongRow {
                                    rowItem: modelData
                                    rankNumber: index + 1
                                }
                            }
                        }
                    }
                }
            }

            // Tracks
            Item {
                ListView {
                    id: topTracksListView
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    clip: true
                    model: root.filteredTracks
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    cacheBuffer: UiConstants.cacheBuffer
                    pixelAligned: UiConstants.pixelAligned
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: RankedSongRow {
                        width: topTracksListView.width
                        rowItem: modelData
                        rankNumber: (modelData && modelData.rank !== undefined) ? modelData.rank : (index + 1)
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: root.filteredTracks.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: root.searchQuery.trim().length > 0 ? "No Tracks Found" : "No Plays Recorded"
                    subtitle: root.searchQuery.trim().length > 0 ? ("No tracks match \"" + root.searchQuery + "\"") : "Play tracks for at least 30 seconds to record your top tracks"
                    actionLabel: root.searchQuery.trim().length > 0 ? "Clear Search" : "Explore Library"
                    onActionClicked: {
                        if (root.searchQuery.trim().length > 0) root.searchQuery = ""
                        else root.appWindow.page = "library"
                    }
                }
            }

            // Artists
            Item {
                GridView {
                    id: artistGrid
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: root.filteredArtists
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 190))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: 245
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    cacheBuffer: UiConstants.cacheBuffer
                    pixelAligned: UiConstants.pixelAligned
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: Item {
                        width: artistGrid.cellWidth
                        height: 235

                        ArtistCard {
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: 225
                            name: modelData.artist
                            count: modelData.count
                            subtitle: modelData.count + (modelData.count === 1 ? " play" : " plays")
                            track: modelData.track
                            onClicked: root.appWindow.openCatalogDetail("artist", modelData.artist, modelData.track)
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: root.filteredArtists.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/04-gray-dancing-headphones.png"
                    title: root.searchQuery.trim().length > 0 ? "No Artists Found" : "No Artists Recorded"
                    subtitle: root.searchQuery.trim().length > 0 ? ("No artists match \"" + root.searchQuery + "\"") : "Artists with qualified plays will appear here"
                    actionLabel: root.searchQuery.trim().length > 0 ? "Clear Search" : "Explore Library"
                    onActionClicked: {
                        if (root.searchQuery.trim().length > 0) root.searchQuery = ""
                        else root.appWindow.page = "library"
                    }
                }
            }

            // Albums
            Item {
                GridView {
                    id: albumGrid
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: root.filteredAlbums
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 195))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: 255
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    cacheBuffer: UiConstants.cacheBuffer
                    pixelAligned: UiConstants.pixelAligned
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: Item {
                        width: albumGrid.cellWidth
                        height: 245

                        AlbumCard {
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: 235
                            name: modelData.album
                            artist: modelData.artist
                            count: modelData.count
                            subtitle: (modelData.artist ? (modelData.artist + " • ") : "") + modelData.count + (modelData.count === 1 ? " play" : " plays")
                            track: modelData.track
                            onClicked: root.appWindow.openCatalogDetail("album", modelData.album, modelData.track)
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: root.filteredAlbums.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: root.searchQuery.trim().length > 0 ? "No Albums Found" : "No Albums Recorded"
                    subtitle: root.searchQuery.trim().length > 0 ? ("No albums match \"" + root.searchQuery + "\"") : "Albums with qualified plays will appear here"
                    actionLabel: root.searchQuery.trim().length > 0 ? "Clear Search" : "Explore Library"
                    onActionClicked: {
                        if (root.searchQuery.trim().length > 0) root.searchQuery = ""
                        else root.appWindow.page = "library"
                    }
                }
            }

            // History
            Item {
                ListView {
                    id: historyListView
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    clip: true
                    model: root.filteredHistory
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    cacheBuffer: UiConstants.cacheBuffer
                    pixelAligned: UiConstants.pixelAligned
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: SongRow {
                        width: historyListView.width
                        track: modelData
                        showAlbum: true
                        onFavoriteClicked: root.appWindow.toggleFavorite(modelData.filePath)
                        onClicked: root.appWindow.playTrack(modelData)
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: root.filteredHistory.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
                    title: root.searchQuery.trim().length > 0 ? "No History Found" : "No History Recorded"
                    subtitle: root.searchQuery.trim().length > 0 ? ("No tracks match \"" + root.searchQuery + "\"") : "Playback history will appear here as you listen to music"
                    actionLabel: root.searchQuery.trim().length > 0 ? "Clear Search" : "Explore Library"
                    onActionClicked: {
                        if (root.searchQuery.trim().length > 0) root.searchQuery = ""
                        else root.appWindow.page = "library"
                    }
                }
            }

            // Recap
            Flickable {
                id: recapScroll
                clip: true
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                pixelAligned: UiConstants.pixelAligned
                ScrollBar.vertical: AutoHideScrollBar {}
                contentWidth: width
                contentHeight: recapCol.implicitHeight + 48

                ColumnLayout {
                    id: recapCol
                    x: 28
                    y: 8
                    width: Math.max(100, recapScroll.width - 56)
                    spacing: 28

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        ColumnLayout {
                            spacing: 4

                            Label {
                                text: "Your " + root.recapYear
                                color: root.appWindow.textPrimary
                                font.family: root.appWindow.displayFont
                                font.pixelSize: 26
                                font.weight: Font.Bold
                            }

                            Label {
                                visible: root.recapHasPlays
                                text: "Recorded since " + new Date(root.recap.firstListen || 0).toLocaleDateString(Qt.locale(), "d MMMM yyyy")
                                color: root.appWindow.textSecondary
                                font.family: root.appWindow.monoFont
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Row {
                            visible: root.recapYears.length > 1
                            spacing: 18

                            Repeater {
                                model: root.recapYears

                                Label {
                                    required property var modelData
                                    text: "" + modelData
                                    color: root.recapYear === modelData ? root.appWindow.textPrimary : root.appWindow.textSecondary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 14
                                    font.weight: root.recapYear === modelData ? Font.Bold : Font.Medium

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.recapYear = modelData
                                    }
                                }
                            }
                        }
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 320
                        visible: !root.recapHasPlays
                        catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
                        title: "Nothing recorded for " + root.recapYear + " yet"
                        subtitle: "Songs you play for at least 30 seconds are counted here, with the date you played them"
                    }

                    RowLayout {
                        visible: root.recapHasPlays
                        Layout.fillWidth: true
                        spacing: 12

                        StatCard {
                            label: "Listening Time"
                            value: root.formatDurationTotal((root.recap.listenedMs || 0) / 1000)
                            subtitle: "time spent listening"
                        }

                        StatCard {
                            label: "Plays"
                            value: "" + (root.recap.plays || 0)
                            subtitle: "counted listens"
                        }

                        StatCard {
                            label: "Songs"
                            value: "" + (root.recap.songCount || 0)
                            subtitle: "different songs"
                        }

                        StatCard {
                            label: "Artists"
                            value: "" + (root.recap.artistCount || 0)
                            subtitle: "different artists"
                        }
                    }

                    RowLayout {
                        visible: root.recapHasPlays
                        Layout.fillWidth: true
                        spacing: 12

                        StatCard {
                            label: "Top Album"
                            value: root.recapAlbums.length ? root.recapAlbums[0].name : "—"
                            subtitle: root.recapAlbums.length ? root.formatCount(root.recapAlbums[0].plays) : ""
                        }

                        StatCard {
                            label: "Top Genre"
                            value: root.recapGenres.length ? root.recapGenres[0].name : "—"
                            subtitle: root.recapGenres.length ? root.formatCount(root.recapGenres[0].plays) : ""
                        }

                        StatCard {
                            label: "Busiest Month"
                            value: (root.recap.busiestMonth ?? -1) >= 0 ? root.monthName(root.recap.busiestMonth) : "—"
                            subtitle: (root.recap.busiestMonth ?? -1) >= 0
                                ? root.formatDurationTotal(root.recap.months[root.recap.busiestMonth] / 1000) + " listened"
                                : ""
                        }
                    }

                    ColumnLayout {
                        visible: root.recapArtists.length > 0
                        Layout.fillWidth: true
                        spacing: 12

                        RecapHeading {
                            title: "Top Artists"
                            subtitle: "Who you played most in " + root.recapYear
                        }

                        ListView {
                            Layout.fillWidth: true
                            height: 200
                            orientation: ListView.Horizontal
                            spacing: 16
                            clip: false
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: UiConstants.flickDeceleration
                            maximumFlickVelocity: UiConstants.maximumFlickVelocity
                            model: root.recapArtists
                            delegate: ArtistCard {
                                name: modelData.name
                                count: modelData.plays
                                subtitle: root.formatCount(modelData.plays)
                                track: modelData.track
                                cardWidth: 148
                                cardHeight: 200
                                onClicked: root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track)
                            }
                        }
                    }

                    ColumnLayout {
                        visible: root.recapSongs.length > 0
                        Layout.fillWidth: true
                        spacing: 4

                        RecapHeading {
                            Layout.bottomMargin: 8
                            title: "Top Songs"
                            subtitle: "Your most played songs of " + root.recapYear
                        }

                        Repeater {
                            model: root.recapSongs

                            RankedSongRow {
                                required property var modelData
                                required property int index
                                rowItem: modelData
                                rankNumber: index + 1
                                countText: root.formatCount(modelData.plays)
                            }
                        }
                    }
                }
            }
        }
    }



    Popup {
        id: clearPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        x: Math.round(((parent ? parent.width : 800) - width) / 2)
        y: Math.round(((parent ? parent.height : 600) - height) / 2)
        width: Math.min((parent ? parent.width - 64 : 420), 420)
        padding: 24
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Overlay.modal: Rectangle {
            color: "#B8000000"
        }

        background: Rectangle {
            radius: 14
            color: root.appWindow.surfaceCard
            border.width: 1
            border.color: root.appWindow.borderSubtle
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 18
                    color: Qt.rgba(1, 0.2, 0.2, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(1, 0.2, 0.2, 0.25)

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        icon: "rotate-ccw"
                        color: root.appWindow.recordRed
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: "Clear Listening Record?"
                        color: root.appWindow.textPrimary
                        font.family: root.appWindow.displayFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Label {
                        text: "This cannot be undone"
                        color: root.appWindow.silverDim
                        font.family: root.appWindow.monoFont
                        font.pixelSize: 11
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: "This will reset all your play counts, top statistics, and playback history. Your music library files and playlists will not be affected."
                color: root.appWindow.textSecondary
                font.family: root.appWindow.bodyFont
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: "Cancel"
                    onClicked: clearPopup.close()
                }

                SettingButton {
                    text: "Clear Record"
                    iconName: "rotate-ccw"
                    destructive: true
                    onClicked: {
                        root.appWindow.clearListeningRecord()
                        clearPopup.close()
                    }
                }
            }
        }
    }
}
