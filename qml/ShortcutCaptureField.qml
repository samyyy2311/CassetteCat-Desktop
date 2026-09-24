import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string shortcut: ""
    property bool allowPlainKey: false
    property bool allowClear: false
    property bool isShortcutCapture: true
    signal shortcutCaptured(string shortcut)

    implicitHeight: 28
    implicitWidth: Math.max(76, contentLayout.implicitWidth + 20)
    radius: 6
    color: activeFocus ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#282623") : (fieldMouse.containsMouse ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#22201D") : (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917"))
    border.width: activeFocus ? 1.5 : (fieldMouse.containsMouse ? 1 : 0)
    border.color: activeFocus ? (typeof accentColor !== "undefined" ? accentColor : "#C23B30") : (fieldMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : "transparent")
    enabled: true
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: "Keyboard shortcut " + (shortcut || "None")

    property string currentModifiersText: ""

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
        case Qt.Key_Tab: return "Tab"
        case Qt.Key_Return: case Qt.Key_Enter: return "Return"
        case Qt.Key_Home: return "Home"
        case Qt.Key_End: return "End"
        case Qt.Key_PageUp: return "PageUp"
        case Qt.Key_PageDown: return "PageDown"
        case Qt.Key_Minus: return "-"
        case Qt.Key_Equal: return "Equal"
        case Qt.Key_Plus: return "Plus"
        case Qt.Key_BracketLeft: return "["
        case Qt.Key_BracketRight: return "]"
        case Qt.Key_Semicolon: return ";"
        case Qt.Key_Apostrophe: return "'"
        case Qt.Key_Comma: return ","
        case Qt.Key_Period: return "."
        case Qt.Key_Slash: return "/"
        case Qt.Key_Backslash: return "\\"
        default: return ""
        }
    }

    Keys.priority: Keys.BeforeItem

    Keys.onReleased: function(event) {
        if (root.activeFocus) {
            updateModifiersText(event.modifiers)
            event.accepted = true
        }
    }

    function updateModifiersText(modifiers) {
        const parts = []
        if (modifiers & Qt.ControlModifier) parts.push("Ctrl")
        if (modifiers & Qt.AltModifier) parts.push("Alt")
        if (modifiers & Qt.ShiftModifier) parts.push("Shift")
        root.currentModifiersText = parts.length > 0 ? parts.join("+") + "+..." : ""
    }

    Keys.onPressed: function(event) {
        event.accepted = true

        if (event.key === Qt.Key_Escape) {
            root.currentModifiersText = ""
            root.focus = false
            return
        }

        if (root.allowClear && (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete)) {
            if (event.modifiers === Qt.NoModifier) {
                root.currentModifiersText = ""
                root.shortcutCaptured("")
                root.focus = false
                return
            }
        }

        if (event.key === Qt.Key_Control || event.key === Qt.Key_Alt || event.key === Qt.Key_Shift || event.key === Qt.Key_Meta) {
            updateModifiersText(event.modifiers)
            return
        }

        const key = root.keyName(event.key)
        const modifiers = event.modifiers
        if (!key) return
        if (!root.allowPlainKey && !(modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            return
        }

        const parts = []
        if (modifiers & Qt.ControlModifier) parts.push("Ctrl")
        if (modifiers & Qt.AltModifier) parts.push("Alt")
        if (modifiers & Qt.ShiftModifier) parts.push("Shift")
        parts.push(key)

        root.currentModifiersText = ""
        root.shortcutCaptured(parts.join("+"))
        root.focus = false
    }

    RowLayout {
        id: contentLayout
        anchors.centerIn: parent
        spacing: 4

        Label {
            id: shortcutText
            text: {
                if (root.activeFocus) {
                    return root.currentModifiersText.length > 0 ? root.currentModifiersText : "Press keys..."
                }
                return root.shortcut.length > 0 ? root.shortcut : "None"
            }
            color: root.activeFocus
                ? textPrimary
                : (root.shortcut.length > 0 ? textPrimary : textSecondary)
            font.family: (typeof monoFont !== "undefined" ? monoFont : "IBM Plex Mono")
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: fieldMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.currentModifiersText = ""
            root.forceActiveFocus()
        }
    }
}
