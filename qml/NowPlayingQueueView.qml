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

    Behavior on opacity {
        NumberAnimation { duration: 280; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        ListView {
            id: queueListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.appWindow.queueEntries
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar { anchors.rightMargin: 8 }

            delegate: QueueTrackRow {
                width: ListView.view.width - 24
                paletteSource: root.appWindow
                entry: modelData
                removeEnabled: modelData.queueEditable === true
                playNextEnabled: modelData.queueEditable === true
                onTrackActivated: track => root.appWindow.playFromQueue(track)
                onPlayNextRequested: track => root.appWindow.moveQueuedTrackNext(track)
                onTrackRemovalRequested: track => root.appWindow.removeQueuedTrack(track)
            }
        }
    }
}
