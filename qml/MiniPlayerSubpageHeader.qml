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

    Row {
        id: controls
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        z: 1

        Rectangle {
            width: 20; height: 20; radius: 3; color: "transparent"
            LucideIcon { anchors.centerIn: parent; width: 11; height: 11; icon: "pin"; color: root.miniPlayer.alwaysOnTop ? root.miniPlayer.recordRed : root.miniPlayer.silverDim }
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.toggleAlwaysOnTop() }
        }

        Rectangle {
            width: 20; height: 20; radius: 3; color: "transparent"
            LucideIcon { anchors.centerIn: parent; width: 11; height: 11; icon: "pip"; color: root.miniPlayer.silverDim }
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.mode = "compact" }
        }

        Rectangle {
            width: 20; height: 20; radius: 3; color: "transparent"
            Label { anchors.centerIn: parent; text: "✕"; color: root.miniPlayer.silverDim; font.pixelSize: 10 }
            MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.closeRequested() }
        }
    }
}
