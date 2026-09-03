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
                                : ((root.heroTrack.artist || "Unknown Artist") + " • " + (root.heroTrack.format || "Music") + " • " + root.tracks.length + (root.tracks.length === 1 ? " track" : " tracks") + " • " + root.durationText)
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

            Item {
                width: scrollView.availableWidth
                height: artistGridRow.implicitHeight
                visible: root.artistDetail && root.tracks.length > 0

                RowLayout {
                    id: artistGridRow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 36
                    anchors.rightMargin: 36
                    spacing: 32

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "Popular Tracks"
                            color: "#FFFFFF"
                            font.family: "Space Grotesk"
                            font.pixelSize: 19
                            font.weight: Font.Bold
                            font.letterSpacing: -0.3
                        }

                        Repeater {
                            model: root.tracks.slice(0, 5)

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 8
                                    color: popMouse.containsMouse ? "#18FFFFFF" : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Label {
                                            Layout.preferredWidth: 20
                                            text: String(index + 1)
                                            color: popMouse.containsMouse ? "#C23B30" : "#6E6C68"
                                            font.family: "Space Grotesk"
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 38
                                            Layout.preferredHeight: 38
                                            radius: 6
                                            clip: true
                                            color: "#181715"

                                            Cover {
                                                anchors.fill: parent
                                                track: modelData
                                                radius: 6
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                radius: 6
                                                color: "#80000000"
                                                visible: popMouse.containsMouse

                                                LucideIcon {
                                                    anchors.centerIn: parent
                                                    width: 13
                                                    height: 13
                                                    icon: "play"
                                                    color: "#FFFFFF"
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.title || modelData.fileName || "Unknown Title"
                                                color: popMouse.containsMouse ? "#C23B30" : "#F5F0EC"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 13
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.album || modelData.artist || ""
                                                color: "#858079"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 11
                                                elide: Text.ElideRight
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredHeight: 18
                                            Layout.preferredWidth: fmtBadgeLbl.implicitWidth + 8
                                            radius: 4
                                            color: "#14FFFFFF"

                                            Label {
                                                id: fmtBadgeLbl
                                                anchors.centerIn: parent
                                                text: (modelData.format || "MP3").toUpperCase()
                                                color: "#858079"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Label {
                                            text: {
                                                const secs = modelData.durationSeconds || 0
                                                const m = Math.floor(secs / 60)
                                                const s = Math.floor(secs % 60)
                                                return m + ":" + (s < 10 ? "0" : "") + s
                                            }
                                            color: "#858079"
                                            font.family: "Space Grotesk"
                                            font.pixelSize: 12
                                        }
                                    }

                                    MouseArea {
                                        id: popMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.appWindow) root.appWindow.playTrack(modelData)
                                    }
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: Math.min(Math.max(280, (scrollView.availableWidth - 72) * 0.38), 380)
                        Layout.alignment: Qt.AlignTop
                        spacing: 8
                        visible: root.albumGroups.length > 0

                        Label {
                            text: "Top Releases"
                            color: "#FFFFFF"
                            font.family: "Space Grotesk"
                            font.pixelSize: 19
                            font.weight: Font.Bold
                            font.letterSpacing: -0.3
                        }

                        Repeater {
                            model: root.albumGroups.slice(0, 2)

                            delegate: Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 100

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    color: topRelMouse.containsMouse ? "#20FFFFFF" : "#141312"
                                    border.width: 1
                                    border.color: topRelMouse.containsMouse ? "#C23B30" : "#1AFFFFFF"

                                    Behavior on color { ColorAnimation { duration: 120 } }
                                    Behavior on border.color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 14

                                        Rectangle {
                                            Layout.preferredWidth: 76
                                            Layout.preferredHeight: 76
                                            radius: 8
                                            clip: true
                                            color: "#181715"

                                            Cover {
                                                anchors.fill: parent
                                                track: modelData.track
                                                radius: 8
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 4

                                            Label {
                                                text: "ALBUM"
                                                color: "#C23B30"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 10
                                                font.weight: Font.Bold
                                                font.letterSpacing: 1.2
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: "#FFFFFF"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 14
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                                maximumLineCount: 1
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.count + (modelData.count === 1 ? " song" : " songs")
                                                color: "#858079"
                                                font.family: "Space Grotesk"
                                                font.pixelSize: 12
                                            }
                                        }

                                        TransportButton {
                                            buttonSize: 34
                                            iconName: "play"
                                            accented: false
                                            tooltipText: "Play Album"
                                            onClicked: root.albumRequested(modelData.name, modelData.track)
                                        }
                                    }

                                    MouseArea {
                                        id: topRelMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.albumRequested(modelData.name, modelData.track)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                visible: root.artistDetail && root.albumGroups.length > 0
                spacing: 10

                Item { width: 1; height: 16 }

                Label {
                    leftPadding: 36
                    rightPadding: 36
                    text: "Albums & Releases (" + root.albumGroups.length + ")"
                    color: "#FFFFFF"
                    font.family: "Space Grotesk"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                ListView {
                    width: parent.width
                    height: 255
                    orientation: ListView.Horizontal
                    clip: true
                    spacing: 16
                    leftMargin: 36
                    rightMargin: 36
                    model: root.albumGroups

                    delegate: AlbumCard {
                        required property var modelData
                        width: 175
                        height: 245
                        cardWidth: 175
                        cardHeight: 245
                        name: modelData.name
                        artist: modelData.track.artist || "Unknown Artist"
                        count: modelData.count
                        track: modelData.track
                        onClicked: root.albumRequested(modelData.name, modelData.track)
                    }
                }
            }

            Column {
                width: parent.width
                visible: root.tracks.length > 0
                spacing: 4

                Item { width: 1; height: 16 }

                Label {
                    leftPadding: 36
                    rightPadding: 36
                    bottomPadding: 8
                    text: root.artistDetail ? ("All Songs (" + root.tracks.length + ")") : ("Tracklist (" + root.tracks.length + ")")
                    color: "#FFFFFF"
                    font.family: "Space Grotesk"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                Repeater {
                    model: root.tracks

                    SongRow {
                        width: scrollView.availableWidth - 56
                        x: 28
                        track: modelData
                        showAlbum: root.artistDetail
                        onClicked: if (root.appWindow) root.appWindow.playTrack(modelData)
                    }
                }
            }

            Column {
                width: parent.width
                visible: root.artistDetail && root.artistBio.length > 0
                spacing: 10

                Item { width: 1; height: 18 }

                Label {
                    leftPadding: 36
                    rightPadding: 36
                    text: "About " + root.title
                    color: "#FFFFFF"
                    font.family: "Space Grotesk"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                Rectangle {
                    width: scrollView.availableWidth - 72
                    x: 36
                    radius: 14
                    color: "#141312"
                    border.width: 1
                    border.color: "#1AFFFFFF"
                    implicitHeight: bioCol.implicitHeight + 36

                    ColumnLayout {
                        id: bioCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 18
                        spacing: 8
                        property bool expanded: false

                        Text {
                            id: bioText
                            Layout.fillWidth: true
                            text: root.artistBio
                            wrapMode: Text.Wrap
                            color: "#B0ACA5"
                            font.family: "Space Grotesk"
                            font.pixelSize: 13
                            lineHeight: 1.45
                            maximumLineCount: bioCol.expanded ? 1000 : 5
                            elide: Text.ElideRight
                        }

                        Label {
                            visible: root.artistBio.length > 300
                            text: bioCol.expanded ? "Show Less" : "Read More"
                            color: "#C23B30"
                            font.family: "Space Grotesk"
                            font.pixelSize: 12
                            font.weight: Font.Bold

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: bioCol.expanded = !bioCol.expanded
                            }
                        }
                    }
                }
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
