import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root
    property var appWindow
    property string mode: "artist"
    property string title: ""
    property var tracks: []
    property var heroTrack: ({})
    property string artistImageUrl: ""
    property string artistBio: ""
    readonly property bool artistDetail: mode === "artist"
    readonly property int totalSeconds: tracks.reduce((total, track) => total + (track.durationSeconds || 0), 0)
    readonly property string durationText: totalSeconds > 3600
        ? Math.floor(totalSeconds / 3600) + "h " + Math.floor((totalSeconds % 3600) / 60) + "m"
        : Math.floor(totalSeconds / 60) + " min"
    readonly property var albumGroups: {
        const groups = {}
        tracks.forEach(track => {
            const name = track.album || "Unknown Album"
            if (!groups[name]) groups[name] = { name: name, track: track, count: 0 }
            groups[name].count++
        })
        return Object.keys(groups).map(name => groups[name])
    }

    signal backRequested()
    signal albumRequested(string name, var track)

    function loadArtistProfile() {
        if (!visible || !artistDetail || !title) return
        artistImageUrl = ""
        artistBio = ""
        const cached = services.getArtistImage(title)
        if (cached && cached.length > 0) {
            artistImageUrl = cached
        } else {
            services.fetchArtistImage(title)
        }
        services.fetchArtistBio(title)
    }

    onVisibleChanged: if (visible) loadArtistProfile()

    Connections {
        target: services
        function onArtistImageLoaded(artist, imageUrl) {
            if (root.visible && root.artistDetail && artist.trim().toLowerCase() === root.title.trim().toLowerCase()) {
                root.artistImageUrl = imageUrl
            }
        }
        function onArtistBioLoaded(artist, bio) {
            if (root.visible && root.artistDetail && artist.trim().toLowerCase() === root.title.trim().toLowerCase()) {
                root.artistBio = bio
            }
        }
    }

    color: "#0B0A09"

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: SleekScrollBar {}

        Column {
            width: scrollView.availableWidth
            spacing: 0

            Item {
                width: parent.width
                height: 250

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#161412" }
                        GradientStop { position: 0.75; color: "#100E0D" }
                        GradientStop { position: 1.0; color: "#0B0A09" }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: "#18FFFFFF"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    anchors.topMargin: 20
                    anchors.bottomMargin: 20
                    spacing: 24

                    Item {
                        id: heroPortraitItem
                        Layout.preferredWidth: 160
                        Layout.preferredHeight: 160
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            id: heroMask
                            width: heroPortraitItem.width
                            height: heroPortraitItem.height
                            radius: root.artistDetail ? width / 2 : 16
                            color: "#FFFFFF"
                            visible: false
                            layer.enabled: true
                            layer.smooth: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: root.artistDetail ? width / 2 : 16
                            color: "#181715"
                            border.width: 1.5
                            border.color: "#30FFFFFF"

                            Cover {
                                anchors.fill: parent
                                track: root.artistDetail ? (root.tracks.length > 0 ? root.tracks[0] : root.heroTrack) : root.heroTrack
                                radius: parent.radius
                                visible: !root.artistDetail || heroArtistImg.status !== Image.Ready || root.artistImageUrl === ""
                            }

                            Image {
                                id: heroArtistImg
                                visible: root.artistDetail && status === Image.Ready && source !== ""
                                anchors.fill: parent
                                source: root.artistImageUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: heroMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Label {
                            text: root.artistDetail ? "ARTIST" : "ALBUM"
                            color: "#C23B30"
                            font.family: "Space Grotesk"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.title
                            color: "#FFFFFF"
                            font.family: "Space Grotesk"
                            font.pixelSize: 36
                            font.weight: Font.Bold
                            font.letterSpacing: -0.8
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.artistDetail
                                ? (root.tracks.length + (root.tracks.length === 1 ? " song" : " songs") + " • " + root.albumGroups.length + (root.albumGroups.length === 1 ? " album" : " albums") + " • " + root.durationText)
                                : ((root.heroTrack.artist || "Unknown Artist") + " • " + (root.heroTrack.format || "Music") + (root.heroTrack.label ? (" • " + root.heroTrack.label) : "") + " • " + root.tracks.length + (root.tracks.length === 1 ? " track" : " tracks") + " • " + root.durationText)
                            color: "#A09B93"
                            font.family: "Space Grotesk"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        Item { Layout.preferredHeight: 4 }

                        RowLayout {
                            spacing: 12

                            TransportButton {
                                buttonSize: 42
                                iconName: (player.isPlaying && root.tracks.some(t => t.filePath === player.currentTrack.filePath)) ? "pause" : "play"
                                accented: true
                                tooltipText: "Play All"
                                onClicked: {
                                    if (root.tracks.length && root.appWindow) {
                                        if (player.isPlaying && root.tracks.some(t => t.filePath === player.currentTrack.filePath)) {
                                            player.togglePlay()
                                        } else {
                                            root.appWindow.startPlayback(root.tracks, 0, player.shuffleEnabled)
                                        }
                                    }
                                }
                            }

                            TransportButton {
                                buttonSize: 36
                                iconName: "shuffle"
                                accented: player.shuffleEnabled
                                tooltipText: "Shuffle"
                                onClicked: {
                                    if (root.tracks.length && root.appWindow) {
                                        const randIdx = Math.floor(Math.random() * root.tracks.length)
                                        player.setShuffleEnabled(true)
                                        root.appWindow.startPlayback(root.tracks, randIdx, true)
                                    }
                                }
                            }

                            PressDepthIconButton {
                                boxSize: 36
                                iconSize: 16
                                iconName: "heart"
                                tint: (root.tracks.length && root.appWindow.isFavorite(root.tracks[0].filePath)) ? "#C23B30" : "#6E6C68"
                                tooltipText: "Favorite"
                                onClicked: {
                                    if (root.tracks.length && root.appWindow) {
                                        root.appWindow.toggleFavorite(root.tracks[0].filePath)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 24 }

            ArtistDetailBody {
                visible: root.artistDetail
                tracks: root.tracks
                title: root.title
                artistBio: root.artistBio
                albumGroups: root.albumGroups
                contentWidth: scrollView.availableWidth
                appWindow: root.appWindow
                onAlbumRequested: (name, track) => root.albumRequested(name, track)
            }

            AlbumDetailBody {
                visible: !root.artistDetail
                tracks: root.tracks
                contentWidth: scrollView.availableWidth
                appWindow: root.appWindow
            }

            Item { width: 1; height: 100 }
        }
    }

    AutoScroller {
        id: autoScroller
        targetView: scrollView
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.ArrowCursor
        z: 9998
        onPressed: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                if (autoScroller.active) autoScroller.stop()
                else autoScroller.start(mouse.x, mouse.y)
            }
        }
    }
}
