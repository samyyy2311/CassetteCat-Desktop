import QtQuick
import QtQuick.Templates as T

T.ScrollBar {
    id: root
    hoverEnabled: true
    policy: T.ScrollBar.AlwaysOn
    orientation: Qt.Vertical
    minimumSize: 0.1
    property int edgeMargin: 8
    implicitWidth: orientation === Qt.Vertical ? (root.hovered ? 6 : 4) : (parent ? parent.width : 100)
    implicitHeight: orientation === Qt.Horizontal ? (root.hovered ? 6 : 4) : (parent ? parent.height : 100)
    anchors.right: orientation === Qt.Vertical && parent ? parent.right : undefined
    anchors.rightMargin: orientation === Qt.Vertical ? root.edgeMargin : 0
    anchors.bottom: orientation === Qt.Horizontal && parent ? parent.bottom : undefined
    anchors.bottomMargin: orientation === Qt.Horizontal ? 2 : 0
    z: 9999

    Behavior on implicitWidth { NumberAnimation { duration: 100 } }
    Behavior on implicitHeight { NumberAnimation { duration: 100 } }

    background: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical ? 4 : (root.parent ? root.parent.width : 100)
        implicitHeight: root.orientation === Qt.Horizontal ? 4 : (root.parent ? root.parent.height : 100)
        color: "transparent"
    }

    contentItem: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical ? (root.hovered ? 6 : 4) : (root.parent ? root.parent.width : 100)
        implicitHeight: root.orientation === Qt.Horizontal ? (root.hovered ? 6 : 4) : (root.parent ? root.parent.height : 100)
        radius: 2
        color: root.pressed
            ? (typeof recordRedHover !== "undefined" ? recordRedHover : "#D14337")
            : (root.hovered ? "#D0FFFFFF" : "#60FFFFFF")
        opacity: 1.0

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }
}
