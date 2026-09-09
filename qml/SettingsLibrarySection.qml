import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int trackCount: 0
    property var libraryFolders: []
    property var excludedFolders: []
    property bool ignoreShortClips: false
    property string defaultLaunchPage: "last"
    property string songSortMetric: "title"
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true

    signal addLibraryFolderRequested()
    signal removeLibraryFolderRequested(string path)
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
            title: "Audio Folders"
            subtitle: root.libraryFolders.length > 0
                      ? (root.libraryFolders.length + " folder(s) • " + root.trackCount + " songs")
                      : (root.trackCount + " tracks loaded from library")

            SettingButton {
                text: "Add folder"
                iconName: "folder"
                onClicked: root.addLibraryFolderRequested()
            }
        }

        SettingsPathList {
            paths: root.libraryFolders
            onRemoveRequested: path => root.removeLibraryFolderRequested(path)
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

        SettingsPathList {
            paths: root.excludedFolders
            onRemoveRequested: path => root.removeExcludeRequested(path)
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
