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
    property string appFont
    property var fontFamilies: []
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true

    signal accentSelected(string value)
    signal customAccentSelected(string hexColor)
    signal albumArtRadiusSelected(int value)
    signal nowPlayingBackdropSelected(string value)
    signal showRemainingTimeSelected(bool value)
    signal appFontSelected(string value)
    signal trackDensitySelected(string value)
    signal showFormatBadgesSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Font") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "type"
            title: qsTr("App Font")
            subtitle: qsTr("Any font installed on this computer, for all of CassetteCat's text")
            forceMenu: true
            options: [{ value: "", label: qsTr("Default") }].concat(
                root.fontFamilies.map(family => ({ value: family, label: family, font: family })))
            selectedValue: root.appFont
            onOptionSelected: val => root.appFontSelected(String(val))
        }
    }

    SectionLabel { text: qsTr("Color Scheme") }

    SettingCard {
        SettingRow {
            iconName: "palette"
            title: qsTr("Accent Colour")
            subtitle: qsTr("Applied to active navigation, selected controls, playback, seek bars, and volume")
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
                label: qsTr("Custom")
                selected: root.accentName === "custom"
                icon: selected ? "check" : "sliders-horizontal"
                onClicked: colorPicker.open()
            }
        }

    }

    SectionLabel { text: qsTr("Cover Art & Backdrop") }

    SettingCard {
        SettingRow {
            iconName: "square"
            title: qsTr("Album Art Corners")
            subtitle: qsTr("Corner roundness for artwork thumbnails and cards")

            SettingSegmentedControl {
                options: [
                    { value: 0, label: qsTr("Square") },
                    { value: 8, label: qsTr("Soft") },
                    { value: 16, label: qsTr("Rounded") }
                ]
                selectedValue: root.albumArtRadius
                onOptionSelected: val => root.albumArtRadiusSelected(Number(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "image"
            title: qsTr("Now Playing Backdrop")
            subtitle: qsTr("Moving slowly shifts the cover's colors, and uses more graphics memory")

            SettingSegmentedControl {
                options: [
                    { value: "tinted", label: qsTr("Tinted") },
                    { value: "moving", label: qsTr("Moving") },
                    { value: "clean", label: qsTr("Clean") }
                ]
                selectedValue: root.nowPlayingBackdrop
                onOptionSelected: val => root.nowPlayingBackdropSelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Track Lists") }

    SettingCard {
        SettingRow {
            iconName: "list"
            title: qsTr("Track Row Density")
            subtitle: qsTr("Vertical spacing for song rows in track lists")

            SettingSegmentedControl {
                options: [
                    { value: "comfortable", label: qsTr("Comfortable") },
                    { value: "compact", label: qsTr("Compact") }
                ]
                selectedValue: root.trackDensity
                onOptionSelected: val => root.trackDensitySelected(String(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "file-audio"
            title: qsTr("Audio Format Badges")
            subtitle: qsTr("Show FLAC, MP3, and AAC badges on track rows and in Now Playing")

            SettingSwitch {
                checked: root.showFormatBadges
                onToggled: val => root.showFormatBadgesSelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Time Counter") }

    SettingCard {
        SettingRow {
            iconName: "clock"
            title: qsTr("Time Display")
            subtitle: qsTr("Show remaining time countdown or total track duration")

            SettingSegmentedControl {
                options: [
                    { value: true, label: qsTr("Remaining") },
                    { value: false, label: qsTr("Total") }
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
