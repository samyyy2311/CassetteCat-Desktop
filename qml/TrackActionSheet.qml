import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

BottomSheet {
    id: root

    property var track: ({})
    maxWidth: 520
    maxHeight: Math.min(parent ? parent.height - 40 : 580, 620)

    signal openMetadataEditor(var targetTrack)

    function openFor(targetTrack) {
        track = targetTrack || ({})
        isOpen = true
    }

    readonly property bool isTrackFavorite: {
        if (!track || !track.filePath || !root.appWindow) return false
        return root.appWindow.isFavorite(track.filePath)
    }

    component ActionItem: Rectangle {
        id: itemRoot
        property string iconName: ""
        property color iconColor: root.appWindow ? root.appWindow.textPrimary : "#F5F0EC"
        property string titleText: ""
        property string subtitleText: ""
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 10
        color: itemMouse.containsMouse ? (root.appWindow ? root.appWindow.surfaceCardHover : "#22201D") : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                radius: 17
                color: itemMouse.containsMouse ? "#20FFFFFF" : "#12FFFFFF"
                Behavior on color { ColorAnimation { duration: 120 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 17
                    height: 17
                    icon: itemRoot.iconName
                    color: itemRoot.iconColor
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: itemRoot.titleText
                    color: root.appWindow ? root.appWindow.textPrimary : "#F5F0EC"
                    font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: itemRoot.subtitleText.length > 0
                    text: itemRoot.subtitleText
                    color: root.appWindow ? root.appWindow.textSecondary : "#8E8A84"
                    font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: itemMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: itemRoot.clicked()
        }
    }

    // Sheet Header: Track thumbnail, title and artist
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        Layout.bottomMargin: 6
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 46
            Layout.preferredHeight: 46
            Layout.alignment: Qt.AlignVCenter
            radius: 8
            clip: true
            color: root.appWindow ? root.appWindow.surfaceElevated : "#282623"
            border.width: 1
            border.color: root.appWindow ? root.appWindow.borderCard : Qt.rgba(1, 1, 1, 0.09)

            Cover {
                anchors.fill: parent
                track: root.track
                radius: 8
                smooth: true
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: root.track ? (root.track.title || root.track.fileName || "Unknown Track") : "No Track"
                color: root.appWindow ? root.appWindow.textPrimary : "#F5F0EC"
                font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: root.track ? (root.track.artist || "Unknown Artist") : ""
                color: root.appWindow ? root.appWindow.textSecondary : "#8E8A84"
                font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            Layout.alignment: Qt.AlignVCenter
            radius: 15
            color: closeMouse.containsMouse ? "#20FFFFFF" : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            LucideIcon {
                anchors.centerIn: parent
                width: 16
                height: 16
                icon: "x"
                color: closeMouse.containsMouse ? (root.appWindow ? root.appWindow.textPrimary : "#FFFFFF") : (root.appWindow ? root.appWindow.textSecondary : "#8E8A84")
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.close()
            }
        }
    }

    SettingDivider {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
    }

    // Scrollable Actions List
    Flickable {
        id: actionsFlick
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(360, actionsColumn.implicitHeight)
        Layout.maximumHeight: 400
        contentHeight: actionsColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: UiConstants.flickDeceleration
        maximumFlickVelocity: UiConstants.maximumFlickVelocity
        pixelAligned: true

        ScrollBar.vertical: AutoHideScrollBar {}

        ColumnLayout {
            id: actionsColumn
            width: actionsFlick.width
            spacing: 2

            ActionItem {
                iconName: "music"
                titleText: "Go to Artist"
                subtitleText: root.track ? (root.track.artist || "Unknown Artist") : ""
                visible: !!(root.track && root.track.artist)
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCatalogDetail("artist", root.track.artist, root.track)
                }
            }

            ActionItem {
                iconName: "disc"
                titleText: "Go to Album"
                subtitleText: root.track ? (root.track.album || "Unknown Album") : ""
                visible: !!(root.track && root.track.album)
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCatalogDetail("album", root.track.album, root.track)
                }
            }

            ActionItem {
                iconName: "search"
                titleText: "Search Cover Online"
                subtitleText: "Find and apply high-resolution artwork"
                visible: !!(root.track && (root.track.album || root.track.title))
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCoverSearch(root.track.album || root.track.title, root.track.artist || "", root.track.filePath || "")
                }
            }

            ActionItem {
                iconName: "list-music"
                titleText: "Go to Playlist"
                subtitleText: {
                    if (!root.appWindow || !root.appWindow.playlists || root.appWindow.playlists.length === 0)
                        return "No saved playlists yet"
                    return root.appWindow.playlists.length + " playlist" + (root.appWindow.playlists.length === 1 ? "" : "s") + " available"
                }
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.page = "library"
                }
            }

            ActionItem {
                iconName: "pencil"
                titleText: "Edit Metadata"
                subtitleText: "Edit tags, year, lyrics and album info"
                onClicked: {
                    root.close()
                    root.openMetadataEditor(root.track)
                }
            }

            ActionItem {
                iconName: "list"
                titleText: "Play Next"
                subtitleText: "Queue immediately after current song"
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.insertTrackNext(root.track)
                }
            }

            ActionItem {
                iconName: "list-music"
                titleText: "Add to Queue"
                subtitleText: "Append to playback queue"
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.appendToQueue(root.track)
                }
            }

            ActionItem {
                iconName: "heart"
                iconColor: root.isTrackFavorite ? (root.appWindow ? root.appWindow.recordRed : "#C23B30") : (root.appWindow ? root.appWindow.textPrimary : "#F5F0EC")
                titleText: root.isTrackFavorite ? "Remove from Favorites" : "Add to Favorites"
                subtitleText: root.isTrackFavorite ? "Saved in your Favorites" : "Save track to Favorites"
                onClicked: {
                    if (root.appWindow && root.track && root.track.filePath)
                        root.appWindow.toggleFavorite(root.track.filePath)
                }
            }

            ActionItem {
                iconName: "folder"
                titleText: "Show in Folder"
                subtitleText: root.track ? (root.track.filePath || "") : ""
                visible: !!(root.track && root.track.filePath && !String(root.track.filePath).startsWith("http"))
                onClicked: {
                    root.close()
                    if (root.track && root.track.filePath) appSettings.showInFolder(root.track.filePath)
                }
            }

            ActionItem {
                iconName: "info"
                titleText: "Copy Title"
                subtitleText: "Copy track title to clipboard"
                onClicked: {
                    root.close()
                    if (root.track) appSettings.copyToClipboard(root.track.title || root.track.fileName || "")
                }
            }
        }
    }
}
