import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property var options: []
    property var selectedValue: ""
    property var currentVal: selectedValue
    signal optionSelected(var value)

    onSelectedValueChanged: currentVal = selectedValue

    Layout.fillWidth: true
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        LucideIcon {
            visible: root.iconName.length > 0
            Layout.preferredWidth: 17
            Layout.preferredHeight: 17
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconName
            color: silverDim
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Label {
                Layout.fillWidth: true
                text: root.title
                color: textPrimary
                font.family: displayFont
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                visible: root.subtitle.length > 0
                text: root.subtitle
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        Layout.leftMargin: 0
        spacing: 8

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: pillItem
                readonly property var optVal: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                readonly property string optLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                readonly property bool isSelected: root.currentVal !== undefined && (root.currentVal === optVal || String(root.currentVal).toLowerCase() === String(optVal).toLowerCase())

                height: 30
                width: pillLabel.implicitWidth + 24
                radius: 15
                color: isSelected ? recordRed : (pillMouse.containsMouse ? "#2A2825" : "#1A1917")
                border.width: 1
                border.color: isSelected ? recordRedHover : (pillMouse.containsMouse ? borderVariant : borderSubtle)
                scale: pillMouse.pressed ? 0.96 : 1.0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                Label {
                    id: pillLabel
                    anchors.centerIn: parent
                    text: pillItem.optLabel
                    color: pillItem.isSelected ? "#FFFFFF" : (pillMouse.containsMouse ? textPrimary : textSecondary)
                    font.family: displayFont
                    font.pixelSize: 11
                    font.weight: pillItem.isSelected ? Font.Bold : Font.Medium
                    font.letterSpacing: 0.5
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentVal = pillItem.optVal
                        root.optionSelected(pillItem.optVal)
                    }
                }
            }
        }
    }
}
