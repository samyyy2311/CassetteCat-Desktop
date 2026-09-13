import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    property string iconName: ""
    property bool preserveIconColor: false
    property bool primary: false
    property bool destructive: false
    property string accessibleName: text
    signal clicked()

    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: 32
    radius: 16
    color: {
        if (mouseArea.containsMouse) {
            if (root.destructive) return mouseArea.containsMouse ? Qt.rgba(1,0.13,0.13,0.18) : "transparent"
            if (root.primary) return "#2A1614"
            return "#2A2825"
        }
        if (root.primary) return "transparent"
        return "#1E1C1A"
    }
    border.width: 1
    border.color: {
        if (root.destructive) return mouseArea.containsMouse ? recordRedHover : recordRed
        if (root.primary) return recordRed
        return mouseArea.containsMouse ? silverDim : borderVariant
    }
    Accessible.name: root.accessibleName
    Accessible.role: Accessible.Button

    scale: mouseArea.pressed ? 0.96 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        LucideIcon {
            visible: root.iconName.length > 0
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconName
            preserveColor: root.preserveIconColor
            color: root.destructive ? recordRedHover : (root.primary ? recordRedHover : textPrimary)
        }

        Label {
            text: root.text
            color: root.destructive ? recordRedHover : (root.primary ? recordRedHover : textPrimary)
            font.family: displayFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }

    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    activeFocusOnTab: true
}
