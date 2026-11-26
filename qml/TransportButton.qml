import QtQuick

ButtonBase {
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

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize

    ButtonFace {
        id: cap
        anchors.fill: parent
        y: root.isPressed ? 2 : 0
        hovered: root.isHovered
        accented: root.accented
        flat: !root.filled
        accentColor: root.recordRed
        accentHoverColor: root.recordRedHover
        border.width: root.accented ? 1.5 : (root.filled || root.isHovered ? 1 : 0)

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }

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
}
