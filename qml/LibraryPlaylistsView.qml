import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 8
        anchors.bottomMargin: 24
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 260
                Layout.preferredHeight: 32
                radius: 16
                color: root.appWindow.surfaceCard
                border.width: 1
                border.color: playlistName.activeFocus ? root.appWindow.recordRed : root.appWindow.borderSubtle

                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    LucideIcon {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        icon: "list"
                        color: playlistName.activeFocus ? root.appWindow.recordRed : root.appWindow.silverDim
                    }

                    TextInput {
                        id: playlistName
                        Layout.fillWidth: true
                        color: root.appWindow.textPrimary
                        font.family: root.appWindow.displayFont
                        font.pixelSize: 12
                        selectByMouse: true
                        onAccepted: createPlaylist()

                        Text {
                            anchors.fill: parent
                            visible: !playlistName.text && !playlistName.activeFocus
                            text: "New playlist name..."
                            color: root.appWindow.silverDim
                            font.family: root.appWindow.displayFont
                            font.pixelSize: 12
                        }
                    }

                    LucideIcon {
                        visible: playlistName.text.length > 0
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        icon: "x"
                        color: root.appWindow.silverDim

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playlistName.text = ""
                        }
                    }
                }
            }

            SettingButton {
                text: "Create"
                iconName: "list"
                primary: true
                onClicked: createPlaylist()
            }

            RowLayout {
                visible: root.appWindow.playlistStatus.length > 0
                Layout.leftMargin: 8
                spacing: 6

                LucideIcon {
                    Layout.preferredWidth: 13
                    Layout.preferredHeight: 13
                    icon: "info"
                    color: root.appWindow.recordRed
                }

                Label {
                    text: root.appWindow.playlistStatus
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                }
            }

            Item {
                Layout.fillWidth: true
            }

            SettingButton {
                text: "Save Queue"
                iconName: "list"
                onClicked: {
                    const name = playlistName.text.trim() || ("Queue " + new Date().toLocaleDateString(Qt.locale(), "MMM d"))
                    if (root.appWindow.saveQueueAsPlaylist(name)) playlistName.text = ""
                }
            }

            SettingButton {
                text: "Import M3U"
                iconName: "folder"
                onClicked: root.appWindow.requestPlaylistImport()
            }
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "SMART PLAYLISTS"
                color: root.appWindow.silverDim
                font.family: root.appWindow.monoFont
                font.pixelSize: 10
                font.weight: Font.Bold
                rightPadding: 4
            }

            SettingButton {
                text: "Favorites"
                iconName: "heart"
                onClicked: root.appWindow.createSmartPlaylist("Favorites", root.appWindow.availableTracks().filter(track => root.appWindow.favoriteTracks[track.filePath]))
            }

            SettingButton {
                text: "Most Played"
                iconName: "list"
                onClicked: root.appWindow.createSmartPlaylist("Most Played", root.appWindow.heavyRotation)
            }

            SettingButton {
                text: "Recently Added"
                iconName: "clock"
                onClicked: root.appWindow.createSmartPlaylist("Recently Added", root.appWindow.recentlyAdded)
            }

            SettingButton {
                text: "Never Played"
                iconName: "eye-off"
                onClicked: root.appWindow.createSmartPlaylist("Never Played", root.appWindow.availableTracks().filter(track => !root.appWindow.playCounts[track.filePath]))
            }
        }

        ListView {
            id: playlistList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.appWindow.playlists
            spacing: 8
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar {}

            delegate: Rectangle {
                id: playlistRow
                required property var modelData
                readonly property var tracks: root.appWindow.playlistTracks(modelData)

                width: playlistList.width - 16
                height: 72
                radius: 10
                color: playlistMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
                border.width: 1
                border.color: playlistDrop.containsDrag ? root.appWindow.recordRed
                    : (playlistMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle)

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: playlistMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.appWindow.openCatalogDetail("playlist", playlistRow.modelData.name, playlistRow.tracks.length ? playlistRow.tracks[0] : ({}))
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Cover {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: (root.appWindow && root.appWindow.albumArtRadius !== undefined)
                                ? (root.appWindow.albumArtRadius === 0 ? 0 : (root.appWindow.albumArtRadius <= 8 ? 5 : 8))
                                : 8
                        track: playlistRow.tracks.length ? playlistRow.tracks[0] : ({})
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
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            text: playlistRow.tracks.length + " track" + (playlistRow.tracks.length === 1 ? "" : "s")
                            color: root.appWindow.textSecondary
                            font.family: root.appWindow.bodyFont
                            font.pixelSize: 11
                        }
                    }

                    PressDepthIconButton {
                        boxSize: 32
                        iconSize: 15
                        iconName: "play"
                        tint: root.appWindow.textPrimary
                        tooltipText: "Play playlist"
                        onClicked: root.appWindow.playPlaylist(playlistRow.modelData)
                    }

                    PressDepthIconButton {
                        boxSize: 32
                        iconSize: 15
                        iconName: "external-link"
                        tint: root.appWindow.silverDim
                        tooltipText: "Export M3U"
                        onClicked: root.appWindow.requestPlaylistExport(playlistRow.modelData)
                    }

                    PressDepthIconButton {
                        boxSize: 32
                        iconSize: 15
                        iconName: "x"
                        tint: root.appWindow.silverDim
                        tooltipText: "Delete playlist"
                        onClicked: root.appWindow.deletePlaylist(playlistRow.modelData.id)
                    }
                }

                DropArea {
                    id: playlistDrop
                    anchors.fill: parent
                    onEntered: drag => drag.accepted = !!(drag.source && drag.source.track
                        && drag.source.track.format !== "STREAM")
                    onDropped: drop => {
                        if (root.appWindow.addTrackToPlaylist(playlistRow.modelData.id, drop.source.track)) {
                            drop.accepted = true
                        }
                    }
                }
            }

            EmptyState {
                anchors.fill: parent
                visible: playlistList.count === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/02-black-cat-cassette.png"
                title: "No Playlists Yet"
                subtitle: "Create a custom playlist above, or save your active queue from Now Playing"
                actionLabel: "Create Playlist"
                onActionClicked: playlistName.forceActiveFocus()
            }
        }
    }

    function createPlaylist() {
        const name = playlistName.text.trim() || ("Playlist " + (root.appWindow.playlists.length + 1))
        if (root.appWindow.createPlaylist(name, [])) playlistName.text = ""
    }
}
