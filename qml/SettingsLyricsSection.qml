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

    SectionLabel { text: qsTr("Typography & Layout") }

    SettingCard {
        SettingRow {
            iconName: "quote"
            title: qsTr("Lyrics Font Size")
            subtitle: qsTr("Relative scale of lyric lines in synchronized view")

            SettingSegmentedControl {
                options: [
                    { value: 24, label: qsTr("Small") },
                    { value: 28, label: qsTr("Default") },
                    { value: 32, label: qsTr("Large") }
                ]
                selectedValue: root.lyricsFontSize
                onOptionSelected: val => root.lyricsFontSizeSelected(Number(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "list"
            title: qsTr("Text Alignment")
            subtitle: qsTr("Horizontal alignment of synced lyric text")

            SettingSegmentedControl {
                options: [
                    { value: "left", label: qsTr("Left") },
                    { value: "center", label: qsTr("Center") }
                ]
                selectedValue: root.lyricsAlignment
                onOptionSelected: val => root.lyricsAlignmentSelected(String(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "pencil"
            title: qsTr("Active Line Color")
            subtitle: qsTr("Highlight styling for currently playing lyrics")

            SettingSegmentedControl {
                options: [
                    { value: "accent", label: qsTr("Accent") },
                    { value: "white", label: qsTr("White") }
                ]
                selectedValue: root.lyricsActiveStyle
                onOptionSelected: val => root.lyricsActiveStyleSelected(String(val))
            }
        }
    }

    SectionLabel { text: qsTr("Local Files") }

    SettingCard {
        SettingRow {
            iconName: "folder"
            title: qsTr("Prefer Local .lrc Files")
            subtitle: qsTr("Load sidecar .lrc files before querying online providers")

            SettingSwitch {
                checked: root.preferLocalLyrics
                onToggled: val => root.preferLocalLyricsSelected(val)
            }
        }
    }
}
