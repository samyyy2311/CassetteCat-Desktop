import QtQuick
import QtQuick.Layouts

// The seek bar and playback buttons the mini player shows in each of its views.
ColumnLayout {
    id: root
    required property var miniPlayer
    // The cover view draws its own seek bar over the artwork.
    property bool showSeeker: true
    spacing: 4

    AudioSeeker {
        Layout.fillWidth: true
        visible: root.showSeeker
        position: root.miniPlayer.playerController.position
        duration: root.miniPlayer.playerController.duration
        showRemainingTime: root.miniPlayer.showRemainingTime
        onSeekRequested: positionMs => root.miniPlayer.playerController.seek(positionMs)
        onRemainingToggled: value => root.miniPlayer.showRemainingTime = value
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        implicitHeight: 36
        z: 5

        Row {
            id: leftControls
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            visible: !root.miniPlayer.volumePillVisible

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                filled: false
                iconName: root.miniPlayer.playerController.volume <= 0.001 ? "volume-x" : (root.miniPlayer.playerController.volume < 0.5 ? "volume-1" : "volume-2")
                iconColor: root.miniPlayer.textSecondary
                tooltipText: qsTr("Volume")
                onClicked: root.miniPlayer.volumePillVisible = true
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                filled: false
                iconName: "heart"
                readonly property bool isFav: !!(root.miniPlayer.playerController.currentTrack && root.miniPlayer.isFavorite(root.miniPlayer.playerController.currentTrack.filePath))
                iconColor: isFav ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                tooltipText: isFav ? qsTr("Remove from favorites") : qsTr("Add to favorites")
                onClicked: if (root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath) root.miniPlayer.toggleFavorite(root.miniPlayer.playerController.currentTrack.filePath)
            }
        }

        // In-Place Volume Slider (replaces left group when open, never collides with Prev)
        MiniPlayerVolumePill {
            id: inlineVolPill
            onCloseRequested: root.miniPlayer.volumePillVisible = false
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            playerController: root.miniPlayer.playerController
            surfacePill: root.miniPlayer.surfacePill
            borderCard: root.miniPlayer.borderCard
            accentColor: root.miniPlayer.recordRed
            silverDim: root.miniPlayer.silverDim
            visible: opacity > 0.001
            opacity: root.miniPlayer.volumePillVisible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }
        }

        Row {
            id: centerControls
            anchors.verticalCenter: parent.verticalCenter
            // Centred, but moved right while the volume slider is open so the two never overlap.
            x: Math.max((root.miniPlayer.volumePillVisible ? inlineVolPill.width : leftControls.width) + 8,
                        Math.round((parent.width - width) / 2))
            spacing: 8

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                iconName: "shuffle"
                accented: root.miniPlayer.playerController.shuffleEnabled
                tooltipText: root.miniPlayer.playerController.shuffleEnabled ? qsTr("Shuffle On") : qsTr("Shuffle Off")
                onClicked: root.miniPlayer.toggleShuffle()
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 30
                iconName: "skip-back"
                tooltipText: qsTr("Previous")
                onClicked: root.miniPlayer.playPrevious()
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 36
                iconName: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? "pause" : "play"
                accented: true
                tooltipText: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? qsTr("Pause") : qsTr("Play")
                onClicked: root.miniPlayer.playerController.togglePlay()
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 30
                iconName: "skip-forward"
                tooltipText: qsTr("Next")
                onClicked: root.miniPlayer.playNext()
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                iconName: root.miniPlayer.repeatMode === 2 ? "repeat-1" : "repeat"
                accented: root.miniPlayer.repeatMode > 0
                tooltipText: root.miniPlayer.repeatMode === 2 ? qsTr("Repeat Track") : (root.miniPlayer.repeatMode === 1 ? qsTr("Repeat All") : qsTr("Repeat Off"))
                onClicked: root.miniPlayer.toggleRepeat()
            }
        }

        Row {
            id: rightControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            // There's no room for these beside the open volume slider.
            visible: !root.miniPlayer.volumePillVisible
            spacing: 6

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                filled: false
                iconName: "quote"
                iconColor: root.miniPlayer.mode === "lyrics" ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                tooltipText: qsTr("Lyrics")
                onClicked: root.miniPlayer.mode = (root.miniPlayer.mode === "lyrics" ? "compact" : "lyrics")
            }

            TransportButton {
                anchors.verticalCenter: parent.verticalCenter
                buttonSize: 28
                filled: false
                iconName: "list"
                iconColor: root.miniPlayer.mode === "queue" ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                tooltipText: qsTr("Queue")
                onClicked: root.miniPlayer.mode = (root.miniPlayer.mode === "queue" ? "compact" : "queue")
            }
        }
    }
}
