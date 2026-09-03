import QtQuick

Rectangle {
    id: root
    property string placeholder: ""
    property alias text: input.text
    signal edited(string text)
    signal submitted()

    implicitWidth: 220
    implicitHeight: 36
    radius: 10
    color: surfaceInput
    border.width: 1
    border.color: input.activeFocus ? recordRed : borderSubtle

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: textPrimary
        font.family: displayFont
        font.pixelSize: 13
        selectByMouse: true
        onTextEdited: root.edited(text)
        onAccepted: root.submitted()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: !input.text && !input.activeFocus
            text: root.placeholder
            color: textSecondary
            font: input.font
        }
    }
}
