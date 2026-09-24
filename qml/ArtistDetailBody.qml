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

    signal albumRequested(string name, var track)

    width: root.contentWidth
    spacing: 0

    Item {
        width: root.contentWidth
        height: Math.max(popularTracksCol.implicitHeight, (discographyCol.visible ? discographyCol.implicitHeight : 0))
        visible: root.tracks.length > 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            spacing: 40

            ColumnLayout {
                id: popularTracksCol
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.maximumWidth: 560
                Layout.alignment: Qt.AlignTop
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "Popular Tracks"
                        color: "#FFFFFF"
                        font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                        font.pixelSize: 21
                        font.weight: Font.Bold
                        font.letterSpacing: -0.35
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "TOP " + Math.min(5, root.tracks.length)
                        color: root.appWindow ? root.appWindow.recordRed : "#C23B30"
                        font.family: root.appWindow ? root.appWindow.monoFont : "IBM Plex Mono"
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
                        showFormatBadge: false
                        onFavoriteClicked: if (root.appWindow) root.appWindow.toggleFavorite(modelData.filePath)

                        TapHandler {
                            onTapped: root.appWindow.playTrack(modelData)
                        }
                    }
                }
            }

            ColumnLayout {
                id: discographyCol
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.alignment: Qt.AlignTop
                spacing: 8
                visible: root.albumGroups.length > 0

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 1

                        Label {
                            text: "Discography"
                            color: "#FFFFFF"
                            font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                            font.pixelSize: 21
                            font.weight: Font.Bold
                            font.letterSpacing: -0.35
                        }

                        Label {
                            text: root.albumGroups.length + (root.albumGroups.length === 1 ? " release" : " releases")
                            color: root.appWindow ? root.appWindow.textSecondary : "#A09B93"
                            font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                            font.pixelSize: 12
                        }
                    }

                }

                ListView {
                    activeFocusOnTab: true
                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                    Layout.fillWidth: true
                    Layout.preferredHeight: 270
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: 16
                    model: root.albumGroups
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    cacheBuffer: UiConstants.cacheBuffer
                    pixelAligned: UiConstants.pixelAligned
                    reuseItems: true

                    delegate: AlbumCard {
                        required property var modelData
                        width: 184
                        height: 255
                        cardWidth: 184
                        cardHeight: 255
                        name: modelData.name
                        subtitle: modelData.count + (modelData.count === 1 ? " song" : " songs") + (modelData.track && modelData.track.year ? " • " + modelData.track.year : "")
                        count: modelData.count
                        track: modelData.track
                        onClicked: root.albumRequested(modelData.name, modelData.track)
                    }
                }
            }
        }
    }

}
