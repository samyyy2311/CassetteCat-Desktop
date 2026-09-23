import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property alias text: labelText.text

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#D14337")
    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#FF5C4D")

    Layout.leftMargin: 4
    Layout.topMargin: 20
    Layout.bottomMargin: 6
    spacing: 8

    Rectangle {
        Layout.preferredWidth: 3
        Layout.preferredHeight: 12
        radius: 1.5
        color: root.accentColor
    }

    Label {
        id: labelText
        color: root.accentHoverColor
        font.family: (typeof monoFont !== "undefined" ? monoFont : "IBM Plex Mono")
        font.pixelSize: 11
        font.weight: Font.Bold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.1
    }
}
