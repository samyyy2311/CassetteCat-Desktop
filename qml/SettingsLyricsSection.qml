import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int lyricsFontSize: 28
    property string lyricsAlignment: "left"
    property string lyricsActiveStyle: "white"
    property bool preferLocalLyrics: true
    property string lyricsFont
    property int lyricsFontWeight: Font.Bold
    property var fontFamilies: []
    property bool libraryLyricsEnabled: false
    property bool lrclibAvailable: true

    signal lyricsFontSizeSelected(int value)
    signal lyricsAlignmentSelected(string value)
    signal lyricsActiveStyleSelected(string value)
    signal preferLocalLyricsSelected(bool value)
    signal lyricsFontSelected(string value)
    signal lyricsFontWeightSelected(int value)
    signal libraryLyricsSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Typography & Layout") }

    SettingCard {
        SettingRow {
            iconName: "a-large-small"
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
            iconName: "align-left"
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
            iconName: "palette"
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

        SettingDivider {}

        SettingChoiceGroup {
            iconName: "type"
            title: qsTr("Lyrics Font")
            subtitle: qsTr("Any font installed on this computer")
            forceMenu: true
            options: [{ value: "", label: qsTr("Same as App") }].concat(
                root.fontFamilies.map(family => ({ value: family, label: family, font: family })))
            selectedValue: root.lyricsFont
            onOptionSelected: val => root.lyricsFontSelected(String(val))
        }

        SettingDivider {}

        SettingRow {
            iconName: "bold"
            title: qsTr("Lyrics Weight")
            subtitle: qsTr("How bold the lyric lines are")

            SettingSegmentedControl {
                options: [
                    { value: Font.Normal, label: qsTr("Regular") },
                    { value: Font.Medium, label: qsTr("Medium") },
                    { value: Font.DemiBold, label: qsTr("SemiBold") },
                    { value: Font.Bold, label: qsTr("Bold") }
                ]
                selectedValue: root.lyricsFontWeight
                onOptionSelected: val => root.lyricsFontWeightSelected(Number(val))
            }
        }
    }

    SectionLabel { text: qsTr("Local Files") }

    SettingCard {
        SettingRow {
            iconName: "file-text"
            title: qsTr("Prefer Local .lrc Files")
            subtitle: qsTr("Load sidecar .lrc files before querying online providers")

            SettingSwitch {
                checked: root.preferLocalLyrics
                onToggled: val => root.preferLocalLyricsSelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Search") }

    SettingCard {
        SettingRow {
            iconName: "search"
            title: qsTr("Find Songs by Their Lyrics")
            subtitle: {
                if (!root.libraryLyricsEnabled)
                    return qsTr("Downloads lyrics for your songs, so you can search by a line")
                if (!root.lrclibAvailable)
                    return qsTr("Paused while LrcLib Lyrics is off or Offline Mode is on")
                if (services.libraryLyricsTotal === 0)
                    return qsTr("Looking up lyrics…")
                if (services.libraryLyricsLeft > 0)
                    return qsTr("%n song(s) left to check", "", services.libraryLyricsLeft)
                return qsTr("%1 of %2 songs have lyrics").arg(services.libraryLyricsFound).arg(services.libraryLyricsTotal)
            }

            SettingSwitch {
                checked: root.libraryLyricsEnabled
                onToggled: val => root.libraryLyricsSelected(val)
            }
        }
    }
}
