import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    required property var playerController
    required property color surfacePill
    required property color borderCard
    required property color accentColor
    required property color silverDim

    width: 80
    height: 26
    radius: 13
    color: surfacePill
    border.width: 1
    border.color: borderCard

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        spacing: 4

        LucideIcon {
            Layout.preferredWidth: 12
            Layout.preferredHeight: 12
            icon: playerController.volume <= 0.001 ? "volume-x" : (playerController.volume < 0.5 ? "volume-1" : "volume-2")
            color: muteButton.containsMouse ? accentColor : silverDim

            MouseArea {
                id: muteButton
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: playerController.setVolume(playerController.volume > 0.001 ? 0.0 : 0.8)
            }
        }

        Item {
            id: trackItem
            Layout.fillWidth: true
            Layout.preferredHeight: 14

            Rectangle {
                id: groove
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 3
                radius: 1.5
                color: "#2EFFFFFF"

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round(groove.width * Math.min(1.0, Math.max(0.0, playerController.volume)))
                    radius: 1.5
                    color: accentColor
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(groove.width - width, Math.round(groove.width * Math.min(1.0, Math.max(0.0, playerController.volume))) - width / 2))
                    width: 8
                    height: 8
                    radius: 4
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                onPressed: mouse => playerController.setVolume(Math.max(0.0, Math.min(1.0, mouse.x / trackItem.width)))
                onPositionChanged: mouse => {
                    if (pressed)
                        playerController.setVolume(Math.max(0.0, Math.min(1.0, mouse.x / trackItem.width)))
                }
            }
        }
    }
}
