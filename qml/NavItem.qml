import QtQuick
import QtQuick.Controls

Item {
    id: root
    required property var appWindow
    required property real sidebarWidth
    required property bool sidebarCollapsed
    property string destination: "home"
    property string iconName: ""
    property string label: ""
    property bool preserveIconColor: false

    implicitWidth: sidebarWidth
    implicitHeight: 40
    width: sidebarWidth
    height: 40
    readonly property bool selected: appWindow.page === destination && !appWindow.nowPlayingOpen

    Rectangle {
        id: navCard
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: root.sidebarCollapsed ? 44 : 180
        height: 40
        radius: 8
        color: root.selected
            ? root.appWindow.surfaceElevated
            : (navMouse.containsMouse ? root.appWindow.surfaceCardHover : "transparent")
        border.width: root.selected ? 1 : 0
        border.color: root.selected ? root.appWindow.borderVariant : "transparent"

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            visible: root.selected
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            width: 3
            height: 16
            radius: 1.5
            color: root.appWindow.recordRed
        }

        LucideIcon {
            id: navIcon
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.sidebarCollapsed ? 12 : 14
            width: 20
            height: 20
            icon: root.iconName
            preserveColor: root.selected && root.preserveIconColor
            color: root.selected
                ? root.appWindow.recordRedHover
                : (navMouse.containsMouse ? root.appWindow.textSecondary : root.appWindow.silverDim)

            Behavior on anchors.leftMargin { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Label {
            anchors.left: navIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.selected
                ? root.appWindow.textPrimary
                : (navMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary)
            font.family: root.appWindow.displayFont
            font.pixelSize: 13
            font.weight: root.selected ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
            visible: !root.sidebarCollapsed && opacity > 0.01
            opacity: Math.max(0.0, Math.min(1.0, (root.sidebarWidth - 90) / 110))
        }
    }

    MouseArea {
        id: navMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.appWindow.nowPlayingOpen = false
            root.appWindow.page = root.destination
        }
    }
}
