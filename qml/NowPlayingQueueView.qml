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

            delegate: Rectangle {
                width: ListView.view.width - 24
                height: modelData.type === "header" ? 30 : 52
                radius: 8
                color: modelData.type === "header" ? "transparent" : (qRowMouse.containsMouse
                    ? root.appWindow.surfaceElevated
                    : (modelData.type === "current" ? "#1C1A18" : "transparent"))

                Label {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData.type === "header"
                    text: modelData.title || ""
                    color: modelData.title === "NOW PLAYING" ? root.appWindow.recordRed : root.appWindow.silverDim
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 14
                    spacing: 12
                    visible: modelData.type !== "header"

                    Cover {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 6
                        track: modelData
                        cacheArtwork: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.fileName
                            color: modelData.type === "current" ? root.appWindow.recordRed : root.appWindow.textPrimary
                            font.family: root.appWindow.displayFont
                            font.pixelSize: 13
                            font.weight: modelData.type === "current" ? Font.Bold : Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (modelData.artist || "Unknown Artist") + " • " + (modelData.album || "Unknown Album")
                            color: root.appWindow.textSecondary
                            font.family: root.appWindow.bodyFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }

                    Label {
                        text: modelData.duration || "—"
                        color: root.appWindow.silverDim
                        font.family: root.appWindow.monoFont
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: qRowMouse
                    anchors.fill: parent
                    enabled: modelData.type !== "header" && modelData.type !== "current"
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.appWindow.playFromQueue(modelData.track)
                }
            }
        }
    }
}
