import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string shortcut: ""
    signal shortcutCaptured(string shortcut)

    implicitWidth: 148
    implicitHeight: 30
    radius: 15
    color: activeFocus ? "#1F1D1A" : "transparent"
    border.width: activeFocus ? 1.5 : 1
    border.color: activeFocus ? recordRed : borderSubtle
    enabled: true
    Accessible.role: Accessible.Button
    Accessible.name: "Keyboard shortcut " + shortcut

    function keyName(key) {
        if (key >= Qt.Key_A && key <= Qt.Key_Z) return String.fromCharCode(key)
        if (key >= Qt.Key_0 && key <= Qt.Key_9) return String.fromCharCode(key)
        if (key >= Qt.Key_F1 && key <= Qt.Key_F24) return "F" + (key - Qt.Key_F1 + 1)
        switch (key) {
        case Qt.Key_Space: return "Space"
        case Qt.Key_Left: return "Left"
        case Qt.Key_Right: return "Right"
        case Qt.Key_Up: return "Up"
        case Qt.Key_Down: return "Down"
        default: return ""
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            root.focus = false
            event.accepted = true
            return
        }
        const key = root.keyName(event.key)
        const modifiers = event.modifiers
        if (!key || !(modifiers & (Qt.ControlModifier | Qt.AltModifier))) return

        const parts = []
        if (modifiers & Qt.ControlModifier) parts.push("Ctrl")
        if (modifiers & Qt.AltModifier) parts.push("Alt")
        if (modifiers & Qt.ShiftModifier) parts.push("Shift")
        parts.push(key)
        root.shortcutCaptured(parts.join("+"))
        root.focus = false
        event.accepted = true
    }

    Label {
        anchors.centerIn: parent
        text: root.activeFocus ? "Press keys..." : root.shortcut
        color: root.activeFocus ? recordRedHover : textSecondary
        font.family: monoFont
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.forceActiveFocus()
    }
}
