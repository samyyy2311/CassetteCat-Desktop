import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string iconName: "play"
    property int buttonSize: 36
    property bool accented: false
    property color iconColor: accented ? root.recordRed : root.textPrimary
    property bool filled: false
    signal clicked()

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize

    readonly property color recordRed: "#C23B30"
    readonly property color recordRedHover: "#D64337"
    readonly property color surfaceContainerHigh: "#24221F"
    readonly property color surfaceContainerLowest: "#161513"
    readonly property color outlineVariant: "#2C2926"
    readonly property color silverDim: "#6E6C68"
    readonly property color textPrimary: "#F5F0EC"
    readonly property color textSecondary: "#A8A29A"

    readonly property bool isPressed: mouseArea.pressed
    readonly property bool isHovered: mouseArea.containsMouse

    Rectangle {
        id: shadow
        anchors.fill: parent
        anchors.topMargin: root.isPressed ? 0 : 2
        anchors.bottomMargin: root.isPressed ? 0 : -2
        radius: width / 2
        color: "#40000000"
        visible: !root.isPressed

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }
    }

    Rectangle {
        id: cap
        anchors.fill: parent
        y: root.isPressed ? 2 : 0
        radius: width / 2

        Behavior on y {
            NumberAnimation { duration: 80; easing.type: Easing.Linear }
        }

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: root.accented
                    ? (root.isHovered ? "#321A18" : "#241412")
                    : (root.isHovered ? "#282623" : root.surfaceContainerHigh)
            }
            GradientStop {
                position: 1.0
                color: root.accented
                    ? (root.isHovered ? "#200E0C" : "#180B0A")
                    : (root.isHovered ? "#181715" : root.surfaceContainerLowest)
            }
        }

        border.width: 1.0
        border.color: root.accented
            ? (root.isHovered ? "#75D64337" : "#48C23B30")
            : (root.isHovered ? "#2CFFFFFF" : "#12FFFFFF")

        Behavior on border.color { ColorAnimation { duration: 150 } }

        LucideIcon {
            anchors.centerIn: parent
            width: Math.max(14, Math.round(root.buttonSize * 0.44))
            height: Math.max(14, Math.round(root.buttonSize * 0.44))
            icon: root.iconName
            color: root.accented
                ? (root.isHovered ? "#FFFFFF" : root.recordRedHover)
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
}
