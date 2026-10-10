import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "ThemeColors.js" as ThemeColors

ColumnLayout {
    id: root
    property string accentName
    property string customAccentColor
    property var theme
    property string themeStatus
    property int albumArtRadius: 16
    property string nowPlayingBackdrop: "tinted"
    property bool showRemainingTime: true

    readonly property bool isDefaultTheme: ["background", "text", "textMuted"].every(key => theme[key] === defaultTheme[key])
    // Measured on the lightest surface, where light text has the least contrast.
    readonly property real themeContrast: Math.min(ThemeColors.contrast(textPrimary, surfaceElevated),
                                                   ThemeColors.contrast(textSecondary, surfaceElevated),
                                                   ThemeColors.contrast(silverDim, surfaceElevated))
    readonly property string themeWarning: {
        if (ThemeColors.luminance(surfaceBase) > ThemeColors.luminance(textPrimary))
            return "Light backgrounds aren't supported yet, so parts of the app will be hard to read"
        if (themeContrast < 4.5)
            return "Some text is hard to read with these colours (" + themeContrast.toFixed(1) + ":1, it needs 4.5:1)"
        return ""
    }

    signal accentSelected(string value)
    signal customAccentSelected(string hexColor)
    signal themeSelected(var theme)
    signal themeImportRequested()
    signal themeExportRequested()
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

    SettingCard {
        SettingRow {
            iconName: "eye"
            title: "Theme Colours"
            subtitle: root.themeStatus.length > 0
                ? root.themeStatus
                : "Cards, menus and fields are shaded from the background. Export a theme to share it with your accent"

            SettingButton {
                text: "Import"
                onClicked: root.themeImportRequested()
            }

            SettingButton {
                text: "Export"
                onClicked: root.themeExportRequested()
            }

            SettingButton {
                visible: !root.isDefaultTheme
                text: "Reset"
                iconName: "rotate-ccw"
                onClicked: root.themeSelected(defaultTheme)
            }
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            spacing: 14

            Repeater {
                model: [
                    { key: "background", label: "Background" },
                    { key: "text", label: "Text" },
                    { key: "textMuted", label: "Muted Text" }
                ]
                delegate: ColorSwatch {
                    required property var modelData
                    color: root.theme[modelData.key]
                    label: modelData.label
                    onClicked: {
                        themePicker.key = modelData.key
                        themePicker.title = modelData.label + " Colour"
                        themePicker.currentColor = root.theme[modelData.key]
                        themePicker.open()
                    }
                }
            }
        }

        Label {
            visible: root.themeWarning.length > 0
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            text: root.themeWarning
            color: danger
            font.family: bodyFont
            font.pixelSize: 12
            wrapMode: Text.WordWrap
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
        id: themePicker
        property string key
        presets: []
        onColorApplied: hex => root.themeSelected(Object.assign({}, root.theme, { [key]: hex.toUpperCase() }))
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
