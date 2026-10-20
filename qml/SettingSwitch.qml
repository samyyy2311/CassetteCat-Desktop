import QtQuick

Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 46
    implicitHeight: 26
    radius: 13
    color: root.checked
        ? (mouseArea.containsMouse ? recordRedHover : recordRed)
        : (mouseArea.containsMouse ? surfaceCardHover : surfaceElevated)
    opacity: root.enabled ? 1.0 : 0.4
    // Off, the track keeps an outline so it doesn't disappear into the card behind it.
    border.width: root.activeFocus ? 2 : (root.checked ? 0 : 1)
    border.color: root.activeFocus
        ? recordRedHover
        : borderVariant

    activeFocusOnTab: true
    Accessible.role: Accessible.CheckBox
    Accessible.name: qsTr("Switch")
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
            : (mouseArea.containsMouse ? textSecondary : silverDim)

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
        // Not focused by a click, so Space afterwards still plays and pauses instead of flipping the switch.
        onClicked: root.toggled(!root.checked)
    }
}
