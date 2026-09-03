import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    title: "CassetteCat MiniPlayer"
    width: 480
    height: 168
    minimumWidth: 440
    maximumWidth: 540
    minimumHeight: 168
    maximumHeight: 168
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint | (alwaysOnTop ? Qt.WindowStaysOnTopHint : Qt.Widget)
    visible: false

    // CassetteCat Theme Palette
    readonly property color surfaceBg: "#141311"
    readonly property color surfaceCard: "#191715"
    readonly property color borderVariant: "#2C2926"
    readonly property color topHighlight: "#35322E"
    readonly property color recordRed: "#C23B30"
    readonly property color recordRedHover: "#D14337"
    readonly property color textPrimary: "#F5F0EC"
    readonly property color textSecondary: "#A8A29A"
    readonly property color silverDim: "#6E6C68"

    // State bindings from Main.qml
    property bool alwaysOnTop: true
    property bool playerVisuallyPlaying: false
    property int repeatMode: 0
    property var favoriteTracks: ({})
    property string displayFont: "Plus Jakarta Sans"
    property string bodyFont: "Plus Jakarta Sans"
    property string monoFont: "JetBrains Mono"
    property int tracksCount: 0

    signal restoreRequested()
    signal closeRequested()
    signal playPrevious()
    signal playNext()
    signal toggleRepeat()
    signal toggleFavorite(string filePath)
    signal toggleAlwaysOnTop()

    Shortcut {
        sequence: "Ctrl+M"
        onActivated: root.restoreRequested()
    }
    Shortcut {
        sequence: "Ctrl+Shift+M"
        onActivated: root.restoreRequested()
    }
    Shortcut {
        sequence: "Escape"
        onActivated: root.restoreRequested()
    }
    Shortcut {
        sequence: "Space"
        onActivated: player.togglePlay()
    }

    onClosing: close => {
        close.accepted = false
        root.closeRequested()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 4
        radius: 14
        color: root.surfaceBg
        border.width: 1
        border.color: root.borderVariant
        clip: true

        // Top edge highlight line
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: root.topHighlight
        }

        // Window header & drag area
        Item {
            id: dragHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 28

            MouseArea {
                anchors.fill: parent
                property point pressPos
                onPressed: mouse => { pressPos = Qt.point(mouse.x, mouse.y) }
                onPositionChanged: mouse => {
                    const deltaX = Math.abs(mouse.x - pressPos.x)
                    const deltaY = Math.abs(mouse.y - pressPos.y)
                    if (deltaX > 3 || deltaY > 3) root.startSystemMove()
                }
                onDoubleClicked: root.restoreRequested()
            }

            // Left branding
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Image {
                    width: 15
                    height: 15
                    anchors.verticalCenter: parent.verticalCenter
                    source: "qrc:/CassetteCat/assets/cassettecat_icon.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CassetteCat"
                    color: root.silverDim
                    font.family: root.monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            // Right header controls
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                // Always On Top Pin Button
                Rectangle {
                    width: 24
                    height: 22
                    radius: 5
                    color: aotMouse.containsMouse ? "#18FFFFFF" : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12
                        height: 12
                        icon: "pin"
                        color: root.alwaysOnTop ? root.recordRed : (aotMouse.containsMouse ? root.textPrimary : root.silverDim)
                    }

                    MouseArea {
                        id: aotMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleAlwaysOnTop()
                    }
                }

                // Minimize Button
                Rectangle {
                    width: 24
                    height: 22
                    radius: 5
                    color: minMouse.containsMouse ? "#18FFFFFF" : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "—"
                        color: minMouse.containsMouse ? root.textPrimary : root.silverDim
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: minMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showMinimized()
                    }
                }

                // Restore Button
                Rectangle {
                    width: 24
                    height: 22
                    radius: 5
                    color: restoreMouse.containsMouse ? "#18FFFFFF" : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 11
                        height: 11
                        icon: "maximize-2"
                        color: restoreMouse.containsMouse ? root.textPrimary : root.silverDim
                    }

                    MouseArea {
                        id: restoreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.restoreRequested()
                    }
                }

                // Close Button
                Rectangle {
                    width: 24
                    height: 22
                    radius: 5
                    color: closeMouse.containsMouse ? root.recordRed : "transparent"

                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeMouse.containsMouse ? "#FFFFFF" : root.silverDim
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }
        }

        // Main Player Content
        Item {
            anchors.top: dragHeader.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 8

            RowLayout {
                anchors.fill: parent
                spacing: 12

                // Left Cover Art
                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    Layout.alignment: Qt.AlignVCenter
                    radius: 10
                    clip: true
                    color: root.surfaceCard
                    border.width: 1
                    border.color: root.borderVariant

                    Cover {
                        anchors.fill: parent
                        track: player.currentTrack
                        radius: 10
                        visible: !!(player.currentTrack && player.currentTrack.filePath)
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        source: "qrc:/CassetteCat/assets/cassettecat_icon.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: !(player.currentTrack && player.currentTrack.filePath)
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onDoubleClicked: root.restoreRequested()
                    }
                }

                // Right Track Details & Controls Column
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    // Row 1: Title, Artist, and Favorite
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Label {
                                Layout.fillWidth: true
                                text: (player.currentTrack && player.currentTrack.title)
                                    ? player.currentTrack.title
                                    : (root.tracksCount > 0 ? "CassetteCat Audio" : "Library Empty")
                                color: root.textPrimary
                                font.family: root.displayFont
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: (player.currentTrack && player.currentTrack.artist)
                                    ? player.currentTrack.artist
                                    : (root.tracksCount > 0 ? "Pick a track to start playback" : "Choose a music folder to begin")
                                color: root.recordRedHover
                                font.family: root.bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        PressDepthIconButton {
                            boxSize: 26
                            iconSize: 13
                            iconName: "heart"
                            tint: (player.currentTrack && root.favoriteTracks && !!root.favoriteTracks[player.currentTrack.filePath]) ? root.recordRed : root.silverDim
                            onClicked: {
                                if (player.currentTrack && player.currentTrack.filePath) {
                                    root.toggleFavorite(player.currentTrack.filePath)
                                }
                            }
                        }
                    }

                    // Row 2: Audio Seeker
                    AudioSeeker {
                        Layout.fillWidth: true
                        position: player.position
                        duration: player.duration
                        onSeekRequested: posMs => player.seek(posMs)
                    }

                    // Row 3: Playback Controls & Volume Control
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        TransportButton {
                            buttonSize: 26
                            iconName: "shuffle"
                            accented: player.shuffleEnabled
                            onClicked: player.toggleShuffle()
                        }

                        TransportButton {
                            buttonSize: 28
                            iconName: "skip-back"
                            iconColor: root.textPrimary
                            onClicked: root.playPrevious()
                        }

                        TransportButton {
                            buttonSize: 34
                            iconName: (player.isPlaying || root.playerVisuallyPlaying) ? "pause" : "play"
                            accented: true
                            iconColor: root.recordRed
                            onClicked: player.togglePlay()
                        }

                        TransportButton {
                            buttonSize: 28
                            iconName: "skip-forward"
                            iconColor: root.textPrimary
                            onClicked: root.playNext()
                        }

                        TransportButton {
                            buttonSize: 26
                            iconName: root.repeatMode === 2 ? "repeat-1" : "repeat"
                            accented: root.repeatMode > 0
                            iconColor: root.repeatMode > 0 ? root.recordRed : root.textPrimary
                            onClicked: root.toggleRepeat()
                        }

                        Item { Layout.fillWidth: true }

                        VolumeControl {
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 28
                            Layout.alignment: Qt.AlignVCenter
                            volume: player.volume
                            showPercentage: false
                            onVolumeAdjusted: newVol => player.setVolume(newVol)
                        }
                    }
                }
            }
        }
    }
}
