import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

CardBase {
    id: root
    property string name: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 190
    property real cardHeight: 110
    property real cardRadius: 14

    accessibleName: root.name

    width: cardWidth
    height: cardHeight
    radius: cardRadius
    clip: true
    color: root.highlighted ? surfaceElevated : surfaceCard
    border.width: 1
    border.color: root.highlighted ? recordRed : borderSubtle
    scale: root.highlighted ? 1.03 : 1.0

    Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on color { ColorAnimation { duration: 120 } }

    Cover {
        anchors.fill: parent
        track: root.track
        radius: root.cardRadius
        opacity: 0.28
        visible: !!(root.track && root.track.filePath)
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#25000000" }
            GradientStop { position: 1.0; color: Qt.alpha(surfaceCard, 0.88) }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.minimumWidth: 0
            text: root.name
            color: root.highlighted ? recordRedHover : textPrimary
            font.family: displayFont
            font.pixelSize: 15
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Label {
            text: root.count + (root.count === 1 ? " track" : " tracks")
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
        }
    }
}
