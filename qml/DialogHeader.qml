import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// The badge, title and subtitle at the top of a dialog. Extra children, such as a close button, go on the right.
RowLayout {
    id: root
    property string iconName
    property url imageSource
    property string title
    property string subtitle

    Layout.fillWidth: true
    spacing: 12

    Rectangle {
        visible: root.iconName !== ""
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 18
        color: "transparent"
        border.width: 1
        border.color: recordRed

        LucideIcon {
            anchors.centerIn: parent
            width: 18
            height: 18
            icon: root.iconName
            color: recordRed
        }
    }

    Image {
        visible: root.imageSource.toString() !== ""
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        source: root.imageSource
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Label {
            Layout.fillWidth: true
            text: root.title
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            visible: root.subtitle !== ""
            Layout.fillWidth: true
            text: root.subtitle
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }
}
