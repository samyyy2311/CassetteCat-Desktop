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
    radius: height / 2
    color: {
        if (mouseArea.containsMouse) {
            if (root.destructive) return Qt.rgba(1, 0.15, 0.15, 0.18)
            if (root.primary) return (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#2E2A27")
            return (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#282623")
        }
        if (root.destructive) return "transparent"
        if (root.primary) return (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#262320")
        return (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917")
    }
    border.width: 1
    border.color: {
        if (root.destructive) return mouseArea.containsMouse ? root.accentHoverColor : Qt.rgba(1, 0.25, 0.25, 0.35)
        if (root.primary) return root.accentColor
        return mouseArea.containsMouse ? (typeof borderVariant !== "undefined" ? borderVariant : "#2C2926") : (typeof borderSubtle !== "undefined" ? borderSubtle : "#22201D")
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
            color: root.destructive ? root.accentHoverColor : (root.primary ? root.accentHoverColor : (mouseArea.containsMouse ? textPrimary : textSecondary))

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Label {
            text: root.text
            color: root.destructive ? root.accentHoverColor : (root.primary ? root.accentHoverColor : (mouseArea.containsMouse ? textPrimary : textSecondary))
            font.family: (typeof monoFont !== "undefined" ? monoFont : "IBM Plex Mono")
            font.pixelSize: 11
            font.weight: root.primary ? Font.Bold : (root.destructive ? Font.DemiBold : Font.Medium)
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
            color: root.destructive ? root.accentHoverColor : (root.primary ? root.accentHoverColor : (mouseArea.containsMouse ? textPrimary : textSecondary))

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
