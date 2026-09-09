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
        anchors.topMargin: 12
        anchors.bottomMargin: 28
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: playlistStatus.visible ? 108 : 68
            radius: 12
            color: root.appWindow.surfaceCard
            border.width: 1
            border.color: root.appWindow.borderSubtle

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                anchors.topMargin: 17
                height: 34
                spacing: 12

                LucideIcon {
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    icon: "list-music"
                    color: root.appWindow.recordRed
                }

                TextField {
                    id: playlistName
                    Layout.fillWidth: true
                    placeholderText: "New playlist name"
                    color: root.appWindow.textPrimary
                    placeholderTextColor: root.appWindow.silverDim
                    font.family: root.appWindow.displayFont
                    font.pixelSize: 13
                    background: Rectangle {
                        radius: 7
                        color: root.appWindow.surfaceInput
                        border.width: 1
                        border.color: playlistName.activeFocus ? root.appWindow.recordRed : root.appWindow.borderSubtle
                    }
                    leftPadding: 10
                    rightPadding: 10
                    onAccepted: createPlaylist()
                }

                SettingButton {
                    text: "Create"
                    iconName: "music"
                    primary: true
                    onClicked: createPlaylist()
                }

                SettingButton {
                    text: "Save Queue"
                    iconName: "list-music"
                    enabled: playlistName.text.trim().length > 0
                    opacity: enabled ? 1 : 0.45
                    onClicked: {
                        if (root.appWindow.saveQueueAsPlaylist(playlistName.text)) playlistName.text = ""
                    }
                }

                SettingButton {
                    text: "Import M3U"
                    iconName: "folder"
                    onClicked: root.appWindow.requestPlaylistImport()
                }
            }

            Label {
                id: playlistStatus
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 10
                visible: root.appWindow.playlistStatus.length > 0
                text: root.appWindow.playlistStatus
                color: root.appWindow.textSecondary
                font.family: root.appWindow.bodyFont
                font.pixelSize: 11
                elide: Text.ElideRight
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
                height: 74
                radius: 12
                color: playlistMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
                border.width: 1
                border.color: playlistDrop.containsDrag ? root.appWindow.recordRed
                    : (playlistMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    Cover {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        radius: 8
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
                        z: 1
                        boxSize: 32
                        iconSize: 15
                        iconName: "play"
                        tint: root.appWindow.textPrimary
                        tooltipText: "Play playlist"
                        onClicked: root.appWindow.playPlaylist(playlistRow.modelData)
                    }

                    PressDepthIconButton {
                        z: 1
                        boxSize: 32
                        iconSize: 15
                        iconName: "external-link"
                        tint: root.appWindow.silverDim
                        tooltipText: "Export M3U"
                        onClicked: root.appWindow.requestPlaylistExport(playlistRow.modelData)
                    }

                    PressDepthIconButton {
                        z: 1
                        boxSize: 32
                        iconSize: 15
                        iconName: "x"
                        tint: root.appWindow.silverDim
                        tooltipText: "Delete playlist"
                        onClicked: root.appWindow.deletePlaylist(playlistRow.modelData.id)
                    }
                }

                MouseArea {
                    id: playlistMouse
                    anchors.fill: parent
                    enabled: playlistRow.tracks.length > 0
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.appWindow.playPlaylist(playlistRow.modelData)
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
                subtitle: "Create one here, or save the active queue from Now Playing"
            }
        }
    }

    function createPlaylist() {
        if (root.appWindow.createPlaylist(playlistName.text, [])) playlistName.text = ""
    }
}
