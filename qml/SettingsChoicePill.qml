import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string label: ""
    property bool selected: false

    signal clicked()

    implicitWidth: choiceLabel.implicitWidth + 20
    implicitHeight: 28
    radius: 14
    color: "transparent"
    border.width: root.selected ? 1.5 : 1
    border.color: root.selected ? recordRed : (choiceMouse.containsMouse ? "#45FFFFFF" : borderSubtle)

    Behavior on border.color { ColorAnimation { duration: 120 } }

    Label {
        id: choiceLabel
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? recordRedHover : (choiceMouse.containsMouse ? textPrimary : textSecondary)
        font.family: monoFont
        font.pixelSize: 10
        font.weight: Font.Bold
    }

    MouseArea {
        id: choiceMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
