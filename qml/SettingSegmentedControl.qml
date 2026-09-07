import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var options: []
    property var selectedValue: ""
    property var currentVal: selectedValue
    signal optionSelected(var value)

    onSelectedValueChanged: currentVal = selectedValue

    implicitHeight: 32
    implicitWidth: rowLayout.implicitWidth + 8
    radius: 16
    color: "#161513"
    border.width: 1
    border.color: borderSubtle

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: segItem
                readonly property var optVal: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                readonly property string optLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                readonly property bool isSelected: root.currentVal !== undefined && (root.currentVal === optVal || String(root.currentVal).toLowerCase() === String(optVal).toLowerCase())

                height: 26
                width: segLabel.implicitWidth + 16
                radius: 13
                color: isSelected ? recordRed : (segMouse.containsMouse ? "#262421" : "transparent")
                scale: segMouse.pressed ? 0.96 : 1.0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                Label {
                    id: segLabel
                    anchors.centerIn: parent
                    text: segItem.optLabel
                    color: segItem.isSelected ? "#FFFFFF" : (segMouse.containsMouse ? textPrimary : textSecondary)
                    font.family: displayFont
                    font.pixelSize: 11
                    font.weight: segItem.isSelected ? Font.Bold : Font.Medium
                    font.letterSpacing: 0.4
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentVal = segItem.optVal
                        root.optionSelected(segItem.optVal)
                    }
                }
            }
        }
    }
}
