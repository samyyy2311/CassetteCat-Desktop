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
        anchors.fill: parent
        radius: 14
        fillMode: Image.PreserveAspectCrop
        track: root.miniPlayer.playerController.currentTrack
        keepPreviousArtwork: true
        cacheArtwork: true
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
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
    readonly property bool artHoverActive: artHoverHandler.hovered || root.miniPlayer.artSeeking || root.miniPlayer.volumePillVisible

    Item {
        id: artOverlays
        anchors.fill: parent
        opacity: root.artHoverActive ? 1.0 : 0.0
        visible: opacity > 0.001
        z: 20

        Behavior on opacity {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Row {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 10
            anchors.rightMargin: 12
            spacing: 8

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    icon: "pin"
                    color: root.miniPlayer.alwaysOnTop ? root.miniPlayer.recordRed : (artPinH.containsMouse ? "#FFFFFF" : "#D0FFFFFF")
                }
                MouseArea {
                    id: artPinH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.toggleAlwaysOnTop()
                }
            }

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "—"
                    color: artMinH.containsMouse ? "#FFFFFF" : "#D0FFFFFF"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: artMinH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.showMinimized()
                }
            }

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                LucideIcon {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    icon: "pip"
                    color: artPopH.containsMouse ? "#FFFFFF" : "#D0FFFFFF"
                }
                MouseArea {
                    id: artPopH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.mode = "compact"
                }
            }

            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: "transparent"
                Label {
                    anchors.centerIn: parent
                    text: "✕"
                    color: artCloseH.containsMouse ? root.miniPlayer.recordRedHover : "#D0FFFFFF"
                    font.pixelSize: 11
                }
                MouseArea {
                    id: artCloseH
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.miniPlayer.closeRequested()
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
            color: "#D8141312"
            border.width: 1
            border.color: "#30FFFFFF"

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

                    Item {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        LucideIcon {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            icon: root.miniPlayer.playerController.volume <= 0.001 ? "volume-x" : "volume-2"
                            color: artVolM.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                        }
                        MouseArea {
                            id: artVolM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.miniPlayer.volumePillVisible = !root.miniPlayer.volumePillVisible
                        }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 20

                        Item {
                            width: 28
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            LucideIcon {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                icon: "skip-back"
                                color: artPrevM.containsMouse ? "#FFFFFF" : "#D0FFFFFF"
                            }
                            MouseArea {
                                id: artPrevM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.miniPlayer.playPrevious()
                            }
                        }

                        Item {
                            width: 30
                            height: 30
                            anchors.verticalCenter: parent.verticalCenter
                            scale: artPlayM.pressed ? 0.92 : (artPlayM.containsMouse ? 1.08 : 1.0)
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 90
                                }
                            }

                            LucideIcon {
                                anchors.centerIn: parent
                                anchors.horizontalCenterOffset: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? 0 : 1
                                width: 21
                                height: 21
                                icon: (root.miniPlayer.playerController.isPlaying || root.miniPlayer.playerVisuallyPlaying) ? "pause" : "play"
                                color: artPlayM.containsMouse ? root.miniPlayer.recordRedHover : "#FFFFFF"
                            }
                            MouseArea {
                                id: artPlayM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.miniPlayer.playerController.togglePlay()
                            }
                        }

                        Item {
                            width: 28
                            height: 28
                            anchors.verticalCenter: parent.verticalCenter
                            LucideIcon {
                                anchors.centerIn: parent
                                width: 17
                                height: 17
                                icon: "skip-forward"
                                color: artNextM.containsMouse ? "#FFFFFF" : "#D0FFFFFF"
                            }
                            MouseArea {
                                id: artNextM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.miniPlayer.playNext()
                            }
                        }
                    }

                    Item {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        LucideIcon {
                            anchors.centerIn: parent
                            width: 15
                            height: 15
                            icon: "pip"
                            color: artToCompM.containsMouse ? "#FFFFFF" : "#C0FFFFFF"
                        }
                        MouseArea {
                            id: artToCompM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.miniPlayer.mode = "compact"
                        }
                    }
                }
            }
        }
    }
}
