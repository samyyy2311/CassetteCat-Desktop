import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string iconName: ""
    property color iconColor: "transparent"
    property string title: ""
    property string subtitle: ""
    property bool showDivider: false
    property bool preserveIconColor: false
    property int iconSize: 20
    default property alias control: trailing.data

    Layout.fillWidth: true
    Layout.minimumHeight: 56
    spacing: 16

    readonly property color accentColor: recordRed
    readonly property color accentHoverColor: recordRedHover

    LucideIcon {
        visible: root.iconName.length > 0
        Layout.preferredWidth: root.iconSize
        Layout.preferredHeight: root.iconSize
        Layout.alignment: Qt.AlignVCenter
        icon: root.iconName
        preserveColor: root.preserveIconColor
        color: root.preserveIconColor ? "transparent" : (root.iconColor.a > 0 ? root.iconColor : textSecondary)
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 3

        Label {
            Layout.fillWidth: true
            text: root.title
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            Layout.fillWidth: true
            visible: root.subtitle.length > 0
            text: root.subtitle
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }
    }

    Row {
        id: trailing
        Layout.alignment: Qt.AlignVCenter
        spacing: 8
    }
}
