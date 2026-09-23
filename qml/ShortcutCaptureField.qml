import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string shortcut: ""
    property bool allowPlainKey: false
    signal shortcutCaptured(string shortcut)

    implicitHeight: 28
    implicitWidth: Math.max(64, shortcutText.implicitWidth + 24)
    radius: 14
    color: activeFocus ? "#262320" : (fieldMouse.containsMouse ? "#262320" : "#1A1816")
    border.width: 1
    border.color: activeFocus ? recordRed : (fieldMouse.containsMouse ? borderVariant : "#2A2825")
    enabled: true
    Accessible.role: Accessible.Button
    Accessible.name: "Keyboard shortcut " + shortcut

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

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
        if (!key || (!root.allowPlainKey && !(modifiers & (Qt.ControlModifier | Qt.AltModifier)))) return

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
        id: shortcutText
        anchors.centerIn: parent
        text: root.activeFocus ? "Press keys..." : root.shortcut
        color: root.activeFocus ? recordRedHover : (fieldMouse.containsMouse ? textPrimary : textSecondary)
        font.family: monoFont
        font.pixelSize: 11
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: fieldMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.forceActiveFocus()
    }
}
