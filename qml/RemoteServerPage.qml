import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var streamingController
    required property string protocol
    required property string serviceName
    required property string serviceLabel
    required property string serviceColor
    required property string description
    required property string urlPlaceholder

    readonly property bool connected: protocol === "jellyfin" ? streamingController.jellyfinConnected : streamingController.subsonicConnected
    readonly property bool connecting: protocol === "jellyfin" ? appWindow.jellyfinConnecting : appWindow.subsonicConnecting
    readonly property string status: protocol === "jellyfin" ? streamingController.jellyfinStatus : streamingController.subsonicStatus
    readonly property string errorText: protocol === "jellyfin" ? appWindow.jellyfinError : appWindow.subsonicError
    readonly property var trackModel: protocol === "jellyfin" ? streamingController.jellyfinModel : streamingController.subsonicModel
    readonly property bool quickConnecting: protocol === "jellyfin" && streamingController.jellyfinQuickConnecting
    readonly property string quickConnectCode: protocol === "jellyfin" ? streamingController.jellyfinQuickConnectCode : ""

    property string searchQuery: ""
    property alias searchVisible: searchBar.expanded
    property alias searchBox: searchBar
    property alias searchInput: searchBar.searchInput
    property string songSortMetric: "title"
    property bool songSortAscending: true
    property string artistSortMetric: "name"
    property bool artistSortAscending: true
    property string albumSortMetric: "album"
    property bool albumSortAscending: true
    property string genreSortMetric: "count"
    property bool genreSortAscending: false

    readonly property string currentSortMetric: {
        if (activeTab === "artists") return artistSortMetric
        if (activeTab === "albums") return albumSortMetric
        if (activeTab === "genres") return genreSortMetric
        return songSortMetric
    }
    readonly property bool currentSortAscending: {
        if (activeTab === "artists") return artistSortAscending
        if (activeTab === "albums") return albumSortAscending
        if (activeTab === "genres") return genreSortAscending
        return songSortAscending
    }

    function setSortMetricForActiveTab(metric) {
        if (activeTab === "artists") {
            artistSortMetric = metric
            artistSortAscending = (metric === "count") ? false : true
        } else if (activeTab === "albums") {
            albumSortMetric = metric
            albumSortAscending = (metric === "count") ? false : true
        } else if (activeTab === "genres") {
            genreSortMetric = metric
            genreSortAscending = (metric === "count") ? false : true
        } else {
            songSortMetric = metric
            songSortAscending = (metric === "duration") ? false : true
        }
    }

    function toggleSortDirectionForActiveTab() {
        if (activeTab === "artists") artistSortAscending = !artistSortAscending
        else if (activeTab === "albums") albumSortAscending = !albumSortAscending
        else if (activeTab === "genres") genreSortAscending = !genreSortAscending
        else songSortAscending = !songSortAscending
    }

    property string viewMode: "list"
    property string activeTab: "songs"
    property int modelRevision: 0
    property bool filterOpen: false
    property string formatFilter: "ALL"
    property bool stateLoaded: false

    function stateKey(name) {
        return "remote/" + root.protocol + "/" + name
    }

    function loadState() {
        root.activeTab = appSettings.value(stateKey("tab"), "songs")
        root.songSortMetric = appSettings.value(stateKey("songSortMetric"), appSettings.value(stateKey("sortMetric"), "title"))
        root.songSortAscending = Boolean(appSettings.value(stateKey("songSortAscending"), appSettings.value(stateKey("sortAscending"), true)))
        root.artistSortMetric = appSettings.value(stateKey("artistSortMetric"), "name")
        root.artistSortAscending = Boolean(appSettings.value(stateKey("artistSortAscending"), true))
        root.albumSortMetric = appSettings.value(stateKey("albumSortMetric"), "album")
        root.albumSortAscending = Boolean(appSettings.value(stateKey("albumSortAscending"), true))
        root.genreSortMetric = appSettings.value(stateKey("genreSortMetric"), "count")
        root.genreSortAscending = Boolean(appSettings.value(stateKey("genreSortAscending"), false))
        root.viewMode = appSettings.value(stateKey("viewMode"), "list")
        root.formatFilter = appSettings.value(stateKey("formatFilter"), "ALL")
        root.stateLoaded = true
    }

    function saveState(name, value) {
        if (root.stateLoaded) appSettings.setValue(stateKey(name), value)
    }

    function loadSavedConnection() {
        const saved = root.streamingController.serverConfigSnapshot()
        if (!serverUrl.text) serverUrl.text = saved[root.protocol + "/url"] || ""
        if (!serverUser.text) serverUser.text = saved[root.protocol + "/username"] || ""
    }

    anchors.fill: parent

    Connections {
        target: root.trackModel
        function onRowsInserted() { root.modelRevision++ }
        function onRowsRemoved() { root.modelRevision++ }
        function onModelReset() { root.modelRevision++ }
        function onLayoutChanged() { root.modelRevision++ }
    }

    function setError(msg) {
        if (protocol === "jellyfin") appWindow.jellyfinError = msg
        else appWindow.subsonicError = msg
    }

    function doConnect() {
        if (connecting) return
        const url = serverUrl.text.trim()
        const username = serverUser.text.trim()
        const password = serverPassword.text
        if (!url || !username || !password) { setError("Enter server URL, username, and password."); return }
        setError("")
        appSettings.setValue("stream/" + protocol + "Url", url)
        appSettings.setValue("stream/" + protocol + "Username", username)
        if (protocol === "jellyfin") { appWindow.jellyfinConnecting = true; streamingController.connectJellyfin(url, username, password) }
        else { appWindow.subsonicConnecting = true; streamingController.connectSubsonic(url, username, password) }
    }

    onActiveTabChanged: saveState("tab", activeTab)
    onSongSortMetricChanged: saveState("songSortMetric", songSortMetric)
    onSongSortAscendingChanged: saveState("songSortAscending", songSortAscending)
    onArtistSortMetricChanged: saveState("artistSortMetric", artistSortMetric)
    onArtistSortAscendingChanged: saveState("artistSortAscending", artistSortAscending)
    onAlbumSortMetricChanged: saveState("albumSortMetric", albumSortMetric)
    onAlbumSortAscendingChanged: saveState("albumSortAscending", albumSortAscending)
    onGenreSortMetricChanged: saveState("genreSortMetric", genreSortMetric)
    onGenreSortAscendingChanged: saveState("genreSortAscending", genreSortAscending)
    onViewModeChanged: saveState("viewMode", viewMode)
    onFormatFilterChanged: saveState("formatFilter", formatFilter)

    function matchesFormatFilter(track) {
        if (!track) return false
        if (formatFilter === "ALL" || !formatFilter) return true
        if (formatFilter === "FAVORITES") return appWindow.isFavorite(track.filePath)
        const fmt = String(track.format || "").toUpperCase()
        if (formatFilter === "FLAC") return fmt === "FLAC" || fmt === "WAV" || fmt === "ALAC" || fmt === "LOSSLESS"
        if (formatFilter === "MP3") return fmt === "MP3"
        if (formatFilter === "AAC") return fmt === "AAC" || fmt === "M4A"
        return fmt === formatFilter
    }

    function matchesSearch(track) {
        if (searchQuery.length === 0) return true
        const q = searchQuery.toLowerCase()
        return (track.title || "").toLowerCase().includes(q)
            || (track.artist || "").toLowerCase().includes(q)
            || (track.album || "").toLowerCase().includes(q)
    }

    function collectTracks() {
        const tracks = []
        for (let i = 0; i < trackModel.rowCount(); i++) {
            const t = trackModel.data(trackModel.index(i, 0), 0x0101)
            if (t) tracks.push(t)
        }
        return tracks
    }

    function playbackSelection() {
        if (root.activeTab === "songs") return trackContent.sortedTracks
        return root.displayItems.map(item => item.track).filter(track => !!track)
    }

    function groups(field) {
        const result = {}
        const q = searchQuery.toLowerCase()
        collectTracks().forEach(track => {
            if (!matchesFormatFilter(track)) return
            let name = ""
            if (field === "artist") {
                name = appWindow.extractPrimaryArtist(track.artist || "Unknown Artist")
            } else if (field === "album") {
                name = (track.album || "Unknown Album").trim()
            } else if (field === "genre") {
                name = (track.genre || "Soundtrack").trim()
            } else {
                name = (track[field] || "Unknown").trim()
            }
            if (!name) name = (field === "album" ? "Unknown Album" : (field === "genre" ? "Soundtrack" : "Unknown Artist"))
            if (q.length > 0) {
                const matchesName = name.toLowerCase().includes(q)
                const matchesArtist = (track.artist || "").toLowerCase().includes(q)
                const matchesTitle = (track.title || "").toLowerCase().includes(q)
                if (!matchesName && !matchesArtist && !matchesTitle) return
            }
            if (!result[name]) result[name] = { name: name, count: 0, track: track, artist: track.artist || "" }
            result[name].count++
        })

        const metric = currentSortMetric
        const asc = currentSortAscending
        const list = Object.values(result)

        list.sort((a, b) => {
            if (metric === "count") {
                const diff = a.count - b.count
                return asc ? diff : -diff
            }
            if (metric === "artist" && field === "album") {
                const va = (a.artist || "").toLowerCase()
                const vb = (b.artist || "").toLowerCase()
                const cmp = va.localeCompare(vb)
                if (cmp !== 0) return asc ? cmp : -cmp
            }
            const na = (a.name || "").toLowerCase()
            const nb = (b.name || "").toLowerCase()
            const cmp = na.localeCompare(nb)
            return asc ? cmp : -cmp
        })
        return list
    }

    readonly property var displayItems: {
        const _rev = modelRevision
        const _metric = currentSortMetric
        const _asc = currentSortAscending
        const _q = searchQuery
        const _ff = formatFilter
        if (activeTab === "songs") return trackContent.sortedTracks
        if (activeTab === "artists") return groups("artist")
        if (activeTab === "albums") return groups("album")
        if (activeTab === "genres") return groups("genre")
        return []
    }

    Component {
        id: songCard
        SongCard {
            property var itemData: ({})
            cardWidth: trackGrid.cellWidth - 14
            cardHeight: 220
            track: itemData || ({})
            onClicked: appWindow.playTrack(itemData)
            onFavoriteClicked: if (itemData && itemData.filePath) appWindow.toggleFavorite(itemData.filePath)
        }
    }

    Component {
        id: artistCard
        ArtistCard {
            property var itemData: ({})
            cardWidth: trackGrid.cellWidth - 16
            cardHeight: 225
            name: itemData && itemData.name ? itemData.name : (itemData && itemData.artist ? itemData.artist : "")
            count: itemData && itemData.count ? itemData.count : 0
            track: itemData && itemData.track ? itemData.track : (itemData && itemData.filePath ? itemData : ({}))
            onClicked: if (name) appWindow.openCatalogDetail("artist", name, track)
        }
    }

    Component {
        id: albumCard
        AlbumCard {
            property var itemData: ({})
            cardWidth: trackGrid.cellWidth - 16
            cardHeight: 235
            name: itemData && itemData.name ? itemData.name : (itemData && itemData.album ? itemData.album : "")
            artist: itemData && itemData.artist ? itemData.artist : ""
            count: itemData && itemData.count ? itemData.count : 0
            track: itemData && itemData.track ? itemData.track : (itemData && itemData.filePath ? itemData : ({}))
            onClicked: if (name) appWindow.openCatalogDetail("album", name, track)
        }
    }

    Component {
        id: genreCard
        GenreCard {
            property var itemData: ({})
            cardWidth: trackGrid.cellWidth - 16
            cardHeight: 110
            name: itemData && itemData.name ? itemData.name : (itemData && itemData.genre ? itemData.genre : "")
            count: itemData && itemData.count ? itemData.count : 0
            onClicked: if (name) appWindow.openCatalogDetail("genre", name, track)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0
        visible: root.connected

        RowLayout {
            z: 100
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.topMargin: 16
            Layout.bottomMargin: 14
            spacing: 16

            Row {
                spacing: 18

                Repeater {
                    model: [
                        { id: "songs", label: "Songs" },
                        { id: "artists", label: "Artists" },
                        { id: "albums", label: "Albums" },
                        { id: "genres", label: "Genres" },
                        { id: "playlists", label: "Playlists" }
                    ]

                    Item {
                        width: tabLabel.implicitWidth
                        height: 32

                        Label {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.activeTab === modelData.id ? textPrimary : textSecondary
                            font.family: displayFont
                            font.pixelSize: 15
                            font.weight: root.activeTab === modelData.id ? Font.Bold : Font.Medium
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 2.5
                            radius: 1.25
                            color: recordRed
                            visible: root.activeTab === modelData.id
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.activeTab = modelData.id; if (modelData.id !== "songs") root.viewMode = "grid" }
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: countLbl.implicitWidth + 14
                radius: 11
                color: surfaceTag
                border.width: 1
                border.color: borderSubtle

                Label {
                    id: countLbl
                    anchors.centerIn: parent
                    text: {
                        if (root.activeTab === "songs") {
                            const n = (root.viewMode === "list" ? trackList.count : trackGrid.count)
                            return n + (n === 1 ? " track" : " tracks")
                        }
                        const count = root.displayItems.length
                        return count + " " + root.activeTab
                    }
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            Row {
                spacing: 8
                visible: root.activeTab === "songs"

                Repeater {
                    model: [
                        { id: "ALL", label: "ALL" },
                        { id: "FAVORITES", label: "♥ FAVORITES" }
                    ]

                    Rectangle {
                        id: qPill
                        property bool isSelected: root.formatFilter === modelData.id
                        width: qPillLbl.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: "transparent"
                        border.width: isSelected ? 1.5 : 1
                        border.color: isSelected ? recordRed : (qPillMouse.containsMouse ? "#45FFFFFF" : "#282828")

                        Behavior on border.color { ColorAnimation { duration: 100 } }

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
                            onClicked: root.formatFilter = modelData.id
                        }
                    }
                }
            }

            PressDepthIconButton {
                visible: root.activeTab === "songs"
                boxSize: 34
                iconSize: 16
                iconName: root.viewMode === "list" ? "grid-2x2" : "list"
                tint: textPrimary
                tooltipText: root.viewMode === "list" ? "Detailed Grid View (Click for List)" : "List View (Click for Grid)"
                onClicked: root.viewMode = (root.viewMode === "list" ? "grid" : "list")
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "play"
                tint: recordRedHover
                tooltipText: "Play All"
                onClicked: {
                    const t = root.playbackSelection()
                    if (t.length) appWindow.startPlayback(t, 0, false)
                }
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "shuffle"
                tint: textPrimary
                tooltipText: "Shuffle"
                onClicked: appWindow.shufflePlayback(root.playbackSelection())
            }

            ExpandableSearchBar {
                id: searchBar
                boxSize: 34
                iconSize: 16
                expandedWidth: 175
                placeholder: "Search..."
                onTextChanged: root.searchQuery = text
                onCleared: root.searchQuery = ""
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "sliders-horizontal"
                tint: textPrimary
                highlighted: root.filterOpen || root.formatFilter !== "ALL"
                tooltipText: "Refine & Sort"
                Accessible.name: "Refine and sort"
                onClicked: root.filterOpen = !root.filterOpen
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "refresh-cw"
                tint: textPrimary
                tooltipText: "Refresh library"
                onClicked: streamingController.refreshLibrary()
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "log-out"
                tint: textSecondary
                tooltipText: "Disconnect server"
                onClicked: streamingController.disconnectServer(root.protocol)
            }
        }

        Item {
            id: trackContent
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 12

            property var sortedTracks: {
                const revision = root.modelRevision
                const m = root.songSortMetric
                const asc = root.songSortAscending
                const q = root.searchQuery.toLowerCase()
                const rows = root.trackModel.rowCount()
                const list = []
                for (let i = 0; i < rows; i++) {
                    const t = root.trackModel.data(root.trackModel.index(i, 0), 0x0101)
                    if (!t) continue
                    if (!root.matchesFormatFilter(t)) continue
                    if (q.length > 0 && !(
                        (t.title || "").toLowerCase().includes(q) ||
                        (t.artist || "").toLowerCase().includes(q) ||
                        (t.album || "").toLowerCase().includes(q)
                    )) continue
                    list.push(t)
                }
                list.sort((a, b) => {
                    if (m === "duration") {
                        const da = a.duration || 0
                        const db = b.duration || 0
                        return asc ? da - db : db - da
                    }
                    const va = (a[m] || "").toLowerCase()
                    const vb = (b[m] || "").toLowerCase()
                    return asc ? va.localeCompare(vb) : vb.localeCompare(va)
                })
                return list
            }

            GridView {
                id: trackGrid
                visible: root.viewMode === "grid" || root.activeTab !== "songs"
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 8
                anchors.bottomMargin: 32
                clip: true
                model: root.activeTab === "songs" && root.formatFilter === "ALL"
                    && root.searchQuery.length === 0 && root.songSortMetric === "title" && root.songSortAscending
                    ? root.trackModel : root.displayItems
                readonly property int cols: Math.max(2, Math.floor((width - 8) / (root.activeTab === "albums" ? 195 : 180)))
                cellWidth: Math.floor((width - 8) / cols)
                cellHeight: root.activeTab === "albums" ? 255 : (root.activeTab === "genres" ? 120 : 240)
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar {}

                delegate: Item {
                    width: trackGrid.cellWidth
                    height: root.activeTab === "albums" ? 245 : (root.activeTab === "genres" ? 115 : 230)

                    Loader {
                        id: cardLoader
                        anchors.centerIn: parent
                        width: parent.width - (root.activeTab === "songs" ? 14 : 16)
                        height: root.activeTab === "genres" ? 110 : root.activeTab === "albums" ? 235 : root.activeTab === "artists" ? 225 : 220
                        property var itemData: root.activeTab === "songs"
                            ? ((typeof model !== "undefined" && typeof model.track !== "undefined" && model.track !== null) ? model.track : (typeof modelData !== "undefined" ? modelData : null))
                            : (typeof modelData !== "undefined" ? modelData : (typeof model !== "undefined" ? model : null))
                        sourceComponent: root.activeTab === "songs" ? songCard : root.activeTab === "artists" ? artistCard : root.activeTab === "albums" ? albumCard : root.activeTab === "genres" ? genreCard : null
                        Binding {
                            target: cardLoader.item
                            property: "itemData"
                            value: cardLoader.itemData
                        }
                    }
                }
            }

            ListView {
                id: trackList
                visible: root.viewMode === "list" && root.activeTab === "songs"
                anchors.fill: parent
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar {}
                model: trackContent.sortedTracks

                delegate: SongRow {
                    width: trackList.width
                    track: modelData
                    showSourceBadge: false
                    showFormatBadge: false
                    cardBg: "transparent"
                    hoverBg: surfaceElevated
                    activeBg: surfaceCard
                    onClicked: appWindow.playTrack(modelData)
                    onFavoriteClicked: appWindow.toggleFavorite(modelData.filePath)
                }

                EmptyState {
                    anchors.fill: parent
                    visible: trackList.count === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: root.searchQuery.length > 0 ? "No Results" : "No Tracks Yet"
                    subtitle: root.searchQuery.length > 0 ? "No tracks match your search" : "Refresh to pull your " + root.serviceName + " library"
                    actionLabel: root.searchQuery.length > 0 ? "Clear Search" : "Refresh Now"
                    onActionClicked: root.searchQuery.length > 0 ? (searchInput.text = "") : streamingController.refreshLibrary()
                }
            }

            EmptyState {
                anchors.fill: parent
                visible: root.viewMode === "grid" && (root.activeTab === "songs" ? root.trackModel.rowCount() === 0 : root.displayItems.length === 0)
                catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                title: root.activeTab === "playlists" ? "No Playlists" : (root.searchQuery.length > 0 ? "No Results" : "No Tracks Yet")
                subtitle: root.activeTab === "playlists" ? "Playlists are not available from this server" : (root.searchQuery.length > 0 ? "No tracks match your search" : "Refresh to pull your " + root.serviceName + " library")
                actionLabel: root.activeTab === "playlists" ? "Refresh Now" : (root.searchQuery.length > 0 ? "Clear Search" : "Refresh Now")
                onActionClicked: root.searchQuery.length > 0 ? (searchInput.text = "") : streamingController.refreshLibrary()
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: !root.connected

        ColumnLayout {
            id: setupForm
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 440)
            spacing: 14

                RowLayout {
                    spacing: 12

                    LucideIcon {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        icon: root.protocol
                        preserveColor: true
                    }

                    ColumnLayout {
                        spacing: 2

                        Label {
                            text: root.serviceLabel
                            color: root.serviceColor
                            font.family: monoFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }

                        Label {
                            text: "Connect your server"
                            color: textPrimary
                            font.family: displayFont
                            font.pixelSize: 18
                            font.weight: Font.Bold
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: root.description
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: borderSubtle }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label { text: "Server Address"; color: textSecondary; font.family: monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                    RefineTextInput {
                        id: serverUrl
                        Layout.fillWidth: true
                        placeholder: root.urlPlaceholder
                        accessibleName: "Server address"
                        text: { const s = root.streamingController.serverConfigSnapshot(); return s[root.protocol + "/url"] || "" }
                        onSubmitted: serverUser.forceActiveFocus()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label { text: "Username"; color: textSecondary; font.family: monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                    RefineTextInput {
                        id: serverUser
                        Layout.fillWidth: true
                        placeholder: "Your username"
                        accessibleName: "Username"
                        text: { const s = root.streamingController.serverConfigSnapshot(); return s[root.protocol + "/username"] || "" }
                        onSubmitted: serverPassword.forceActiveFocus()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label { text: "Password"; color: textSecondary; font.family: monoFont; font.pixelSize: 10; font.weight: Font.DemiBold; font.letterSpacing: 0.8 }

                    RefineTextInput {
                        id: serverPassword
                        Layout.fillWidth: true
                        placeholder: "Your password"
                        accessibleName: "Password"
                        echoMode: TextInput.Password
                        isPassword: true
                        onSubmitted: root.doConnect()
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: root.errorText.length > 0
                    text: root.errorText
                    color: recordRedHover
                    font.family: bodyFont
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                SettingCard {
                    Layout.fillWidth: true
                    visible: root.quickConnecting && root.quickConnectCode.length > 0

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            Layout.fillWidth: true
                            text: "Enter this code in the Jellyfin app"
                            color: textPrimary
                            font.family: bodyFont
                            font.pixelSize: 12
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.quickConnectCode
                            color: root.serviceColor
                            font.family: monoFont
                            font.pixelSize: 28
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        SettingButton {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Cancel"
                            onClicked: root.streamingController.cancelJellyfinQuickConnect()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    SettingButton {
                        Layout.preferredWidth: 124
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignLeft
                        text: root.connecting ? "Connecting…" : "Connect"
                        iconName: root.connecting ? "rotate-ccw" : "plug"
                        accessibleName: "Connect to server"
                        onClicked: root.doConnect()
                    }

                    SettingButton {
                        visible: root.protocol === "jellyfin" && !root.quickConnecting
                        Layout.preferredWidth: 142
                        Layout.preferredHeight: 40
                        text: "Quick Connect"
                        iconName: "key-round"
                        accessibleName: "Connect with Jellyfin Quick Connect"
                        onClicked: root.streamingController.startJellyfinQuickConnect(serverUrl.text)
                    }

                    Item { Layout.fillWidth: true }

                    LucideIcon { Layout.preferredWidth: 13; Layout.preferredHeight: 13; icon: "shield"; color: silverDim }

                    Label {
                        text: "Stored securely in Windows Credential Locker"
                        color: silverDim
                        font.family: bodyFont
                        font.pixelSize: 11
                    }
                }
        }
    }

    LibraryRefineSheet {
        anchors.fill: parent
        isOpen: root.filterOpen
        activeTab: root.activeTab
        currentFilter: root.formatFilter
        currentSongSort: root.songSortMetric
        currentArtistSort: root.artistSortMetric
        currentAlbumSort: root.albumSortMetric
        currentGenreSort: root.genreSortMetric
        currentSortAscending: root.currentSortAscending
        onFilterSelected: filterId => root.formatFilter = filterId
        onSortSelected: sortId => root.setSortMetricForActiveTab(sortId)
        onSortDirectionToggled: root.toggleSortDirectionForActiveTab()
        onResetRequested: {
            root.formatFilter = "ALL"
            root.searchQuery = ""
            root.searchInput.text = ""
            root.songSortMetric = "title"
            root.songSortAscending = true
            root.artistSortMetric = "name"
            root.artistSortAscending = true
            root.albumSortMetric = "album"
            root.albumSortAscending = true
            root.genreSortMetric = "count"
            root.genreSortAscending = false
        }
        onClosed: root.filterOpen = false
    }

    Component.onCompleted: {
        root.loadSavedConnection()
        root.loadState()
    }
}
