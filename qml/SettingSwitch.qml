import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    radius: 13
    color: root.checked
        ? (mouseArea.containsMouse ? (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337") : (typeof recordRed !== "undefined" ? recordRed : "#C23B30"))
        : (mouseArea.containsMouse ? "#201E1C" : "#181715")
    opacity: root.enabled ? 1.0 : 0.4
    border.width: root.activeFocus ? 2 : 1
    border.color: root.activeFocus
        ? (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337")
        : (root.checked ? (mouseArea.containsMouse ? (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337") : (typeof recordRed !== "undefined" ? recordRed : "#C23B30")) : (mouseArea.containsMouse ? "#3A3632" : borderVariant))

    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: "Switch"
    Accessible.checked: root.checked

    Keys.onSpacePressed: event => {
        event.accepted = true
        root.toggled(!root.checked)
    }
    Keys.onReturnPressed: event => {
        event.accepted = true
        root.toggled(!root.checked)
    }

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    Rectangle {
        id: thumb
        y: 4
        x: root.checked ? root.width - width - 4 : 4
        width: 18
        height: 18
        radius: 9
        color: root.checked
            ? "#FFFFFF"
            : (mouseArea.containsMouse ? "#B5B0AA" : "#96918A")

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
        Behavior on color { ColorAnimation { duration: 140 } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.forceActiveFocus()
            root.toggled(!root.checked)
        }
    }
}
