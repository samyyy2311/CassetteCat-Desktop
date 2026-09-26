import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow
    required property var playerController
    anchors.fill: parent
    visible: opacity > 0.001
    opacity: appWindow.nowPlayingMode === "queue" ? 1.0 : 0.0
    scale: appWindow.nowPlayingMode === "queue" ? 1.0 : 0.97
    enabled: appWindow.nowPlayingMode === "queue"

    Behavior on opacity {
        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
    }
    Behavior on scale {
        NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd }
    }

    QueueModel {
        id: queueModel
        entries: root.appWindow.queueEntries
    }

    function scrollToCurrentTrack() {
        const entries = appWindow.queueEntries
        if (!entries || !entries.length) return
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].type === "current") {
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
        target: root.playerController
        function onCurrentTrackChanged() {
            if (root.visible) Qt.callLater(root.scrollToCurrentTrack)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        AppListView {
            id: queueListView
            activeFocusOnTab: true
            onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: queueModel
            spacing: 4
            reuseItems: true
            ScrollBar.vertical: AutoHideScrollBar { anchors.rightMargin: 8 }

            move: Transition { NumberAnimation { property: "y"; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }
            displaced: Transition { NumberAnimation { property: "y"; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }

            delegate: QueueTrackRow {
                width: ListView.view.width - 24
                paletteSource: root.appWindow
                entry: queueModel.entryByKey[model.key] || ({})
                removeEnabled: entry.queueEditable === true
                playNextEnabled: entry.queueEditable === true
                reorderEnabled: entry.queueEditable === true
                onTrackActivated: track => root.appWindow.playFromQueue(track)
                onPlayNextRequested: track => root.appWindow.moveQueuedTrackNext(track)
                onTrackRemovalRequested: track => root.appWindow.removeQueuedTrack(track)
                onTrackReorderRequested: (srcTrack, targetTrack, srcIndex, targetIndex) => root.appWindow.reorderQueuedTrack(srcTrack, targetTrack, srcIndex, targetIndex)
            }
        }
    }
}
