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

    readonly property color accentColor: recordRed
    readonly property color accentHoverColor: recordRedHover

    implicitWidth: contentRow.implicitWidth + 22
    implicitHeight: 32
    radius: height / 2
    // A main action has an accent border and text, a destructive one a red border and text.
    readonly property color contentColor: root.destructive ? (mouseArea.containsMouse ? danger : Qt.alpha(danger, 0.9))
        : root.primary ? root.accentHoverColor
        : (mouseArea.containsMouse ? textPrimary : textSecondary)
    color: "transparent"
    Accessible.name: root.accessibleName
    Accessible.role: Accessible.Button

    ButtonFace {
        anchors.fill: parent
        hovered: mouseArea.containsMouse
        accented: root.primary || root.destructive
        accentColor: root.destructive ? Qt.alpha(danger, 0.6) : root.accentColor
        accentHoverColor: root.destructive ? danger : root.accentHoverColor
        border.width: root.primary ? 1.5 : 1
    }

    transform: Translate {
        y: mouseArea.pressed ? 2 : 0
        Behavior on y { NumberAnimation { duration: 80; easing.type: Easing.Linear } }
    }

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
            color: root.contentColor

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Label {
            text: root.text
            color: root.contentColor
            font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
            font.pixelSize: 12
            font.weight: Font.DemiBold
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
            color: root.contentColor

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
