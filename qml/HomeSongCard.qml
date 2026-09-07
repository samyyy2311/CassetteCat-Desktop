import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var track: ({})
    property real cardWidth: 150
    property real cardHeight: 225

    signal clicked()

    width: cardWidth
    height: cardHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            id: coverBox
            Layout.preferredWidth: root.cardWidth
            Layout.preferredHeight: root.cardWidth
            radius: 12
            clip: true
            color: surfaceCard
            border.width: 1
            border.color: cardMouse.containsMouse ? borderVariant : borderSubtle
            scale: cardMouse.containsMouse ? 1.03 : 1.0

            Behavior on scale {
                NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
            }

            Cover {
                anchors.fill: parent
                track: root.track
                radius: 12
            }

            TransportButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                buttonSize: 38
                iconName: "play"
                accented: true
                iconColor: recordRed
                opacity: cardMouse.containsMouse ? 1.0 : 0.0
                scale: cardMouse.containsMouse ? 1.0 : 0.6
                z: 10

                Behavior on opacity { NumberAnimation { duration: 150 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                onClicked: root.clicked()
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.track.title || root.track.fileName
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            Layout.fillWidth: true
            text: root.track.artist || "Unknown Artist"
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
