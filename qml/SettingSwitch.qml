import QtQuick

Rectangle {
    id: root
    property bool checked: false
    property bool isChecked: checked
    signal toggled(bool checked)

    onCheckedChanged: isChecked = checked

    implicitWidth: 42
    implicitHeight: 24
    radius: 12
    color: root.isChecked ? (mouseArea.containsMouse ? recordRedHover : recordRed) : (mouseArea.containsMouse ? "#383531" : "#262421")
    opacity: root.enabled ? 1.0 : 0.4
    border.width: 1
    border.color: root.isChecked ? recordRedHover : (mouseArea.containsMouse ? "#4A4641" : borderVariant)

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    Rectangle {
        id: thumb
        y: 3
        x: root.isChecked ? root.width - width - 3 : 3
        width: 18
        height: 18
        radius: 9
        color: "#FFFFFF"

        Behavior on x {
            NumberAnimation {
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.isChecked = !root.isChecked
            root.toggled(root.isChecked)
        }
    }
}
