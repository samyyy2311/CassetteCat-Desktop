import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Label {
    id: root

    color: (typeof recordRedHover !== "undefined" ? recordRedHover : "#D14337")
    font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
    font.pixelSize: 11
    font.weight: Font.Bold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1.2
    Layout.leftMargin: 4
    Layout.topMargin: 14
    Layout.bottomMargin: 4
}
