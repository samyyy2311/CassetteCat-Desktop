import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property var options: []
    property var selectedValue: ""
    readonly property bool useMenu: options.length > 3
    signal optionSelected(var value)

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

    Item {
        Layout.alignment: Qt.AlignVCenter
        Layout.preferredWidth: root.useMenu ? menuButton.implicitWidth : segmentedControl.implicitWidth
        Layout.preferredHeight: root.useMenu ? menuButton.implicitHeight : segmentedControl.implicitHeight

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
            width: Math.max(menuButton.width, 180)
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
