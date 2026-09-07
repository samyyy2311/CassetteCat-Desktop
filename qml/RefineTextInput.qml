import QtQuick

Rectangle {
    id: root
    property string placeholder: ""
    property alias text: input.text
    property int echoMode: TextInput.Normal
    property bool isPassword: false
    readonly property bool showPasswordToggle: isPassword || echoMode === TextInput.Password
    property bool passwordVisible: false
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
        anchors.rightMargin: root.showPasswordToggle ? 38 : 12
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.showPasswordToggle ? (root.passwordVisible ? TextInput.Normal : TextInput.Password) : root.echoMode
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
            elide: Text.ElideRight
        }
    }

    Item {
        visible: root.showPasswordToggle
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24

        LucideIcon {
            anchors.centerIn: parent
            width: 16
            height: 16
            icon: root.passwordVisible ? "eye-off" : "eye"
            color: eyeMouse.containsMouse ? textPrimary : silverDim
        }

        MouseArea {
            id: eyeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.passwordVisible = !root.passwordVisible
        }

        AppToolTip {
            text: root.passwordVisible ? "Hide password" : "Show password"
            visibleTarget: eyeMouse.containsMouse
            below: true
        }
    }
}
