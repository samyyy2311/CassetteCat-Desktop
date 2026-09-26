import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root
    property var tracks: []
    property string title: ""
    property string artistBio: ""
    property var albumGroups: []
    property real contentWidth: 0
    property var appWindow
    // A release counts as a single when its name says so, or it holds one song named like the release.
    readonly property var discographySections: {
        const isSingle = group => /\b(single|ep)\b/i.test(group.name)
            || (group.count === 1 && (group.track.title || "").toLowerCase() === group.name.toLowerCase())
        const singles = albumGroups.filter(isSingle)
        const albums = albumGroups.filter(group => !isSingle(group))
        return [{ title: "Albums", releases: albums }, { title: "Singles & EPs", releases: singles }]
            .filter(section => section.releases.length > 0)
    }

    signal albumRequested(string name, var track)

    width: root.contentWidth
    spacing: 0

    Item {
        width: root.contentWidth
        height: artistSections.implicitHeight
        visible: root.tracks.length > 0

        ColumnLayout {
            id: artistSections
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            spacing: 36

            ColumnLayout {
                id: popularTracksCol
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Popular Tracks"
                        color: "#FFFFFF"
                        font.family: root.appWindow.displayFont
                        font.pixelSize: 21
                        font.weight: Font.Bold
                        font.letterSpacing: -0.35
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "TOP " + Math.min(5, root.tracks.length)
                        color: root.appWindow.recordRed
                        font.family: root.appWindow.monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                Repeater {
                    model: root.tracks.slice(0, 5)

                    SongRow {
                        required property var modelData
                        Layout.fillWidth: true
                        track: modelData
                        showAlbum: true
                        omitArtist: root.title
                        showFormatBadge: false
                        onClicked: root.appWindow.playTrack(modelData)
                        onFavoriteClicked: if (root.appWindow) root.appWindow.toggleFavorite(modelData.filePath)
                    }
                }
            }

            ColumnLayout {
                id: discographyCol
                Layout.fillWidth: true
                spacing: 8
                visible: root.albumGroups.length > 0

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 1

                        Label {
                            text: "Discography"
                            color: "#FFFFFF"
                            font.family: root.appWindow.displayFont
                            font.pixelSize: 21
                            font.weight: Font.Bold
                            font.letterSpacing: -0.35
                        }

                        Label {
                            text: root.albumGroups.length + (root.albumGroups.length === 1 ? " release" : " releases")
                            color: root.appWindow.textSecondary
                            font.family: root.appWindow.bodyFont
                            font.pixelSize: 12
                        }
                    }

                }

                Repeater {
                    model: root.discographySections

                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        spacing: 10

                        Label {
                            visible: root.discographySections.length > 1
                            text: modelData.title
                            color: root.appWindow.textSecondary
                            font.family: root.appWindow.monoFont
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                            font.capitalization: Font.AllUppercase
                        }

                        AppListView {
                            id: releaseList
                            // Sized so a row shows whole cards only.
                            readonly property int visibleCards: Math.max(2, Math.floor((width + spacing) / (180 + spacing)))
                            readonly property real cardWidth: Math.floor((width - (visibleCards - 1) * spacing) / visibleCards)
                            activeFocusOnTab: true
                            onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                            Layout.fillWidth: true
                            Layout.preferredHeight: cardWidth + 72 + topMargin
                            orientation: ListView.Horizontal
                            clip: true
                            // Keeps the hover zoom inside the clip.
                            topMargin: 6
                            spacing: 16
                            snapMode: ListView.SnapToItem
                            model: modelData.releases
                            reuseItems: true

                            delegate: AlbumCard {
                                required property var modelData
                                cardWidth: releaseList.cardWidth
                                cardHeight: releaseList.cardWidth + 72
                                name: modelData.name
                                subtitle: (modelData.year ? modelData.year + " • " : "") + modelData.count + (modelData.count === 1 ? " song" : " songs")
                                count: modelData.count
                                track: modelData.track
                                onClicked: root.albumRequested(modelData.name, modelData.track)
                            }
                        }
                    }
                }
            }
        }
    }

}
