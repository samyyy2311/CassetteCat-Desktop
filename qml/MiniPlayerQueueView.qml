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

            ListView {
                id: queueListView
                anchors.fill: parent
                clip: true
                model: miniPlayer.queueEntries
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar { anchors.rightMargin: 2 }

                delegate: Rectangle {
                    id: queueRowItem
                    width: ListView.view.width - 4
                    height: modelData.type === "header" ? 22 : 40
                    radius: 5
                    color: modelData.type === "header"
                        ? "transparent"
                        : (queueRowMouse.containsMouse
                            ? miniPlayer.surfaceElevated
                            : (modelData.type === "current" ? "#1E1C1A" : "transparent"))
                    border.width: modelData.type === "current" ? 1 : 0
                    border.color: miniPlayer.borderCard

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: modelData.type === "header"
                        text: modelData.title || ""
                        color: modelData.title === "NOW PLAYING" ? miniPlayer.recordRed : miniPlayer.silverDim
                        font.family: miniPlayer.monoFont
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        spacing: 8
                        visible: modelData.type !== "header"

                        Cover {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 4
                            fillMode: Image.PreserveAspectCrop
                            track: modelData.track || modelData
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                text: modelData.title || (modelData.track ? modelData.track.title : "") || ""
                                color: modelData.type === "current" ? miniPlayer.recordRedHover : miniPlayer.textPrimary
                                font.family: miniPlayer.displayFont
                                font.pixelSize: 11
                                font.weight: modelData.type === "current" ? Font.Bold : Font.Medium
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.artist || (modelData.track ? modelData.track.artist : "") || "Unknown Artist"
                                color: miniPlayer.textSecondary
                                font.family: miniPlayer.bodyFont
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        Label {
                            text: modelData.duration || ""
                            color: miniPlayer.silverDim
                            font.family: miniPlayer.monoFont
                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        id: queueRowMouse
                        anchors.fill: parent
                        enabled: modelData.type !== "header"
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const track = modelData.track || modelData
                            if (track && track.filePath) miniPlayer.playTrack(track)
                        }
                    }
                }

                Label {
                    anchors.centerIn: parent
                    visible: !miniPlayer.queueEntries || miniPlayer.queueEntries.length === 0
                    text: "Queue is empty"
                    color: miniPlayer.silverDim
                    font.family: miniPlayer.displayFont
                    font.pixelSize: 11
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Label {
                    Layout.preferredWidth: 30
                    text: miniPlayer.formatTime(miniPlayer.playerController.position)
                    color: miniPlayer.silverDim
                    font.family: miniPlayer.monoFont
                    font.pixelSize: 9
                    elide: Text.ElideNone
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14

                    Rectangle {
                        id: queueGroove
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 2.5
                        radius: 1.25
                        color: miniPlayer.surfaceElevated

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.round(queueGroove.width * (miniPlayer.playerController.duration > 0 ? Math.min(1.0, Math.max(0.0, miniPlayer.playerController.position / miniPlayer.playerController.duration)) : 0))
                            radius: 1.25
                            color: miniPlayer.recordRed
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onClicked: mouse => {
                            if (miniPlayer.playerController.duration > 0) {
                                miniPlayer.playerController.seek(Math.floor((mouse.x / width) * miniPlayer.playerController.duration))
                            }
                        }
                    }
                }

                Label {
                    Layout.preferredWidth: 34
                    text: miniPlayer.showRemainingTime
                        ? miniPlayer.formatRemaining(miniPlayer.playerController.position, miniPlayer.playerController.duration)
                        : miniPlayer.formatTime(miniPlayer.playerController.duration)
                    color: miniPlayer.silverDim
                    font.family: miniPlayer.monoFont
                    font.pixelSize: 9
                    elide: Text.ElideNone
                    horizontalAlignment: Text.AlignRight
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28
                    height: 28
                    radius: 4
                    color: "transparent"
                    visible: !miniPlayer.volumePillVisible

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        icon: miniPlayer.playerController.volume <= 0.001 ? "volume-x" : (miniPlayer.playerController.volume < 0.5 ? "volume-1" : "volume-2")
                        color: queueVolumeMouse.containsMouse ? miniPlayer.textPrimary : miniPlayer.silverDim
                    }

                    MouseArea {
                        id: queueVolumeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: miniPlayer.volumePillVisible = true
                    }
                }

                MiniPlayerVolumePill {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    playerController: miniPlayer.playerController
                    surfacePill: miniPlayer.surfacePill
                    borderCard: miniPlayer.borderCard
                    accentColor: miniPlayer.recordRed
                    silverDim: miniPlayer.silverDim
                    visible: opacity > 0.001
                    opacity: (miniPlayer.mode === "queue" && miniPlayer.volumePillVisible) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 18

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 17; height: 17; icon: "skip-back"; color: miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: miniPlayer.playPrevious() }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 4
                        color: "transparent"
                        LucideIcon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: (miniPlayer.playerController.isPlaying || miniPlayer.playerVisuallyPlaying) ? 0 : 1
                            width: 20
                            height: 20
                            icon: (miniPlayer.playerController.isPlaying || miniPlayer.playerVisuallyPlaying) ? "pause" : "play"
                            color: miniPlayer.textPrimary
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: miniPlayer.playerController.togglePlay() }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 17; height: 17; icon: "skip-forward"; color: miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: miniPlayer.playNext() }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 16; height: 16; icon: "quote"; color: miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: miniPlayer.mode = "lyrics" }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 16; height: 16; icon: "list-music"; color: miniPlayer.recordRed }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: miniPlayer.mode = "compact" }
                    }
                }
            }
        }
    }
}
