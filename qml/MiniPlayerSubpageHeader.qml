import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var miniPlayer

    height: 44
    z: 30

    MouseArea {
        anchors.fill: parent
        z: 0
        property point pressPos
        onPressed: mouse => pressPos = Qt.point(mouse.x, mouse.y)
        onPositionChanged: mouse => {
            if (Math.abs(mouse.x - pressPos.x) > 3 || Math.abs(mouse.y - pressPos.y) > 3) {
                root.miniPlayer.startSystemMove()
            }
        }
        onDoubleClicked: root.miniPlayer.restoreRequested()
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        z: 1

        Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 6
            clip: true
            color: root.miniPlayer.surfaceCard
            border.width: 1
            border.color: root.miniPlayer.borderCard

            Cover {
                anchors.fill: parent
                radius: 6
                track: root.miniPlayer.playerController.currentTrack
                fillMode: Image.PreserveAspectCrop
                visible: !!(root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath)
            }

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
                fillMode: Image.PreserveAspectFit
                visible: !(root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.miniPlayer.mode = "art"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: (root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.title)
                    ? root.miniPlayer.playerController.currentTrack.title : "CassetteCat"
                color: root.miniPlayer.textPrimary
                font.family: root.miniPlayer.displayFont
                font.pixelSize: 12
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                text: (root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.artist)
                    ? root.miniPlayer.playerController.currentTrack.artist : ""
                color: root.miniPlayer.textSecondary
                font.family: root.miniPlayer.bodyFont
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }
    }

    Rectangle {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: subControlsRow.implicitWidth + 8
        height: 26
        radius: 13
        color: root.miniPlayer.surfaceElevated
        border.width: 1
        border.color: root.miniPlayer.borderCard
        z: 10

        Row {
            id: subControlsRow
            anchors.centerIn: parent
            spacing: 2
            padding: 2

            Rectangle {
                width: 22; height: 22; radius: 11
                color: root.miniPlayer.alwaysOnTop ? root.miniPlayer.recordRed : (subPinH.containsMouse ? "#25FFFFFF" : "transparent")
                scale: subPinH.pressed ? 0.90 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 11; height: 11
                    icon: "pin"
                    color: root.miniPlayer.alwaysOnTop ? "#FFFFFF" : (subPinH.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim)
                }
                MouseArea {
                    id: subPinH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.toggleAlwaysOnTop()
                }
                AppToolTip {
                    text: root.miniPlayer.alwaysOnTop ? "Unpin from top" : "Keep on top"
                    visibleTarget: subPinH.containsMouse
                    delay: 350
                }
            }

            Rectangle {
                width: 22; height: 22; radius: 11
                color: subMinH.containsMouse ? "#25FFFFFF" : "transparent"
                scale: subMinH.pressed ? 0.90 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 11; height: 11
                    icon: "minus"
                    color: subMinH.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim
                }
                MouseArea {
                    id: subMinH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.showMinimized()
                }
                AppToolTip {
                    text: "Minimize"
                    visibleTarget: subMinH.containsMouse
                    delay: 350
                }
            }

            Rectangle {
                width: 22; height: 22; radius: 11
                color: subPopH.containsMouse ? "#25FFFFFF" : "transparent"
                scale: subPopH.pressed ? 0.90 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 11; height: 11
                    icon: "pip"
                    color: subPopH.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim
                }
                MouseArea {
                    id: subPopH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.mode = "compact"
                }
                AppToolTip {
                    text: "Compact mode"
                    visibleTarget: subPopH.containsMouse
                    delay: 350
                }
            }

            Rectangle {
                width: 22; height: 22; radius: 11
                color: subExpH.containsMouse ? "#25FFFFFF" : "transparent"
                scale: subExpH.pressed ? 0.90 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 11; height: 11
                    icon: "maximize-2"
                    color: subExpH.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim
                }
                MouseArea {
                    id: subExpH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.restoreRequested()
                }
                AppToolTip {
                    text: "Restore full player"
                    visibleTarget: subExpH.containsMouse
                    delay: 350
                }
            }

            Rectangle {
                width: 22; height: 22; radius: 11
                color: subCloseH.containsMouse ? "#E53935" : "transparent"
                scale: subCloseH.pressed ? 0.90 : 1.0
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                LucideIcon {
                    anchors.centerIn: parent
                    width: 11; height: 11
                    icon: "x"
                    color: subCloseH.containsMouse ? "#FFFFFF" : root.miniPlayer.silverDim
                }
                MouseArea {
                    id: subCloseH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.closeRequested()
                }
                AppToolTip {
                    text: "Close miniplayer"
                    visibleTarget: subCloseH.containsMouse
                    delay: 350
                }
            }
        }
    }
}
