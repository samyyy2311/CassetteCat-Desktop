import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow
    required property var libraryModel
    required property var playerController

    anchors.fill: parent

    property alias searchBox: pageSearchBox
    property alias searchInput: pageSearchInput
    readonly property bool filtering: appWindow.searchQuery.trim().length > 0 || appWindow.activeFormatFilter !== "ALL"

    property var cachedGroups: ({})

    function refreshCatalog() {
        if (root.libraryModel && typeof root.libraryModel.catalogGroups === "function") {
            cachedGroups = root.libraryModel.catalogGroups()
        }
    }

    Component.onCompleted: refreshCatalog()

    Connections {
        target: root.libraryModel
        function onTracksChanged() { root.refreshCatalog() }
        function onChanged() { root.refreshCatalog() }
    }

    // Deduplicated genres by normalized lowercase name
    readonly property var popularGenres: {
        const raw = (cachedGroups && cachedGroups.genres) || []
        if (!Array.isArray(raw)) return []
        const seen = {}
        const list = []
        for (let i = 0; i < raw.length; ++i) {
            const g = raw[i]
            if (!g) continue
            const name = (typeof g === "object" ? (g.name || "") : String(g)).trim()
            if (!name || name.toLowerCase() === "unknown") continue
            const normKey = name.toLowerCase()
            if (seen[normKey]) {
                seen[normKey].count += (g.count || 1)
                continue
            }
            const item = {
                name: name,
                count: g.count || 1,
                track: (typeof g === "object" && g.track) ? g.track : ({})
            }
            seen[normKey] = item
            list.push(item)
        }
        list.sort(function(a, b) { return b.count - a.count })
        return list.slice(0, 12)
    }

    // Deduplicated artists by normalized lowercase name
    readonly property var topArtists: {
        const raw = (cachedGroups && cachedGroups.artists) || []
        if (!Array.isArray(raw)) return []
        const seen = {}
        const list = []
        for (let i = 0; i < raw.length; ++i) {
            const a = raw[i]
            if (!a) continue
            const name = (typeof a === "object" ? (a.name || "") : String(a)).trim()
            if (!name || name.toLowerCase() === "unknown" || name.toLowerCase() === "unknown artist") continue
            const normKey = name.toLowerCase()
            if (seen[normKey]) {
                seen[normKey].count += (a.count || 1)
                continue
            }
            const item = {
                name: name,
                count: a.count || 1,
                track: (typeof a === "object" && a.track) ? a.track : ({})
            }
            seen[normKey] = item
            list.push(item)
        }
        list.sort(function(a, b) { return b.count - a.count })
        return list.slice(0, 12)
    }

    // Deduplicated recent listens: unique track and unique artist per card, excluding current playing track
    readonly property var recentListens: {
        const history = root.appWindow.playbackHistory
        if (!history || !Array.isArray(history) || !history.length) return []
        const currentPath = (root.playerController && root.playerController.currentTrack) ? root.playerController.currentTrack.filePath : ""
        const seenTrack = {}
        if (currentPath) {
            seenTrack[currentPath] = true
        }
        const seenArtist = {}
        const list = []

        function getArtistTokens(str) {
            if (!str) return []
            return str.split(/[,;&/]|(?:\s+(?:feat\.?|ft\.?|with|x)\s+)/i)
                .map(s => s.trim().toLowerCase())
                .filter(s => s.length > 0)
        }

        for (let i = 0; i < history.length; ++i) {
            const t = history[i]
            if (!t || !t.filePath) continue
            if (seenTrack[t.filePath]) continue
            seenTrack[t.filePath] = true

            const tokens = getArtistTokens(t.artist)
            let duplicate = false
            for (let j = 0; j < tokens.length; ++j) {
                if (seenArtist[tokens[j]]) {
                    duplicate = true
                    break
                }
            }
            if (duplicate) continue

            for (let j = 0; j < tokens.length; ++j) {
                seenArtist[tokens[j]] = true
            }

            list.push(t)
            if (list.length >= 8) break
        }
        return list
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 14

        // Hero Search Box
        Rectangle {
            id: pageSearchBox
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 12
            color: pageSearchInput.activeFocus ? surfaceElevated : surfaceCard
            border.width: pageSearchInput.activeFocus ? 1.5 : 1
            border.color: pageSearchInput.activeFocus ? recordRedHover : borderVariant

            Behavior on color { ColorAnimation { duration: UiConstants.durationFast } }
            Behavior on border.color { ColorAnimation { duration: UiConstants.durationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 14
                spacing: 12

                LucideIcon {
                    Layout.preferredWidth: 18
                    Layout.preferredHeight: 18
                    icon: "search"
                    color: pageSearchInput.activeFocus ? recordRedHover : silverDim

                    Behavior on color { ColorAnimation { duration: UiConstants.durationFast } }
                }

                TextInput {
                    id: pageSearchInput
                    Layout.fillWidth: true
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    selectByMouse: true
                    text: root.appWindow.searchQuery
                    onTextChanged: root.appWindow.searchQuery = text
                    Keys.onEscapePressed: focus = false

                    Text {
                        anchors.fill: parent
                        visible: !pageSearchInput.text && !pageSearchInput.activeFocus
                        text: "Search songs, artists, albums, or audio formats..."
                        color: silverDim
                        font.family: displayFont
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Keyboard shortcut hint when idle
                Rectangle {
                    visible: pageSearchInput.text.length === 0
                    Layout.preferredHeight: 22
                    Layout.preferredWidth: shortcutLabel.implicitWidth + 12
                    radius: 5
                    color: surfaceTag
                    border.width: 1
                    border.color: borderSubtle

                    Label {
                        id: shortcutLabel
                        anchors.centerIn: parent
                        text: "Ctrl + F"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                // Clear button when active text exists
                Rectangle {
                    visible: pageSearchInput.text.length > 0
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 12
                    color: clearMouse.containsMouse ? surfaceElevated : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        icon: "x"
                        color: clearMouse.containsMouse ? textPrimary : silverDim
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pageSearchInput.text = ""
                            root.appWindow.searchQuery = ""
                        }
                    }
                }
            }
        }

        // Format Filter Pills Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "FORMAT"
                color: silverDim
                font.family: monoFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.0
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "ALL", label: "All Formats", icon: "disc" },
                        { id: "FLAC", label: "Lossless (FLAC)", icon: "audio-lines" },
                        { id: "MP3", label: "MP3", icon: "music" },
                        { id: "AAC", label: "AAC / M4A", icon: "sparkles" }
                    ]

                    Rectangle {
                        property bool isSelected: root.appWindow.activeFormatFilter === modelData.id
                        width: chipRow.implicitWidth + 20
                        height: 28
                        radius: height / 2
                        color: isSelected
                            ? "#262320"
                            : (chipMouse.containsMouse ? surfaceElevated : surfaceTag)
                        border.width: 1
                        border.color: isSelected
                            ? recordRed
                            : (chipMouse.containsMouse ? borderVariant : borderSubtle)

                        Behavior on color { ColorAnimation { duration: UiConstants.durationFast } }
                        Behavior on border.color { ColorAnimation { duration: UiConstants.durationFast } }

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            LucideIcon {
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
                                icon: modelData.icon
                                color: parent.parent.isSelected ? recordRedHover : (chipMouse.containsMouse ? textPrimary : textSecondary)
                            }

                            Label {
                                text: modelData.label
                                color: parent.parent.isSelected ? recordRedHover : (chipMouse.containsMouse ? textPrimary : textSecondary)
                                font.family: monoFont
                                font.pixelSize: 11
                                font.weight: parent.parent.isSelected ? Font.Bold : Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.activeFormatFilter = modelData.id
                        }
                    }
                }
            }

            // Stat tag when idle
            Rectangle {
                visible: !root.filtering && root.libraryModel.trackCount > 0
                Layout.preferredHeight: 24
                Layout.preferredWidth: countTagLbl.implicitWidth + 16
                radius: 12
                color: surfaceTag
                border.width: 1
                border.color: borderSubtle

                Label {
                    id: countTagLbl
                    anchors.centerIn: parent
                    text: root.libraryModel.trackCount + " songs"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            // Match count when filtering
            Label {
                visible: root.filtering
                text: root.libraryModel.visibleTrackCount + (root.libraryModel.visibleTrackCount === 1 ? " track found" : " tracks found")
                color: silverDim
                font.family: monoFont
                font.pixelSize: 11
            }

            // Reset button when filtering
            PressDepthIconButton {
                visible: root.filtering
                boxSize: 30
                iconSize: 14
                iconName: "rotate-ccw"
                tint: recordRedHover
                tooltipText: "Reset Search & Filters"
                onClicked: {
                    pageSearchInput.text = ""
                    root.appWindow.searchQuery = ""
                    root.appWindow.activeFormatFilter = "ALL"
                }
            }
        }

        // Search Results List (visible during active query or filter)
        ListView {
            id: searchResults
            activeFocusOnTab: true
            onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.filtering
            clip: true
            model: root.libraryModel
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: UiConstants.flickDeceleration
            maximumFlickVelocity: UiConstants.maximumFlickVelocity
            cacheBuffer: UiConstants.cacheBuffer
            pixelAligned: UiConstants.pixelAligned
            reuseItems: true
            ScrollBar.vertical: SleekScrollBar {}

            header: Item {
                width: searchResults.width
                height: 32

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: 8

                    Label {
                        text: "MATCHING TRACKS"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.appWindow.searchQuery.length > 0 ? "Sorted by relevance" : "Filtered by format"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                    }
                }
            }

            delegate: SongRow {
                width: searchResults.width
                track: model.track
                showAlbum: true
                showCover: true
                showDuration: true
                showHeart: true
                onClicked: root.appWindow.playTrack(model.track)
                onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
            }

            EmptyState {
                anchors.centerIn: parent
                visible: root.libraryModel.visibleTrackCount === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                title: "No matching tracks"
                subtitle: "Try a different search or clear the format filter"
                actionLabel: "Clear Search"
                onActionClicked: {
                    pageSearchInput.text = ""
                    root.appWindow.searchQuery = ""
                    root.appWindow.activeFormatFilter = "ALL"
                }
            }
        }

        // Idle Discovery View (visible when no search query or filter is active)
        Flickable {
            id: idleScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.filtering
            clip: true
            readonly property real availableWidth: width
            contentWidth: width
            contentHeight: idleColumn.implicitHeight + 32
            flickDeceleration: UiConstants.flickDeceleration
            maximumFlickVelocity: UiConstants.maximumFlickVelocity
            pixelAligned: UiConstants.pixelAligned
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar {}

            ColumnLayout {
                id: idleColumn
                width: idleScrollView.availableWidth
                spacing: 24

                // Section 1: Recent Listens Shelf (deduplicated by artist)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.recentListens.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel {
                            text: "Recent Listens"
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: "Jump back in"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }
                    }

                    ListView {
                        activeFocusOnTab: true
                        onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                        Layout.fillWidth: true
                        height: 205
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: false
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: UiConstants.flickDeceleration
                        maximumFlickVelocity: UiConstants.maximumFlickVelocity
                        cacheBuffer: UiConstants.cacheBuffer
                        pixelAligned: UiConstants.pixelAligned
                        reuseItems: true
                        model: root.recentListens

                        delegate: HomeSongCard {
                            cardWidth: 135
                            cardHeight: 200
                            track: modelData
                            onClicked: root.appWindow.playTrack(modelData)
                        }
                    }
                }

                // Section 2: Explore Genres Grid (deduplicated by normalized name)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.popularGenres.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel {
                            text: "Explore Genres"
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: root.popularGenres.length + " categories"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }
                    }

                    Flow {
                        id: genreFlow
                        Layout.fillWidth: true
                        spacing: 12
                        readonly property int cols: Math.max(2, Math.min(5, Math.floor((width - 4) / 180)))
                        readonly property real cardW: Math.floor((width - (cols - 1) * 12) / cols)

                        Repeater {
                            model: root.popularGenres
                            delegate: GenreCard {
                                cardWidth: genreFlow.cardW
                                cardHeight: 95
                                cardRadius: 12
                                name: modelData.name
                                count: modelData.count
                                track: modelData.track
                                onClicked: root.appWindow.openCatalogDetail("genre", modelData.name, modelData.track)
                            }
                        }
                    }
                }

                // Section 3: Popular Artists Shelf (deduplicated by normalized name)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.topArtists.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel {
                            text: "Popular Artists"
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: "In your library"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }
                    }

                    ListView {
                        activeFocusOnTab: true
                        onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                        Layout.fillWidth: true
                        height: 180
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: false
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: UiConstants.flickDeceleration
                        maximumFlickVelocity: UiConstants.maximumFlickVelocity
                        cacheBuffer: UiConstants.cacheBuffer
                        pixelAligned: UiConstants.pixelAligned
                        reuseItems: true
                        model: root.topArtists

                        delegate: ArtistCard {
                            cardWidth: 110
                            cardHeight: 175
                            name: modelData.name
                            count: modelData.count
                            track: modelData.track
                            onClicked: root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track)
                        }
                    }
                }

                // Empty state if library has 0 songs
                EmptyState {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    visible: root.libraryModel.trackCount === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: "No Music in Library"
                    subtitle: "Choose a music folder in Settings to start exploring"
                    actionLabel: "Open Settings"
                    onActionClicked: root.appWindow.page = "settings"
                }
            }
        }
    }
}
