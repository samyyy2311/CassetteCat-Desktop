import QtQuick
import QtQuick.Controls

Item {
    id: root

    readonly property color accentColor: recordRedHover

    // Indeterminate progress bar along the top edge
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2.5
        clip: true

        Rectangle {
            anchors.fill: parent
            color: surfaceCard
            opacity: 0.3
        }

        Rectangle {
            id: indicatorBar
            width: parent.width * 0.35
            height: parent.height
            radius: 1.25
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.accentColor }
                GradientStop { position: 1.0; color: "transparent" }
            }

            // A running animation redraws the whole window every frame, so it only runs while the bar shows.
            SequentialAnimation on x {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation {
                    from: -indicatorBar.width
                    to: root.width
                    duration: 1100
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
