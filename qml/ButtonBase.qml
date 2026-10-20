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
    // A button reached with Tab takes Space before the play/pause shortcut does. One focused by a click leaves
    // Space to the shortcut, or Space would press whatever was clicked last.
    Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Space && !root.mouseFocused
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat && !root.mouseFocused) root.clicked() }

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
