import QtQuick

Item {
    id: root
    property string iconName: ""
    property int boxSize: 40
    property int iconSize: 20
    property color tint: "#A8A29A"
    property color hoverTint: "#F5F0EC"
    signal clicked()

    implicitWidth: root.boxSize
    implicitHeight: root.boxSize

    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isHovered: mouseArea.containsMouse

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
            color: root.isHovered ? root.hoverTint : root.tint
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
