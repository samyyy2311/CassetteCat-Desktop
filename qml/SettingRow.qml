import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string iconName: ""
    property color iconColor: ""
    property string title: ""
    property string subtitle: ""
    property bool showDivider: false
    property bool preserveIconColor: false
    property int iconSize: 20
    default property alias control: trailing.data

    Layout.fillWidth: true
    Layout.minimumHeight: 56
    spacing: 16

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#C23B30")
    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337")

    LucideIcon {
        visible: root.iconName.length > 0
        Layout.preferredWidth: root.iconSize
        Layout.preferredHeight: root.iconSize
        Layout.alignment: Qt.AlignVCenter
        icon: root.iconName
        preserveColor: root.preserveIconColor
        color: root.preserveIconColor ? "transparent" : (root.iconColor != "" ? root.iconColor : root.accentHoverColor)
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
