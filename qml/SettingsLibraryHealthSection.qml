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
    // Songs without a cover in a file or beside it; -1 while still counting.
    property int missingCovers: -1
    property var duplicates: []
    // Copies ticked for the Recycle Bin, by file path.
    property var removals: ({})
    readonly property var removalPaths: Object.keys(removals).filter(path => removals[path])
    readonly property int acceptedCount: tagScan.acceptedDetails + tagScan.acceptedCovers

    Layout.fillWidth: true
    spacing: 16

    // Coming back while a check is running, paused or has results, shows it.
    onVisibleChanged: if (visible) showCurrent()
    Component.onCompleted: if (visible) showCurrent()

    function showCurrent() {
        refresh()
        view = tagScan.running || tagScan.paused || tagScan.hasResults ? "tags" : "overview"
    }

    function refresh() {
        health = appWindow.libraryHealth()
        missingCovers = -1
        library.countMissingArtwork(health.withoutCoverFile)
    }

    Connections {
        target: library
        function onMissingArtworkCounted(count) { root.missingCovers = count }
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

    function changesText(changes) {
        return changes.map(change => change.label + ":  " + (change.from || qsTr("(empty)")) + "  →  " + change.to).join("\n")
    }

    SectionLabel { text: qsTr("Library Health") }

    RowLayout {
        visible: root.view !== "overview"
        Layout.fillWidth: true
        spacing: 10

        SettingButton {
            text: qsTr("Back")
            iconName: "chevron-left"
            onClicked: {
                root.refresh()
                root.view = "overview"
            }
        }

        Item { Layout.fillWidth: true }

        SettingButton {
            visible: root.view === "tags"
            primary: true
            enabled: root.acceptedCount > 0
            text: qsTr("Apply %n Change(s)", "", root.acceptedCount)
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
            text: qsTr("Move %n to Recycle Bin", "", root.removalPaths.length)
            onClicked: recycleConfirm.open()
        }
    }

    SettingCard {
        visible: root.view === "overview"

        SettingRow {
            iconName: "musicbrainz"
            preserveIconColor: true
            title: qsTr("Song Details & Covers")
            subtitle: root.tagScan.running
                      ? qsTr("Checking %1 of %n song(s) with MusicBrainz", "", root.tagScan.songPaths.length).arg(root.tagScan.checkedCount)
                      : qsTr("%n missing a title, artist or album", "", root.health.metadataGaps || 0) + "  •  "
                        + (root.missingCovers < 0 ? qsTr("checking covers") : qsTr("%n without a cover", "", root.missingCovers))

            SettingButton {
                text: root.tagScan.running || root.tagScan.paused || root.tagScan.hasResults ? qsTr("View") : qsTr("Fix Tags")
                onClicked: {
                    if (!root.tagScan.running && !root.tagScan.paused && !root.tagScan.hasResults)
                        root.tagScan.startLibrary(root.appWindow.availableTracks())
                    root.view = "tags"
                }
            }
        }

        SettingRow {
            iconName: "list-music"
            title: qsTr("Duplicates")
            subtitle: (root.health.duplicateMetadata || 0) > 0
                      ? qsTr("%n extra copy(s) of songs you already have", "", root.health.duplicateMetadata)
                      : qsTr("No duplicate songs found")

            SettingButton {
                text: qsTr("Review")
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
                   ? qsTr("Checking %1 of %n song(s)", "", root.tagScan.songPaths.length).arg(root.tagScan.checkedCount)
                   : root.tagScan.paused ? qsTr("Paused at %1 of %n song(s)", "", root.tagScan.songPaths.length).arg(root.tagScan.checkedCount)
                   : qsTr("Check finished")
            subtitle: root.tagScan.problem
                      || (root.tagScan.running ? qsTr("You can leave this page. The check keeps going, about a song a second.")
                          : root.tagScan.hasResults ? qsTr("Turn off anything that looks wrong, then apply.")
                          : root.tagScan.songPaths.length === 0 ? qsTr("Every song in your library has been checked already.")
                          : qsTr("MusicBrainz agrees with these songs, or has no confident match for them."))

            SettingButton {
                visible: root.tagScan.running
                text: qsTr("Stop")
                onClicked: root.tagScan.stop()
            }

            SettingButton {
                visible: root.tagScan.paused
                text: qsTr("Continue")
                onClicked: root.tagScan.resume()
            }

            SettingButton {
                // Starting over drops unapplied results, so it's only offered once there are none.
                visible: !root.tagScan.running && !root.tagScan.paused && !root.tagScan.hasResults
                text: qsTr("Check All Again")
                onClicked: root.tagScan.checkAllAgain(root.appWindow.availableTracks())
            }
        }
    }

    SectionLabel {
        visible: root.view === "tags" && root.tagScan.details.length > 0
        text: qsTr("Song Details")
    }

    SettingCard {
        visible: root.view === "tags" && root.tagScan.details.length > 0

        SettingRow {
            title: qsTr("%n song(s) with new details", "", root.tagScan.details.length)
            subtitle: qsTr("Titles, artists and albums that differ from MusicBrainz, and years or track numbers that are missing.")

            SettingButton {
                text: root.tagScan.acceptedDetails > 0 ? qsTr("Turn All Off") : qsTr("Turn All On")
                onClicked: root.tagScan.setAllDetailsSkipped(root.tagScan.acceptedDetails > 0)
            }
        }

        Repeater {
            model: root.tagScan.details

            SettingRow {
                required property var modelData
                title: modelData.song.title + "  •  " + (modelData.song.artist || qsTr("Unknown Artist"))
                subtitle: root.changesText(modelData.changes)

                SettingSwitch {
                    Accessible.name: qsTr("Apply new details to %1").arg(modelData.song.title)
                    checked: !root.tagScan.skippedDetails[modelData.song.filePath]
                    onToggled: value => root.tagScan.setDetailSkipped(modelData.song.filePath, !value)
                }
            }
        }
    }

    SectionLabel {
        visible: root.view === "tags" && root.tagScan.covers.length > 0
        text: qsTr("Album Covers")
    }

    SettingCard {
        visible: root.view === "tags" && root.tagScan.covers.length > 0

        SettingRow {
            title: qsTr("%n album(s) without a cover", "", root.tagScan.covers.length)
            subtitle: qsTr("Each cover is saved into the album's songs that don't have one.")

            SettingButton {
                text: root.tagScan.acceptedCovers > 0 ? qsTr("Turn All Off") : qsTr("Turn All On")
                onClicked: root.tagScan.setAllCoversSkipped(root.tagScan.acceptedCovers > 0)
            }
        }

        Repeater {
            model: root.tagScan.covers

            RowLayout {
                id: coverRow
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumHeight: 64
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 6
                    color: surfaceInput
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: "https://coverartarchive.org/release/" + coverRow.modelData.releaseId + "/front-250"
                        sourceSize: Qt.size(96, 96)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Label {
                        Layout.fillWidth: true
                        text: coverRow.modelData.album + "  •  " + (coverRow.modelData.artist || qsTr("Unknown Artist"))
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("%n song(s): ", "", coverRow.modelData.songs.length)
                              + coverRow.modelData.songs.map(song => song.title).join(", ")
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                SettingSwitch {
                    Accessible.name: qsTr("Add the cover for %1").arg(coverRow.modelData.album)
                    checked: !root.tagScan.skippedCovers[coverRow.modelData.releaseId]
                    onToggled: value => root.tagScan.setCoverSkipped(coverRow.modelData.releaseId, !value)
                }
            }
        }
    }

    SettingCard {
        visible: root.view === "duplicates"

        SettingRow {
            iconName: "list-music"
            title: qsTr("%n song(s) with copies", "", root.duplicates.length)
            subtitle: qsTr("The best copy of each song is kept: lossless first, then the largest file. Turn on any other copy to remove it.")
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
                        title: (index === 0 ? qsTr("Keep: %1") : "%1").arg(modelData.title + "  •  " + (modelData.artist || qsTr("Unknown Artist")))
                        subtitle: [modelData.format, root.sizeText(modelData.fileSize), modelData.filePath].filter(part => !!part).join("  •  ")

                        SettingSwitch {
                            Accessible.name: qsTr("Remove %1").arg(modelData.filePath)
                            checked: !!root.removals[modelData.filePath]
                            onToggled: value => root.removals = Object.assign({}, root.removals, { [modelData.filePath]: value })
                        }
                    }
                }
            }
        }
    }

    ConfirmPopup {
        id: recycleConfirm
        title: qsTr("Move %n song(s) to the Recycle Bin?", "", root.removalPaths.length)
        subtitle: qsTr("You can restore them from the Recycle Bin")
        message: qsTr("The files leave your music folders and your CassetteCat library. The copies you keep stay as they are.")
        iconName: "list-music"
        confirmText: qsTr("Move to Recycle Bin")
        destructive: true
        onConfirmed: {
            library.moveToTrash(root.removalPaths)
            root.refresh()
            root.reviewDuplicates()
            if (root.duplicates.length === 0) root.view = "overview"
        }
    }
}
