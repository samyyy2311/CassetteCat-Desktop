import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string title: ""
    property string subtitle: ""
    property string actionText: ""
    property string actionIcon: ""
    property real leftMargin: 32
    property real rightMargin: 32

    signal actionClicked()

    Layout.fillWidth: true
    Layout.leftMargin: root.leftMargin
    Layout.rightMargin: root.rightMargin
    spacing: 12

    ColumnLayout {
        spacing: 2
        Label {
            text: root.title
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 18
            font.weight: Font.Bold
        }
        Label {
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: silverDim
            font.family: monoFont
            font.pixelSize: 11
        }
    }

    Item { Layout.fillWidth: true }

    Rectangle {
        visible: root.actionText.length > 0 || root.actionIcon.length > 0
        Layout.preferredHeight: 28
        Layout.preferredWidth: actionLbl.implicitWidth + (root.actionIcon.length > 0 ? 30 : 20)
        radius: 14
        color: actionMouse.containsMouse ? "#20FFFFFF" : "#10FFFFFF"
        border.width: 1
        border.color: actionMouse.containsMouse ? "#40FFFFFF" : borderSubtle

        Behavior on color { ColorAnimation { duration: 150 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            LucideIcon {
                visible: root.actionIcon.length > 0
                Layout.preferredWidth: 12
                Layout.preferredHeight: 12
                icon: root.actionIcon
                color: recordRedHover
            }
            Label {
                id: actionLbl
                text: root.actionText
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionClicked()
        }
    }
}
