import QtQuick

Item {
    id: root

    property string text: ""
    property color textColor: "white"
    property string fontFamily: ""
    property int pixelSize: 16
    property int weight: Font.Normal

    implicitHeight: label.implicitHeight
    clip: true

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        x: hover.containsMouse && implicitWidth > root.width ? root.width - implicitWidth : 0
        width: implicitWidth
        text: root.text
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        wrapMode: Text.NoWrap

        Behavior on x { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
    }
}
