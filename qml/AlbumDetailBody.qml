import QtQuick
import QtQuick.Controls

ListView {
    id: root
    property var tracks: []
    property var appWindow

    clip: true
    spacing: 4
    model: root.tracks
    ScrollBar.vertical: SleekScrollBar {}

    delegate: Item {
        width: root.width
        height: songRow.height

        SongRow {
            id: songRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            track: modelData
            onFavoriteClicked: if (root.appWindow) root.appWindow.toggleFavorite(modelData.filePath)

            TapHandler {
                onTapped: root.appWindow.playTrack(modelData)
            }
        }
    }
}
