import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root
    hoverEnabled: true
    policy: ScrollBar.AsNeeded
    minimumSize: 0.04
    visible: policy !== ScrollBar.AlwaysOff && size > 0 && size < 0.999
    opacity: visible && (active || hovered || pressed) ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }

    contentItem: Rectangle {
        visible: root.visible
        implicitWidth: root.hovered ? 6 : 4
        implicitHeight: root.hovered ? 6 : 4
        radius: width / 2
        color: root.pressed ? "#D14337" : (root.hovered ? "#D0FFFFFF" : "#60FFFFFF")

        Behavior on implicitWidth { NumberAnimation { duration: 100 } }
        Behavior on implicitHeight { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
