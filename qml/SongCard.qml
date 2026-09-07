import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 230
    property bool isCurrent: !!(player.currentTrack && track && player.currentTrack.filePath === track.filePath)
    property bool isPlaying: isCurrent && player.isPlaying

    signal clicked()
    signal favoriteClicked()

    width: cardWidth
    height: cardHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: coverContainer
                anchors.fill: parent
                radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12
                color: surfaceCard
                clip: true
                border.width: root.isCurrent ? 1.5 : (cardMouse.containsMouse ? 1.5 : 0)
                border.color: root.isCurrent ? recordRed : (cardMouse.containsMouse ? recordRed : "transparent")
                scale: cardMouse.containsMouse ? 1.03 : 1.0

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: 12
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: "transparent"
                    border.width: 1
                    border.color: root.isCurrent ? recordRed : "#15FFFFFF"
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.track.title || root.track.fileName || "Unknown Track"
                color: root.isCurrent ? recordRed : (cardMouse.containsMouse ? recordRedHover : textPrimary)
                font.family: displayFont
                font.pixelSize: 13
                font.weight: root.isCurrent ? Font.Bold : Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.track.artist || "Unknown Artist"
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
