import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow

    // availableTracks() is a plain function, so libraryRevision makes these refresh after a rescan.
    readonly property var favoritesTracks: {
        root.appWindow.libraryRevision
        root.appWindow.favoriteTracks
        return root.appWindow.playlistTracks("Favorites")
    }
    readonly property var mostPlayedTracks: {
        root.appWindow.libraryRevision
        root.appWindow.playCounts
        return root.appWindow.playlistTracks("Most Played")
    }
    readonly property var recentlyAddedTracks: root.appWindow.recentlyAdded || []
    readonly property var neverPlayedTracks: {
        root.appWindow.libraryRevision
        root.appWindow.playCounts
        return root.appWindow.playlistTracks("Never Played")
    }

    readonly property var allPlaylists: {
        root.appWindow.libraryRevision
        const smart = [
            {
                id: "smart_favorites",
                name: "Favorites",
                isSmart: true,
                tracks: root.favoritesTracks
            },
            {
                id: "smart_most_played",
                name: "Most Played",
                isSmart: true,
                tracks: root.mostPlayedTracks
            },
            {
                id: "smart_recently_added",
                name: "Recently Added",
                isSmart: true,
                tracks: root.recentlyAddedTracks
            },
            {
                id: "smart_never_played",
                name: "Never Played",
                isSmart: true,
                tracks: root.neverPlayedTracks
            }
        ]
        const custom = (root.appWindow.playlists || []).map(p => ({
            id: p.id,
            name: p.name,
            isSmart: false,
            trackPaths: p.trackPaths,
            tracks: root.appWindow.playlistTracks(p)
        }))
        const combined = smart.concat(custom)
        const q = (root.appWindow.libSearchQuery || "").toLowerCase().trim()
        if (!q.length) return combined
        return combined.filter(p => p.name.toLowerCase().includes(q))
    }

    // Grid View (default, matches AlbumCard / ArtistCard layout)
    GridView {
        id: playlistGrid
        visible: root.appWindow.libraryViewMode === "grid"
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 8
        bottomMargin: 32
        clip: true
        model: root.allPlaylists
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
            width: playlistGrid.cellWidth
            height: 245

            AlbumCard {
                id: albumCard
                anchors.centerIn: parent
                cardWidth: parent.width - 16
                cardHeight: 235
                name: modelData.name
                artist: modelData.isSmart ? "Smart Playlist" : "Custom Playlist"
                count: modelData.tracks.length
                track: modelData.tracks.length ? modelData.tracks[0] : ({})
                onClicked: {
                    const hero = modelData.tracks.length ? modelData.tracks[0] : ({})
                    root.appWindow.openCatalogDetail("playlist", modelData.name, hero,
                                                     modelData.isSmart ? modelData.name : modelData.id)
                }

                DropArea {
                    anchors.fill: parent
                    enabled: !modelData.isSmart
                    onEntered: drag => drag.accepted = !!(drag.source && drag.source.track && drag.source.track.format !== "STREAM")
                    onDropped: drop => {
                        if (root.appWindow.addTrackToPlaylist(modelData.id, drop.source.track)) {
                            drop.accepted = true
                        }
                    }
                }
            }
        }
    }

    // List View (matches SongRow / Library ListView layout)
    ListView {
        id: playlistList
        visible: root.appWindow.libraryViewMode !== "grid"
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        bottomMargin: 32
        clip: true
        model: root.allPlaylists
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: UiConstants.flickDeceleration
        maximumFlickVelocity: UiConstants.maximumFlickVelocity
        cacheBuffer: UiConstants.cacheBuffer
        pixelAligned: UiConstants.pixelAligned
        reuseItems: true
        ScrollBar.vertical: AutoHideScrollBar {}

        delegate: Rectangle {
            id: playlistRow
            required property var modelData

            width: playlistList.width
            height: 58
            radius: 8
            color: playlistMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
            border.width: playlistDrop.containsDrag ? 1.5 : 1
            border.color: playlistDrop.containsDrag ? root.appWindow.recordRed
                : (playlistMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle)

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: playlistMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const hero = playlistRow.modelData.tracks.length ? playlistRow.modelData.tracks[0] : ({})
                    root.appWindow.openCatalogDetail("playlist", playlistRow.modelData.name, hero,
                                                     playlistRow.modelData.isSmart ? playlistRow.modelData.name
                                                                                   : playlistRow.modelData.id)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                Cover {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 6
                    track: playlistRow.modelData.tracks.length ? playlistRow.modelData.tracks[0] : ({})
                    cacheArtwork: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        Layout.fillWidth: true
                        text: playlistRow.modelData.name
                        color: root.appWindow.textPrimary
                        font.family: root.appWindow.displayFont
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: playlistRow.modelData.tracks.length + " track" + (playlistRow.modelData.tracks.length === 1 ? "" : "s") + (playlistRow.modelData.isSmart ? " • Smart" : "")
                        color: root.appWindow.textSecondary
                        font.family: root.appWindow.bodyFont
                        font.pixelSize: 11
                    }
                }

                PressDepthIconButton {
                    boxSize: 30
                    iconSize: 14
                    iconName: "play"
                    tint: root.appWindow.textPrimary
                    tooltipText: "Play playlist"
                    enabled: playlistRow.modelData.tracks.length > 0
                    onClicked: {
                        if (playlistRow.modelData.isSmart) {
                            root.appWindow.startPlayback(playlistRow.modelData.tracks, 0, false)
                        } else {
                            root.appWindow.playPlaylist(playlistRow.modelData)
                        }
                    }
                }

                PressDepthIconButton {
                    visible: !playlistRow.modelData.isSmart
                    boxSize: 30
                    iconSize: 14
                    iconName: "external-link"
                    tint: root.appWindow.silverDim
                    tooltipText: "Export M3U"
                    onClicked: root.appWindow.requestPlaylistExport(playlistRow.modelData)
                }

                PressDepthIconButton {
                    visible: !playlistRow.modelData.isSmart
                    boxSize: 30
                    iconSize: 14
                    iconName: "x"
                    tint: root.appWindow.silverDim
                    tooltipText: "Delete playlist"
                    onClicked: root.appWindow.deletePlaylist(playlistRow.modelData.id)
                }
            }

            DropArea {
                id: playlistDrop
                anchors.fill: parent
                enabled: !playlistRow.modelData.isSmart
                onEntered: drag => drag.accepted = !!(drag.source && drag.source.track && drag.source.track.format !== "STREAM")
                onDropped: drop => {
                    if (root.appWindow.addTrackToPlaylist(playlistRow.modelData.id, drop.source.track)) {
                        drop.accepted = true
                    }
                }
            }
        }
    }

    EmptyState {
        anchors.fill: parent
        visible: root.allPlaylists.length === 0
        catImage: "qrc:/qt/qml/CassetteCat/assets/02-black-cat-cassette.png"
        title: "No Playlists Found"
        subtitle: "No playlists match \"" + root.appWindow.libSearchQuery + "\""
        actionLabel: "Clear Search"
        onActionClicked: root.appWindow.libSearchQuery = ""
    }
}
