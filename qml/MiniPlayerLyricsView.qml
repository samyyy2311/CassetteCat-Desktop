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

            LyricsList {
                id: lyricsListView
                anchors.fill: parent
                items: root.miniPlayer.lyricDisplayItems
                lines: root.miniPlayer.parsedLyrics
                activeItemIndex: root.miniPlayer.activeLyricDisplayIndex
                activeLineIndex: (root.miniPlayer.lyricDisplayItems[root.miniPlayer.activeLyricDisplayIndex] || {}).type === "line"
                    ? root.miniPlayer.activeLyricIndex : -1
                positionMs: root.miniPlayer.playerController.position
                playing: root.miniPlayer.playerController.isPlaying
                fontSize: Math.round((root.miniPlayer.lyricsFontSize || 28) * 0.7)
                fontFamily: root.miniPlayer.lyricsFont
                fontWeight: root.miniPlayer.lyricsFontWeight
                centered: root.miniPlayer.lyricsAlignment === "center"
                activeColor: root.miniPlayer.lyricsActiveStyle === "accent" ? root.miniPlayer.recordRedHover : "#FFFFFF"
                sidePadding: 8
                anchorRatio: 0.3
                onLineClicked: item => {
                    if (item.startMs >= 0) root.miniPlayer.playerController.seek(item.startMs)
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
                                running: root.miniPlayer.playerController.isPlaying && waveContainer.visible
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
                            text: root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath ? qsTr("No Lyrics Available") : qsTr("Instrumental")
                            color: root.miniPlayer.silverDim
                            font.family: root.miniPlayer.displayFont
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        MiniPlayerControls {
            Layout.fillWidth: true
            miniPlayer: root.miniPlayer
        }
    }
}
