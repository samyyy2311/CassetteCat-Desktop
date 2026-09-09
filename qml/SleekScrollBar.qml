import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root
    hoverEnabled: true
    policy: ScrollBar.AsNeeded
    minimumSize: 0.04
    visible: size < 0.999
    opacity: visible && (active || hovered || pressed) ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 140 } }

    contentItem: Rectangle {
        implicitWidth: root.hovered ? 6 : 4
        implicitHeight: root.hovered ? 6 : 4
        radius: width / 2
        color: root.pressed ? "#D14337" : (root.hovered ? "#D0FFFFFF" : "#60FFFFFF")

        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
