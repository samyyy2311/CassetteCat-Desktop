import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: root
    property string title: ""
    property string subtitle: "This cannot be undone"
    property string message: ""
    property string iconName: ""
    // Gives the confirm button the warning look, for actions that remove something.
    property bool destructive: false
    property string confirmText: ""
    property string cancelText: "Cancel"

    signal confirmed()

    maxWidth: 420

    contentItem: ColumnLayout {
        spacing: 16

        DialogHeader {
            iconName: root.iconName
            title: root.title
            subtitle: root.subtitle
        }

        Label {
            Layout.fillWidth: true
            text: root.message
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 10

            Item { Layout.fillWidth: true }

            SettingButton {
                text: root.cancelText
                onClicked: root.close()
            }

            SettingButton {
                text: root.confirmText
                primary: !root.destructive
                destructive: root.destructive
                onClicked: {
                    root.confirmed()
                    root.close()
                }
            }
        }
    }
}
