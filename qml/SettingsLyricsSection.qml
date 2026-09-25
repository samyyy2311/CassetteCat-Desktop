import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int lyricsFontSize: 28
    property string lyricsAlignment: "left"
    property string lyricsActiveStyle: "white"
    property bool preferLocalLyrics: true

    signal lyricsFontSizeSelected(int value)
    signal lyricsAlignmentSelected(string value)
    signal lyricsActiveStyleSelected(string value)
    signal preferLocalLyricsSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Typography & Layout" }

    SettingCard {
        SettingRow {
            iconName: "quote"
            title: "Lyrics Font Size"
            subtitle: "Relative scale of lyric lines in synchronized view"

            SettingSegmentedControl {
                options: [
                    { value: 24, label: "Small" },
                    { value: 28, label: "Default" },
                    { value: 32, label: "Large" }
                ]
                selectedValue: root.lyricsFontSize
                onOptionSelected: val => root.lyricsFontSizeSelected(Number(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "list"
            title: "Text Alignment"
            subtitle: "Horizontal alignment of synced lyric text"

            SettingSegmentedControl {
                options: [
                    { value: "left", label: "Left" },
                    { value: "center", label: "Center" }
                ]
                selectedValue: root.lyricsAlignment
                onOptionSelected: val => root.lyricsAlignmentSelected(String(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "pencil"
            title: "Active Line Color"
            subtitle: "Highlight styling for currently playing lyrics"

            SettingSegmentedControl {
                options: [
                    { value: "accent", label: "Accent" },
                    { value: "white", label: "White" }
                ]
                selectedValue: root.lyricsActiveStyle
                onOptionSelected: val => root.lyricsActiveStyleSelected(String(val))
            }
        }
    }

    SectionLabel { text: "Local Files" }

    SettingCard {
        SettingRow {
            iconName: "folder"
            title: "Prefer Local .lrc Files"
            subtitle: "Load sidecar .lrc files before querying online providers"

            SettingSwitch {
                checked: root.preferLocalLyrics
                onToggled: val => root.preferLocalLyricsSelected(val)
            }
        }
    }
}
