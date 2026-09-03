import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string name: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 224
    property real cardHeight: 104
    property real cardRadius: 14

    signal clicked()

    width: cardWidth
    height: cardHeight
    radius: cardRadius
    clip: true
    color: folderMouse.containsMouse ? surfaceElevated : surfaceCard
    border.width: 1
    border.color: folderMouse.containsMouse ? recordRed : borderSubtle
    scale: folderMouse.containsMouse ? 1.02 : 1.0

    Behavior on scale { NumberAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    Cover {
        anchors.fill: parent
        track: root.track
        radius: root.cardRadius
        opacity: 0.25
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#40000000" }
            GradientStop { position: 1.0; color: "#CC000000" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            LucideIcon {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                icon: "folder"
                color: recordRedHover
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.preferredHeight: 20
                Layout.preferredWidth: fCountLbl.implicitWidth + 12
                radius: 10
                color: "#30FFFFFF"
                Label {
                    id: fCountLbl
                    anchors.centerIn: parent
                    text: root.count + " songs"
                    color: textPrimary
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.minimumWidth: 0
            text: root.name
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 15
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: folderMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
