import QtQuick
import QtQuick.Controls

Item {
    id: root

    required property var appWindow
    height: 64
    z: 10

    // The frosted round button every control on this bar uses.
    component GlassButton: PressDepthIconButton {
        boxSize: 38
        iconSize: 18
        tint: root.appWindow.silverDim
        hoverTint: root.appWindow.textPrimary
        backgroundColor: "#10FFFFFF"
        hoverBackgroundColor: "#24FFFFFF"
        borderColor: "#14FFFFFF"
        hoverBorderColor: "#30FFFFFF"
    }

    GlassButton {
        anchors.left: parent.left
        anchors.leftMargin: 28
        anchors.verticalCenter: parent.verticalCenter
        iconName: "chevron-down"
        tooltipText: "Close Now Playing"
        onClicked: root.appWindow.nowPlayingOpen = false
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


        GlassButton {
            visible: phoneRemote.controllerName !== ""
            iconName: "smartphone"
            highlighted: true
            tooltipText: "Controlled from " + phoneRemote.controllerName + ". Click to continue on it."
            onClicked: phoneRemote.continueOnPhone()
        }

        GlassButton {
            readonly property bool favorite: root.appWindow.isFavorite(player.currentTrack.filePath)
            iconName: "heart"
            highlighted: favorite
            tooltipText: favorite ? "Remove from Favorites" : "Add to Favorites"
            onClicked: root.appWindow.toggleFavorite(player.currentTrack.filePath)
        }

        GlassButton {
            iconName: "more-vertical"
            tooltipText: "Track options"
            onClicked: root.appWindow.openTrackActionSheet(player.currentTrack)
        }

        GlassButton {
            iconName: "pip"
            tooltipText: "Open MiniPlayer"
            onClicked: root.appWindow.toggleMiniPlayer()
        }

        GlassButton {
            iconName: "quote"
            highlighted: root.appWindow.nowPlayingMode === "lyrics"
            tooltipText: highlighted ? "Hide lyrics" : "Show lyrics"
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "lyrics"
        }

        GlassButton {
            iconName: "list"
            highlighted: root.appWindow.nowPlayingMode === "queue"
            tooltipText: highlighted ? "Hide queue" : "Show queue"
            onClicked: root.appWindow.nowPlayingMode = highlighted ? "controls" : "queue"
        }

    }
}
