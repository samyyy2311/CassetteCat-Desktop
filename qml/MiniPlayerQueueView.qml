import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var miniPlayer

    function scrollToCurrentTrack() {
        if (!miniPlayer.queueEntries || !miniPlayer.queueEntries.length) return
        for (let i = 0; i < miniPlayer.queueEntries.length; ++i) {
            if (miniPlayer.queueEntries[i].type === "current") {
                queueListView.currentIndex = i
                queueListView.positionViewAtIndex(i, ListView.Center)
                return
            }
        }
    }

    onVisibleChanged: {
        if (visible) Qt.callLater(scrollToCurrentTrack)
    }

    Connections {
        target: miniPlayer.playerController
        function onCurrentTrackChanged() {
            if (root.visible) Qt.callLater(root.scrollToCurrentTrack)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            QueueModel {
                id: queueModel
                entries: miniPlayer.queueEntries
            }

            AppListView {
                id: queueListView
                activeFocusOnTab: true
                onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
                anchors.fill: parent
                clip: true
                model: queueModel
                spacing: 2
                reuseItems: true
                ScrollBar.vertical: AutoHideScrollBar {}

                move: Transition { NumberAnimation { property: "y"; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }
                displaced: Transition { NumberAnimation { property: "y"; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }

                delegate: QueueTrackRow {
                    width: ListView.view.width - 4
                    entry: queueModel.entryByKey[model.key] || ({})
                    compact: true
                    allowCurrentActivation: true
                    onTrackActivated: track => miniPlayer.playTrack(track)
                }

                Label {
                    anchors.centerIn: parent
                    visible: !miniPlayer.queueEntries || miniPlayer.queueEntries.length === 0
                    text: qsTr("Queue is empty")
                    color: miniPlayer.silverDim
                    font.family: miniPlayer.displayFont
                    font.pixelSize: 11
                }
            }
        }

        MiniPlayerControls {
            Layout.fillWidth: true
            miniPlayer: root.miniPlayer
        }
    }
}
