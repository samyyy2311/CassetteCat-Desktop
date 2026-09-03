import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string name: ""
    property string artist: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 235
    property real imageRadius: 12

    signal clicked()

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
                radius: root.imageRadius
                color: surfaceCard
                clip: true
                border.width: albumCardMouse.containsMouse ? 1.5 : 0
                border.color: albumCardMouse.containsMouse ? recordRed : "transparent"
                scale: albumCardMouse.containsMouse ? 1.03 : 1.0

                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: root.imageRadius
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.imageRadius
                    color: "transparent"
                    border.width: 1
                    border.color: "#15FFFFFF"
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
                text: root.name
                color: albumCardMouse.containsMouse ? recordRedHover : textPrimary
                font.family: displayFont
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.artist ? root.artist : (root.count + " songs")
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
        id: albumCardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
