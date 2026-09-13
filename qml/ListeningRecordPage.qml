import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property var appWindow
    property var tracks: []
    property var playCounts: ({})
    property var playbackHistory: []

    readonly property var mostPlayed: {
        const rows = (tracks || []).filter(track => track && track.filePath && (playCounts[track.filePath] || 0) > 0)
            .map(track => ({ track: track, count: playCounts[track.filePath] || 0 }))
        rows.sort((left, right) => right.count - left.count)
        return rows.slice(0, 50)
    }
    readonly property var recentTracks: (playbackHistory || []).slice(0, 50)
    readonly property int totalPlays: Object.keys(playCounts || {}).reduce((total, path) => total + (playCounts[path] || 0), 0)
    readonly property int uniquePlayed: Object.keys(playCounts || {}).filter(path => (playCounts[path] || 0) > 0).length
    readonly property var artistRanks: {
        const counts = {}
        mostPlayed.forEach(row => {
            const artist = row.track.artist || "Unknown Artist"
            counts[artist] = (counts[artist] || 0) + row.count
        })
        return Object.keys(counts).map(artist => ({ artist: artist, count: counts[artist] }))
            .sort((left, right) => right.count - left.count).slice(0, 5)
    }
    readonly property var albumRanks: {
        const counts = {}
        mostPlayed.forEach(row => {
            const album = row.track.album || "Unknown Album"
            counts[album] = (counts[album] || 0) + row.count
        })
        return Object.keys(counts).map(album => ({ album: album, count: counts[album] }))
            .sort((left, right) => right.count - left.count).slice(0, 5)
    }

    function formatCount(count) {
        return count + (count === 1 ? " play" : " plays")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 22

        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Your listening history and most played tracks"
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.bodyFont
                    font.pixelSize: 13
                }
            }

            Label {
                text: root.totalPlays + (root.totalPlays === 1 ? " play" : " plays") + " / " + root.uniquePlayed + " tracks"
                color: root.appWindow.recordRed
                font.family: root.appWindow.monoFont
                font.pixelSize: 12
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 18

            Label {
                text: "Save top tracks as playlist"
                color: root.appWindow.recordRed
                font.family: root.appWindow.displayFont
                font.pixelSize: 12
                font.weight: Font.DemiBold
                opacity: root.mostPlayed.length > 0 ? 1 : 0.45
                MouseArea {
                    anchors.fill: parent
                    enabled: root.mostPlayed.length > 0
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.appWindow.createPlaylist("Listening Record", root.mostPlayed.map(row => row.track))
                        root.appWindow.playlistStatus = "Listening Record playlist saved"
                    }
                }
            }

            Label {
                text: "Clear record"
                color: root.appWindow.textSecondary
                font.family: root.appWindow.displayFont
                font.pixelSize: 12
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearDialog.open()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: root.appWindow.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 36

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Label {
                    text: "MOST PLAYED"
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.mostPlayed

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: 64
                        radius: 8
                        color: rowMouse.containsMouse ? root.appWindow.surfaceCardHover : "transparent"

                        RowLayout {
                            z: 1
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Label {
                                text: index < 9 ? "0" + (index + 1) : index + 1
                                color: root.appWindow.silverDim
                                font.family: root.appWindow.monoFont
                                font.pixelSize: 11
                                Layout.preferredWidth: 22
                            }
                            Cover {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                track: modelData.track
                                radius: 6
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.track.title || modelData.track.fileName
                                    color: root.appWindow.textPrimary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: (modelData.track.artist || "Unknown Artist") + " / " + formatCount(modelData.count)
                                    color: root.appWindow.textSecondary
                                    font.family: root.appWindow.bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                            TransportButton {
                                buttonSize: 34
                                paletteSource: root.appWindow
                                iconName: "play"
                                accented: true
                                onClicked: root.appWindow.playTrack(modelData.track)
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.playTrack(modelData.track)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Label {
                    text: "TOP ARTISTS"
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(140, contentHeight)
                    clip: true
                    spacing: 2
                    model: root.artistRanks
                    delegate: RowLayout {
                        required property var modelData
                        width: ListView.view.width
                        height: 24
                        Label { Layout.fillWidth: true; text: modelData.artist; color: root.appWindow.textPrimary; font.family: root.appWindow.bodyFont; font.pixelSize: 12; elide: Text.ElideRight }
                        Label { text: formatCount(modelData.count); color: root.appWindow.textSecondary; font.family: root.appWindow.monoFont; font.pixelSize: 10 }
                    }
                }

                Label {
                    text: "TOP ALBUMS"
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(140, contentHeight)
                    clip: true
                    spacing: 2
                    model: root.albumRanks
                    delegate: RowLayout {
                        required property var modelData
                        width: ListView.view.width
                        height: 24
                        Label { Layout.fillWidth: true; text: modelData.album; color: root.appWindow.textPrimary; font.family: root.appWindow.bodyFont; font.pixelSize: 12; elide: Text.ElideRight }
                        Label { text: formatCount(modelData.count); color: root.appWindow.textSecondary; font.family: root.appWindow.monoFont; font.pixelSize: 10 }
                    }
                }

                Label {
                    text: "RECENTLY PLAYED"
                    color: root.appWindow.textSecondary
                    font.family: root.appWindow.monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.recentTracks

                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width
                        height: 56
                        radius: 8
                        color: recentMouse.containsMouse ? root.appWindow.surfaceCardHover : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12
                            Cover {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 40
                                track: modelData
                                radius: 6
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.title || modelData.fileName
                                    color: root.appWindow.textPrimary
                                    font.family: root.appWindow.displayFont
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: (modelData.artist || "Unknown Artist") + (modelData.album ? " / " + modelData.album : "")
                                    color: root.appWindow.textSecondary
                                    font.family: root.appWindow.bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            id: recentMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.playTrack(modelData)
                        }
                    }
                }
            }
        }

        Label {
            visible: root.mostPlayed.length === 0 && root.recentTracks.length === 0
            text: "Play a song for at least 30 seconds to start your record."
            color: root.appWindow.textSecondary
            font.family: root.appWindow.bodyFont
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Dialog {
        id: clearDialog
        title: "Clear listening record?"
        modal: true
        standardButtons: Dialog.Cancel | Dialog.Ok
        onAccepted: root.appWindow.clearListeningRecord()
    }
}
