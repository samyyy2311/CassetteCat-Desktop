import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int trackCount: 0
    property string libraryFolder: ""
    property var excludedFolders: []
    property bool ignoreShortClips: false
    property string defaultLaunchPage: "last"
    property string songSortMetric: "title"
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true

    signal chooseFolderRequested()
    signal addExcludeRequested()
    signal removeExcludeRequested(string path)
    signal ignoreShortClipsSelected(bool value)
    signal defaultLaunchPageSelected(string value)
    signal songSortSelected(string value)
    signal trackDensitySelected(string value)
    signal showFormatBadgesSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Audio Folders" }

    SettingCard {
        SettingRow {
            iconName: "folder"
            title: "Audio Directory"
            subtitle: root.libraryFolder.length > 0
                      ? (root.libraryFolder + " • " + root.trackCount + " songs")
                      : (root.trackCount + " tracks loaded from library")

            SettingButton {
                text: "Choose folder"
                iconName: "folder"
                onClicked: root.chooseFolderRequested()
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "folder"
            title: "Excluded Folders"
            subtitle: root.excludedFolders.length === 0 ? "No exclusions. Every subfolder is scanned" : (root.excludedFolders.length + " folder(s) hidden from the library")

            SettingButton {
                text: "Exclude folder"
                iconName: "folder"
                onClicked: root.addExcludeRequested()
            }
        }

        Repeater {
            model: root.excludedFolders
            delegate: RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 0
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                spacing: 10

                Label {
                    Layout.fillWidth: true
                    text: modelData
                    color: textSecondary
                    font.family: monoFont
                    font.pixelSize: 10
                    elide: Text.ElideMiddle
                }

                SettingButton {
                    text: "Remove"
                    destructive: true
                    onClicked: root.removeExcludeRequested(modelData)
                }
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "audio-lines"
            title: "Ignore Short Clips"
            subtitle: "Hide audio tracks shorter than 30 seconds from library and search"

            SettingSwitch {
                checked: root.ignoreShortClips
                onToggled: val => root.ignoreShortClipsSelected(val)
            }
        }
    }

    SectionLabel { text: "Startup & Navigation" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "compass"
            title: "Default Launch Page"
            subtitle: "View displayed immediately upon opening CassetteCat"
            options: [
                { value: "last", label: "LAST VISITED" },
                { value: "home", label: "HOME" },
                { value: "library", label: "LIBRARY" },
                { value: "radio", label: "RADIO" },
                { value: "search", label: "SEARCH" },
                { value: "settings", label: "SETTINGS" }
            ]
            selectedValue: root.defaultLaunchPage
            onOptionSelected: val => root.defaultLaunchPageSelected(val)
        }
    }

    SectionLabel { text: "Display & Sorting" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "arrow-up-down"
            title: "Default Library Sort"
            subtitle: "Default track order for songs listing"
            options: [
                { value: "title", label: "TITLE" },
                { value: "artist", label: "ARTIST" },
                { value: "album", label: "ALBUM" },
                { value: "duration", label: "DURATION" }
            ]
            selectedValue: root.songSortMetric
            onOptionSelected: val => root.songSortSelected(val)
        }

        SettingDivider {}

        SettingRow {
            iconName: "sliders-horizontal"
            title: "Track Row Density"
            subtitle: "Vertical spacing for song rows in track lists"

            SettingSegmentedControl {
                options: [
                    { value: "comfortable", label: "COMFORTABLE" },
                    { value: "compact", label: "COMPACT" }
                ]
                selectedValue: root.trackDensity
                onOptionSelected: val => root.trackDensitySelected(val)
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "disc"
            title: "Audio Format Badges"
            subtitle: "Show FLAC, MP3, and AAC badges on track rows"

            SettingSwitch {
                checked: root.showFormatBadges
                onToggled: val => root.showFormatBadgesSelected(val)
            }
        }
    }
}
