import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int trackCount: 0
    property var libraryFolders: []
    property var excludedFolders: []
    property bool ignoreShortClips: false
    property string songSortMetric: "title"
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true

    signal addLibraryFolderRequested()
    signal removeLibraryFolderRequested(string path)
    signal addExcludeRequested()
    signal removeExcludeRequested(string path)
    signal ignoreShortClipsSelected(bool value)
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
                onClicked: root.addLibraryFolderRequested()
            }
        }

        SettingsPathList {
            paths: root.libraryFolders
            onRemoveRequested: path => root.removeLibraryFolderRequested(path)
        }

        SettingDivider {}

        SettingRow {
            iconName: "eye-off"
            title: "Excluded Folders"
            subtitle: root.excludedFolders.length === 0 ? "No exclusions. Every subfolder is scanned" : (root.excludedFolders.length + " folder(s) hidden from the library")

            SettingButton {
                text: "Exclude folder"
                onClicked: root.addExcludeRequested()
            }
        }

        SettingsPathList {
            paths: root.excludedFolders
            onRemoveRequested: path => root.removeExcludeRequested(path)
        }
    }

    SectionLabel { text: "Library Filtering" }

    SettingCard {
        SettingRow {
            iconName: "clock"
            title: "Ignore Short Clips"
            subtitle: "Hide audio tracks shorter than 30 seconds from library and search"

            SettingSwitch {
                checked: root.ignoreShortClips
                onToggled: val => root.ignoreShortClipsSelected(val)
            }
        }
    }

    SectionLabel { text: "Display & Sorting" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "arrow-up-down"
            title: "Default Library Sort"
            subtitle: "Default track order for songs listing"
            options: [
                { value: "title", label: "Title" },
                { value: "artist", label: "Artist" },
                { value: "album", label: "Album" },
                { value: "duration", label: "Duration" }
            ]
            selectedValue: root.songSortMetric
            onOptionSelected: val => root.songSortSelected(String(val))
        }

        SettingDivider {}

        SettingRow {
            iconName: "list"
            title: "Track Row Density"
            subtitle: "Vertical spacing for song rows in track lists"

            SettingSegmentedControl {
                options: [
                    { value: "comfortable", label: "Comfortable" },
                    { value: "compact", label: "Compact" }
                ]
                selectedValue: root.trackDensity
                onOptionSelected: val => root.trackDensitySelected(String(val))
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
