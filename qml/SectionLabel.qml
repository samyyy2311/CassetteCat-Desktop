import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property alias text: labelText.text

    readonly property color labelColor: (typeof textSecondary !== "undefined" ? textSecondary : "#8E8A84")

    Layout.fillWidth: true
    Layout.leftMargin: 8
    Layout.topMargin: 18
    Layout.bottomMargin: 4
    implicitHeight: labelText.implicitHeight + 2

    Label {
        id: labelText
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.labelColor
        font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
        font.letterSpacing: 1.2
    }
}
