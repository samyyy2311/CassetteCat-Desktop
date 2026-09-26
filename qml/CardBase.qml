import QtQuick

Rectangle {
    id: root
    property string accessibleName: ""
    // Only keyboard focus shows the hover state.
    readonly property bool highlighted: cardMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false

    signal clicked()
    signal rightClicked()

    color: "transparent"
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    // Declared first so buttons inside a card stay above it.
    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            root.mouseFocused = true
            root.forceActiveFocus()
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                root.rightClicked()
            else
                root.clicked()
        }
    }
}
