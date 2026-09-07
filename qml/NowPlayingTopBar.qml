import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var appWindow
    height: 64
    z: 10

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        height: 38
        radius: 19
        color: backMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
        border.width: 1
        border.color: backMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF"

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        LucideIcon {
            anchors.centerIn: parent
            width: 18
            height: 18
            icon: "chevron-down"
            color: backMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.silverDim
        }

        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.appWindow.nowPlayingOpen = false
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: root.appWindow.nowPlayingMode === "lyrics" && root.appWindow.parsedLyrics.length > 0

            Rectangle {
                width: chooseLyricsLabel.implicitWidth + 20
                height: 32
                radius: 16
                color: chooseLyricsMouse.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
                border.width: 1
                border.color: chooseLyricsMouse.containsMouse ? root.appWindow.borderVariant : root.appWindow.borderSubtle

                Label {
                    id: chooseLyricsLabel
                    anchors.centerIn: parent
                    text: "Choose lyrics"
                    color: chooseLyricsMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.textSecondary
                    font.family: root.appWindow.displayFont
                    font.pixelSize: 11
                }

                MouseArea {
                    id: chooseLyricsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.appWindow.openLyricsSearch()
                }
            }

            Rectangle {
                width: 28; height: 28; radius: 14
                color: offsetBack.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
                border.width: 1; border.color: root.appWindow.borderSubtle
                Label { anchors.centerIn: parent; text: "−"; color: root.appWindow.textSecondary; font.pixelSize: 16 }
                MouseArea { id: offsetBack; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.appWindow.lyricsSyncOffsetMs -= 100 }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: (root.appWindow.lyricsSyncOffsetMs >= 0 ? "+" : "") + (root.appWindow.lyricsSyncOffsetMs / 1000).toFixed(1) + "s"
                color: root.appWindow.textSecondary
                font.family: root.appWindow.monoFont
                font.pixelSize: 10
            }

            Rectangle {
                width: 28; height: 28; radius: 14
                color: offsetForward.containsMouse ? root.appWindow.surfaceElevated : root.appWindow.surfaceCard
                border.width: 1; border.color: root.appWindow.borderSubtle
                Label { anchors.centerIn: parent; text: "+"; color: root.appWindow.textSecondary; font.pixelSize: 16 }
                MouseArea { id: offsetForward; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.appWindow.lyricsSyncOffsetMs += 100 }
            }
        }

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: npPipMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
            border.width: 1
            border.color: npPipMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF"

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            LucideIcon {
                anchors.centerIn: parent
                width: 18
                height: 18
                icon: "pip"
                color: npPipMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.silverDim
            }

            MouseArea {
                id: npPipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.appWindow.toggleMiniPlayer()
            }
        }

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: lyricsBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
            border.width: 1
            border.color: root.appWindow.nowPlayingMode === "lyrics"
                ? root.appWindow.recordRed
                : (lyricsBtnMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF")

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            LucideIcon {
                anchors.centerIn: parent
                width: 18
                height: 18
                icon: "quote"
                color: root.appWindow.nowPlayingMode === "lyrics" ? root.appWindow.recordRedHover : (lyricsBtnMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.silverDim)
            }

            MouseArea {
                id: lyricsBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.appWindow.nowPlayingMode = root.appWindow.nowPlayingMode === "lyrics" ? "controls" : "lyrics"
            }
        }

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: queueBtnMouse.containsMouse ? "#24FFFFFF" : "#10FFFFFF"
            border.width: 1
            border.color: root.appWindow.nowPlayingMode === "queue"
                ? root.appWindow.recordRed
                : (queueBtnMouse.containsMouse ? "#30FFFFFF" : "#14FFFFFF")

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            LucideIcon {
                anchors.centerIn: parent
                width: 18
                height: 18
                icon: "list-music"
                color: root.appWindow.nowPlayingMode === "queue" ? root.appWindow.recordRedHover : (queueBtnMouse.containsMouse ? root.appWindow.textPrimary : root.appWindow.silverDim)
            }

            MouseArea {
                id: queueBtnMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.appWindow.nowPlayingMode = root.appWindow.nowPlayingMode === "queue" ? "controls" : "queue"
            }
        }

        Rectangle {
            width: 38
            height: 38
            radius: 19
            color: closeNpMouse.containsMouse ? "#45C23B30" : "#10FFFFFF"
            border.width: 1
            border.color: closeNpMouse.containsMouse ? "#65C23B30" : "#14FFFFFF"

            Behavior on color { ColorAnimation { duration: 160 } }
            Behavior on border.color { ColorAnimation { duration: 160 } }

            LucideIcon {
                anchors.centerIn: parent
                width: 16
                height: 16
                icon: "x"
                color: closeNpMouse.containsMouse ? "#FFFFFF" : root.appWindow.silverDim
            }

            MouseArea {
                id: closeNpMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.appWindow.nowPlayingOpen = false
            }
        }
    }
}
