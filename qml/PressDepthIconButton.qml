import QtQuick
import QtQuick.Controls

Item {
    id: root
    property string iconName: ""
    property int boxSize: 36
    property int iconSize: 18
    property color tint: textPrimary
    property color hoverTint: "#FFFFFF"
    property bool highlighted: false
    property string tooltipText: ""
    property real cornerRadius: Math.round(boxSize / 2)
    signal clicked()

    implicitWidth: root.boxSize
    implicitHeight: root.boxSize

    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isHovered: mouseArea.containsMouse

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.isHovered ? surfaceElevated : surfaceCard
        border.width: root.highlighted ? 1.5 : 1.0
        border.color: root.highlighted ? recordRed : (root.isHovered ? borderVariant : borderSubtle)

        Behavior on color { ColorAnimation { duration: 130 } }
        Behavior on border.color { ColorAnimation { duration: 130 } }
    }

    Item {
        id: iconContainer
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        y: root.isPressed ? 1.5 : 0

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }

        LucideIcon {
            anchors.fill: parent
            icon: root.iconName
            color: root.highlighted ? recordRedHover : (root.isHovered ? root.hoverTint : root.tint)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    AppToolTip {
        text: root.tooltipText
        visibleTarget: mouseArea.containsMouse && root.tooltipText.length > 0
        delay: 350
    }
}
