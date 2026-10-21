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

    signal addLibraryFolderRequested()
    signal removeLibraryFolderRequested(string path)
    signal addExcludeRequested()
    signal removeExcludeRequested(string path)
    signal ignoreShortClipsSelected(bool value)
    signal songSortSelected(string value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Audio Folders") }

    SettingCard {
        SettingRow {
            iconName: "folder"
            title: qsTr("Audio Folders")
            subtitle: root.libraryFolders.length > 0
                      ? (qsTr("%n folder(s)", "", root.libraryFolders.length) + "  •  " + qsTr("%n song(s)", "", root.trackCount))
                      : qsTr("%n track(s) loaded from library", "", root.trackCount)

            SettingButton {
                text: qsTr("Add folder")
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
            title: qsTr("Excluded Folders")
            subtitle: root.excludedFolders.length === 0 ? qsTr("No exclusions. Every subfolder is scanned") : qsTr("%n folder(s) hidden from the library", "", root.excludedFolders.length)

            SettingButton {
                text: qsTr("Exclude folder")
                onClicked: root.addExcludeRequested()
            }
        }

        SettingsPathList {
            paths: root.excludedFolders
            onRemoveRequested: path => root.removeExcludeRequested(path)
        }
    }

    SectionLabel { text: qsTr("Library Filtering") }

    SettingCard {
        SettingRow {
            iconName: "clock"
            title: qsTr("Ignore Short Clips")
            subtitle: qsTr("Hide audio tracks shorter than 30 seconds from library and search")

            SettingSwitch {
                checked: root.ignoreShortClips
                onToggled: val => root.ignoreShortClipsSelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Sorting") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "arrow-up-down"
            title: qsTr("Default Library Sort")
            subtitle: qsTr("Default track order for songs listing")
            options: [
                { value: "title", label: qsTr("Title") },
                { value: "artist", label: qsTr("Artist") },
                { value: "album", label: qsTr("Album") },
                { value: "duration", label: qsTr("Duration") }
            ]
            selectedValue: root.songSortMetric
            onOptionSelected: val => root.songSortSelected(String(val))
        }

    }
}
