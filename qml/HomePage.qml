import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: root

    property var appWindow
    property var libraryModel
    property var spotlightTrack
    property var quickPicks: []
    property var heavyRotation: []
    property var recentlyPlayed: []
    property var recentlyAdded: []
    property var forgottenFavs: []
    property var albumsRotation: []
    property var artistsRotation: []
    property string greeting: ""
    property string greetingSubtitle: ""
    property int albumCount: 0
    property int artistCount: 0
    property real initialScrollPosition: 0

    signal scrollPositionChanged(real position)
                                anchors.fill: parent

                                ScrollView {
                            id: homeScrollView
                            Component.onCompleted: Qt.callLater(() => {
                                if (contentItem) contentItem.contentY = root.initialScrollPosition
                            })
                            anchors.fill: parent
                            clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical: SleekScrollBar {}
                            contentWidth: availableWidth
                            contentHeight: homeContentCol.implicitHeight + 48

                            Connections {
                                target: homeScrollView.contentItem
                                function onContentYChanged() {
                                    root.scrollPositionChanged(homeScrollView.contentItem.contentY)
                                }
                            }

                        Column {
                            id: homeContentCol
                            width: homeScrollView.availableWidth
                            spacing: 32
                            topPadding: 24
                            bottomPadding: 36

                            ColumnLayout {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                spacing: 4

                                Label {
                                    text: greeting.toUpperCase()
                                    color: recordRed
                                    font.family: monoFont
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    font.letterSpacing: 1.0
                                }

                                Label {
                                    text: greetingSubtitle
                                    color: textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 28
                                    font.weight: Font.Bold
                                    font.letterSpacing: -0.4
                                }

                                Label {
                                    text: root.libraryModel.trackCount
                                        ? (root.libraryModel.trackCount + " songs • " + artistCount + " artists • " + albumCount + " albums")
                                        : "Scan a music folder to populate your library"
                                    color: silverDim
                                    font.family: monoFont
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                id: heroCard
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                height: 175
                                radius: 12
                                color: surfaceCard
                                border.width: 1
                                border.color: heroCardMouse.containsMouse ? borderVariant : borderSubtle
                                visible: root.libraryModel.trackCount > 0
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: heroMask
                                }

                                Item {
                                    id: heroMask
                                    anchors.fill: parent
                                    layer.enabled: true
                                    visible: false
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "white"
                                    }
                                }

                                Cover {
                                    anchors.fill: parent
                                    track: spotlightTrack || root.libraryModel.firstPlayableTrack()
                                    radius: 12
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 12
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "#40000000" }
                                        GradientStop { position: 0.45; color: "#A00E0D0C" }
                                        GradientStop { position: 1.0; color: "#F00E0D0C" }
                                    }
                                }

                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 22
                                    z: 2

                                    ColumnLayout {
                                        anchors.left: parent.left
                                        anchors.right: heroShuffleBtn.left
                                        anchors.rightMargin: 16
                                        anchors.bottom: parent.bottom
                                        spacing: 3

                                        Label {
                                            text: "Shuffle your library"
                                            color: "#FFFFFF"
                                            font.family: displayFont
                                            font.pixelSize: 22
                                            font.weight: Font.Bold
                                        }

                                        Label {
                                            text: "Play something different from " + root.libraryModel.trackCount + " songs"
                                            color: silver
                                            font.family: bodyFont
                                            font.pixelSize: 13
                                        }
                                    }

                                    TransportButton {
                                        id: heroShuffleBtn
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        buttonSize: 46
                                        iconName: "shuffle"
                                        accented: true
                                        iconColor: recordRed
                                        onClicked: root.appWindow.shuffleAll()
                                    }
                                }

                                MouseArea {
                                    id: heroCardMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: 200
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    z: 1
                                    onClicked: root.appWindow.shuffleAll()
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: quickPicks.length > 0
                                spacing: 16

                                HomeSectionHeader {
                                    title: "Start here"
                                    subtitle: "Handpicked from your library"
                                    onPlayClicked: {
                                        if (quickPicks.length > 0) root.appWindow.playTrack(quickPicks[0])
                                    }
                                    onShuffleClicked: {
                                        root.appWindow.refreshHomeRecommendations()
                                        if (quickPicks.length > 0) root.appWindow.playTrack(quickPicks[0])
                                    }
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: quickPicks

                                    delegate: HomeSongCard {
                                        track: modelData
                                        onClicked: root.appWindow.playTrack(modelData)
                                    }
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: heavyRotation.length > 0
                                spacing: 16

                                HomeSectionHeader {
                                    title: "Heavy Rotation"
                                    subtitle: "Your most played tracks"
                                    onPlayClicked: {
                                        if (heavyRotation.length > 0) root.appWindow.playTrack(heavyRotation[0])
                                    }
                                    onShuffleClicked: root.appWindow.shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: heavyRotation

                                    delegate: HomeSongCard {
                                        track: modelData
                                        onClicked: root.appWindow.playTrack(modelData)
                                    }
                                }
                            }

                            HomeTrackShelf {
                                title: "Recently Played"
                                subtitle: "Continue where you left off"
                                tracks: recentlyPlayed
                                onTrackSelected: track => root.appWindow.playTrack(track)
                                onShuffleSelected: root.appWindow.startPlayback(root.appWindow.shuffledTracks(recentlyPlayed), 0, false)
                            }

                            HomeTrackShelf {
                                title: "Recently Added"
                                subtitle: "New to your library"
                                tracks: recentlyAdded
                                onTrackSelected: track => root.appWindow.playTrack(track)
                                onShuffleSelected: root.appWindow.startPlayback(root.appWindow.shuffledTracks(recentlyAdded), 0, false)
                            }

                            HomeTrackShelf {
                                title: "Forgotten Favorites"
                                subtitle: "Liked tracks waiting for another spin"
                                tracks: forgottenFavs
                                onTrackSelected: track => root.appWindow.playTrack(track)
                                onShuffleSelected: root.appWindow.startPlayback(root.appWindow.shuffledTracks(forgottenFavs), 0, false)
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: albumsRotation.length > 0
                                spacing: 16

                                HomeSectionHeader {
                                    title: "Albums in Rotation"
                                    subtitle: albumCount + " Total albums in library"
                                    onPlayClicked: {
                                        if (albumsRotation.length > 0) root.appWindow.playTrack(albumsRotation[0].track)
                                    }
                                    onShuffleClicked: root.appWindow.shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: albumsRotation

                                    delegate: Item {
                                        width: 150
                                        height: 225

                                        ColumnLayout {
                                            anchors.fill: parent
                                            spacing: 8

                                            Rectangle {
                                                id: albCoverBox
                                                Layout.preferredWidth: 150
                                                Layout.preferredHeight: 150
                                                radius: 12
                                                clip: true
                                                color: surfaceCard
                                                border.width: 1
                                                border.color: albumCardMouse.containsMouse ? borderVariant : borderSubtle
                                                scale: albumCardMouse.containsMouse ? 1.03 : 1.0

                                                Behavior on scale {
                                                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                                                }

                                                Cover {
                                                    anchors.fill: parent
                                                    track: modelData.track
                                                    radius: 12
                                                }

                                                TransportButton {
                                                    anchors.right: parent.right
                                                    anchors.bottom: parent.bottom
                                                    anchors.margins: 8
                                                    buttonSize: 38
                                                    iconName: "play"
                                                    accented: true
                                                    iconColor: recordRed
                                                    opacity: albumCardMouse.containsMouse ? 1.0 : 0.0
                                                    scale: albumCardMouse.containsMouse ? 1.0 : 0.6
                                                    z: 10

                                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                                    onClicked: root.appWindow.playTrack(modelData.track)
                                                }
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: textPrimary
                                                font.family: displayFont
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }

                                            Label {
                                                Layout.fillWidth: true
                                                text: modelData.count + " songs"
                                                color: silverDim
                                                font.family: monoFont
                                                font.pixelSize: 10
                                            }

                                            Item { Layout.fillHeight: true }
                                        }

                                        MouseArea {
                                            id: albumCardMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.appWindow.playTrack(modelData.track)
                                        }
                                    }
                                }
                            }

                            Column {
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                visible: artistsRotation.length > 0
                                spacing: 16

                                HomeSectionHeader {
                                    title: "Artists"
                                    subtitle: artistCount + " Total artists in library"
                                    onPlayClicked: {
                                        if (artistsRotation.length > 0) root.appWindow.playTrack(artistsRotation[0].track)
                                    }
                                    onShuffleClicked: root.appWindow.shuffleAll()
                                }

                                ListView {
                                    width: parent.width
                                    height: 195
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    model: artistsRotation

                                    delegate: ArtistCard {
                                        cardWidth: 120
                                        cardHeight: 185
                                        name: modelData.name
                                        count: modelData.count
                                        track: modelData.track
                                        onClicked: root.appWindow.openCatalogDetail("artist", modelData.name, modelData.track)
                                    }
                                }
                            }
                        }
                    }

                    AutoScroller {
                        id: homeAutoScroller
                        targetView: homeScrollView
                    }

                    MouseArea {
                        anchors.fill: homeScrollView
                        acceptedButtons: Qt.MiddleButton
                        cursorShape: Qt.ArrowCursor
                        z: 9998
                        onPressed: mouse => {
                            if (mouse.button === Qt.MiddleButton) {
                                if (homeAutoScroller.active) homeAutoScroller.stop()
                                else homeAutoScroller.start(mouse.x, mouse.y)
                            }
                }
                        }
                            }
