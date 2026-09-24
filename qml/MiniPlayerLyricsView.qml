import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var miniPlayer
    readonly property bool meterVisible: waveRow.visible

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: lyricsListView
                anchors.fill: parent
                clip: true
                model: root.miniPlayer.lyricDisplayItems
                currentIndex: root.miniPlayer.activeLyricDisplayIndex
                spacing: 22
                topMargin: Math.round(height * 0.30)
                bottomMargin: Math.round(height * 0.40)
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: Math.round(height * 0.28)
                preferredHighlightEnd: Math.round(height * 0.36)
                highlightMoveDuration: UiConstants.highlightDurationMini
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                cacheBuffer: UiConstants.cacheBuffer
                pixelAligned: UiConstants.pixelAligned
                reuseItems: true
                ScrollBar.vertical: SleekScrollBar {}

                delegate: Item {
                    id: lyricItem
                    width: ListView.view.width
                    readonly property bool isGap: modelData.type === "gap"
                    readonly property bool isCurrent: !isGap && modelData.lineIndex === root.miniPlayer.activeLyricIndex && (root.miniPlayer.lyricDisplayItems[root.miniPlayer.activeLyricDisplayIndex] || {}).type === "line"
                    readonly property bool gapActive: isGap && root.miniPlayer.playerController.position >= modelData.startMs && root.miniPlayer.playerController.position <= modelData.endMs
                    height: isGap ? 36 : lyricLabel.implicitHeight + 8

                    Label {
                        id: lyricLabel
                        width: parent.width - 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !lyricItem.isGap
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText
                        text: lyricItem.isGap ? "" : root.miniPlayer.karaokeLyricHtml(modelData.lineIndex, modelData.text)
                        color: isCurrent
                            ? (root.miniPlayer.lyricsActiveStyle === "accent" ? root.miniPlayer.recordRedHover : "#FFFFFF")
                            : (lyricLineMouse.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim)
                        horizontalAlignment: root.miniPlayer.lyricsAlignment === "center" ? Text.AlignHCenter : Text.AlignLeft
                        font.family: root.miniPlayer.displayFont
                        font.pixelSize: {
                            const base = root.miniPlayer.lyricsFontSize || 28
                            const scale = base / 28.0
                            return isCurrent ? Math.round(22 * scale) : Math.round(16 * scale)
                        }
                        font.weight: isCurrent ? Font.Bold : Font.DemiBold
                        scale: isCurrent ? 1.03 : 1.0
                        opacity: isCurrent ? 1.0 : (lyricLineMouse.containsMouse ? 0.75 : 0.36)

                        Behavior on color { ColorAnimation { duration: UiConstants.durationStd } }
                        Behavior on opacity { NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd } }
                        Behavior on scale { NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd } }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: lyricItem.isGap
                        opacity: lyricItem.gapActive ? 1.0 : 0.2

                        Repeater {
                            model: 3
                            delegate: Rectangle { width: 5; height: 5; radius: 2.5; color: root.miniPlayer.recordRedHover }
                        }
                    }

                    MouseArea {
                        id: lyricLineMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.playerController.seek(modelData.startMs)
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: !root.miniPlayer.parsedLyrics || root.miniPlayer.parsedLyrics.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 12

                        Item {
                            id: waveContainer
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: waveRow.implicitWidth
                            Layout.preferredHeight: 40
                            Layout.minimumHeight: 40
                            Layout.maximumHeight: 40

                            property real wavePhase: 0.0

                            NumberAnimation {
                                target: waveContainer
                                property: "wavePhase"
                                from: 0.0
                                to: 62.83185307179586
                                duration: 24000
                                loops: Animation.Infinite
                                running: root.miniPlayer.playerController.isPlaying && root.visible
                            }

                            Row {
                                id: waveRow
                                anchors.centerIn: parent
                                spacing: 5

                                Repeater {
                                    model: [0.45, 0.70, 0.88, 1.0, 0.88, 0.70, 0.45]
                                    delegate: Rectangle {
                                        id: waveBar
                                        required property int index
                                        required property real modelData
                                        width: 3.5
                                        radius: 1.75
                                        color: root.miniPlayer.recordRedHover
                                        anchors.verticalCenter: parent.verticalCenter

                                        readonly property real harmonic: {
                                            const h1 = Math.sin(waveContainer.wavePhase * 1.5 + index * 0.95)
                                            const h2 = Math.cos(waveContainer.wavePhase * 2.2 - index * 0.65)
                                            return (h1 * 0.6 + h2 * 0.4) * 0.5 + 0.5
                                        }
                                        readonly property real energy: Math.max(0.20, Math.min(1.0, (root.miniPlayer.playerController.audioLevel * 1.6) + 0.25))
                                        readonly property real activeHeight: 5 + (harmonic * 28 * modelData * energy)

                                        height: root.miniPlayer.playerController.isPlaying ? activeHeight : 5
                                        opacity: root.miniPlayer.playerController.isPlaying ? (0.65 + 0.35 * Math.min(1.0, height / 32)) : 0.45

                                        Behavior on height {
                                            enabled: !root.miniPlayer.playerController.isPlaying
                                            NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation { duration: UiConstants.durationStd }
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath ? "No Lyrics Available" : "Instrumental"
                            color: root.miniPlayer.silverDim
                            font.family: root.miniPlayer.displayFont
                            font.pixelSize: 13
                        }
                    }
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
                    text: root.miniPlayer.formatTime(root.miniPlayer.playerController.position)
                    color: root.miniPlayer.silverDim
                    font.family: root.miniPlayer.monoFont
                    font.pixelSize: 9
                    elide: Text.ElideNone
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14

                    Rectangle {
                        id: lyrGrooveBar
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 2.5
                        radius: 1.25
                        color: root.miniPlayer.surfaceElevated

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.round(lyrGrooveBar.width * (root.miniPlayer.playerController.duration > 0 ? Math.min(1.0, Math.max(0.0, root.miniPlayer.playerController.position / root.miniPlayer.playerController.duration)) : 0))
                            radius: 1.25
                            color: root.miniPlayer.recordRed
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true
                        onClicked: mouse => {
                            if (root.miniPlayer.playerController.duration > 0) root.miniPlayer.playerController.seek(Math.floor((mouse.x / width) * root.miniPlayer.playerController.duration))
                        }
                    }
                }

                Label {
                    Layout.preferredWidth: 34
                    text: root.miniPlayer.showRemainingTime ? root.miniPlayer.formatRemaining(root.miniPlayer.playerController.position, root.miniPlayer.playerController.duration) : root.miniPlayer.formatTime(root.miniPlayer.playerController.duration)
                    color: root.miniPlayer.silverDim
                    font.family: root.miniPlayer.monoFont
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
                    visible: !root.miniPlayer.volumePillVisible

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        icon: root.miniPlayer.playerController.volume <= 0.001 ? "volume-x" : (root.miniPlayer.playerController.volume < 0.5 ? "volume-1" : "volume-2")
                        color: lyricVolumeMouse.containsMouse ? root.miniPlayer.textPrimary : root.miniPlayer.silverDim
                    }

                    MouseArea {
                        id: lyricVolumeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.volumePillVisible = true
                    }
                }

                MiniPlayerVolumePill {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    playerController: root.miniPlayer.playerController
                    surfacePill: root.miniPlayer.surfacePill
                    borderCard: root.miniPlayer.borderCard
                    accentColor: root.miniPlayer.recordRed
                    silverDim: root.miniPlayer.silverDim
                    volumeLimitEnabled: root.miniPlayer.volumeLimitEnabled
                    maxVolumePercent: root.miniPlayer.maxVolumePercent
                    visible: opacity > 0.001
                    opacity: (root.miniPlayer.mode === "lyrics" && root.miniPlayer.volumePillVisible) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 18

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 17; height: 17; icon: "skip-back"; color: root.miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.playPrevious() }
                    }

                    Rectangle {
                        width: 30
                        height: 30
                        radius: 4
                        color: "transparent"
                        LucideIcon {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? 0 : 1
                            width: 20
                            height: 20
                            icon: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? "pause" : "play"
                            color: root.miniPlayer.textPrimary
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.playerController.togglePlay() }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 17; height: 17; icon: "skip-forward"; color: root.miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.playNext() }
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
                        LucideIcon { anchors.centerIn: parent; width: 16; height: 16; icon: "quote"; color: root.miniPlayer.recordRed }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.mode = "compact" }
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 4
                        color: "transparent"
                        LucideIcon { anchors.centerIn: parent; width: 16; height: 16; icon: "list"; color: root.miniPlayer.silverDim }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.miniPlayer.mode = "queue" }
                    }
                }
            }
        }
    }
}
