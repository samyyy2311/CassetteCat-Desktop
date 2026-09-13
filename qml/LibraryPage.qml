import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var libraryModel
    anchors.fill: parent
    property alias searchBox: libSearchBar
    property alias searchInput: libSearchBar.searchInput
    readonly property int selectedTrackCount: Object.keys(root.appWindow.selectedTrackPaths || {}).length
    property var health: ({})

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
                        {
                            id: "songs",
                            label: "Songs"
                        },
                        {
                            id: "artists",
                            label: "Artists"
                        },
                        {
                            id: "albums",
                            label: "Albums"
                        },
                        {
                            id: "genres",
                            label: "Genres"
                        },
                        {
                            id: "folders",
                            label: "Folders"
                        },
                        {
                            id: "playlists",
                            label: "Playlists"
                        }
                    ]

                    Item {
                        width: tabLbl.implicitWidth
                        height: 32

                        Label {
                            id: tabLbl
                            anchors.centerIn: parent
                            text: modelData.label
                            color: root.appWindow.libraryTab === modelData.id ? textPrimary : textSecondary
                            font.family: displayFont
                            font.pixelSize: 15
                            font.weight: root.appWindow.libraryTab === modelData.id ? Font.Bold : Font.Medium
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width
                            height: 2.5
                            radius: 1.25
                            color: recordRed
                            visible: root.appWindow.libraryTab === modelData.id
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.libraryTab = modelData.id
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
                    text: root.libraryModel.trackCount + " songs"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }


            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: 8
                visible: root.appWindow.libraryTab === "songs"

                Repeater {
                    model: [
                        {
                            id: "ALL",
                            label: "ALL"
                        },
                        {
                            id: "FAVORITES",
                            label: "♥ FAVORITES"
                        },
                    ]

                    Rectangle {
                        id: qPill
                        property bool isSelected: root.appWindow.songFilterMode === modelData.id
                        width: qPillLbl.implicitWidth + 20
                        height: 28
                        radius: 14
                        color: "transparent"
                        border.width: isSelected ? 1.5 : 1
                        border.color: isSelected ? recordRed : (qPillMouse.containsMouse ? "#45FFFFFF" : "#282828")

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

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
                            onClicked: root.appWindow.songFilterMode = modelData.id
                        }
                    }
                }
            }

            PressDepthIconButton {
                visible: root.appWindow.libraryTab === "songs"
                boxSize: 34
                iconSize: 16
                iconName: root.appWindow.libraryViewMode === "grid" ? "grid-2x2" : "list"
                tint: textPrimary
                tooltipText: root.appWindow.libraryViewMode === "grid" ? "Detailed Grid View (Click for List)" : "List View (Click for Grid)"
                onClicked: root.appWindow.libraryViewMode = (root.appWindow.libraryViewMode === "grid" ? "list" : "grid")
            }

            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "play"
                tint: recordRedHover
                tooltipText: "Play library"
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
                tooltipText: "Shuffle library"
                onClicked: {
                    root.appWindow.shufflePlayback(root.appWindow.availableTracks())
                }
            }

            ExpandableSearchBar {
                id: libSearchBar
                visible: root.appWindow.libraryTab !== "playlists"
                boxSize: 34
                iconSize: 16
                expandedWidth: 175
                placeholder: "Search library..."
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
                tooltipText: "Refine & Sort"
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
                tooltipText: "Library health"
                onClicked: {
                    root.health = root.appWindow.libraryHealth()
                    healthDialog.open()
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
                text: root.selectedTrackCount + " selected"
                color: root.appWindow.recordRed
                font.family: root.appWindow.monoFont
                font.pixelSize: 11
                Layout.rightMargin: 4
            }

            SettingButton {
                text: "Queue"
                iconName: "list"
                onClicked: root.appWindow.addSelectedTracksToQueue()
            }

            SettingButton {
                text: "Favorite"
                iconName: "heart"
                onClicked: root.appWindow.favoriteSelectedTracks()
            }

            SettingButton {
                text: "Save Playlist"
                iconName: "list"
                onClicked: {
                    root.appWindow.createPlaylist("Selection", root.appWindow.selectedTracks())
                    root.appWindow.clearTrackSelection()
                }
            }

            SettingButton {
                text: "Clear"
                iconName: "x"
                onClicked: root.appWindow.clearTrackSelection()
            }
        }

        StackLayout {
            id: libraryStack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.appWindow.libraryTab === "songs" ? 0 : (root.appWindow.libraryTab === "artists" ? 1 : (root.appWindow.libraryTab === "albums" ? 2 : (root.appWindow.libraryTab === "genres" ? 3 : (root.appWindow.libraryTab === "folders" ? 4 : 5))))

            Item {
                GridView {
                    id: songsGridView
                    visible: root.appWindow.libraryViewMode === "grid"
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: library
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
                            track: model.track
                            onClicked: root.appWindow.playTrack(model.track)
                            onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
                        }
                    }
                }

                ListView {
                    id: songsListView
                    visible: root.appWindow.libraryViewMode === "list"
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    clip: true
                    model: library
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: SleekScrollBar {}

                    delegate: SongRow {
                        width: songsListView.width
                        track: model.track
                        selectable: true
                        selected: root.appWindow.isTrackSelected(model.track.filePath)
                        showPlayCount: true
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

                EmptyState {
                    anchors.fill: parent
                    visible: root.libraryModel.visibleTrackCount === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: "No Songs Found"
                    subtitle: "Try resetting format filters or changing search keywords"
                    actionLabel: "Reset Filters"
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
                        let res = sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name);
                        return asc ? res : -res;
                    });
                    return list;
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
                                root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curArtists.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/04-gray-dancing-headphones.png"
                    title: "No Artists Found"
                    subtitle: "No artists match your current search query"
                    actionLabel: "Clear Search"
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
                        let res = sortM === "artist" ? ((a.track ? a.track.artist : "").localeCompare(b.track ? b.track.artist : "")) : (sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name));
                        return asc ? res : -res;
                    });
                    return list;
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
                                root.appWindow.openCatalogDetail("album", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curAlbums.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/02-black-cat-cassette.png"
                    title: "No Albums Found"
                    subtitle: "No albums match your current search query"
                    actionLabel: "Clear Search"
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
                        let res = sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name);
                        return asc ? res : -res;
                    });
                    return list;
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
                                root.appWindow.openCatalogDetail("genre", modelData.name, modelData.track);
                            }
                        }
                    }
                }

                EmptyState {
                    anchors.fill: parent
                    visible: parent.curGenres.length === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/03-cream-cassette-hug.png"
                    title: "No Genres Found"
                    subtitle: "No audio genres matched your search"
                    actionLabel: "Clear Search"
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
                        let res = sortM === "count" ? (a.count - b.count) : a.name.localeCompare(b.name);
                        return asc ? res : -res;
                    });
                    return list;
                }

                GridView {
                    id: folderGrid
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 8
                    bottomMargin: 32
                    clip: true
                    model: parent.curFolders
                    readonly property int cols: Math.max(2, Math.floor((width - 8) / 210))
                    cellWidth: Math.floor((width - 8) / cols)
                    cellHeight: 125
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: SleekScrollBar {}

                    delegate: Item {
                        width: folderGrid.cellWidth
                        height: 115

                        FolderCard {
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
                    title: "No Folders Found"
                    subtitle: "No audio folders matched your search"
                    actionLabel: "Clear Search"
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

    Dialog {
        id: healthDialog
        title: "Library health"
        modal: true
        standardButtons: Dialog.Ok
        onOpened: root.health = root.appWindow.libraryHealth()

        contentItem: ColumnLayout {
            spacing: 10
            Label { text: "This check uses the tracks currently indexed by CassetteCat."; color: root.appWindow.textSecondary; wrapMode: Text.WordWrap; Layout.preferredWidth: 360 }
            Label { text: (root.health.total || 0) + " tracks indexed"; color: root.appWindow.textPrimary }
            Label { text: (root.health.noFolderArtwork || 0) + " without folder artwork"; color: root.appWindow.textSecondary }
            Label { text: (root.health.metadataGaps || 0) + " with missing title, artist, or album"; color: root.appWindow.textSecondary }
            Label { text: (root.health.duplicateMetadata || 0) + " duplicate metadata entries"; color: root.appWindow.textSecondary }
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
            color: "#B00E0D0C"
            border.width: 2
            border.color: recordRed
            radius: 12

            Label {
                anchors.centerIn: parent
                text: "Drop a music folder to scan"
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 18
                font.weight: Font.Bold
            }
        }
    }
}
