import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var appWindow: (typeof window !== "undefined") ? window : null
    property var track: ({})

    implicitWidth: 190
    topPadding: 4
    bottomPadding: 4

    background: Rectangle {
        radius: 8
        color: root.appWindow ? root.appWindow.surfaceElevated : "#22201D"
        border.width: 1
        border.color: root.appWindow ? root.appWindow.borderVariant : Qt.rgba(1, 1, 1, 0.09)
    }

    component TrackMenuItem: MenuItem {
        id: item
        implicitHeight: visible ? 32 : 0
        contentItem: Row {
            spacing: 10
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10

            LucideIcon {
                width: 14
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                icon: item.icon.name
                color: item.highlighted
                    ? (root.appWindow ? root.appWindow.recordRedHover : "#D64337")
                    : (root.appWindow ? root.appWindow.textPrimary : "#F5F0EC")
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: item.text
                color: item.highlighted
                    ? (root.appWindow ? root.appWindow.recordRedHover : "#D64337")
                    : (root.appWindow ? root.appWindow.textPrimary : "#F5F0EC")
                font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }

        background: Rectangle {
            color: item.highlighted ? (root.appWindow ? root.appWindow.surfaceCardHover : "#2C2A26") : "transparent"
            radius: 5
            anchors.fill: parent
            anchors.margins: 2
        }
    }

    TrackMenuItem {
        text: "Play Next"
        icon.name: "list"
        onTriggered: if (root.appWindow) root.appWindow.insertTrackNext(root.track)
    }

    TrackMenuItem {
        text: "Add to Queue"
        icon.name: "list"
        onTriggered: if (root.appWindow) root.appWindow.appendToQueue(root.track)
    }

    TrackMenuItem {
        text: root.appWindow && root.track && root.appWindow.isFavorite(root.track.filePath)
            ? "Remove Favorite" : "Add to Favorites"
        icon.name: "heart"
        onTriggered: if (root.appWindow && root.track) root.appWindow.toggleFavorite(root.track.filePath)
    }

    TrackMenuItem {
        text: "Go to Artist"
        icon.name: "music"
        visible: !!(root.track && root.track.artist)
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCatalogDetail("artist", root.track.artist, root.track)
    }

    TrackMenuItem {
        text: "Go to Album"
        icon.name: "disc"
        visible: !!(root.track && root.track.album)
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCatalogDetail("album", root.track.album, root.track)
    }

    TrackMenuItem {
        text: "Search Cover Art"
        icon.name: "disc"
        visible: !!(root.track && (root.track.album || root.track.title))
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCoverSearch(root.track.album || root.track.title, root.track.artist || "", root.track.filePath || "")
    }

    TrackMenuItem {
        text: "Show in Folder"
        icon.name: "folder"
        visible: !!(root.track && root.track.filePath && !String(root.track.filePath).startsWith("http"))
        onTriggered: if (root.track && root.track.filePath) appSettings.showInFolder(root.track.filePath)
    }

    TrackMenuItem {
        text: "Copy Title"
        icon.name: "info"
        onTriggered: if (root.track) appSettings.copyToClipboard(root.track.title || root.track.fileName || "")
    }
}
