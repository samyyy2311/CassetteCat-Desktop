import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow
    required property var playerController

    signal remainingTimeToggled(bool value)

    ColumnLayout {
        id: metadataHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 88
        spacing: 4

        HoverMarqueeLabel {
            Layout.fillWidth: true
            text: root.playerController.currentTrack.title || "No Track Selected"
            textColor: "#FFFFFF"
            fontFamily: root.appWindow.displayFont
            pixelSize: 30
            weight: Font.Bold
            Layout.preferredHeight: 38
        }

        Label {
            id: artistLabel
            Layout.fillWidth: true
            text: {
                if (!root.playerController.currentTrack.title && !root.playerController.currentTrack.filePath) {
                    return "Select a track to start playback"
                }
                let artist = root.playerController.currentTrack.artist || "Unknown Artist"
                if (root.playerController.currentTrack.album) artist += " • " + root.playerController.currentTrack.album
                return artist
            }
            color: (!root.playerController.currentTrack.title && !root.playerController.currentTrack.filePath)
                ? root.appWindow.textSecondary
                : (artistMouseArea.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary)
            font.family: root.appWindow.displayFont
            font.pixelSize: 15
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
            maximumLineCount: 1
            elide: Text.ElideRight

            Behavior on color { ColorAnimation { duration: 130 } }

            MouseArea {
                id: artistMouseArea
                anchors.fill: parent
                enabled: !!root.playerController.currentTrack.album
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.appWindow.openCoverSearch(root.playerController.currentTrack.album, root.playerController.currentTrack.artist || "", root.playerController.currentTrack.filePath || "")
                    } else {
                        root.appWindow.nowPlayingOpen = false
                        root.appWindow.openCatalogDetail("album", root.playerController.currentTrack.album, root.playerController.currentTrack)
                    }
                }
            }
        }

    }

    AudioSeeker {
        id: deckSeeker
        anchors.top: metadataHeader.bottom
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28
        position: root.playerController.position
        duration: root.playerController.duration
        showRemainingTime: root.appWindow.showRemainingTime
        paletteSource: root.appWindow
        onSeekRequested: positionMs => root.playerController.seek(positionMs)
        onRemainingToggled: value => root.remainingTimeToggled(value)
    }

    RowLayout {
        id: deckTransportRow
        anchors.top: deckSeeker.bottom
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 18

            TransportButton {
                buttonSize: 42
                paletteSource: root.appWindow
                iconName: "shuffle"
                accented: root.playerController.shuffleEnabled
                tooltipText: root.playerController.shuffleEnabled ? "Shuffle On" : "Shuffle Off"
                onClicked: root.appWindow.toggleQueueShuffle()
            }

            TransportButton {
                buttonSize: 52
                paletteSource: root.appWindow
                iconName: "skip-back"
                iconColor: root.appWindow.textPrimary
                tooltipText: "Previous"
                onClicked: root.appWindow.playPrevious()
            }

            TransportButton {
                buttonSize: 72
                paletteSource: root.appWindow
                iconName: root.appWindow.playerVisuallyPlaying ? "pause" : "play"
                accented: true
                iconColor: root.appWindow.recordRed
                tooltipText: root.appWindow.playerVisuallyPlaying ? "Pause" : "Play"
                onClicked: root.playerController.togglePlay()
            }

            TransportButton {
                buttonSize: 52
                paletteSource: root.appWindow
                iconName: "skip-forward"
                iconColor: root.appWindow.textPrimary
                tooltipText: "Next"
                onClicked: root.appWindow.playNext()
            }

            TransportButton {
                buttonSize: 42
                paletteSource: root.appWindow
                iconName: root.appWindow.repeatMode === 2 ? "repeat-1" : "repeat"
                accented: root.appWindow.repeatMode > 0
                iconColor: root.appWindow.repeatMode > 0 ? root.appWindow.recordRed : root.appWindow.textPrimary
                tooltipText: root.appWindow.repeatMode === 2 ? "Repeat Track" : (root.appWindow.repeatMode === 1 ? "Repeat All" : "Repeat Off")
                onClicked: root.appWindow.toggleRepeat()
            }
        }

        Item { Layout.fillWidth: true }
    }

    RowLayout {
        anchors.top: deckTransportRow.bottom
        anchors.topMargin: 20
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        Item { Layout.fillWidth: true }

        VolumeControl {
            Layout.preferredWidth: 200
            paletteSource: root.appWindow
            volume: root.playerController.volume
            onVolumeAdjusted: value => {
                if (root.appWindow && root.appWindow.setPlayerVolume) root.appWindow.setPlayerVolume(value)
                else root.playerController.setVolume(value)
            }
        }

        Item { Layout.fillWidth: true }
    }
}
