import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var appWindow
    height: 64
    z: 10

    // The round button every control on this bar uses. Its dark fill keeps it readable on a light backdrop.
    component GlassButton: PressDepthIconButton {
        boxSize: 38
        iconSize: 18
        tint: root.appWindow.textSecondary
        hoverTint: root.appWindow.textPrimary
        backgroundColor: "#4D000000"
        hoverBackgroundColor: "#80000000"
        borderColor: "#1AFFFFFF"
        hoverBorderColor: "#40FFFFFF"
    }

    GlassButton {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        iconName: "chevron-down"
        tooltipText: qsTr("Close Now Playing")
        onClicked: root.appWindow.nowPlayingOpen = false
    }


    Row {
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

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
                text: qsTr("Press Space as each line starts  %1 / %2").arg(root.appWindow.lyricsTapStamps.length).arg(parent.lines.length)
                color: root.appWindow.textSecondary
                font.family: root.appWindow.bodyFont
                font.pixelSize: 12
            }

            SettingButton {
                visible: parent.syncing
                text: qsTr("Undo")
                iconName: "rotate-ccw"
                enabled: root.appWindow.lyricsTapStamps.length > 0
                onClicked: root.appWindow.lyricsTapStamps = root.appWindow.lyricsTapStamps.slice(0, -1)
            }

            SettingButton {
                visible: parent.syncing
                text: qsTr("Cancel")
                onClicked: root.appWindow.lyricsTapSyncing = false
            }

            SettingButton {
                visible: !parent.syncing
                text: qsTr("Choose Lyrics")
                iconName: "search"
                onClicked: root.appWindow.openLyricsSearch()
            }

            SettingButton {
                visible: !parent.syncing && !parent.synced && !!parent.track.filePath && !parent.track.remoteId && parent.track.format !== "STREAM"
                text: qsTr("Tap to Sync")
                iconName: "clock"
                onClicked: root.appWindow.startLyricsTapSync()
            }

            PressDepthIconButton {
                visible: parent.synced
                anchors.verticalCenter: parent.verticalCenter
                boxSize: 28
                iconSize: 14
                iconName: "minus"
                tooltipText: qsTr("Lyrics earlier")
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
                tooltipText: qsTr("Lyrics later")
                onClicked: root.appWindow.lyricsSyncOffsetMs += 100
            }
        }

        GlassButton {
            visible: phoneRemote.controllerName !== ""
            iconName: "smartphone"
            highlighted: true
            tooltipText: qsTr("Controlled from %1. Click to continue on it.").arg(phoneRemote.controllerName)
            onClicked: phoneRemote.continueOnPhone()
        }

        GlassButton {
            readonly property bool favorite: root.appWindow.isFavorite(root.appWindow.shownPlayer.currentTrack.filePath)
            iconName: "heart"
            visible: !!root.appWindow.shownPlayer.currentTrack.filePath
            highlighted: favorite
            tooltipText: favorite ? qsTr("Remove from Favorites") : qsTr("Add to Favorites")
            onClicked: root.appWindow.toggleFavorite(root.appWindow.shownPlayer.currentTrack.filePath)
        }

        GlassButton {
            iconName: "more-vertical"
            visible: !root.appWindow.phoneInDock
            tooltipText: qsTr("Track options")
            onClicked: root.appWindow.openTrackActionSheet(player.currentTrack)
        }

        GlassButton {
            readonly property bool fullScreen: root.appWindow.visibility === Window.FullScreen
            iconName: fullScreen ? "minimize-2" : "maximize-2"
            tooltipText: fullScreen ? qsTr("Exit full screen") : qsTr("Full screen")
            onClicked: root.appWindow.toggleFullScreen()
        }

        GlassButton {
            iconName: "pip"
            tooltipText: qsTr("Open MiniPlayer")
            onClicked: root.appWindow.toggleMiniPlayer()
        }

        GlassButton {
            iconName: "quote"
            visible: !root.appWindow.phoneInDock
            highlighted: root.appWindow.nowPlayingMode === "lyrics"
            tooltipText: highlighted ? qsTr("Hide lyrics") : qsTr("Show lyrics")
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "lyrics"
        }

        GlassButton {
            iconName: "list"
            visible: !root.appWindow.phoneInDock
            highlighted: root.appWindow.nowPlayingMode === "queue"
            tooltipText: highlighted ? qsTr("Hide queue") : qsTr("Show queue")
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "queue"
        }

    }
}
