import QtQuick
import QtQuick.Controls

Column {
    id: root
    property color color
    property string label: ""
    property string icon: ""
    property bool selected: false
    signal clicked()

    spacing: 6
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Rectangle {
        width: 36
        height: 36
        radius: 18
        color: root.color
        border.width: root.selected || root.activeFocus ? 2.5 : 1
        border.color: root.selected || root.activeFocus ? textPrimary : borderSubtle
        scale: swatchMouse.pressed ? 0.92 : (swatchMouse.containsMouse ? 1.08 : 1.0)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

        LucideIcon {
            visible: root.icon.length > 0
            anchors.centerIn: parent
            width: 16
            height: 16
            icon: root.icon
            color: "#FFFFFF"
        }

        MouseArea {
            id: swatchMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.label
        color: root.selected ? textPrimary : textSecondary
        font.family: displayFont
        font.pixelSize: 10
        font.weight: root.selected ? Font.Bold : Font.Medium
    }
}
