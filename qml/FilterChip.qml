import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    property string iconName: ""
    property bool selected: false

    signal clicked()

    readonly property color contentColor: selected ? recordRedHover : (chipMouse.containsMouse ? textPrimary : textSecondary)

    implicitWidth: chipContent.implicitWidth + 20
    implicitHeight: 28
    radius: height / 2
    color: selected ? "#262320" : (chipMouse.containsMouse ? surfaceElevated : surfaceTag)
    border.width: 1
    border.color: selected ? recordRed : (chipMouse.containsMouse ? borderVariant : borderSubtle)

    Accessible.role: Accessible.RadioButton
    Accessible.name: text
    Accessible.checked: selected
    Accessible.onPressAction: root.clicked()

    Behavior on color { ColorAnimation { duration: UiConstants.durationFast } }
    Behavior on border.color { ColorAnimation { duration: UiConstants.durationFast } }

    RowLayout {
        id: chipContent
        anchors.centerIn: parent
        spacing: 6

        LucideIcon {
            visible: root.iconName.length > 0
            Layout.preferredWidth: 12
            Layout.preferredHeight: 12
            icon: root.iconName
            color: root.contentColor
        }

        Label {
            text: root.text
            color: root.contentColor
            font.family: monoFont
            font.pixelSize: 11
            font.weight: root.selected ? Font.Bold : Font.DemiBold
        }
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
