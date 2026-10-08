import QtQuick
import QtQuick.Controls

// A centred card over a dimmed window, shared by the app's dialogs.
Popup {
    property int maxWidth: 440

    parent: Overlay.overlay
    modal: true
    focus: true
    x: Math.round(((parent ? parent.width : 800) - width) / 2)
    y: Math.round(((parent ? parent.height : 600) - height) / 2)
    width: Math.min((parent ? parent.width - 64 : maxWidth), maxWidth)
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle { color: "#B8000000" }

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
}
