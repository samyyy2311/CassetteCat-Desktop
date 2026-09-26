import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property int count: 0

    signal clicked()

    readonly property color tint: linkMouse.containsMouse ? recordRedHover : textSecondary

    spacing: 4

    Accessible.role: Accessible.Link
    Accessible.name: "See all " + count
    Accessible.onPressAction: root.clicked()

    Label {
        text: "See all " + root.count
        color: root.tint
        font.family: bodyFont
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    LucideIcon {
        icon: "chevron-right"
        Layout.preferredWidth: 14
        Layout.preferredHeight: 14
        color: root.tint
    }

    MouseArea {
        id: linkMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
