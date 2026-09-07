import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var playerController
    anchors.fill: parent
    property alias searchBox: radioSearchBox
    property alias searchInput: radSearchInput

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                spacing: 2
                Label {
                    text: "Radio Broadcast"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 26
                    font.weight: Font.Bold
                }
                Label {
                    text: root.appWindow.radioStations.length > 0 ? (root.appWindow.radioIsCustomized ? (root.appWindow.radioStations.length + " filtered live stations") : (root.appWindow.radioStations.length + " global live stations (Radio Browser API)")) : "Discover online radio streams"
                    color: textSecondary
                    font.family: monoFont
                    font.pixelSize: 12
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                id: radioSearchBox
                Layout.preferredWidth: 240
                Layout.preferredHeight: 36
                radius: 18
                color: surfaceCard
                border.width: 1
                border.color: radSearchInput.activeFocus ? recordRed : borderSubtle

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    LucideIcon {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        icon: "search"
                        color: radSearchInput.activeFocus ? recordRedHover : silverDim
                    }

                    TextInput {
                        id: radSearchInput
                        Layout.fillWidth: true
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 13
                        selectByMouse: true
                        text: root.appWindow.radioSearchQuery
                        onTextChanged: root.appWindow.radioSearchQuery = text
                        onAccepted: {
                            root.appWindow.refreshRadio();
                            focus = false;
                        }

                        Text {
                            anchors.fill: parent
                            visible: !radSearchInput.text && !radSearchInput.activeFocus
                            text: "Search live stations..."
                            color: textSecondary
                            font.family: displayFont
                            font.pixelSize: 13
                        }
                    }

                    Label {
                        visible: radSearchInput.text.length > 0
                        text: "×"
                        color: textPrimary
                        font.pixelSize: 16
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                radSearchInput.text = "";
                                root.appWindow.radioSearchQuery = "";
                                root.appWindow.refreshRadio();
                            }
                        }
                    }
                }
            }

            PressDepthIconButton {
                boxSize: 36
                iconSize: 18
                iconName: "refresh-cw"
                tint: textPrimary
                tooltipText: "Refresh Stations"
                onClicked: root.appWindow.refreshRadio()
            }

            PressDepthIconButton {
                boxSize: 36
                iconSize: 18
                iconName: "sliders-horizontal"
                tint: textPrimary
                highlighted: root.appWindow.radioIsCustomized
                tooltipText: "Refine & Sort Stations"
                onClicked: root.appWindow.radioRefineOpen = true
            }
        }

        GridView {
            id: radGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.appWindow.radioStations
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar {}
            readonly property int cols: Math.max(2, Math.floor(width / 260))
            cellWidth: Math.floor(width / cols)
            cellHeight: 110

            delegate: Item {
                width: radGrid.cellWidth
                height: 100

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 12
                    height: parent.height
                    radius: 16
                    color: radCardMouse.containsMouse ? surfaceElevated : surfaceCard
                    border.width: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl ? 1.5 : 1
                    border.color: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl ? recordRed : (radCardMouse.containsMouse ? borderVariant : borderSubtle)

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 120
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 12
                            color: "#181818"
                            border.width: 1
                            border.color: "#30FFFFFF"
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.favicon || ""
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }

                            LucideIcon {
                                anchors.centerIn: parent
                                width: 24
                                height: 24
                                icon: "radio"
                                color: recordRedHover
                                visible: !modelData.favicon || modelData.favicon.length === 0
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Label {
                                Layout.fillWidth: true
                                text: modelData.name || "Live Station"
                                color: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl ? recordRed : textPrimary
                                font.family: displayFont
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.country ? (modelData.country + (modelData.bitrate ? (" • " + modelData.bitrate + " kbps") : "")) : (modelData.tags || "Live Broadcast")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        TransportButton {
                            buttonSize: 36
                            iconName: (root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl && root.playerController.isPlaying) ? "pause" : "play"
                            accented: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl
                            onClicked: {
                                const stTrack = {
                                    title: modelData.name || "Live Radio Stream",
                                    artist: modelData.country || "Radio Browser",
                                    album: "Internet Radio Broadcast",
                                    filePath: modelData.streamUrl,
                                    format: "STREAM",
                                    duration: "LIVE",
                                    artworkUrl: modelData.favicon || ""
                                };
                                root.appWindow.playTrack(stTrack);
                            }
                        }
                    }

                    MouseArea {
                        id: radCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const stTrack = {
                                title: modelData.name || "Live Radio Stream",
                                artist: modelData.country || "Radio Browser",
                                album: "Internet Radio Broadcast",
                                filePath: modelData.streamUrl,
                                format: "STREAM",
                                duration: "LIVE",
                                artworkUrl: modelData.favicon || ""
                            };
                            root.appWindow.playTrack(stTrack);
                        }
                    }
                }
            }
        }

        EmptyState {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.appWindow.radioStations.length === 0
            catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
            title: "Loading Radio Stations..."
            subtitle: "Connecting to the global Radio Browser directory"
            actionLabel: "Retry Connection"
            onActionClicked: root.appWindow.refreshRadio()
        }
    }
}
