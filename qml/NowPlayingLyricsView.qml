import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    readonly property bool meterVisible: visible && waveRow.visible
    readonly property color recordRedHover: appWindow.recordRedHover
    readonly property color textPrimary: appWindow.textPrimary
    readonly property color textSecondary: appWindow.textSecondary
    readonly property color silverDim: appWindow.silverDim
    readonly property color surfaceElevated: appWindow.surfaceElevated
    readonly property color surfaceCard: appWindow.surfaceCard
    readonly property color borderVariant: appWindow.borderVariant
    readonly property color borderSubtle: appWindow.borderSubtle
    readonly property string displayFont: appWindow.displayFont
    readonly property string bodyFont: appWindow.bodyFont
    readonly property int lyricsFontSize: appWindow.lyricsFontSize
    anchors.fill: parent
    visible: opacity > 0.001
    opacity: root.appWindow.nowPlayingMode === "lyrics" ? 1.0 : 0.0
    scale: root.appWindow.nowPlayingMode === "lyrics" ? 1.0 : 0.98
    enabled: root.appWindow.nowPlayingMode === "lyrics"

    Behavior on opacity {
        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
    }
    Behavior on scale {
        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
    }

    // New lyrics fade in instead of the list swapping and jumping in one frame.
    property var shownLyrics: []
    Component.onCompleted: shownLyrics = appWindow.lyricDisplayItems
    Connections {
        target: root.appWindow
        function onLyricDisplayItemsChanged() { lyricsSwap.restart() }
    }
    SequentialAnimation {
        id: lyricsSwap
        NumberAnimation { target: lyricsListView; property: "opacity"; to: 0; duration: UiConstants.durationFast }
        ScriptAction { script: root.shownLyrics = root.appWindow.lyricDisplayItems }
        NumberAnimation { target: lyricsListView; property: "opacity"; to: 1; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
    }

    LyricsList {
        id: lyricsListView
        anchors.fill: parent
        items: root.shownLyrics
        lines: root.appWindow.parsedLyrics
        // While tapping, the line being stamped is a line number; breaks between lines also take rows.
        activeItemIndex: root.appWindow.lyricsTapSyncing
            ? root.shownLyrics.findIndex(item => item.type === "line" && item.lineIndex === root.appWindow.lyricsTapStamps.length)
            : root.appWindow.activeLyricDisplayIndex
        activeLineIndex: {
            if (root.appWindow.lyricsTapSyncing)
                return root.appWindow.lyricsTapStamps.length
            const active = root.appWindow.lyricDisplayItems[root.appWindow.activeLyricDisplayIndex]
            return active && active.type === "line" ? root.appWindow.activeLyricIndex : -1
        }
        positionMs: player.position
        playing: player.isPlaying
        fontSize: lyricsFontSize
        fontFamily: root.appWindow.lyricsFont || displayFont
        fontWeight: root.appWindow.lyricsFontWeight
        centered: root.appWindow.lyricsAlignment === "center"
        activeColor: root.appWindow.lyricsActiveStyle === "accent" ? recordRedHover : "#FFFFFF"
        enabled: !lyricsSwap.running
        onLineClicked: item => {
            if (root.appWindow.lyricsTapSyncing) root.appWindow.stampLyricLine()
            else if (item.startMs >= 0) player.seek(item.startMs)
        }

        Item {
            anchors.fill: parent
            visible: !root.appWindow.parsedLyrics || root.appWindow.parsedLyrics.length === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 18

                Item {
                    id: waveContainer
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: waveRow.implicitWidth
                    Layout.preferredHeight: 64
                    Layout.minimumHeight: 64
                    Layout.maximumHeight: 64

                    property real wavePhase: 0.0

                    NumberAnimation {
                        target: waveContainer
                        property: "wavePhase"
                        from: 0.0
                        to: 62.83185307179586
                        duration: 24000
                        loops: Animation.Infinite
                        running: player.isPlaying && waveContainer.visible
                    }

                    Row {
                        id: waveRow
                        anchors.centerIn: parent
                        spacing: 7

                        Repeater {
                            model: [0.45, 0.70, 0.88, 1.0, 0.88, 0.70, 0.45]
                            delegate: Rectangle {
                                id: waveBar
                                required property int index
                                required property real modelData
                                width: 5
                                radius: 2.5
                                color: recordRedHover
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property real harmonic: {
                                    const h1 = Math.sin(waveContainer.wavePhase * 1.5 + index * 0.95)
                                    const h2 = Math.cos(waveContainer.wavePhase * 2.2 - index * 0.65)
                                    return (h1 * 0.6 + h2 * 0.4) * 0.5 + 0.5
                                }
                                readonly property real energy: Math.max(0.20, Math.min(1.0, (player.audioLevel * 1.6) + 0.25))
                                readonly property real activeHeight: 8 + (harmonic * 46 * modelData * energy)

                                height: player.isPlaying ? activeHeight : 8
                                opacity: player.isPlaying ? (0.65 + 0.35 * Math.min(1.0, height / 50)) : 0.45

                                Behavior on height {
                                    enabled: !player.isPlaying
                                    NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: UiConstants.durationStd }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 6

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Instrumental")
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 28
                        font.weight: Font.Medium
                        font.letterSpacing: -0.3
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: player.currentTrack.artist ? qsTr("Composed by %1").arg(player.currentTrack.artist) : (player.currentTrack.title ? qsTr("Track by %1").arg(player.currentTrack.artist || qsTr("Unknown Artist")) : qsTr("No lyrics available"))
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 14
                    }
                }

                Item {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 6
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    Rectangle {
                        implicitWidth: searchRow.implicitWidth + 32
                        implicitHeight: 40
                        radius: 20
                        color: searchPillMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: 1
                        border.color: searchPillMouse.containsMouse ? borderVariant : borderSubtle

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: searchRow
                            anchors.centerIn: parent
                            spacing: 8

                            LucideIcon {
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                icon: "search"
                                color: recordRedHover
                            }

                            Label {
                                text: qsTr("Choose lyrics")
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: searchPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.openLyricsSearch()
                        }
                    }

                    Rectangle {
                        implicitWidth: artRow.implicitWidth + 32
                        implicitHeight: 40
                        radius: 20
                        color: artPillMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: 1
                        border.color: artPillMouse.containsMouse ? borderVariant : borderSubtle

                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: artRow
                            anchors.centerIn: parent
                            spacing: 8

                            LucideIcon {
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 15
                                icon: "disc"
                                color: silverDim
                            }

                            Label {
                                text: qsTr("Album Art")
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            id: artPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.appWindow.nowPlayingMode = "controls"
                            }
                        }
                    }
                }
            }
        }
    }

}

