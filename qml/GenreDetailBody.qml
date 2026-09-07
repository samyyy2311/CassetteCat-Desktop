import QtQuick
import QtQuick.Controls

Column {
    id: root
    property var tracks: []
    property real contentWidth: 0
    property var appWindow

    width: parent.width
    visible: root.tracks.length > 0
    spacing: 4

        Item { width: 1; height: 16 }

        Label {
            leftPadding: 36
            rightPadding: 36
            bottomPadding: 8
            text: "Tracklist (" + root.tracks.length + ")"
            color: "#FFFFFF"
            font.family: "Space Grotesk"
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: -0.3
        }

        Repeater {
            model: root.tracks

            SongRow {
                width: root.contentWidth - 56
                x: 28
                track: modelData
                showAlbum: false
                showFormatBadge: root.appWindow ? root.appWindow.showFormatBadges : true
                coverRadius: root.appWindow ? (root.appWindow.albumArtRadius <= 0 ? 2 : (root.appWindow.albumArtRadius <= 8 ? 6 : 8)) : 8
                onClicked: if (root.appWindow) root.appWindow.playTrack(modelData)
            }
        }
    }
