import QtQuick

ButtonBase {
    id: root
    property string iconName: ""
    property int boxSize: 36
    property int iconSize: 18
    property color tint: textPrimary
    property color hoverTint: "#FFFFFF"
    // The website's button face; buttons over artwork or inside a group turn it off and use a flat colour.
    property bool face: true
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: backgroundColor
    property color borderColor: capBorder
    property color hoverBorderColor: capBorderHover
    property bool highlighted: false
    property alias accented: root.highlighted
    property real cornerRadius: Math.round(boxSize / 2)

    implicitWidth: root.boxSize
    implicitHeight: root.boxSize

    // Pressed, the whole button sinks a little, as on the website.
    transform: Translate {
        y: root.isPressed ? 2 : 0
        Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.Linear } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.isHovered ? root.hoverBackgroundColor : root.backgroundColor
        gradient: root.face ? capFace : null
        border.width: root.highlighted ? 1.5 : 1.0
        border.color: root.highlighted ? (root.isHovered ? recordRedHover : recordRed)
                                       : (root.isHovered ? root.hoverBorderColor : root.borderColor)

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }

        Gradient {
            id: capFace
            GradientStop { position: 0; color: capTop }
            GradientStop { position: 1; color: capBottom }
        }
    }

    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize

        LucideIcon {
            anchors.fill: parent
            icon: root.iconName
            color: root.highlighted ? recordRedHover : (root.isHovered ? root.hoverTint : root.tint)
        }
    }
}
