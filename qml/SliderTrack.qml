import QtQuick

// The groove, fill and knob of the seek bar and the volume slider. It thickens and shows its knob while active.
Item {
    id: root
    property real fraction: 0
    property bool active: false
    property bool animateFill: false
    property color fillColor: recordRed
    readonly property real fillWidth: Math.round(width * Math.max(0, Math.min(1, fraction)))

    implicitHeight: 14

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: root.active ? 6 : 4
        radius: height / 2
        color: Qt.rgba(1, 1, 1, 0.14)

        Behavior on height { NumberAnimation { duration: UiConstants.durationFast; easing.type: UiConstants.easingStd } }

        Rectangle {
            width: root.fillWidth
            height: parent.height
            radius: height / 2
            color: root.fillColor

            Behavior on width {
                enabled: root.animateFill
                NumberAnimation { duration: 250 }
            }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.active ? 12 : 0
        height: width
        radius: width / 2
        x: Math.max(0, Math.min(root.width - width, root.fillWidth - width / 2))
        color: "#FFFFFF"

        Behavior on width { NumberAnimation { duration: UiConstants.durationFast; easing.type: UiConstants.easingStd } }
    }
}
