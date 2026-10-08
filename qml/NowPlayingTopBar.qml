import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var appWindow
    height: 64
    z: 10

    // The frosted round button every control on this bar uses.
    component GlassButton: PressDepthIconButton {
        boxSize: 38
        iconSize: 18
        tint: root.appWindow.silverDim
        hoverTint: root.appWindow.textPrimary
        backgroundColor: "#10FFFFFF"
        hoverBackgroundColor: "#24FFFFFF"
        borderColor: "#14FFFFFF"
        hoverBorderColor: "#30FFFFFF"
    }

    GlassButton {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        iconName: "chevron-down"
        tooltipText: "Close Now Playing"
        onClicked: root.appWindow.nowPlayingOpen = false
    }


    Row {
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Row {
            readonly property var lines: root.appWindow.parsedLyrics
            readonly property bool synced: lines.length > 0 && lines[0].timeMs >= 0
            readonly property bool syncing: root.appWindow.lyricsTapSyncing
            readonly property var track: root.appWindow.shownPlayer.currentTrack
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: root.appWindow.nowPlayingMode === "lyrics" && lines.length > 0

            Label {
                visible: parent.syncing
                anchors.verticalCenter: parent.verticalCenter
                text: "Press Space as each line starts  " + root.appWindow.lyricsTapStamps.length + " / " + parent.lines.length
                color: root.appWindow.textSecondary
                font.family: root.appWindow.bodyFont
                font.pixelSize: 12
            }

            SettingButton {
                visible: parent.syncing
                text: "Undo"
                iconName: "rotate-ccw"
                enabled: root.appWindow.lyricsTapStamps.length > 0
                onClicked: root.appWindow.lyricsTapStamps = root.appWindow.lyricsTapStamps.slice(0, -1)
            }

            SettingButton {
                visible: parent.syncing
                text: "Cancel"
                onClicked: root.appWindow.lyricsTapSyncing = false
            }

            SettingButton {
                visible: !parent.syncing
                text: "Choose Lyrics"
                iconName: "search"
                onClicked: root.appWindow.openLyricsSearch()
            }

            SettingButton {
                visible: !parent.syncing && !parent.synced && !!parent.track.filePath && !parent.track.remoteId && parent.track.format !== "STREAM"
                text: "Tap to Sync"
                iconName: "clock"
                onClicked: root.appWindow.startLyricsTapSync()
            }

            PressDepthIconButton {
                visible: parent.synced
                anchors.verticalCenter: parent.verticalCenter
                boxSize: 28
                iconSize: 14
                iconName: "minus"
                tooltipText: "Lyrics earlier"
                onClicked: root.appWindow.lyricsSyncOffsetMs -= 100
            }

            Label {
                visible: parent.synced
                anchors.verticalCenter: parent.verticalCenter
                text: (root.appWindow.lyricsSyncOffsetMs >= 0 ? "+" : "") + (root.appWindow.lyricsSyncOffsetMs / 1000).toFixed(1) + "s"
                color: root.appWindow.textSecondary
                font.family: root.appWindow.monoFont
                font.pixelSize: 10
            }

            PressDepthIconButton {
                visible: parent.synced
                anchors.verticalCenter: parent.verticalCenter
                boxSize: 28
                iconSize: 14
                iconName: "plus"
                tooltipText: "Lyrics later"
                onClicked: root.appWindow.lyricsSyncOffsetMs += 100
            }
        }

        GlassButton {
            visible: phoneRemote.controllerName !== ""
            iconName: "smartphone"
            highlighted: true
            tooltipText: "Controlled from " + phoneRemote.controllerName + ". Click to continue on it."
            onClicked: phoneRemote.continueOnPhone()
        }

        GlassButton {
            readonly property bool favorite: root.appWindow.isFavorite(root.appWindow.shownPlayer.currentTrack.filePath)
            iconName: "heart"
            visible: !!root.appWindow.shownPlayer.currentTrack.filePath
            highlighted: favorite
            tooltipText: favorite ? "Remove from Favorites" : "Add to Favorites"
            onClicked: root.appWindow.toggleFavorite(root.appWindow.shownPlayer.currentTrack.filePath)
        }

        GlassButton {
            iconName: "more-vertical"
            visible: !root.appWindow.phoneInDock
            tooltipText: "Track options"
            onClicked: root.appWindow.openTrackActionSheet(player.currentTrack)
        }

        GlassButton {
            iconName: "pip"
            tooltipText: "Open MiniPlayer"
            onClicked: root.appWindow.toggleMiniPlayer()
        }

        GlassButton {
            iconName: "quote"
            visible: !root.appWindow.phoneInDock
            highlighted: root.appWindow.nowPlayingMode === "lyrics"
            tooltipText: highlighted ? "Hide lyrics" : "Show lyrics"
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "lyrics"
        }

        GlassButton {
            iconName: "list"
            visible: !root.appWindow.phoneInDock
            highlighted: root.appWindow.nowPlayingMode === "queue"
            tooltipText: highlighted ? "Hide queue" : "Show queue"
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "queue"
        }

    }
}
