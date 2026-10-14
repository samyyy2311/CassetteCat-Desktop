import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string accentName
    property string customAccentColor
    property int albumArtRadius: 16
    property string nowPlayingBackdrop: "tinted"
    property bool showRemainingTime: true

    signal accentSelected(string value)
    signal customAccentSelected(string hexColor)
    signal albumArtRadiusSelected(int value)
    signal nowPlayingBackdropSelected(string value)
    signal showRemainingTimeSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Color Scheme" }

    SettingCard {
        SettingRow {
            iconName: "pencil"
            title: "Accent Colour"
            subtitle: "Applied to active navigation, selected controls, playback, seek bars, and volume"
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            spacing: 14

            Repeater {
                model: accentPresets
                delegate: ColorSwatch {
                    required property var modelData
                    color: modelData.base
                    label: modelData.label
                    selected: root.accentName === modelData.id
                    icon: selected ? "check" : ""
                    onClicked: root.accentSelected(modelData.id)
                }
            }

            ColorSwatch {
                color: selected ? root.customAccentColor : surfaceElevated
                label: "Custom"
                selected: root.accentName === "custom"
                icon: selected ? "check" : "sliders-horizontal"
                onClicked: colorPicker.open()
            }
        }

    }

    SectionLabel { text: "Cover Art & Backdrop" }

    SettingCard {
        SettingRow {
            iconName: "disc"
            title: "Album Art Corners"
            subtitle: "Corner roundness for artwork thumbnails and cards"

            SettingSegmentedControl {
                options: [
                    { value: 0, label: "Square" },
                    { value: 8, label: "Soft" },
                    { value: 16, label: "Rounded" }
                ]
                selectedValue: root.albumArtRadius
                onOptionSelected: val => root.albumArtRadiusSelected(Number(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "maximize-2"
            title: "Now Playing Backdrop"
            subtitle: "Visual style of the expanded player backdrop"

            SettingSegmentedControl {
                options: [
                    { value: "tinted", label: "Tinted" },
                    { value: "clean", label: "Clean" }
                ]
                selectedValue: root.nowPlayingBackdrop
                onOptionSelected: val => root.nowPlayingBackdropSelected(val)
            }
        }
    }

    SectionLabel { text: "Time Counter" }

    SettingCard {
        SettingRow {
            iconName: "clock"
            title: "Time Display"
            subtitle: "Show remaining time countdown or total track duration"

            SettingSegmentedControl {
                options: [
                    { value: true, label: "Remaining" },
                    { value: false, label: "Total" }
                ]
                selectedValue: root.showRemainingTime
                onOptionSelected: val => root.showRemainingTimeSelected(Boolean(val))
            }
        }
    }

    SettingColorPicker {
        id: colorPicker
        currentColor: root.customAccentColor
        onColorApplied: hex => {
            root.customAccentColor = hex
            root.customAccentSelected(hex)
            root.accentSelected("custom")
        }
    }
}
