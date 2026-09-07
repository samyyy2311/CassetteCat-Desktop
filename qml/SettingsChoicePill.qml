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
    opacity: root.enabled ? 1.0 : 0.5
    border.width: root.selected ? 1.5 : 1
    border.color: root.selected ? recordRed : (choiceMouse.containsMouse && root.enabled ? "#45FFFFFF" : borderSubtle)

    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Label {
        id: choiceLabel
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? recordRedHover : (choiceMouse.containsMouse && root.enabled ? textPrimary : textSecondary)
        font.family: displayFont
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.6
    }

    MouseArea {
        id: choiceMouse
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
