import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

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
    Flickable {
        id: homeScrollView
        anchors.fill: parent
        clip: true
        readonly property real availableWidth: width
        contentWidth: width
        contentHeight: homeContentCol.implicitHeight + 48
        flickDeceleration: UiConstants.flickDeceleration
        maximumFlickVelocity: UiConstants.maximumFlickVelocity
        pixelAligned: UiConstants.pixelAligned
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: AutoHideScrollBar {}

        Component.onCompleted: Qt.callLater(() => {
            homeScrollView.contentY = root.initialScrollPosition
        })

        onContentYChanged: root.scrollPositionChanged(contentY)

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
                                readonly property var heroTrack: spotlightTrack || root.libraryModel.firstPlayableTrack()
                                readonly property real cornerRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12
                                x: 32
                                width: homeScrollView.availableWidth - 64
                                height: 150
                                radius: cornerRadius
                                color: surfaceCard
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
                                        radius: heroCard.cornerRadius
                                        color: "white"
                                    }
                                }

                                Cover {
                                    anchors.centerIn: parent
                                    width: parent.width * 1.2
                                    height: width
                                    track: heroCard.heroTrack
                                    stableSourceSize: 160
                                    layer.enabled: true
                                    layer.textureSize: Qt.size(200, 200)
                                    layer.smooth: true
                                    layer.effect: MultiEffect {
                                        blurEnabled: true
                                        blur: 1.0
                                        blurMax: 48
                                        saturation: 0.3
                                        brightness: -0.3
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "#700E0D0C" }
                                        GradientStop { position: 1.0; color: "#D00E0D0C" }
                                    }
                                }

                                MouseArea {
                                    id: heroCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.appWindow.shuffleAll()
                                }

                                CoverFrame {
                                    id: heroArt
                                    anchors.left: parent.left
                                    anchors.leftMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 110
                                    height: 110
                                    radius: 10
                                    highlighted: heroCardMouse.containsMouse

                                    Cover {
                                        anchors.fill: parent
                                        track: heroCard.heroTrack
                                        radius: heroArt.radius
                                    }
                                }

                                ColumnLayout {
                                    anchors.left: heroArt.right
                                    anchors.leftMargin: 22
                                    anchors.right: heroShuffleBtn.left
                                    anchors.rightMargin: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4

                                    Label {
                                        text: "SHUFFLE"
                                        color: recordRedHover
                                        font.family: monoFont
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.0
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Your whole library, in a new order"
                                        color: "#FFFFFF"
                                        font.family: displayFont
                                        font.pixelSize: 22
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Play something different from " + root.libraryModel.trackCount + " songs"
                                        color: silver
                                        font.family: bodyFont
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }
                                }

                                TransportButton {
                                    id: heroShuffleBtn
                                    Accessible.name: "Shuffle library"
                                    anchors.right: parent.right
                                    anchors.rightMargin: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    buttonSize: 52
                                    iconName: "shuffle"
                                    accented: true
                                    iconColor: recordRed
                                    onClicked: root.appWindow.shuffleAll()
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: heroCard.cornerRadius
                                    color: "transparent"
                                    border.width: 1
                                    border.color: heroCardMouse.containsMouse ? borderVariant : borderSubtle
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
                                    activeFocusOnTab: true
                                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickDeceleration: UiConstants.flickDeceleration
                                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                                    cacheBuffer: UiConstants.cacheBuffer
                                    pixelAligned: UiConstants.pixelAligned
                                    reuseItems: true
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
                                    activeFocusOnTab: true
                                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickDeceleration: UiConstants.flickDeceleration
                                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                                    cacheBuffer: UiConstants.cacheBuffer
                                    pixelAligned: UiConstants.pixelAligned
                                    reuseItems: true
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
                                onShuffleSelected: root.appWindow.shufflePlayback(recentlyPlayed)
                            }

                            HomeTrackShelf {
                                title: "Recently Added"
                                subtitle: "New to your library"
                                tracks: recentlyAdded
                                onTrackSelected: track => root.appWindow.playTrack(track)
                                onShuffleSelected: root.appWindow.shufflePlayback(recentlyAdded)
                            }

                            HomeTrackShelf {
                                title: "Forgotten Favorites"
                                subtitle: "Liked tracks waiting for another spin"
                                tracks: forgottenFavs
                                onTrackSelected: track => root.appWindow.playTrack(track)
                                onShuffleSelected: root.appWindow.shufflePlayback(forgottenFavs)
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
                                    activeFocusOnTab: true
                                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                                    height: 225
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickDeceleration: UiConstants.flickDeceleration
                                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                                    cacheBuffer: UiConstants.cacheBuffer
                                    pixelAligned: UiConstants.pixelAligned
                                    reuseItems: true
                                    model: albumsRotation

                                    delegate: AlbumCard {
                                        cardWidth: 150
                                        cardHeight: 225
                                        name: modelData.name
                                        count: modelData.count
                                        track: modelData.track
                                        onClicked: root.appWindow.openCatalogDetail("album", modelData.name, modelData.track)
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
                                    activeFocusOnTab: true
                                    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                                    height: 195
                                    orientation: ListView.Horizontal
                                    spacing: 16
                                    clip: false
                                    boundsBehavior: Flickable.StopAtBounds
                                    flickDeceleration: UiConstants.flickDeceleration
                                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                                    cacheBuffer: UiConstants.cacheBuffer
                                    pixelAligned: UiConstants.pixelAligned
                                    reuseItems: true
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
