import QtQuick
import QtQuick.Controls

Item {
    id: root

    readonly property color accentColor: (typeof window !== "undefined" && window.recordRedHover) ? window.recordRedHover : "#E11D48"
    readonly property color barBgColor: (typeof window !== "undefined" && window.surfaceCard) ? window.surfaceCard : "#1B1917"

    // Indeterminate progress bar along the top edge
    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2.5
        clip: true

        Rectangle {
            anchors.fill: parent
            color: root.barBgColor
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

            SequentialAnimation on x {
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
