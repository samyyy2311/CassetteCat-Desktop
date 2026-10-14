import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "LibraryTidy.js" as LibraryTidy

ColumnLayout {
    id: root
    required property var appWindow
    required property var tagScan

    // "overview", "tags" or "duplicates"
    property string view: "overview"
    property var health: ({})
    property var duplicates: []
    // Copies ticked for the Recycle Bin, by file path.
    property var removals: ({})
    readonly property var removalPaths: Object.keys(removals).filter(path => removals[path])

    Layout.fillWidth: true
    spacing: 16

    // Coming back while a check is running, or has results, shows it.
    onVisibleChanged: if (visible) showCurrent()
    Component.onCompleted: if (visible) showCurrent()

    function showCurrent() {
        refresh()
        view = tagScan.running || tagScan.suggestions.length > 0 ? "tags" : "overview"
    }

    function refresh() {
        health = appWindow.libraryHealth()
    }

    function reviewDuplicates() {
        duplicates = LibraryTidy.duplicateGroups(appWindow.availableTracks().filter(song => !song.remoteId && song.format !== "STREAM"))
        const ticked = {}
        duplicates.forEach(group => group.slice(1).forEach(song => ticked[song.filePath] = true))
        removals = ticked
        view = "duplicates"
    }

    function sizeText(bytes) {
        return (Number(bytes || 0) / 1048576).toFixed(1) + " MB"
    }

    function changesText(item) {
        const parts = item.changes.map(change => change.label + ": " + (change.from || "empty") + " → " + change.to)
        if (item.addsCover) parts.push("Adds a cover")
        return parts.join("  •  ")
    }

    SectionLabel { text: "Library Health" }

    SettingCard {
        visible: root.view === "overview"

        SettingRow {
            iconName: "musicbrainz"
            preserveIconColor: true
            title: "Song Details"
            subtitle: root.tagScan.running
                      ? "Checking " + root.tagScan.checkedCount + " of " + root.tagScan.songs.length + " songs with MusicBrainz"
                      : (root.health.metadataGaps || 0) + " missing a title, artist or album  •  "
                        + (root.health.noFolderArtwork || 0) + " without a cover"

            SettingButton {
                text: root.tagScan.running || root.tagScan.suggestions.length > 0 ? "View" : "Fix Tags"
                onClicked: {
                    if (!root.tagScan.running && root.tagScan.suggestions.length === 0)
                        root.tagScan.start(root.appWindow.availableTracks())
                    root.view = "tags"
                }
            }
        }

        SettingRow {
            iconName: "list-music"
            title: "Duplicates"
            subtitle: (root.health.duplicateMetadata || 0) > 0
                      ? root.health.duplicateMetadata + " extra copies of songs you already have"
                      : "No duplicate songs found"

            SettingButton {
                text: "Review"
                enabled: (root.health.duplicateMetadata || 0) > 0
                onClicked: root.reviewDuplicates()
            }
        }
    }

    SettingCard {
        visible: root.view === "tags"

        SettingRow {
            iconName: "musicbrainz"
            preserveIconColor: true
            title: root.tagScan.running
                   ? "Checking " + root.tagScan.checkedCount + " of " + root.tagScan.songs.length + " songs"
                   : root.tagScan.suggestions.length + (root.tagScan.suggestions.length === 1 ? " song to fix" : " songs to fix")
            subtitle: root.tagScan.problem
                      || (root.tagScan.running ? "You can leave this page. The check keeps going, about a song a second."
                          : root.tagScan.suggestions.length > 0 ? "Turn off anything that looks wrong, then apply."
                          : "MusicBrainz agrees with these songs, or has no confident match for them.")

            SettingButton {
                visible: root.tagScan.running
                text: "Stop"
                onClicked: root.tagScan.stop()
            }
        }

        Repeater {
            model: root.tagScan.suggestions

            SettingRow {
                required property var modelData
                title: modelData.song.title + "  •  " + (modelData.song.artist || "Unknown Artist")
                subtitle: root.changesText(modelData)

                SettingSwitch {
                    Accessible.name: "Apply to " + modelData.song.title
                    checked: !root.tagScan.skipped[modelData.song.filePath]
                    onToggled: value => root.tagScan.setSkipped(modelData.song.filePath, !value)
                }
            }
        }
    }

    SettingCard {
        visible: root.view === "duplicates"

        SettingRow {
            iconName: "list-music"
            title: root.duplicates.length + (root.duplicates.length === 1 ? " song with copies" : " songs with copies")
            subtitle: "The best copy of each song is kept: lossless first, then the largest file. Turn on any other copy to remove it."
        }

        Repeater {
            model: root.duplicates

            ColumnLayout {
                id: group
                required property var modelData
                Layout.fillWidth: true
                spacing: 0

                Repeater {
                    model: group.modelData

                    SettingRow {
                        required property var modelData
                        required property int index
                        title: (index === 0 ? "Keep: " : "") + modelData.title + "  •  " + (modelData.artist || "Unknown Artist")
                        subtitle: [modelData.format, root.sizeText(modelData.fileSize), modelData.filePath].filter(part => !!part).join("  •  ")

                        SettingSwitch {
                            Accessible.name: "Remove " + modelData.filePath
                            checked: !!root.removals[modelData.filePath]
                            onToggled: value => root.removals = Object.assign({}, root.removals, { [modelData.filePath]: value })
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        visible: root.view !== "overview"
        Layout.fillWidth: true
        spacing: 10

        SettingButton {
            text: "Back"
            onClicked: {
                root.refresh()
                root.view = "overview"
            }
        }

        Item { Layout.fillWidth: true }

        SettingButton {
            visible: root.view === "tags"
            primary: true
            enabled: !root.tagScan.running && root.tagScan.acceptedCount > 0
            text: "Apply to " + root.tagScan.acceptedCount + (root.tagScan.acceptedCount === 1 ? " Song" : " Songs")
            onClicked: {
                root.tagScan.apply()
                root.refresh()
                root.view = "overview"
            }
        }

        SettingButton {
            visible: root.view === "duplicates"
            destructive: true
            enabled: root.removalPaths.length > 0
            text: "Move " + root.removalPaths.length + " to Recycle Bin"
            onClicked: recycleConfirm.open()
        }
    }

    ConfirmPopup {
        id: recycleConfirm
        title: "Move " + root.removalPaths.length + (root.removalPaths.length === 1 ? " song" : " songs") + " to the Recycle Bin?"
        subtitle: "You can restore them from the Recycle Bin"
        message: "The files leave your music folders and your CassetteCat library. The copies you keep stay as they are."
        iconName: "list-music"
        confirmText: "Move to Recycle Bin"
        destructive: true
        onConfirmed: {
            library.moveToTrash(root.removalPaths)
            root.refresh()
            root.reviewDuplicates()
            if (root.duplicates.length === 0) root.view = "overview"
        }
    }
}
