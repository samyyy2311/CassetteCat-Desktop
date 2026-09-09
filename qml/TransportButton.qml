import QtQuick

Item {
    id: root
    property string iconName: "play"
    property int buttonSize: 36
    property bool accented: false
    property var paletteSource: null
    property color accentColor: paletteSource ? paletteSource.recordRed : "#C23B30"
    property color accentHover: paletteSource ? paletteSource.recordRedHover : "#D64337"
    readonly property color recordRed: accentColor
    readonly property color recordRedHover: accentHover
    property color iconColor: accented ? root.accentColor : root.textPrimary
    property bool filled: true
    property string tooltipText: ""
    signal clicked()

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize

    readonly property color surfaceContainerHigh: "#22201D"
    readonly property color surfaceContainerHover: "#2C2A26"
    readonly property color surfaceContainerLowest: "#161513"
    readonly property color outlineVariant: "#2C2926"
    readonly property color silverDim: "#6E6C68"
    readonly property color textPrimary: "#F5F0EC"
    readonly property color textSecondary: "#A8A29A"

    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isHovered: mouseArea.containsMouse

    Rectangle {
        id: cap
        anchors.fill: parent
        y: root.isPressed ? 1.5 : 0
        radius: width / 2
        color: root.isPressed 
            ? root.surfaceContainerLowest 
            : (root.isHovered 
                ? root.surfaceContainerHover 
                : (root.filled ? root.surfaceContainerHigh : "transparent"))

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        border.width: root.accented ? 1.2 : (root.isHovered ? 1.0 : 0)
        border.color: root.accented
            ? (root.isHovered ? root.recordRedHover : root.recordRed)
            : (root.isHovered ? "#35FFFFFF" : "transparent")

        Behavior on border.color { ColorAnimation { duration: 150 } }

        LucideIcon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.iconName === "play" ? 1.0 : 0
            width: Math.max(14, Math.round(root.buttonSize * 0.44))
            height: Math.max(14, Math.round(root.buttonSize * 0.44))
            icon: root.iconName
            color: root.accented
                ? root.recordRedHover
                : (root.isHovered ? root.textPrimary : root.iconColor)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    AppToolTip {
        text: root.tooltipText
        visibleTarget: mouseArea.containsMouse
    }
}
