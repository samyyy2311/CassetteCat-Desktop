import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "LyricsText.js" as LyricsText

Window {
    id: root
    title: "CassetteCat MiniPlayer"
    color: "transparent"
    transientParent: null
    flags: Qt.Window | Qt.FramelessWindowHint | (alwaysOnTop ? Qt.WindowStaysOnTopHint : 0)
    visible: false

    onVisibleChanged: {
        if (!visible) releaseResources()
    }

    property string mode: "compact"

    readonly property int artDimension: 360

    width: mode === "art" ? (artDimension + 12) : 362
    height: mode === "art" ? (artDimension + 12) : (mode === "compact" ? 158 : 492)
    minimumWidth: mode === "art" ? (artDimension + 12) : 332
    maximumWidth: mode === "art" ? (artDimension + 12) : 412
    minimumHeight: mode === "art" ? (artDimension + 12) : (mode === "compact" ? 158 : 432)
    maximumHeight: mode === "art" ? (artDimension + 12) : (mode === "compact" ? 158 : 652)

    onModeChanged: {
        volumePillVisible = false
        if (mode === "art") {
            root.width = artDimension + 12
            root.height = artDimension + 12
        } else if (mode === "compact") {
            root.width = 362
            root.height = 158
        } else {
            root.width = 362
            root.height = 492
        }
        if (Screen.desktopAvailableHeight > 0 && y + height > Screen.desktopAvailableHeight - 30) {
            y = Math.max(20, Screen.desktopAvailableHeight - height - 30)
        }
    }

    readonly property color surfaceBg: "#161514"
    readonly property color surfaceCard: "#1D1C1A"
    readonly property color surfaceElevated: "#252320"
    readonly property color surfacePill: "#23211F"
    readonly property color borderCard: "#2B2825"
    property color accentColor: "#C23B30"
    property color accentHover: "#D64337"
    readonly property color recordRed: accentColor
    readonly property color recordRedHover: accentHover
    readonly property color textPrimary: "#F7F3EE"
    readonly property color textSecondary: "#96918A"
    readonly property color silverDim: "#6B6762"

    property bool alwaysOnTop: true
    property int albumArtRadius: 16
    property bool playerVisuallyPlaying: false
    property int repeatMode: 0
    property var favoriteTracks: ({})
    function isFavorite(path) {
        if (!path || !root.favoriteTracks) return false
        const raw = String(path).trim()
        const norm = raw.replace(/\\/g, "/").replace(/^\/+([A-Za-z]:\/)/, "$1").toLowerCase()
        return !!(root.favoriteTracks[raw] || root.favoriteTracks[norm])
    }
    property string displayFont: (typeof displayFontFamily !== "undefined" && displayFontFamily.length > 0) ? displayFontFamily : "Space Grotesk"
    property string bodyFont: (typeof bodyFontFamily !== "undefined" && bodyFontFamily.length > 0) ? bodyFontFamily : "IBM Plex Sans"
    property string monoFont: (typeof monoFontFamily !== "undefined" && monoFontFamily.length > 0) ? monoFontFamily : "IBM Plex Mono"
    property int tracksCount: 0
    property bool showFormatBadges: false
    property var queueEntries: []
    property var parsedLyrics: []
    property int activeLyricIndex: -1
    property var lyricDisplayItems: []
    property int activeLyricDisplayIndex: -1
    property string lyricsActiveStyle: "white"
    property string lyricsAlignment: "left"
    property int lyricsFontSize: 28
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 100

    property bool volumePillVisible: false
    property bool showRemainingTime: true
    property bool artSeeking: false

    readonly property var playerController: player
    readonly property bool audioMeterVisible: lyricsView.meterVisible
        && root.visible && root.visibility !== Window.Minimized

    signal restoreRequested()
    signal closeRequested()
    signal playPrevious()
    signal playNext()
    signal toggleRepeat()
    signal toggleShuffle()
    signal toggleFavorite(string filePath)
    signal toggleAlwaysOnTop()
    signal playTrack(var track)

    Shortcut { sequence: "Ctrl+M"; onActivated: root.restoreRequested() }
    Shortcut { sequence: "Ctrl+Shift+M"; onActivated: root.restoreRequested() }
    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (volumePillVisible) volumePillVisible = false
            else if (root.mode !== "compact") root.mode = "compact"
            else root.restoreRequested()
        }
    }
    Shortcut { sequence: "Space"; onActivated: player.togglePlay() }

    onClosing: close => {
        close.accepted = false
        root.closeRequested()
    }

    function formatTime(ms) {
        if (!ms || ms <= 0) return "0:00"
        const totalSec = Math.floor(ms / 1000)
        const m = Math.floor(totalSec / 60)
        const s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function formatRemaining(pos, dur) {
        if (!dur || dur <= 0 || pos > dur) return "-0:00"
        return "-" + formatTime(dur - pos)
    }

    function karaokeLyricHtml(index, text) {
        if (index !== activeLyricIndex) return LyricsText.escape(text)
        const color = lyricsActiveStyle === "accent" ? accentHover : Qt.color("#FFFFFF")
        return LyricsText.karaoke(parsedLyrics, index, activeLyricIndex, player.position, color, text)
    }

    MouseArea {
        anchors.fill: parent
        z: 90
        visible: root.volumePillVisible
        onClicked: root.volumePillVisible = false
    }

    Rectangle {
        id: cardShadow
        anchors.fill: card
        anchors.margins: -1
        radius: card.radius + 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(255, 255, 255, 0.08)
        z: 0
        antialiasing: true
    }

    Item {
        id: windowMask
        anchors.fill: card
        visible: false
        layer.enabled: true
        layer.smooth: true

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "#FFFFFF"
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 14
        color: root.surfaceBg
        clip: true
        z: 1

        // Antialiased alpha-mask prevents sharp corner bleed
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: windowMask
        }

        Item {
            id: compactContainer
            anchors.fill: parent
            visible: root.mode === "compact"

            MouseArea {
                anchors.fill: parent
                z: -1
                property point pressPos
                onPressed: mouse => { pressPos = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: mouse => {
                    const deltaX = Math.abs(mouse.x - pressPos.x)
                    const deltaY = Math.abs(mouse.y - pressPos.y)
                    if (deltaX > 3 || deltaY > 3) root.startSystemMove()
                }
                onDoubleClicked: root.restoreRequested()
            }

            HoverHandler { id: compactHoverHandler }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 8
                anchors.rightMargin: 10
                width: compactControlsRow.implicitWidth + 8
                height: 26
                radius: 13
                color: compactHoverHandler.hovered ? "#22201E" : "#1A1918"
                border.width: 1
                border.color: compactHoverHandler.hovered ? "#35FFFFFF" : "#1AFFFFFF"
                z: 20

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Row {
                    id: compactControlsRow
                    anchors.centerIn: parent
                    spacing: 2
                    padding: 2

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: root.alwaysOnTop ? root.recordRed : (pinHover.containsMouse ? "#25FFFFFF" : "transparent")
                        scale: pinHover.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            icon: "pin"
                            color: root.alwaysOnTop ? "#FFFFFF" : (pinHover.containsMouse ? root.textPrimary : root.silverDim)
                        }
                        MouseArea {
                            id: pinHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleAlwaysOnTop()
                        }
                        AppToolTip {
                            text: root.alwaysOnTop ? "Unpin from top" : "Keep on top"
                            visibleTarget: pinHover.containsMouse
                            delay: 350
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: minHover.containsMouse ? "#25FFFFFF" : "transparent"
                        scale: minHover.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            icon: "minus"
                            color: minHover.containsMouse ? root.textPrimary : root.silverDim
                        }
                        MouseArea {
                            id: minHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showMinimized()
                        }
                        AppToolTip {
                            text: "Minimize"
                            visibleTarget: minHover.containsMouse
                            delay: 350
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: expHover.containsMouse ? "#25FFFFFF" : "transparent"
                        scale: expHover.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            icon: "maximize-2"
                            color: expHover.containsMouse ? root.textPrimary : root.silverDim
                        }
                        MouseArea {
                            id: expHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.restoreRequested()
                        }
                        AppToolTip {
                            text: "Restore full player"
                            visibleTarget: expHover.containsMouse
                            delay: 350
                        }
                    }

                    Rectangle {
                        width: 22; height: 22; radius: 11
                        color: closeHover.containsMouse ? "#E53935" : "transparent"
                        scale: closeHover.pressed ? 0.90 : 1.0
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 80 } }

                        LucideIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            icon: "x"
                            color: closeHover.containsMouse ? "#FFFFFF" : root.silverDim
                        }
                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.closeRequested()
                        }
                        AppToolTip {
                            text: "Close miniplayer"
                            visibleTarget: closeHover.containsMouse
                            delay: 350
                        }
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                z: 1

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 50; height: 50
                        radius: root.albumArtRadius === 0 ? 0 : (root.albumArtRadius <= 8 ? 5 : 8)
                        clip: true
                        color: root.surfaceCard
                        border.width: 1
                        border.color: root.borderCard

                        Cover {
                            anchors.fill: parent
                            track: player.currentTrack
                            radius: parent.radius
                            keepPreviousArtwork: true
                            cacheArtwork: true
                            fillMode: Image.PreserveAspectCrop
                            visible: !!(player.currentTrack && player.currentTrack.filePath)
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 26; height: 26
                            source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
                            fillMode: Image.PreserveAspectFit
                            visible: !(player.currentTrack && player.currentTrack.filePath)
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "#80000000"
                            opacity: coverHoverM.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }
                            LucideIcon { anchors.centerIn: parent; width: 14; height: 14; icon: "disc"; color: "#FFFFFF" }
                        }

                        MouseArea {
                            id: coverHoverM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.mode = "art"
                        }

                        AppToolTip {
                            text: "Switch to artwork mode"
                            visibleTarget: coverHoverM.containsMouse
                            delay: 350
                        }
                    }

                    ColumnLayout {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 60
                        anchors.rightMargin: 115
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            text: (player.currentTrack && player.currentTrack.title)
                                ? player.currentTrack.title
                                : (root.tracksCount > 0 ? "CassetteCat" : "Library Empty")
                            color: root.textPrimary
                            font.family: root.displayFont
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }

                        Label {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                if (player.currentTrack && player.currentTrack.artist) {
                                    return player.currentTrack.album
                                        ? player.currentTrack.artist + " — " + player.currentTrack.album
                                        : player.currentTrack.artist
                                }
                                return root.tracksCount > 0 ? "Ready to play" : "Select folder"
                            }
                            color: root.textSecondary
                            font.family: root.bodyFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    spacing: 8

                    Label {
                        Layout.preferredWidth: 32
                        text: root.formatTime(player.position)
                        color: root.silverDim
                        font.family: root.monoFont
                        font.pixelSize: 10
                        elide: Text.ElideNone
                    }

                    Item {
                        id: compactSeekArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16

                        Rectangle {
                            id: compactGrooveBar
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 2.5
                            radius: 1.25
                            color: "#2C2926"

                            Rectangle {
                                anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                                width: Math.round(compactGrooveBar.width * (player.duration > 0 ? Math.min(1.0, Math.max(0.0, player.position / player.duration)) : 0.0))
                                radius: 1.25
                                color: root.recordRed
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(compactGrooveBar.width - width, Math.round(compactGrooveBar.width * (player.duration > 0 ? Math.min(1.0, Math.max(0.0, player.position / player.duration)) : 0.0)) - width / 2))
                                width: (compactSeekM.containsMouse || compactSeekM.pressed) ? 7 : 0
                                height: width
                                radius: width / 2
                                color: "#FFFFFF"
                                border.width: 1.5
                                border.color: root.recordRed
                                opacity: (compactSeekM.containsMouse || compactSeekM.pressed) ? 1.0 : 0.0

                                Behavior on width { NumberAnimation { duration: 100 } }
                                Behavior on height { NumberAnimation { duration: 100 } }
                            }
                        }

                        MouseArea {
                            id: compactSeekM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function applySeek(mouseX) {
                                if (player.duration > 0) {
                                    const frac = Math.max(0.0, Math.min(1.0, mouseX / compactSeekArea.width))
                                    player.seek(Math.floor(frac * player.duration))
                                }
                            }

                            onPressed: mouse => applySeek(mouse.x)
                            onPositionChanged: mouse => { if (pressed) applySeek(mouse.x) }
                        }
                    }

                    Label {
                        Layout.preferredWidth: 36
                        text: root.showRemainingTime
                            ? root.formatRemaining(player.position, player.duration)
                            : root.formatTime(player.duration)
                        color: root.silverDim
                        font.family: root.monoFont
                        font.pixelSize: 10
                        elide: Text.ElideNone
                        horizontalAlignment: Text.AlignRight

                        MouseArea {
                            id: compactTimeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showRemainingTime = !root.showRemainingTime
                        }

                        AppToolTip {
                            targetItem: compactTimeMouse
                            text: root.showRemainingTime ? "Switch to duration" : "Switch to remaining time"
                            visibleTarget: compactTimeMouse.containsMouse
                            delay: 350
                        }
                    }
                }

                Item {
                    id: bottomControlsArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    implicitHeight: 36
                    z: 5

                    Row {
                        id: leftControls
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        visible: !root.volumePillVisible

                        Item {
                            width: 28; height: 28
                            LucideIcon {
                                anchors.centerIn: parent; width: 16; height: 16
                                icon: player.volume <= 0.001 ? "volume-x" : (player.volume < 0.5 ? "volume-1" : "volume-2")
                                color: volBtnM.containsMouse ? root.textPrimary : root.textSecondary
                            }
                            MouseArea { id: volBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.volumePillVisible = true }
                        }

                        Item {
                            width: 28; height: 28
                            readonly property bool isFav: player.currentTrack && root.isFavorite(player.currentTrack.filePath)
                            LucideIcon {
                                anchors.centerIn: parent; width: 16; height: 16; icon: "heart"
                                color: parent.isFav ? root.recordRed : (favBtnM.containsMouse ? root.textPrimary : root.silverDim)
                            }
                            MouseArea {
                                id: favBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (player.currentTrack && player.currentTrack.filePath) root.toggleFavorite(player.currentTrack.filePath)
                            }
                        }
                    }

                    // In-Place Volume Slider (replaces left group when open, never collides with Prev)
                    MiniPlayerVolumePill {
                        id: inlineVolPill
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        playerController: root.playerController
                        surfacePill: root.surfacePill
                        borderCard: root.borderCard
                        accentColor: root.recordRed
                        silverDim: root.silverDim
                        volumeLimitEnabled: root.volumeLimitEnabled
                        maxVolumePercent: root.maxVolumePercent
                        visible: opacity > 0.001
                        opacity: root.volumePillVisible ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }
                    }

                    Row {
                        id: centerControls
                        anchors.centerIn: parent
                        spacing: 8

                        Item {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property bool active: player.shuffleEnabled
                            LucideIcon {
                                anchors.centerIn: parent; width: 15; height: 15; icon: "shuffle"
                                color: parent.active ? root.recordRed : (shufBtnM.containsMouse ? root.textPrimary : root.textSecondary)
                            }
                            MouseArea { id: shufBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleShuffle() }
                        }

                        Item {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            LucideIcon {
                                anchors.centerIn: parent; width: 18; height: 18; icon: "skip-back"
                                color: prevBtnM.containsMouse ? root.textPrimary : root.textSecondary
                            }
                            MouseArea { id: prevBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.playPrevious() }
                        }

                        Item {
                            width: 36; height: 36
                            anchors.verticalCenter: parent.verticalCenter
                            scale: playBtnM.pressed ? 0.92 : (playBtnM.containsMouse ? 1.08 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 90 } }

                            LucideIcon {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: (player.isPlaying || root.playerVisuallyPlaying) ? 0 : 1
                                width: 22; height: 22
                                icon: (player.isPlaying || root.playerVisuallyPlaying) ? "pause" : "play"
                                color: playBtnM.containsMouse ? root.recordRedHover : root.textPrimary
                            }
                            MouseArea { id: playBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: player.togglePlay() }
                        }

                        Item {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            LucideIcon {
                                anchors.centerIn: parent; width: 18; height: 18; icon: "skip-forward"
                                color: nextBtnM.containsMouse ? root.textPrimary : root.textSecondary
                            }
                            MouseArea { id: nextBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.playNext() }
                        }

                        Item {
                            width: 28; height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property bool active: root.repeatMode > 0
                            LucideIcon {
                                anchors.centerIn: parent; width: 15; height: 15
                                icon: root.repeatMode === 2 ? "repeat-1" : "repeat"
                                color: parent.active ? root.recordRed : (repBtnM.containsMouse ? root.textPrimary : root.textSecondary)
                            }
                            MouseArea { id: repBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleRepeat() }
                        }
                    }

                    Row {
                        id: rightControls
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Item {
                            width: 28; height: 28
                            LucideIcon {
                                anchors.centerIn: parent; width: 15; height: 15; icon: "quote"
                                color: root.mode === "lyrics" ? root.recordRed : (lyrBtnM.containsMouse ? root.textPrimary : root.textSecondary)
                            }
                            MouseArea { id: lyrBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.mode = (root.mode === "lyrics" ? "compact" : "lyrics") }
                        }

                        Item {
                            width: 28; height: 28
                            LucideIcon {
                                anchors.centerIn: parent; width: 15; height: 15; icon: "list"
                                color: root.mode === "queue" ? root.recordRed : (qBtnM.containsMouse ? root.textPrimary : root.textSecondary)
                            }
                            MouseArea { id: qBtnM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.mode = (root.mode === "queue" ? "compact" : "queue") }
                        }
                    }
                }
            }
        }

        MiniPlayerArtView {
            anchors.fill: parent
            miniPlayer: root
        }

        MiniPlayerSubpageHeader {
            id: subpageHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            visible: root.mode === "lyrics" || root.mode === "queue"
            miniPlayer: root
        }

        MiniPlayerLyricsView {
            id: lyricsView
            anchors.top: subpageHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            visible: root.mode === "lyrics"
            miniPlayer: root
        }

        MiniPlayerQueueView {
            anchors.top: subpageHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 10
            visible: root.mode === "queue"
            miniPlayer: root
        }
    }

    // Crisp, antialiased outer border stroke on top of all card contents (never clipped or masked)
    Rectangle {
        id: cardBorderStroke
        anchors.fill: card
        radius: card.radius
        color: "transparent"
        border.width: 1
        border.color: cardHoverHandler.hovered ? "#55FFFFFF" : "#32FFFFFF"
        z: 100
        antialiasing: true
        Behavior on border.color { ColorAnimation { duration: 140 } }
    }

    HoverHandler {
        id: cardHoverHandler
        target: card
    }
}
