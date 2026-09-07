import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property bool showDivider: false
    default property alias control: trailing.data

    Layout.fillWidth: true
    Layout.minimumHeight: 52
    spacing: 10

    LucideIcon {
        visible: root.iconName.length > 0
        Layout.preferredWidth: 17
        Layout.preferredHeight: 17
        Layout.alignment: Qt.AlignVCenter
        icon: root.iconName
        color: silverDim
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
