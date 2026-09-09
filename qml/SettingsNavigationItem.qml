import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string iconName: ""
    property bool selected: false
    property bool compact: false
    signal clicked()

    implicitWidth: compact ? content.implicitWidth + 22 : 184
    implicitHeight: compact ? 34 : 42
    radius: compact ? 17 : 10
    color: selected ? (compact ? recordRed : surfaceCard) : (mouse.containsMouse ? surfaceCardHover : "transparent")
    border.width: selected && compact ? 0 : 1
    border.color: selected ? recordRed : borderSubtle
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.checked: selected

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: compact ? 11 : 12
        anchors.rightMargin: compact ? 11 : 12
        spacing: 8

        LucideIcon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            icon: root.iconName
            color: root.selected ? (root.compact ? "white" : recordRedHover) : silverDim
        }

        Label {
            Layout.fillWidth: !root.compact
            text: root.label
            color: root.selected ? textPrimary : textSecondary
            font.family: displayFont
            font.pixelSize: 12
            font.weight: root.selected ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
