import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    readonly property string countText: {
        switch (root.appWindow.libraryTab) {
        case "artists": return qsTr("%n artist(s)", "", root.appWindow.artists.length)
        case "albums": return qsTr("%n album(s)", "", root.appWindow.albums.length)
        case "genres": return qsTr("%n genre(s)", "", root.appWindow.genreGroups.length)
        case "folders": return qsTr("%n folder(s)", "", root.appWindow.folderGroups.length)
        case "playlists": return qsTr("%n playlist(s)", "", root.appWindow.playlists.length + 4)
        default: return qsTr("%n song(s)", "", root.libraryModel.trackCount)
        }
    }
    required property var appWindow
    required property var libraryModel
    anchors.fill: parent
    property alias searchBox: libSearchBar
    // The first index filed under each letter of a list sorted by the names name() gives, for an IndexRail.
    function letterRows(list, name) {
        const rows = {}
        for (let i = 0; i < list.length; ++i) {
            const letter = library.indexLetter(name(list[i]))
            if (rows[letter] === undefined)
                rows[letter] = i
        }
        return rows
    }
    property alias searchInput: libSearchBar.searchInput
    readonly property int selectedTrackCount: Object.keys(root.appWindow.selectedTrackPaths || {}).length

    // The page is unloaded while hidden, so each view's scroll position is kept on the window.
    readonly property var scrollViews: ({ songsGrid: songsGridView, songsList: songsListView, artists: artistGrid,
                                          albums: albumGrid, genres: genreGrid, folders: folderGrid })
    Component.onCompleted: Qt.callLater(() => {
        const saved = root.appWindow.libraryScrollPositions
        for (const key in root.scrollViews) {
            if (saved[key]) root.scrollViews[key].contentY = saved[key]
        }
    })
    Component.onDestruction: {
        const positions = {}
        for (const key in root.scrollViews) positions[key] = root.scrollViews[key].contentY
        root.appWindow.libraryScrollPositions = positions
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PageToolbar {
            tabs: [
                { id: "songs", label: qsTr("Songs") },
                { id: "artists", label: qsTr("Artists") },
                { id: "albums", label: qsTr("Albums") },
                { id: "genres", label: qsTr("Genres") },
                { id: "folders", label: qsTr("Folders") },
                { id: "playlists", label: qsTr("Playlists") }
            ]
            current: root.appWindow.libraryTab
            onSelected: id => root.appWindow.libraryTab = id

            Row {
                spacing: 8
                visible: root.appWindow.libraryTab === "songs"

                Repeater {
                    model: [
                        {
                            id: "ALL",
                            label: qsTr("ALL")
                        },
                        {
                            id: "FAVORITES",
                            label: qsTr("♥ FAVORITES")
                        },
                    ]

                    FilterChip {
                        required property var modelData
                        text: modelData.label
                        selected: root.appWindow.songFilterMode === modelData.id
                        onClicked: root.appWindow.songFilterMode = modelData.id
                    }
                }
            }

            Row {
                spacing: 8
                visible: root.appWindow.libraryTab === "playlists"

                SettingButton {
                    text: qsTr("New Playlist")
                    iconName: "plus"
                    onClicked: createPlaylistDialog.open()
                }

                SettingButton {
                    text: qsTr("Save Queue")
                    iconName: "list"
                    onClicked: {
                        const defaultName = qsTr("Queue %1").arg(new Date().toLocaleDateString(Qt.locale(), "MMM d"))
                        root.appWindow.saveQueueAsPlaylist(defaultName)
                    }
                }

                SettingButton {
                    text: qsTr("Import M3U")
                    iconName: "folder"
                    onClicked: root.appWindow.requestPlaylistImport()
                }
            }

            PressDepthIconButton {
                visible: root.appWindow.libraryTab === "songs" || root.appWindow.libraryTab === "playlists"
                boxSize: 34
                iconSize: 16
                iconName: root.appWindow.libraryViewMode === "grid" ? "grid-2x2" : "list"
                tint: textPrimary
                tooltipText: root.appWindow.libraryViewMode === "grid" ? qsTr("Detailed Grid View (Click for List)") : qsTr("List View (Click for Grid)")
                onClicked: root.appWindow.libraryViewMode = (root.appWindow.libraryViewMode === "grid" ? "list" : "grid")
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "play"
                tint: recordRedHover
                tooltipText: qsTr("Play library")
                onClicked: {
                    const tracks = root.appWindow.playbackTracks()
                    if (tracks.length) root.appWindow.startPlayback(tracks, 0, false)
                }
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "shuffle"
                tint: textPrimary
                tooltipText: qsTr("Shuffle library")
                onClicked: {
                    root.appWindow.shufflePlayback(root.appWindow.availableTracks())
                }
            }

            ExpandableSearchBar {
                id: libSearchBar
                visible: true
                boxSize: 34
                iconSize: 16
                expandedWidth: 175
                placeholder: root.appWindow.libraryTab === "playlists" ? qsTr("Search playlists...") : qsTr("Search library...")
                text: root.appWindow.libSearchQuery
                onTextChanged: root.appWindow.libSearchQuery = text
                onCleared: root.appWindow.libSearchQuery = ""
            }

            PressDepthIconButton {
                visible: root.appWindow.libraryTab !== "playlists"
                boxSize: 34
                iconSize: 16
                iconName: "sliders-horizontal"
                tint: textPrimary
                tooltipText: qsTr("Refine & Sort")
                highlighted: {
                    if (root.appWindow.refineSheetOpen)
                        return true;
                    if (root.appWindow.songFilterMode !== "ALL")
                        return true;
                    if (root.appWindow.libraryTab === "songs")
                        return !root.appWindow.songSortAscending || root.appWindow.songSortMetric !== "title";
                    if (root.appWindow.libraryTab === "artists")
                        return !root.appWindow.artistSortAscending || root.appWindow.artistSortMetric !== "name";
                    if (root.appWindow.libraryTab === "albums")
                        return !root.appWindow.albumSortAscending || root.appWindow.albumSortMetric !== "album";
                    if (root.appWindow.libraryTab === "genres")
                        return root.appWindow.genreSortAscending || root.appWindow.genreSortMetric !== "count";
                    return false;
                }
                onClicked: root.appWindow.refineSheetOpen = !root.appWindow.refineSheetOpen
            }

            PressDepthIconButton {
                visible: root.appWindow.libraryTab === "songs"
                boxSize: 34
                iconSize: 16
                iconName: "info"
                tint: textPrimary
                tooltipText: qsTr("Library health")
                onClicked: {
                    root.appWindow.settingsSection = "health"
                    root.appWindow.page = "settings"
                }
            }
        }

        RowLayout {
            visible: root.selectedTrackCount > 0 && root.appWindow.libraryTab === "songs"
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.bottomMargin: 10
            spacing: 8

            Label {
                text: qsTr("%n selected", "", root.selectedTrackCount)
                color: root.appWindow.recordRed
                font.family: root.appWindow.monoFont
                font.pixelSize: 11
                Layout.rightMargin: 4
            }

            SettingButton {
                text: qsTr("Queue")
                iconName: "list"
                onClicked: root.appWindow.addSelectedTracksToQueue()
            }

            SettingButton {
                text: qsTr("Favorite")
                iconName: "heart"
                onClicked: root.appWindow.favoriteSelectedTracks()
            }

            SettingButton {
                text: qsTr("Edit Tags")
                iconName: "pencil"
                onClicked: root.appWindow.openBatchMetadataEditor()
            }

            SettingButton {
                text: qsTr("Fix Tags")
                iconName: "search"
                onClicked: root.appWindow.fixTags(root.appWindow.selectedTracks())
            }

            SettingButton {
                text: qsTr("Save Playlist")
                iconName: "list"
                onClicked: {
                    root.appWindow.createPlaylist(qsTr("Selection"), root.appWindow.selectedTracks())
                    root.appWindow.clearTrackSelection()
                }
            }

            SettingButton {
                text: qsTr("Clear")
                iconName: "x"
                onClicked: root.appWindow.clearTrackSelection()
            }
        }

        StackLayout {
            id: libraryStack
            transform: Translate { id: tabShift }
            onCurrentIndexChanged: tabEnter.restart()

            EnterAnimation {
                id: tabEnter
                target: libraryStack
                shift: tabShift
                distance: 6
                duration: UiConstants.durationFast
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.appWindow.libraryTab === "songs" ? 0 : (root.appWindow.libraryTab === "artists" ? 1 : (root.appWindow.libraryTab === "albums" ? 2 : (root.appWindow.libraryTab === "genres" ? 3 : (root.appWindow.libraryTab === "folders" ? 4 : 5))))

            Item {
                AppGridView {
                    id: songsGridView
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, GridView.Contain)
                    visible: root.appWindow.libraryViewMode === "grid"
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: songRail.visible ? songRail.width + songRail.anchors.rightMargin : 8
                    bottomMargin: 32
                    clip: true
                    model: library
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 180))
                    cellWidth: Math.floor((width - 8) / cols)
                    // Covers are square, so a row is as tall as a column is wide plus the title and artist lines.
                    cellHeight: cellWidth + 50
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: FocusScope {
                        width: songsGridView.cellWidth
                        height: songsGridView.cellHeight - 10

                        SongCard {
                            focus: true
                            anchors.centerIn: parent
                            cardWidth: parent.width - 14
                            cardHeight: parent.height - 10
                            track: model.track
                            onClicked: root.appWindow.playTrack(model.track)
                            onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
                        }
                    }
                }

                AppListView {
                    id: songsListView
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                    visible: root.appWindow.libraryViewMode === "list"
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: songRail.visible ? songRail.width + songRail.anchors.rightMargin + 6 : 24
                    clip: true
                    model: library
                    spacing: 4
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: SongRow {
                        width: songsListView.width
                        track: model.track
                        selectable: true
                        selected: root.appWindow.isTrackSelected(model.track.filePath)
                        onClicked: modifiers => {
                            if (modifiers & Qt.ControlModifier) {
                                root.appWindow.toggleTrackSelection(model.track.filePath)
                            } else {
                                root.appWindow.clearTrackSelection()
                                root.appWindow.playTrack(model.track)
                            }
                        }
                        onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
                    }
                }

                IndexRail {
                    id: songRail
                    anchors.right: parent.right
                    // Clear of the window's edge, like the page's other controls. A grid's jump puts the letter's row
                    // at the top, so its letter is read from the end of that row.
                    anchors.rightMargin: 22
                    position: songsListView.visible ? songsListView.indexAt(20, songsListView.contentY + 1)
                                                    : songsGridView.indexAt(songsGridView.width - 30, songsGridView.contentY + 1)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 32
                    rows: library.letterRows()
                    onJump: index => {
                        if (songsListView.visible) songsListView.positionViewAtIndex(index, ListView.Beginning)
                        else songsGridView.positionViewAtIndex(index, GridView.Beginning)
                    }

                    Connections {
                        target: library
                        function onVisibleTracksChanged() { songRail.rows = library.letterRows() }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: root.libraryModel.visibleTrackCount === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: qsTr("No Songs Found")
                    subtitle: qsTr("Try resetting format filters or changing search keywords")
                    actionLabel: qsTr("Reset Filters")
                    onActionClicked: {
                        root.appWindow.songFilterMode = "ALL";
                        root.appWindow.libSearchQuery = "";
                        root.appWindow.songSortAscending = true;
                        root.appWindow.songSortMetric = "title";
                    }
                }
            }

            Item {
                readonly property var curArtists: {
                    const q = root.appWindow.libSearchQuery.toLowerCase().trim();
                    const sortM = root.appWindow.artistSortMetric;
                    const asc = root.appWindow.artistSortAscending;
                    let list = root.appWindow.artists.slice();
                    if (q.length > 0) {
                        list = list.filter(a => a.name.toLowerCase().includes(q));
                    }
                    list.sort((a, b) => {
                        let res;
                        if (sortM === "count") {
                            res = (a.count - b.count) || (a.rank - b.rank);
                        } else {
                            res = a.rank - b.rank;
                        }
                        return asc ? res : -res;
                    });
                    return list;
                }

                IndexRail {
                    id: artistRail
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    position: artistGrid.indexAt(artistGrid.width - 30, artistGrid.contentY + 1)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 32
                    rows: root.appWindow.artistSortMetric === "name" ? root.letterRows(parent.curArtists, artist => artist.name) : ({})
                    onJump: index => artistGrid.positionViewAtIndex(index, GridView.Beginning)
                }

                AppGridView {
                    id: artistGrid
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, GridView.Contain)
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: artistRail.visible ? artistRail.width + artistRail.anchors.rightMargin : 8
                    bottomMargin: 32
                    clip: true
                    model: parent.curArtists
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 190))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: cellWidth + 52
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: FocusScope {
                        width: artistGrid.cellWidth
                        height: artistGrid.cellHeight - 10

                        ArtistCard {
                            focus: true
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: parent.height - 10
                            name: modelData.name
                            count: modelData.count
                            track: modelData.track
                            onClicked: {
                                root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curArtists.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/04-gray-dancing-headphones.png"
                    title: qsTr("No Artists Found")
                    subtitle: qsTr("No artists match your current search query")
                    actionLabel: qsTr("Clear Search")
                    onActionClicked: root.appWindow.libSearchQuery = ""
                }
            }

            Item {
                readonly property var curAlbums: {
                    const q = root.appWindow.libSearchQuery.toLowerCase().trim();
                    const sortM = root.appWindow.albumSortMetric;
                    const asc = root.appWindow.albumSortAscending;
                    let list = root.appWindow.albums.slice();
                    if (q.length > 0) {
                        list = list.filter(a => a.name.toLowerCase().includes(q) || (a.track && a.track.artist && a.track.artist.toLowerCase().includes(q)));
                    }
                    list.sort((a, b) => {
                        let res;
                        if (sortM === "artist") {
                            res = a.artistRank - b.artistRank;
                        } else if (sortM === "count") {
                            res = (a.count - b.count) || (a.rank - b.rank);
                        } else {
                            res = a.rank - b.rank;
                        }
                        return asc ? res : -res;
                    });
                    return list;
                }

                IndexRail {
                    id: albumRail
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    position: albumGrid.indexAt(albumGrid.width - 30, albumGrid.contentY + 1)
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 32
                    rows: root.appWindow.albumSortMetric === "album" ? root.letterRows(parent.curAlbums, album => album.name)
                        : root.appWindow.albumSortMetric === "artist" ? root.letterRows(parent.curAlbums, album => album.track ? album.track.artist : "")
                        : ({})
                    onJump: index => albumGrid.positionViewAtIndex(index, GridView.Beginning)
                }

                AppGridView {
                    id: albumGrid
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, GridView.Contain)
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: albumRail.visible ? albumRail.width + albumRail.anchors.rightMargin : 8
                    bottomMargin: 32
                    clip: true
                    model: parent.curAlbums
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 195))
                    cellWidth: Math.floor((width - 8) / cols)
                    // Album titles take up to two lines.
                    cellHeight: cellWidth + 66
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: FocusScope {
                        width: albumGrid.cellWidth
                        height: albumGrid.cellHeight - 10

                        AlbumCard {
                            focus: true
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: parent.height - 10
                            name: modelData.name
                            artist: modelData.track ? modelData.track.artist : qsTr("Various Artists")
                            count: modelData.count
                            track: modelData.track
                            onClicked: {
                                root.appWindow.openCatalogDetail("album", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curAlbums.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/02-black-cat-cassette.png"
                    title: qsTr("No Albums Found")
                    subtitle: qsTr("No albums match your current search query")
                    actionLabel: qsTr("Clear Search")
                    onActionClicked: root.appWindow.libSearchQuery = ""
                }
            }

            Item {
                readonly property var curGenres: {
                    const q = root.appWindow.libSearchQuery.toLowerCase().trim();
                    const sortM = root.appWindow.genreSortMetric;
                    const asc = root.appWindow.genreSortAscending;
                    let list = root.appWindow.genreGroups.slice();
                    if (q.length > 0) {
                        list = list.filter(g => g.name.toLowerCase().includes(q));
                    }
                    list.sort((a, b) => {
                        let res = sortM === "count"
                            ? ((a.count - b.count) || (a.rank - b.rank))
                            : (a.rank - b.rank);
                        return asc ? res : -res;
                    });
                    return list;
                }

                AppGridView {
                    id: genreGrid
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, GridView.Contain)
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: parent.curGenres
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 210))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: 125
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: FocusScope {
                        width: genreGrid.cellWidth
                        height: 115

                        CategoryCard {
                            focus: true
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: 110
                            name: modelData.name
                            count: modelData.count
                            track: modelData.track
                            onClicked: {
                                root.appWindow.openCatalogDetail("genre", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curGenres.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/03-cream-cassette-hug.png"
                    title: qsTr("No Genres Found")
                    subtitle: qsTr("No audio genres matched your search")
                    actionLabel: qsTr("Clear Search")
                    onActionClicked: root.appWindow.libSearchQuery = ""
                }
            }

            Item {
                readonly property var curFolders: {
                    const q = root.appWindow.libSearchQuery.toLowerCase().trim();
                    const sortM = root.appWindow.folderSortMetric;
                    const asc = root.appWindow.folderSortAscending;
                    let list = (root.appWindow.folderGroups || []).slice();
                    if (q.length > 0) {
                        list = list.filter(f => f.name.toLowerCase().includes(q));
                    }
                    list.sort((a, b) => {
                        let res = sortM === "count"
                            ? ((a.count - b.count) || (a.rank - b.rank))
                            : (a.rank - b.rank);
                        return asc ? res : -res;
                    });
                    return list;
                }

                AppGridView {
                    id: folderGrid
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, GridView.Contain)
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: parent.curFolders
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 210))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: 125
                    reuseItems: true
                    ScrollBar.vertical: AutoHideScrollBar {}

                    delegate: FocusScope {
                        width: folderGrid.cellWidth
                        height: 115

                        CategoryCard {
                            focus: true
                            anchors.centerIn: parent
                            cardWidth: parent.width - 16
                            cardHeight: 110
                            name: modelData.name
                            count: modelData.count
                            track: modelData.track
                            onClicked: root.appWindow.openCatalogDetail("folder", modelData.name, modelData.track)
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curFolders.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/03-cream-cassette-hug.png"
                    title: qsTr("No Folders Found")
                    subtitle: qsTr("No audio folders matched your search")
                    actionLabel: qsTr("Clear Search")
                    onActionClicked: root.appWindow.libSearchQuery = ""
                }
            }

            LibraryPlaylistsView {
                appWindow: root.appWindow
            }
        }
    }

    AutoScroller {
        id: libAutoScroller
        targetView: {
            if (root.appWindow.libraryTab === "songs")
                return (root.appWindow.libraryViewMode === "grid" ? songsGridView : songsListView);
            if (root.appWindow.libraryTab === "artists")
                return artistGrid;
            if (root.appWindow.libraryTab === "albums")
                return albumGrid;
            if (root.appWindow.libraryTab === "genres")
                return genreGrid;
            if (root.appWindow.libraryTab === "folders")
                return folderGrid;
            return null;
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.ArrowCursor
        z: 9998
        onPressed: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (libAutoScroller.active)
                    libAutoScroller.stop();
                else
                    libAutoScroller.start(mouse.x, mouse.y);
            }
        }
    }

    AppDialog {
        id: createPlaylistDialog
        maxWidth: 400
        property bool smart: false
        property var rules: []
        readonly property bool canCreate: !smart || rules.length > 0
        // Rules in the same group rule each other out, so picking one replaces the other.
        readonly property var smartRules: [
            { id: "RECENTLY_ADDED", label: qsTr("Added in the last 30 days") },
            { id: "FAVORITES_ONLY", label: qsTr("Favorites only") },
            { id: "MIN_DURATION", label: qsTr("Longer than 5 minutes"), group: "length" },
            { id: "MAX_DURATION", label: qsTr("Shorter than 3 minutes"), group: "length" },
            { id: "DECADE_90S", label: qsTr("1990s"), group: "decade" },
            { id: "DECADE_2000S", label: qsTr("2000s"), group: "decade" },
            { id: "DECADE_2010S", label: qsTr("2010s"), group: "decade" },
            { id: "DECADE_2020S", label: qsTr("2020s"), group: "decade" }
        ]

        function toggleRule(rule) {
            if (rules.includes(rule.id)) {
                rules = rules.filter(id => id !== rule.id)
                return
            }
            const sameGroup = smartRules.filter(other => rule.group && other.group === rule.group).map(other => other.id)
            rules = rules.filter(id => !sameGroup.includes(id)).concat([rule.id])
        }

        function create() {
            if (!canCreate) return
            const typed = newPlaylistInput.text.trim()
            if (smart) {
                const firstRule = smartRules.find(rule => rule.id === rules[0])
                root.appWindow.createSmartPlaylist(typed || firstRule.label, rules)
            } else {
                root.appWindow.createPlaylist(typed || qsTr("Playlist %1").arg((root.appWindow.playlists || []).length + 1), [])
            }
            close()
        }
        onOpened: {
            smart = false
            rules = []
            newPlaylistInput.text = ""
            newPlaylistInput.forceActiveFocus()
        }

        contentItem: ColumnLayout {
            spacing: 14

            DialogHeader {
                iconName: "list-music"
                title: qsTr("New Playlist")
                subtitle: createPlaylistDialog.smart
                    ? qsTr("Songs that match every rule, up to 100")
                    : qsTr("Songs you add yourself")
            }

            SettingSegmentedControl {
                options: [{ value: "standard", label: qsTr("Standard") }, { value: "smart", label: qsTr("Smart") }]
                selectedValue: createPlaylistDialog.smart ? "smart" : "standard"
                onOptionSelected: value => createPlaylistDialog.smart = value === "smart"
            }

            RefineTextInput {
                id: newPlaylistInput
                Layout.fillWidth: true
                placeholder: qsTr("Playlist name")
                onSubmitted: createPlaylistDialog.create()
            }

            Flow {
                visible: createPlaylistDialog.smart
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: createPlaylistDialog.smartRules

                    FilterChip {
                        required property var modelData
                        text: modelData.label
                        selected: createPlaylistDialog.rules.includes(modelData.id)
                        onClicked: createPlaylistDialog.toggleRule(modelData)
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 12

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: qsTr("Cancel")
                    onClicked: createPlaylistDialog.close()
                }

                SettingButton {
                    text: qsTr("Create")
                    primary: true
                    enabled: createPlaylistDialog.canCreate
                    onClicked: createPlaylistDialog.create()
                }
            }
        }
    }

    DropArea {
        anchors.fill: parent
        keys: ["text/uri-list"]
        onDropped: drop => {
            if (!drop.urls || drop.urls.length === 0) return
            root.libraryModel.loadFolder(drop.urls[0])
            drop.accepted = true
        }

        Rectangle {
            anchors.fill: parent
            visible: parent.containsDrag
            color: Qt.alpha(surfaceBase, 0.69)
            border.width: 2
            border.color: recordRed
            radius: 12

            Label {
                anchors.centerIn: parent
                text: qsTr("Drop a music folder to scan")
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 18
                font.weight: Font.Bold
            }
        }
    }
}
