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

    Rectangle {
        id: cap
        anchors.fill: parent
        y: root.isPressed ? 2 : 0
        radius: width / 2
        color: "transparent"
        gradient: root.filled ? face : null

        Gradient {
            id: face
            GradientStop { position: 0; color: capTop }
            GradientStop { position: 1; color: capBottom }
        }

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }

        border.width: root.accented ? 1.5 : (root.filled || root.isHovered ? 1 : 0)
        border.color: root.accented
            ? (root.isHovered ? root.recordRedHover : root.recordRed)
            : (root.isHovered ? capBorderHover : capBorder)

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
}
