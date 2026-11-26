import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property int count: 0

    signal clicked()

    readonly property color tint: linkMouse.containsMouse || activeFocus ? recordRedHover : textSecondary

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Accessible.role: Accessible.Link
    Accessible.name: qsTr("See all %1").arg(count)
    Accessible.onPressAction: root.clicked()
    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    // Space opens the list rather than reaching the play/pause shortcut.
    Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Space
    Keys.onSpacePressed: event => { if (!event.isAutoRepeat) root.clicked() }

    RowLayout {
        id: content
        anchors.fill: parent
        spacing: 4

        Label {
            text: qsTr("See all %1").arg(root.count)
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
    }

    MouseArea {
        id: linkMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
