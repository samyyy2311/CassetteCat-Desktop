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

    AppListView {
        id: lyricsListView
        Component.onCompleted: root.appWindow.lyricsListView = lyricsListView
        Component.onDestruction: {
            if (root.appWindow.lyricsListView === lyricsListView) root.appWindow.lyricsListView = null
        }
        anchors.fill: parent
        clip: true
        model: root.shownLyrics
        currentIndex: root.appWindow.activeLyricDisplayIndex
        spacing: 26
        interactive: root.shownLyrics.length > 0
        topMargin: Math.round(height * 0.38)
        bottomMargin: Math.round(height * 0.45)
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: Math.round(height * 0.36)
        preferredHighlightEnd: Math.round(height * 0.38)
        highlightMoveDuration: UiConstants.highlightDurationFull
        reuseItems: true
        ScrollBar.vertical: AutoHideScrollBar {}

        delegate: Item {
            id: lyricItem
            width: ListView.view.width
            readonly property bool isGap: modelData.type === "gap"
            readonly property bool isCurrent: Boolean(!isGap && root.appWindow.activeLyricDisplayIndex >= 0 && modelData.lineIndex === root.appWindow.activeLyricIndex && root.appWindow.lyricDisplayItems[root.appWindow.activeLyricDisplayIndex] && root.appWindow.lyricDisplayItems[root.appWindow.activeLyricDisplayIndex].type === "line")
            readonly property bool isSynced: !isGap
            readonly property bool gapActive: Boolean(isGap && player.position >= modelData.startMs && player.position <= modelData.endMs)
            height: isGap ? 72 : lyricTextLabel.implicitHeight + 14

            Label {
                id: lyricTextLabel
                width: Math.min(parent.width - 72, 920)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                visible: !lyricItem.isGap
                wrapMode: Text.WordWrap
                textFormat: Text.RichText
                text: lyricItem.isGap ? "" : root.appWindow.karaokeLyricHtml(modelData.lineIndex, modelData.text)
                color: isCurrent ? (root.appWindow.lyricsActiveStyle === "accent" ? recordRedHover : "#FFFFFF") : (lyricLineMouse.containsMouse ? textPrimary : (isSynced ? "#7E7A74" : textPrimary))
                horizontalAlignment: root.appWindow.lyricsAlignment === "center" ? Text.AlignHCenter : Text.AlignLeft
                font.family: displayFont
                font.pixelSize: lyricsFontSize
                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                font.letterSpacing: -0.3
                lineHeight: 1.35
                transformOrigin: Item.Center
                scale: isCurrent ? 1.03 : (lyricLineMouse.containsMouse ? 1.01 : 0.96)
                opacity: isCurrent ? 1.0 : (lyricLineMouse.containsMouse ? 0.75 : (isSynced ? 0.28 : 0.85))

                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on opacity { NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd } }
                Behavior on scale { NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: lyricItem.isGap
                opacity: lyricItem.gapActive ? 1.0 : 0.22

                Behavior on opacity { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }

                Repeater {
                    model: 3
                    delegate: Rectangle {
                        width: 7
                        height: 7
                        radius: 4
                        color: recordRedHover
                        y: 0
                        SequentialAnimation on y {
                            running: lyricItem.gapActive && player.isPlaying
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { to: -6; duration: 260; easing.type: Easing.OutSine }
                            NumberAnimation { to: 0; duration: 260; easing.type: Easing.InSine }
                            PauseAnimation { duration: (2 - index) * 150 }
                        }
                    }
                }
            }

            MouseArea {
                id: lyricLineMouse
                anchors.fill: parent
                enabled: !lyricsSwap.running
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: player.seek(modelData.startMs)
            }
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
                        text: "Instrumental"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 28
                        font.weight: Font.Medium
                        font.letterSpacing: -0.3
                    }

                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: player.currentTrack.artist ? ("Composed by " + player.currentTrack.artist) : (player.currentTrack.title ? ("Track by " + (player.currentTrack.artist || "Unknown Artist")) : "No lyrics available")
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
                                text: "Choose lyrics"
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
                                text: "Album Art"
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

