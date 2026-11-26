import QtQuick

// What sits behind a dropdown or menu item while it's hovered or reached with the keyboard.
Rectangle {
    property bool highlighted: false

    radius: height / 2
    color: highlighted ? surfaceCardHover : "transparent"

    Behavior on color { ColorAnimation { duration: 90 } }
}
