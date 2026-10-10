import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var miniPlayer
    anchors.fill: parent
    visible: root.miniPlayer.mode === "art"

    Cover {
        id: fullCover
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: root.miniPlayer.albumArtRadius === 0 ? 0 : (root.miniPlayer.albumArtRadius <= 8 ? 8 : 14)
        fillMode: Image.PreserveAspectCrop
        track: root.miniPlayer.playerController.currentTrack
        keepPreviousArtwork: true
        cacheArtwork: true
    }

    Rectangle {
        anchors.fill: parent
        radius: root.miniPlayer.albumArtRadius === 0 ? 0 : (root.miniPlayer.albumArtRadius <= 8 ? 8 : 14)
        color: root.miniPlayer.surfaceCard
        visible: !(root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath)

        Image {
            anchors.centerIn: parent
            width: 64
            height: 64
            source: "qrc:/qt/qml/CassetteCat/assets/cassettecat_icon.png"
            fillMode: Image.PreserveAspectFit
        }
    }

    MouseArea {
        id: artBackgroundDrag
        anchors.fill: parent
        hoverEnabled: true
        property point pressPos
        onPressed: mouse => {
            pressPos = Qt.point(mouse.x, mouse.y);
        }
        onPositionChanged: mouse => {
            const deltaX = Math.abs(mouse.x - pressPos.x);
            const deltaY = Math.abs(mouse.y - pressPos.y);
            if (deltaX > 3 || deltaY > 3)
                root.miniPlayer.startSystemMove();
        }
        onDoubleClicked: root.miniPlayer.restoreRequested()
    }

    HoverHandler {
        id: artHoverHandler
    }
    readonly property bool artHoverActive: artHoverHandler.hovered || artBackgroundDrag.containsMouse || root.miniPlayer.artSeeking || root.miniPlayer.volumePillVisible

    Item {
        id: artOverlays
        anchors.fill: parent
        z: 20

        Rectangle {
            id: artTopControlsPill
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 10
            width: artControlsRow.implicitWidth + 8
            height: 28
            radius: 14
            color: Qt.alpha(surfaceSidebar, 0.89)
            border.width: 1
            border.color: "#35FFFFFF"
            z: 20
            opacity: root.artHoverActive ? 1.0 : 0.85

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                id: artControlsRow
                anchors.centerIn: parent
                spacing: 2
                padding: 2

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: root.miniPlayer.alwaysOnTop ? root.miniPlayer.recordRed : (artPinH.containsMouse ? "#30FFFFFF" : "transparent")
                    scale: artPinH.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        icon: "pin"
                        color: root.miniPlayer.alwaysOnTop ? "#FFFFFF" : (artPinH.containsMouse ? "#FFFFFF" : "#C0FFFFFF")
                    }
                    MouseArea {
                        id: artPinH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.toggleAlwaysOnTop()
                    }
                    AppToolTip {
                        text: root.miniPlayer.alwaysOnTop ? "Unpin from top" : "Keep on top"
                        visibleTarget: artPinH.containsMouse
                        delay: 350
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: artMinH.containsMouse ? "#30FFFFFF" : "transparent"
                    scale: artMinH.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        icon: "minus"
                        color: artMinH.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                    }
                    MouseArea {
                        id: artMinH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.showMinimized()
                    }
                    AppToolTip {
                        text: "Minimize"
                        visibleTarget: artMinH.containsMouse
                        delay: 350
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: artPopH.containsMouse ? "#30FFFFFF" : "transparent"
                    scale: artPopH.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        icon: "pip"
                        color: artPopH.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                    }
                    MouseArea {
                        id: artPopH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.mode = "compact"
                    }
                    AppToolTip {
                        text: "Compact mode"
                        visibleTarget: artPopH.containsMouse
                        delay: 350
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: artExpandH.containsMouse ? "#30FFFFFF" : "transparent"
                    scale: artExpandH.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        icon: "maximize-2"
                        color: artExpandH.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                    }
                    MouseArea {
                        id: artExpandH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.restoreRequested()
                    }
                    AppToolTip {
                        text: "Restore full player"
                        visibleTarget: artExpandH.containsMouse
                        delay: 350
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: artCloseH.containsMouse ? windowCloseHover : "transparent"
                    scale: artCloseH.pressed ? 0.90 : 1.0
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 80 } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 12; height: 12
                        icon: "x"
                        color: artCloseH.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                    }
                    MouseArea {
                        id: artCloseH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.miniPlayer.closeRequested()
                    }
                    AppToolTip {
                        text: "Close miniplayer"
                        visibleTarget: artCloseH.containsMouse
                        delay: 350
                    }
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 12
            height: 72
            radius: 16
            color: Qt.alpha(surfaceSidebar, 0.85)
            border.width: 1
            border.color: "#30FFFFFF"
            opacity: root.artHoverActive ? 1.0 : 0.0
            visible: opacity > 0.001

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 14
                    spacing: 8

                    Label {
                        Layout.preferredWidth: 28
                        text: root.miniPlayer.formatTime(root.miniPlayer.playerController.position)
                        color: "#B0FFFFFF"
                        font.family: root.miniPlayer.monoFont
                        font.pixelSize: 9
                    }

                    Item {
                        id: artSeekItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: 14

                        Rectangle {
                            id: artSeekGroove
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: (artSeekAreaM.containsMouse || artSeekAreaM.pressed) ? 3.5 : 2.5
                            radius: height / 2
                            color: "#40FFFFFF"

                            Behavior on height {
                                NumberAnimation {
                                    duration: 80
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.round(artSeekGroove.width * (root.miniPlayer.playerController.duration > 0 ? Math.min(1.0, Math.max(0.0, root.miniPlayer.playerController.position / root.miniPlayer.playerController.duration)) : 0))
                                radius: height / 2
                                color: root.miniPlayer.recordRed
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(artSeekGroove.width - width, Math.round(artSeekGroove.width * (root.miniPlayer.playerController.duration > 0 ? Math.min(1.0, Math.max(0.0, root.miniPlayer.playerController.position / root.miniPlayer.playerController.duration)) : 0)) - width / 2))
                                width: (artSeekAreaM.containsMouse || artSeekAreaM.pressed) ? 7 : 0
                                height: width
                                radius: width / 2
                                color: "#FFFFFF"
                                opacity: (artSeekAreaM.containsMouse || artSeekAreaM.pressed) ? 1.0 : 0.0
                            }
                        }

                        MouseArea {
                            id: artSeekAreaM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            preventStealing: true

                            function applySeek(xPos) {
                                if (root.miniPlayer.playerController.duration > 0) {
                                    const frac = Math.max(0.0, Math.min(1.0, xPos / artSeekItem.width));
                                    root.miniPlayer.playerController.seek(Math.floor(frac * root.miniPlayer.playerController.duration));
                                }
                            }
                            onPressed: mouse => {
                                root.miniPlayer.artSeeking = true;
                                applySeek(mouse.x);
                            }
                            onPositionChanged: mouse => {
                                if (pressed)
                                    applySeek(mouse.x);
                            }
                            onReleased: root.miniPlayer.artSeeking = false
                            onCanceled: root.miniPlayer.artSeeking = false
                        }
                    }

                    Label {
                        Layout.preferredWidth: 32
                        text: root.miniPlayer.showRemainingTime ? root.miniPlayer.formatRemaining(root.miniPlayer.playerController.position, root.miniPlayer.playerController.duration) : root.miniPlayer.formatTime(root.miniPlayer.playerController.duration)
                        color: "#B0FFFFFF"
                        font.family: root.miniPlayer.monoFont
                        font.pixelSize: 9
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Row {
                        id: artLeftControls
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
                            tooltipText: "Volume"
                            onClicked: root.miniPlayer.volumePillVisible = true
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 28
                            filled: false
                            iconName: "heart"
                            readonly property bool isFav: !!(root.miniPlayer.playerController.currentTrack && root.miniPlayer.isFavorite(root.miniPlayer.playerController.currentTrack.filePath))
                            iconColor: isFav ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                            tooltipText: isFav ? "Remove from favorites" : "Add to favorites"
                            onClicked: if (root.miniPlayer.playerController.currentTrack && root.miniPlayer.playerController.currentTrack.filePath) root.miniPlayer.toggleFavorite(root.miniPlayer.playerController.currentTrack.filePath)
                        }
                    }

                    // In-Place Volume Slider
                    MiniPlayerVolumePill {
                        id: artInlineVolPill
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
                        opacity: (root.miniPlayer.mode === "art" && root.miniPlayer.volumePillVisible) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: UiConstants.durationFast } }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 28
                            iconName: "shuffle"
                            accented: root.miniPlayer.playerController.shuffleEnabled
                            tooltipText: root.miniPlayer.playerController.shuffleEnabled ? "Shuffle On" : "Shuffle Off"
                            onClicked: root.miniPlayer.toggleShuffle()
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 30
                            iconName: "skip-back"
                            tooltipText: "Previous"
                            onClicked: root.miniPlayer.playPrevious()
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 36
                            iconName: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? "pause" : "play"
                            accented: true
                            tooltipText: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? "Pause" : "Play"
                            onClicked: root.miniPlayer.playerController.togglePlay()
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 30
                            iconName: "skip-forward"
                            tooltipText: "Next"
                            onClicked: root.miniPlayer.playNext()
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 28
                            iconName: root.miniPlayer.repeatMode === 2 ? "repeat-1" : "repeat"
                            accented: root.miniPlayer.repeatMode > 0
                            tooltipText: root.miniPlayer.repeatMode === 2 ? "Repeat Track" : (root.miniPlayer.repeatMode === 1 ? "Repeat All" : "Repeat Off")
                            onClicked: root.miniPlayer.toggleRepeat()
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 28
                            filled: false
                            iconName: "quote"
                            iconColor: root.miniPlayer.mode === "lyrics" ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                            tooltipText: "Lyrics"
                            onClicked: root.miniPlayer.mode = "lyrics"
                        }

                        TransportButton {
                            anchors.verticalCenter: parent.verticalCenter
                            buttonSize: 28
                            filled: false
                            iconName: "list"
                            iconColor: root.miniPlayer.mode === "queue" ? root.miniPlayer.recordRed : root.miniPlayer.textSecondary
                            tooltipText: "Queue"
                            onClicked: root.miniPlayer.mode = "queue"
                        }
                    }
                }
            }
        }
    }
}
