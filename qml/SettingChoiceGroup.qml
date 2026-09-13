import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SettingRow {
    id: root
    property var options: []
    property var selectedValue: ""
    property bool forceMenu: false
    readonly property bool useMenu: forceMenu || options.length > 3
    signal optionSelected(var value)

    Item {
        implicitWidth: root.useMenu ? menuButton.implicitWidth : segmentedControl.implicitWidth
        implicitHeight: root.useMenu ? menuButton.implicitHeight : segmentedControl.implicitHeight

        SettingSegmentedControl {
            id: segmentedControl
            visible: !root.useMenu
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            options: root.options
            selectedValue: root.selectedValue
            onOptionSelected: value => root.optionSelected(value)
        }

        SettingButton {
            id: menuButton
            visible: root.useMenu
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: {
                for (let i = 0; i < root.options.length; ++i) {
                    const option = root.options[i]
                    const value = (option && typeof option === "object" && "value" in option) ? option.value : option
                    if (root.selectedValue === value || String(root.selectedValue).toLowerCase() === String(value).toLowerCase())
                        return (option && typeof option === "object" && "label" in option) ? option.label : String(option)
                }
                return "Choose"
            }
            iconName: "chevron-down"
            primary: true
            onClicked: choiceMenu.open()
        }

        Menu {
            id: choiceMenu
            y: menuButton.height + 6
            width: Math.max(menuButton.width, 220)
            padding: 6

            background: Rectangle {
                color: surfaceCard
                radius: 10
                border.width: 1
                border.color: borderVariant
            }

            Repeater {
                model: root.options
                delegate: MenuItem {
                    readonly property var optionValue: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                    readonly property string optionLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                    readonly property bool isSelected: root.selectedValue === optionValue || String(root.selectedValue).toLowerCase() === String(optionValue).toLowerCase()
                    width: choiceMenu.width - choiceMenu.leftPadding - choiceMenu.rightPadding
                    height: 34
                    onTriggered: root.optionSelected(optionValue)

                    contentItem: Label {
                        text: optionLabel
                        color: isSelected ? recordRedHover : textPrimary
                        font.family: displayFont
                        font.pixelSize: 11
                        font.weight: isSelected ? Font.Bold : Font.Medium
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        radius: 7
                        color: parent.highlighted ? "#2A2825" : "transparent"
                        border.width: isSelected ? 1 : 0
                        border.color: recordRed
                    }
                }
            }
        }
    }
}
