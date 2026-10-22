import QtQuick

// The face every button shares, the same as the website's: a dark gradient with a thin border that lightens on hover,
// and an accent border for the main or selected one. A flat face drops the gradient for buttons over artwork or
// inside a group.
Rectangle {
    property bool hovered: false
    property bool accented: false
    property bool flat: false
    property color accentColor: recordRed
    property color accentHoverColor: recordRedHover

    radius: height / 2
    color: "transparent"
    gradient: flat ? null : face
    border.width: accented ? 1.5 : 1
    border.color: accented ? (hovered ? accentHoverColor : accentColor) : (hovered ? capBorderHover : capBorder)

    Behavior on border.color { ColorAnimation { duration: 120 } }

    Gradient {
        id: face
        GradientStop { position: 0; color: capTop }
        GradientStop { position: 1; color: capBottom }
    }
}
