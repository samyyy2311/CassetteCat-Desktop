import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property alias text: labelText.text

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#C23B30")

    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.topMargin: 18
    Layout.bottomMargin: 4
    implicitHeight: labelText.implicitHeight + 2

    Label {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.accentColor
        font.family: (typeof monoFont !== "undefined" ? monoFont : "IBM Plex Mono")
        font.pixelSize: 11
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
    }
}
