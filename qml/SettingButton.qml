import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    property string iconName: ""
    property bool iconRight: false
    property bool preserveIconColor: false
    property bool primary: false
    property bool destructive: false
    property string accessibleName: text
    signal clicked()

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#C23B30")
    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337")

    implicitWidth: contentRow.implicitWidth + 22
    implicitHeight: 32
    radius: 8
    color: {
        if (mouseArea.containsMouse) {
            if (root.destructive) return Qt.rgba(1, 0.15, 0.15, 0.18)
            if (root.primary) return root.accentHoverColor
            return (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#282623")
        }
        if (root.destructive) return "transparent"
        if (root.primary) return root.accentColor
        return (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917")
    }
    border.width: root.primary ? 0 : (mouseArea.containsMouse || root.destructive ? 1 : 0)
    border.color: {
        if (root.destructive) return mouseArea.containsMouse ? Qt.rgba(1, 0.35, 0.35, 0.5) : Qt.rgba(1, 0.25, 0.25, 0.25)
        if (root.primary) return "transparent"
        return mouseArea.containsMouse ? (typeof borderVariant !== "undefined" ? borderVariant : Qt.rgba(255, 255, 255, 0.09)) : "transparent"
    }
    Accessible.name: root.accessibleName
    Accessible.role: Accessible.Button

    scale: mouseArea.pressed ? 0.97 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        LucideIcon {
            visible: root.iconName.length > 0 && !root.iconRight
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconName
            preserveColor: root.preserveIconColor
            color: root.primary ? "#FFFFFF" : (root.destructive ? (mouseArea.containsMouse ? "#FF6B6B" : Qt.rgba(1, 0.45, 0.45, 0.9)) : (mouseArea.containsMouse ? textPrimary : textSecondary))

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Label {
            text: root.text
            color: root.primary ? "#FFFFFF" : (root.destructive ? (mouseArea.containsMouse ? "#FF6B6B" : Qt.rgba(1, 0.45, 0.45, 0.9)) : (mouseArea.containsMouse ? textPrimary : textSecondary))
            font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
            font.pixelSize: 12
            font.weight: root.primary ? Font.Bold : Font.DemiBold
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        LucideIcon {
            visible: root.iconName.length > 0 && root.iconRight
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconName
            preserveColor: root.preserveIconColor
            color: root.primary ? "#FFFFFF" : (root.destructive ? (mouseArea.containsMouse ? "#FF6B6B" : Qt.rgba(1, 0.45, 0.45, 0.9)) : (mouseArea.containsMouse ? textPrimary : textSecondary))

            Behavior on color { ColorAnimation { duration: 120 } }
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
