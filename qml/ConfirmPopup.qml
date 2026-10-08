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

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: root.title
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Label {
                    text: root.subtitle
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 11
                }
            }
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
