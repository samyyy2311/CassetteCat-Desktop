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

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#C23B30")
    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337")

    implicitWidth: compact ? content.implicitWidth + 22 : 184
    implicitHeight: compact ? 34 : 40
    radius: compact ? 17 : 8
    color: selected
        ? (compact ? root.accentColor : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12))
        : (mouse.containsMouse ? surfaceCardHover : "transparent")
    border.width: (!compact && selected) ? 1 : 0
    border.color: selected ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35) : "transparent"
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.checked: selected

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Rectangle {
        visible: root.selected && !root.compact
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 16
        radius: 1.5
        color: root.accentColor
    }

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: compact ? 11 : 14
        anchors.rightMargin: compact ? 11 : 12
        spacing: 10

        LucideIcon {
            Layout.preferredWidth: 18
            Layout.preferredHeight: 18
            icon: root.iconName
            color: root.selected
                ? (root.compact ? "white" : root.accentHoverColor)
                : (mouse.containsMouse ? textPrimary : silverDim)

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Label {
            Layout.fillWidth: !root.compact
            text: root.label
            color: root.selected
                ? (root.compact ? "white" : textPrimary)
                : (mouse.containsMouse ? textPrimary : textSecondary)
            font.family: displayFont
            font.pixelSize: 13
            font.weight: root.selected ? Font.Bold : Font.Normal
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: 120 } }
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
