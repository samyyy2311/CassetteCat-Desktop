import QtQuick
import QtQuick.Controls

Row {
    id: root
    property var tabs: [] // [{ id, label }]
    property string current: ""

    signal selected(string id)

    spacing: 22

    Repeater {
        model: root.tabs

        Item {
            id: tab
            required property var modelData
            readonly property bool active: root.current === modelData.id

            width: tabLabel.implicitWidth
            height: 32

            Accessible.role: Accessible.PageTab
            Accessible.name: modelData.label
            Accessible.onPressAction: root.selected(modelData.id)

            Label {
                id: tabLabel
                anchors.centerIn: parent
                text: tab.modelData.label
                color: tab.active ? textPrimary : textSecondary
                font.family: displayFont
                font.pixelSize: 15
                font.weight: tab.active ? Font.Bold : Font.Medium
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2.5
                radius: 1.25
                color: recordRed
                visible: tab.active
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(tab.modelData.id)
            }
        }
    }
}
