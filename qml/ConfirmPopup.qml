import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property string title: ""
    property string subtitle: "This cannot be undone"
    property string message: ""
    // Styles the confirm button as a warning, for actions that remove something.
    property bool destructive: false
    property string confirmText: ""
    property string cancelText: "Cancel"

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

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: UiConstants.durationFast }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: UiConstants.durationFast }
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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: root.title
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Label {
                    text: root.subtitle
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
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
