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

    onClosed: isOpen = false

    readonly property bool isTrackFavorite: {
        if (!track || !track.filePath || !root.appWindow) return false
        return root.appWindow.isFavorite(track.filePath)
    }

    component ActionItem: Rectangle {
        id: itemRoot
        property string iconName: ""
        property color iconColor: root.appWindow.textPrimary
        property string titleText: ""
        property string subtitleText: ""
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 10
        color: itemMouse.containsMouse ? root.appWindow.surfaceCardHover : "transparent"
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
                    color: root.appWindow.textPrimary
                    font.family: root.appWindow.displayFont
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    visible: itemRoot.subtitleText.length > 0
                    text: itemRoot.subtitleText
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.bodyFont
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
            color: root.appWindow.surfaceElevated
            border.width: 1
            border.color: root.appWindow.borderCard

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
                text: root.track ? (root.track.title || root.track.fileName || qsTr("Unknown Track")) : qsTr("No Track")
                color: root.appWindow.textPrimary
                font.family: root.appWindow.displayFont
                font.pixelSize: 15
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: root.track ? (root.track.artist || qsTr("Unknown Artist")) : ""
                color: root.appWindow.textSecondary
                font.family: root.appWindow.bodyFont
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        TransportButton {
            Layout.alignment: Qt.AlignVCenter
            Accessible.name: qsTr("Close")
            buttonSize: 32
            iconName: "x"
            tooltipText: qsTr("Close")
            onClicked: root.close()
        }
    }

    SettingDivider {
        Layout.fillWidth: true
        Layout.bottomMargin: 4
    }

    // Scrollable Actions List
    AppFlickable {
        id: actionsFlick
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(360, actionsColumn.implicitHeight)
        Layout.maximumHeight: 400
        contentHeight: actionsColumn.implicitHeight
        clip: true
        pixelAligned: true

        ScrollBar.vertical: AutoHideScrollBar {}

        ColumnLayout {
            id: actionsColumn
            width: actionsFlick.width
            spacing: 2

            ActionItem {
                iconName: "music"
                titleText: qsTr("Go to Artist")
                readonly property string mainArtist: root.track && root.track.artist
                    ? (library.artistNames(root.track.artist)[0] || root.track.artist) : ""
                subtitleText: mainArtist || qsTr("Unknown Artist")
                visible: mainArtist.length > 0
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCatalogDetail("artist", mainArtist, root.track)
                }
            }

            ActionItem {
                iconName: "disc"
                titleText: qsTr("Go to Album")
                subtitleText: root.track ? (root.track.album || qsTr("Unknown Album")) : ""
                visible: !!(root.track && root.track.album)
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCatalogDetail("album", root.track.album, root.track)
                }
            }

            ActionItem {
                iconName: "search"
                titleText: qsTr("Search Cover Art")
                subtitleText: qsTr("Find and apply high-resolution artwork")
                visible: !!(root.track && (root.track.album || root.track.title))
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.openCoverSearch(root.track.album || root.track.title, root.track.artist || "", root.track.filePath || "")
                }
            }

            ActionItem {
                iconName: "list-music"
                titleText: qsTr("Go to Playlist")
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
                titleText: qsTr("Edit Metadata")
                subtitleText: qsTr("Edit tags, year, lyrics and album info")
                onClicked: {
                    root.close()
                    root.openMetadataEditor(root.track)
                }
            }

            ActionItem {
                iconName: "list"
                titleText: qsTr("Play Next")
                subtitleText: qsTr("Queue immediately after current song")
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.insertTrackNext(root.track)
                }
            }

            ActionItem {
                iconName: "list-music"
                titleText: qsTr("Add to Queue")
                subtitleText: qsTr("Append to playback queue")
                onClicked: {
                    root.close()
                    if (root.appWindow) root.appWindow.appendToQueue(root.track)
                }
            }

            ActionItem {
                iconName: "heart"
                iconColor: root.isTrackFavorite ? root.appWindow.recordRed : root.appWindow.textPrimary
                titleText: root.isTrackFavorite ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
                subtitleText: root.isTrackFavorite ? qsTr("Saved in your Favorites") : qsTr("Save track to Favorites")
                onClicked: {
                    if (root.appWindow && root.track && root.track.filePath)
                        root.appWindow.toggleFavorite(root.track.filePath)
                }
            }

            ActionItem {
                iconName: "folder"
                titleText: qsTr("Show in Folder")
                subtitleText: root.track ? (root.track.filePath || "") : ""
                visible: !!(root.track && root.track.filePath && !String(root.track.filePath).startsWith("http"))
                onClicked: {
                    root.close()
                    if (root.track && root.track.filePath) appSettings.showInFolder(root.track.filePath)
                }
            }

            ActionItem {
                iconName: "info"
                titleText: qsTr("Copy Title")
                subtitleText: qsTr("Copy track title to clipboard")
                onClicked: {
                    root.close()
                    if (root.track) appSettings.copyToClipboard(root.track.title || root.track.fileName || "")
                }
            }
        }
    }
}
