import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    readonly property string countText: !filtering && libraryModel.trackCount > 0 ? libraryModel.trackCount + " songs" : ""

    required property var appWindow
    required property var libraryModel
    required property var playerController

    anchors.fill: parent

    property alias searchBox: pageSearchBox
    property alias searchInput: pageSearchInput
    readonly property bool filtering: appWindow.searchQuery.trim().length > 0 || appWindow.activeFormatFilter !== "ALL"

    property var cachedGroups: ({})
    readonly property string query: appWindow.searchQuery.trim().toLowerCase()
    readonly property var formatCounts: (cachedGroups && cachedGroups.formats) || ({})

    // The last few searches that led somewhere, newest first.
    property var recentSearches: JSON.parse(appSettings.value("search/recent", "[]"))

    function rememberSearch() {
        const text = appWindow.searchQuery.trim()
        if (!text) return
        const kept = recentSearches.filter(item => item.toLowerCase() !== text.toLowerCase())
        recentSearches = [text].concat(kept).slice(0, 8)
        appSettings.setValue("search/recent", JSON.stringify(recentSearches))
    }

    function forgetSearch(text) {
        recentSearches = recentSearches.filter(item => item !== text)
        appSettings.setValue("search/recent", JSON.stringify(recentSearches))
    }

    function search(text) {
        pageSearchInput.text = text
        pageSearchInput.forceActiveFocus()
    }

    function playResult(track) {
        rememberSearch()
        appWindow.playTrack(track)
    }

    function matches(groups) {
        if (!query) return []
        const list = []
        for (let i = 0; i < groups.length; ++i) {
            const group = groups[i]
            if (group && group.name && group.name.toLowerCase().includes(query) && group.name !== "Unknown Album")
                list.push(group)
        }
        list.sort((a, b) => (b.name.toLowerCase().startsWith(query) - a.name.toLowerCase().startsWith(query)) || b.count - a.count)
        return list.slice(0, 10)
    }
    readonly property var matchingArtists: matches((cachedGroups && cachedGroups.artists) || [])
    readonly property var matchingAlbums: matches((cachedGroups && cachedGroups.albums) || [])

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
        // Lists from C++ arrive as sequence objects, which Array.isArray() does not accept.
        const raw = (cachedGroups && cachedGroups.genres) || []
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
        // Lists from C++ arrive as sequence objects, which Array.isArray() does not accept.
        const raw = (cachedGroups && cachedGroups.artists) || []
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
        anchors.topMargin: 16
        spacing: 14

        // Hero Search Box
        Rectangle {
            id: pageSearchBox
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
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
                    Keys.onEscapePressed: {
                        if (text) text = ""
                        else focus = false
                    }
                    Keys.onReturnPressed: if (root.libraryModel.visibleTrackCount > 0) root.playResult(root.libraryModel.visibleTracks()[0])
                    Keys.onEnterPressed: if (root.libraryModel.visibleTrackCount > 0) root.playResult(root.libraryModel.visibleTracks()[0])
                    Keys.onDownPressed: {
                        if (root.libraryModel.visibleTrackCount === 0) return
                        searchResults.currentIndex = 0
                        searchResults.forceActiveFocus()
                    }

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
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            spacing: 10

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "ALL", label: "All Formats", icon: "disc" },
                        { id: "FLAC", label: "Lossless (FLAC)", icon: "audio-lines" },
                        { id: "MP3", label: "MP3", icon: "music" },
                        { id: "AAC", label: "AAC / M4A", icon: "list-music" }
                    ]

                    FilterChip {
                        required property var modelData
                        readonly property int count: root.formatCounts[modelData.id] || 0
                        visible: modelData.id === "ALL" || count > 0
                        text: modelData.label + "  " + count
                        iconName: modelData.icon
                        selected: root.appWindow.activeFormatFilter === modelData.id
                        onClicked: root.appWindow.activeFormatFilter = modelData.id
                    }
                }
            }

            // Stat tag when idle

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
        AppListView {
            id: searchResults
            activeFocusOnTab: true
            onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
            Keys.onUpPressed: event => {
                if (currentIndex <= 0) pageSearchInput.forceActiveFocus()
                else event.accepted = false
            }
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.filtering
            clip: true
            model: root.libraryModel
            spacing: 4
            leftMargin: 28
            rightMargin: 28
            bottomMargin: 24
            reuseItems: true
            ScrollBar.vertical: AutoHideScrollBar {}

            header: ColumnLayout {
                width: searchResults.width - 56
                spacing: 12

                SectionLabel {
                    visible: root.matchingArtists.length > 0
                    text: "Artists"
                }

                AppListView {
                    visible: root.matchingArtists.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 165
                    orientation: ListView.Horizontal
                    spacing: 14
                    clip: true
                    model: root.matchingArtists

                    delegate: ArtistCard {
                        cardWidth: 100
                        cardHeight: 160
                        name: modelData.name
                        count: modelData.count
                        track: modelData.track
                        onClicked: {
                            root.rememberSearch()
                            root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track)
                        }
                    }
                }

                SectionLabel {
                    visible: root.matchingAlbums.length > 0
                    text: "Albums"
                }

                AppListView {
                    visible: root.matchingAlbums.length > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    orientation: ListView.Horizontal
                    spacing: 14
                    clip: true
                    model: root.matchingAlbums

                    delegate: AlbumCard {
                        cardWidth: 135
                        cardHeight: 195
                        name: modelData.name
                        artist: modelData.track ? modelData.track.artist : ""
                        count: modelData.count
                        track: modelData.track
                        onClicked: {
                            root.rememberSearch()
                            root.appWindow.openCatalogDetail("album", modelData.name, modelData.track)
                        }
                    }
                }

                RowLayout {
                    visible: root.libraryModel.visibleTrackCount > 0
                    Layout.fillWidth: true
                    Layout.bottomMargin: 4
                    spacing: 8

                    SectionLabel { text: "Songs" }

                    Item { Layout.fillWidth: true }

                    SettingButton {
                        text: "Shuffle"
                        onClicked: {
                            root.rememberSearch()
                            root.appWindow.shufflePlayback(root.libraryModel.visibleTracks())
                        }
                    }

                    SettingButton {
                        text: "Play"
                        primary: true
                        onClicked: {
                            root.rememberSearch()
                            root.appWindow.startPlayback(root.libraryModel.visibleTracks(), 0)
                        }
                    }
                }
            }

            delegate: SongRow {
                width: searchResults.width - 56
                track: model.track
                showAlbum: true
                showCover: true
                showDuration: true
                showHeart: true
                onClicked: root.playResult(model.track)
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
        AppFlickable {
            id: idleScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.filtering
            clip: true
            contentWidth: width
            contentHeight: idleColumn.implicitHeight + 32
            ScrollBar.vertical: AutoHideScrollBar {}

            ColumnLayout {
                id: idleColumn
                x: 28
                width: idleScrollView.width - 56
                spacing: 24

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: root.recentSearches.length > 0

                    SectionLabel { text: "Recent Searches" }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.recentSearches

                            delegate: Rectangle {
                                required property string modelData
                                implicitWidth: recentRow.implicitWidth + 20
                                implicitHeight: 28
                                radius: height / 2
                                color: recentMouse.containsMouse ? surfaceElevated : surfaceTag
                                border.width: 1
                                border.color: recentMouse.containsMouse ? borderVariant : borderSubtle

                                MouseArea {
                                    id: recentMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.search(modelData)
                                }

                                RowLayout {
                                    id: recentRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Label {
                                        text: modelData
                                        color: recentMouse.containsMouse ? textPrimary : textSecondary
                                        font.family: monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    LucideIcon {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        icon: "x"
                                        color: removeMouse.containsMouse ? textPrimary : silverDim
                                        Accessible.role: Accessible.Button
                                        Accessible.name: "Remove " + modelData

                                        MouseArea {
                                            id: removeMouse
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.forgetSearch(modelData)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

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
                    }

                    AppListView {
                        activeFocusOnTab: true
                        onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                        Layout.fillWidth: true
                        height: 205
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: false
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
                    }

                    Flow {
                        id: genreFlow
                        Layout.fillWidth: true
                        spacing: 12
                        readonly property int cols: Math.max(2, Math.min(5, Math.floor((width - 4) / 180)))
                        readonly property real cardW: Math.floor((width - (cols - 1) * 12) / cols)

                        Repeater {
                            model: root.popularGenres
                            delegate: CategoryCard {
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
                    }

                    AppListView {
                        activeFocusOnTab: true
                        onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                        Layout.fillWidth: true
                        height: 180
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: false
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
