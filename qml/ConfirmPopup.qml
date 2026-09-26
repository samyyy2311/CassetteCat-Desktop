import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property string title: ""
    property string subtitle: "This cannot be undone"
    property string message: ""
    property string iconName: ""
    property string confirmText: ""

    signal confirmed()

    parent: Overlay.overlay
    modal: true
    focus: true
    x: Math.round(((parent ? parent.width : 800) - width) / 2)
    y: Math.round(((parent ? parent.height : 600) - height) / 2)
    width: Math.min((parent ? parent.width - 64 : 420), 420)
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#B8000000"
    }

    background: Rectangle {
        radius: 14
        color: surfaceCard
        border.width: 1
        border.color: borderSubtle
    }

    contentItem: ColumnLayout {
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: Qt.rgba(1, 0.2, 0.2, 0.12)
                border.width: 1
                border.color: Qt.rgba(1, 0.2, 0.2, 0.25)

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
                text: "Cancel"
                onClicked: root.close()
            }

            SettingButton {
                text: root.confirmText
                iconName: root.iconName
                destructive: true
                onClicked: {
                    root.confirmed()
                    root.close()
                }
            }
        }
    }
}
