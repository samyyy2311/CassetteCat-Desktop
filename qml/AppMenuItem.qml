import QtQuick
import QtQuick.Controls

MenuItem {
    id: item
    implicitHeight: visible ? 32 : 0
    indicator: null

    contentItem: Row {
        spacing: 10
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10

        LucideIcon {
            visible: item.icon.name.length > 0
            width: 14
            height: 14
            anchors.verticalCenter: parent.verticalCenter
            icon: item.icon.name
            color: item.highlighted || item.checked ? recordRedHover : textPrimary
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: item.text
            color: item.highlighted || item.checked ? recordRedHover : textPrimary
            font.family: displayFont
            font.pixelSize: 12
            font.weight: Font.Medium
        }
    }

    background: MenuHighlight {
        highlighted: item.highlighted
        anchors.fill: parent
        anchors.margins: 2
    }
}
