import QtQuick
import QtQuick.Controls

Menu {
    id: root
    property var appWindow: (typeof window !== "undefined") ? window : null
    property var track: ({})

    implicitWidth: 190
    padding: 6

    background: MenuSurface {}

    AppMenuItem {
        text: qsTr("Play Next")
        icon.name: "list"
        onTriggered: if (root.appWindow) root.appWindow.insertTrackNext(root.track)
    }

    AppMenuItem {
        text: qsTr("Play Next on Phone")
        icon.name: "smartphone"
        visible: phoneRemote.phonePlayback.title !== undefined && !!(root.track && root.track.title) && root.track.format !== "STREAM"
        onTriggered: phoneRemote.playNextOnPhone(root.track.title, root.track.artist || "")
    }

    AppMenuItem {
        text: qsTr("Add to Queue")
        icon.name: "list"
        onTriggered: if (root.appWindow) root.appWindow.appendToQueue(root.track)
    }

    AppMenuItem {
        text: root.appWindow && root.track && root.appWindow.isFavorite(root.track.filePath)
            ? qsTr("Remove Favorite") : qsTr("Add to Favorites")
        icon.name: "heart"
        onTriggered: if (root.appWindow && root.track) root.appWindow.toggleFavorite(root.track.filePath)
    }

    AppMenuItem {
        text: qsTr("Go to Artist")
        icon.name: "music"
        visible: !!(root.track && root.track.artist)
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCatalogDetail("artist", root.track.artist, root.track)
    }

    AppMenuItem {
        text: qsTr("Go to Album")
        icon.name: "disc"
        visible: !!(root.track && root.track.album)
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCatalogDetail("album", root.track.album, root.track)
    }

    AppMenuItem {
        text: qsTr("Search Cover Art")
        icon.name: "disc"
        visible: !!(root.track && (root.track.album || root.track.title))
        onTriggered: if (root.appWindow && root.track) root.appWindow.openCoverSearch(root.track.album || root.track.title, root.track.artist || "", root.track.filePath || "")
    }

    AppMenuItem {
        text: qsTr("Edit Metadata")
        icon.name: "pencil"
        visible: !!(root.track && root.track.filePath && !root.track.remoteId && !String(root.track.filePath).startsWith("http"))
        onTriggered: if (root.appWindow && root.track) root.appWindow.openTrackMetadataEditor(root.track)
    }

    AppMenuItem {
        text: qsTr("Show in Folder")
        icon.name: "folder"
        visible: !!(root.track && root.track.filePath && !String(root.track.filePath).startsWith("http"))
        onTriggered: if (root.track && root.track.filePath) appSettings.showInFolder(root.track.filePath)
    }

    AppMenuItem {
        text: qsTr("Copy Title")
        icon.name: "info"
        onTriggered: if (root.track) appSettings.copyToClipboard(root.track.title || root.track.fileName || "")
    }
}
