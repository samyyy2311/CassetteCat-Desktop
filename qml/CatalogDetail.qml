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
    property string albumBio: ""
    readonly property bool artistDetail: mode === "artist"
    readonly property bool albumDetail: mode === "album"
    readonly property bool featuredDetail: artistDetail || albumDetail
    readonly property string detailBio: artistDetail ? artistBio : albumBio
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

    function loadAlbumProfile() {
        if (!visible || !albumDetail || !title) return
        albumBio = ""
        services.fetchAlbumBio(title, heroTrack ? heroTrack.artist || "" : "")
    }

    function loadDetailProfile() {
        if (artistDetail) loadArtistProfile()
        else if (albumDetail) loadAlbumProfile()
    }

    Component.onCompleted: loadDetailProfile()
    onVisibleChanged: if (visible) loadDetailProfile()
    onModeChanged: loadDetailProfile()
    onTitleChanged: loadDetailProfile()
    onHeroTrackChanged: if (albumDetail) loadAlbumProfile()

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
        function onAlbumBioLoaded(album, bio) {
            if (root.visible && root.albumDetail && album.trim().toLowerCase() === root.title.trim().toLowerCase()) {
                root.albumBio = bio
            }
        }
    }

    color: "#0B0A09"

    AlbumDetailBody {
        id: scrollView
        anchors.fill: parent
        tracks: root.tracks
        appWindow: root.appWindow
        footer: Item { width: 1; height: 100 }

        header: Column {
            width: scrollView.width
            spacing: 0

            Item {
                width: parent.width
                height: root.albumDetail ? 344 : (root.artistDetail ? 282 : 250)

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#161412" }
                        GradientStop { position: 0.75; color: "#100E0D" }
                        GradientStop { position: 1.0; color: "#0B0A09" }
                    }
                }

                Image {
                    anchors.fill: parent
                    source: root.artistDetail ? root.artistImageUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: root.artistDetail ? 0.2 : 0
                    visible: root.artistDetail && status === Image.Ready
                }

                Cover {
                    anchors.fill: parent
                    track: root.heroTrack
                    radius: 0
                    opacity: root.albumDetail ? 0.24 : 0
                    visible: root.albumDetail
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.albumDetail ? "#280B0A09" : "#620B0A09" }
                        GradientStop { position: 0.75; color: "#D00B0A09" }
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
                    anchors.topMargin: root.featuredDetail ? 26 : 20
                    anchors.bottomMargin: root.featuredDetail ? 24 : 20
                    spacing: root.featuredDetail ? 32 : 24

                    Item {
                        id: heroPortraitItem
                        Layout.preferredWidth: root.albumDetail ? 208 : (root.artistDetail ? 164 : 160)
                        Layout.preferredHeight: width
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
                            border.width: root.featuredDetail ? 2 : 1.5
                            border.color: root.artistDetail && heroArtistImg.status === Image.Ready ? "#B8FFFFFF" : "#30FFFFFF"

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

                        PressDepthIconButton {
                            visible: root.albumDetail
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.rightMargin: 8
                            anchors.bottomMargin: 8
                            z: 2
                            boxSize: 32
                            iconSize: 15
                            iconName: "disc"
                            tint: root.appWindow ? root.appWindow.textPrimary : "#F5F0EC"
                            tooltipText: "Change cover art"
                            onClicked: root.appWindow.openCoverSearch(root.title, root.heroTrack.artist || "", root.heroTrack.filePath || "")
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 6

                        Label {
                            text: root.artistDetail ? "ARTIST" : (root.albumDetail ? "ALBUM" : root.mode.toUpperCase())
                            color: root.appWindow ? root.appWindow.recordRed : "#C23B30"
                            font.family: root.appWindow ? root.appWindow.monoFont : "IBM Plex Mono"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            font.letterSpacing: 2
                        }

                        Label {
                            Layout.fillWidth: true
                            text: root.title
                            color: "#FFFFFF"
                            font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                            font.pixelSize: root.featuredDetail ? 40 : 36
                            font.weight: Font.Bold
                            font.letterSpacing: -0.8
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Label {
                            Layout.fillWidth: true
                            text: {
                                if (root.artistDetail) {
                                    return root.tracks.length + (root.tracks.length === 1 ? " song" : " songs") + " • " + root.albumGroups.length + (root.albumGroups.length === 1 ? " album" : " albums") + " • " + root.durationText
                                }
                                if (root.mode === "genre" || root.mode === "folder") {
                                    return root.tracks.length + (root.tracks.length === 1 ? " song" : " songs") + " • " + root.durationText
                                }
                                if (root.mode === "playlist") {
                                    return root.tracks.length + (root.tracks.length === 1 ? " track" : " tracks") + " • " + root.durationText
                                }
                                return (root.heroTrack.artist || "Unknown Artist") + " • " + (root.heroTrack.format || "Music") + (root.heroTrack.label ? (" • " + root.heroTrack.label) : "") + " • " + root.tracks.length + (root.tracks.length === 1 ? " track" : " tracks") + " • " + root.durationText
                            }
                            color: root.appWindow ? root.appWindow.textSecondary : "#A09B93"
                            font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: root.albumDetail && root.heroTrack && root.heroTrack.artist
                            text: root.heroTrack.artist || ""
                            color: "#F5F0EC"
                            font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            visible: root.featuredDetail && root.detailBio.length > 0
                            text: root.artistDetail ? "ABOUT THIS ARTIST" : "ABOUT THIS ALBUM"
                            color: root.appWindow ? root.appWindow.recordRed : "#C23B30"
                            font.family: root.appWindow ? root.appWindow.monoFont : "IBM Plex Mono"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 1.2
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.featuredDetail && root.detailBio.length > 0
                            text: root.detailBio
                            color: root.appWindow ? root.appWindow.textSecondary : "#A09B93"
                            font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                            font.pixelSize: 13
                            wrapMode: Text.Wrap
                            maximumLineCount: 3
                            elide: Text.ElideRight

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: detailAboutPopup.open()
                            }
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
                                        root.appWindow.shufflePlayback(root.tracks)
                                    }
                                }
                            }

                            PressDepthIconButton {
                                boxSize: 36
                                iconSize: 16
                                iconName: "heart"
                                tint: (root.tracks.length && root.appWindow.isFavorite(root.tracks[0].filePath)) ? (root.appWindow ? root.appWindow.recordRed : "#C23B30") : (root.appWindow ? root.appWindow.silverDim : "#6E6C68")
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
                contentWidth: scrollView.width
                appWindow: root.appWindow
                onAlbumRequested: (name, track) => root.albumRequested(name, track)
            }

            Rectangle {
                visible: root.artistDetail
                width: scrollView.width - 72
                x: 36
                height: 1
                color: root.appWindow ? root.appWindow.borderSubtle : "#1AFFFFFF"
            }

            Label {
                visible: true
                topPadding: root.artistDetail ? 20 : 16
                leftPadding: 36
                rightPadding: 36
                bottomPadding: 12
                text: root.artistDetail ? "All Songs (" + root.tracks.length + ")" : "Tracklist (" + root.tracks.length + ")"
                color: "#FFFFFF"
                font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                font.pixelSize: 19
                font.weight: Font.Bold
                font.letterSpacing: -0.3
            }
        }
    }

    Popup {
        id: detailAboutPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)
        width: Math.min(root.width - 96, 720)
        height: Math.min(root.height - 96, 680)
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Overlay.modal: Rectangle { color: "#B8000000" }

        background: Rectangle {
            radius: 14
            color: root.appWindow ? root.appWindow.surfaceCard : "#181715"
            border.width: 1
            border.color: root.appWindow ? root.appWindow.borderVariant : "#3A3632"
        }

        contentItem: ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 24
                Layout.rightMargin: 18
                Layout.topMargin: 18
                Layout.bottomMargin: 14

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Label {
                        text: root.artistDetail ? "About " + root.title : "About this album"
                        color: root.appWindow ? root.appWindow.textPrimary : "#F5F0EC"
                        font.family: root.appWindow ? root.appWindow.displayFont : "Space Grotesk"
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Label {
                        text: root.title + (root.heroTrack && root.heroTrack.artist ? " • " + root.heroTrack.artist : "")
                        color: root.appWindow ? root.appWindow.textSecondary : "#A09B93"
                        font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                PressDepthIconButton {
                    boxSize: 32
                    iconSize: 16
                    iconName: "x"
                    tooltipText: "Close"
                    onClicked: detailAboutPopup.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.appWindow ? root.appWindow.borderSubtle : "#1AFFFFFF"
            }

            ScrollView {
                id: aboutScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 24
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical: SleekScrollBar {}

                Text {
                    width: aboutScroll.availableWidth
                    text: root.detailBio
                    wrapMode: Text.Wrap
                    color: root.appWindow ? root.appWindow.textSecondary : "#A09B93"
                    font.family: root.appWindow ? root.appWindow.bodyFont : "IBM Plex Sans"
                    font.pixelSize: 15
                    lineHeight: 1.42
                }
            }
        }
    }

}
