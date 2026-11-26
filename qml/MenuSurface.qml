import QtQuick

// The panel every dropdown and menu shares.
Rectangle {
    radius: 14
    gradient: Gradient {
        GradientStop { position: 0; color: menuTop }
        GradientStop { position: 1; color: menuBottom }
    }
    border.width: 1
    border.color: capBorder
}
