import QtQuick

Item {
    id: root
    property string iconName: "play"
    property int buttonSize: 36
    property bool accented: false
    property color accentColor: window.recordRed
    property color accentHover: window.recordRedHover
    readonly property color recordRed: accentColor
    readonly property color recordRedHover: accentHover
    property color iconColor: accented ? root.accentColor : textPrimary
    property bool filled: true
    property string tooltipText: ""
    signal clicked()

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize

    readonly property bool isPressed: mouseArea.pressed
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

    Rectangle {
        id: cap
        anchors.fill: parent
        y: root.isPressed ? 1.5 : 0
        radius: width / 2
        color: root.isPressed 
            ? surfaceDock 
            : (root.isHovered 
                ? surfaceElevated 
                : (root.filled ? surfaceCardHover : "transparent"))

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        border.width: root.accented ? 1.2 : (root.isHovered ? 1.0 : 0)
        border.color: root.accented
            ? (root.isHovered ? root.recordRedHover : root.recordRed)
            : (root.isHovered ? "#35FFFFFF" : "transparent")

        Behavior on border.color { ColorAnimation { duration: 150 } }

        LucideIcon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.iconName === "play" ? 1.0 : 0
            width: Math.max(14, Math.round(root.buttonSize * 0.44))
            height: Math.max(14, Math.round(root.buttonSize * 0.44))
            icon: root.iconName
            color: root.accented
                ? root.recordRedHover
                : (root.isHovered ? textPrimary : root.iconColor)
        }
    }

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
