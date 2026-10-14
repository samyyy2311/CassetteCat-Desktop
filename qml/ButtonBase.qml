import QtQuick

// Hover, press, keyboard and tooltip behaviour shared by the round icon buttons; each button draws itself on top.
Item {
    id: root
    property string tooltipText: ""
    signal clicked()

    readonly property bool isPressed: mouseArea.pressed
    // Only keyboard focus shows the hover state, so a clicked button doesn't stay lit.
    readonly property bool isHovered: mouseArea.containsMouse || (root.activeFocus && !root.mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: root.tooltipText
    Accessible.onPressAction: root.clicked()
    activeFocusOnTab: root.opacity > 0
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    // A focused button takes Space before a window's play/pause shortcut does.
    Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Space
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat) root.clicked() }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            root.mouseFocused = true
            root.forceActiveFocus()
        }
        onClicked: root.clicked()
    }

    AppToolTip {
        targetItem: mouseArea
        text: root.tooltipText
        visibleTarget: mouseArea.containsMouse && root.tooltipText.length > 0
    }
}
