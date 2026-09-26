import QtQuick

// Artwork frame shared by the cards, so hover and now-playing states look the same on every page.
Rectangle {
    id: root
    property bool highlighted: false
    property bool current: false

    color: surfaceCard
    clip: true
    scale: highlighted ? 1.03 : 1.0

    Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }

    // Drawn above the artwork; a border on the frame itself would be hidden by it.
    Rectangle {
        anchors.fill: parent
        z: 1
        radius: root.radius
        color: "transparent"
        border.width: root.highlighted || root.current ? 1.5 : 1
        border.color: root.highlighted || root.current ? recordRed : "#15FFFFFF"

        Behavior on border.color { ColorAnimation { duration: UiConstants.durationFast } }
    }
}
