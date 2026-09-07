import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root
    property var tracks: []
    property string title: ""
    property string artistBio: ""
    property var albumGroups: []
    property real contentWidth: 0
    property var appWindow

    signal albumRequested(string name, var track)

    width: root.contentWidth
    spacing: 0

    Item {
        width: root.contentWidth
        height: artistGridRow.implicitHeight
        visible: root.tracks.length > 0

        RowLayout {
            id: artistGridRow
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            spacing: 32

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "Popular Tracks"
                    color: "#FFFFFF"
                    font.family: "Space Grotesk"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                Repeater {
                    model: root.tracks.slice(0, 5)

                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: popMouse.containsMouse ? "#18FFFFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 14
                                spacing: 12

                                Label {
                                    Layout.preferredWidth: 20
                                    text: String(index + 1)
                                    color: popMouse.containsMouse ? "#C23B30" : "#6E6C68"
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                Rectangle {
                                    Layout.preferredWidth: 38
                                    Layout.preferredHeight: 38
                                    radius: 6
                                    clip: true
                                    color: "#181715"

                                    Cover {
                                        anchors.fill: parent
                                        track: modelData
                                        radius: 6
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: "#80000000"
                                        visible: popMouse.containsMouse

                                        LucideIcon {
                                            anchors.centerIn: parent
                                            width: 13
                                            height: 13
                                            icon: "play"
                                            color: "#FFFFFF"
                                        }
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.title || modelData.fileName || "Unknown Title"
                                        color: popMouse.containsMouse ? "#C23B30" : "#F5F0EC"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 13
                                        font.weight: Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.album || modelData.artist || ""
                                        color: "#858079"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 18
                                    Layout.preferredWidth: fmtBadgeLbl.implicitWidth + 8
                                    radius: 4
                                    color: "#14FFFFFF"

                                    Label {
                                        id: fmtBadgeLbl
                                        anchors.centerIn: parent
                                        text: (modelData.format || "MP3").toUpperCase()
                                        color: "#858079"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                }

                                Label {
                                    text: {
                                        const secs = modelData.durationSeconds || 0
                                        const m = Math.floor(secs / 60)
                                        const s = Math.floor(secs % 60)
                                        return m + ":" + (s < 10 ? "0" : "") + s
                                    }
                                    color: "#858079"
                                    font.family: "Space Grotesk"
                                    font.pixelSize: 12
                                }
                            }

                            MouseArea {
                                id: popMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.appWindow) root.appWindow.playTrack(modelData)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: Math.min(Math.max(280, (root.contentWidth - 72) * 0.38), 380)
                Layout.alignment: Qt.AlignTop
                spacing: 8
                visible: root.albumGroups.length > 0

                Label {
                    text: "Top Releases"
                    color: "#FFFFFF"
                    font.family: "Space Grotesk"
                    font.pixelSize: 19
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                Repeater {
                    model: root.albumGroups.slice(0, 2)

                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 100

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: topRelMouse.containsMouse ? "#20FFFFFF" : "#141312"
                            border.width: 1
                            border.color: topRelMouse.containsMouse ? "#C23B30" : "#1AFFFFFF"

                            Behavior on color { ColorAnimation { duration: 120 } }
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 14

                                Rectangle {
                                    Layout.preferredWidth: 76
                                    Layout.preferredHeight: 76
                                    radius: 8
                                    clip: true
                                    color: "#181715"

                                    Cover {
                                        anchors.fill: parent
                                        track: modelData.track
                                        radius: 8
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: "ALBUM"
                                        color: "#C23B30"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        font.letterSpacing: 1.2
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: "#FFFFFF"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.count + (modelData.count === 1 ? " song" : " songs")
                                        color: "#858079"
                                        font.family: "Space Grotesk"
                                        font.pixelSize: 12
                                    }
                                }

                                TransportButton {
                                    buttonSize: 34
                                    iconName: "play"
                                    accented: false
                                    tooltipText: "Play Album"
                                    onClicked: root.albumRequested(modelData.name, modelData.track)
                                }
                            }

                            MouseArea {
                                id: topRelMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.albumRequested(modelData.name, modelData.track)
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        visible: root.albumGroups.length > 0
        spacing: 10

        Item { width: 1; height: 16 }

        Label {
            leftPadding: 36
            rightPadding: 36
            text: "Albums & Releases (" + root.albumGroups.length + ")"
            color: "#FFFFFF"
            font.family: "Space Grotesk"
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: -0.3
        }

        ListView {
            width: parent.width
            height: 255
            orientation: ListView.Horizontal
            clip: true
            spacing: 16
            leftMargin: 36
            rightMargin: 36
            model: root.albumGroups

            delegate: AlbumCard {
                required property var modelData
                width: 175
                height: 245
                cardWidth: 175
                cardHeight: 245
                name: modelData.name
                artist: modelData.track.artist || "Unknown Artist"
                count: modelData.count
                track: modelData.track
                onClicked: root.albumRequested(modelData.name, modelData.track)
            }
        }
    }

    Column {
        width: parent.width
        visible: root.tracks.length > 0
        spacing: 4

        Item { width: 1; height: 16 }

        Label {
            leftPadding: 36
            rightPadding: 36
            bottomPadding: 8
            text: "All Songs (" + root.tracks.length + ")"
            color: "#FFFFFF"
            font.family: "Space Grotesk"
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: -0.3
        }

        Repeater {
            model: root.tracks

            SongRow {
                width: root.contentWidth - 56
                x: 28
                track: modelData
                showAlbum: true
                onClicked: if (root.appWindow) root.appWindow.playTrack(modelData)
            }
        }
    }

    Column {
        width: parent.width
        visible: root.artistBio.length > 0
        spacing: 10

        Item { width: 1; height: 18 }

        Label {
            leftPadding: 36
            rightPadding: 36
            text: "About " + root.title
            color: "#FFFFFF"
            font.family: "Space Grotesk"
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: -0.3
        }

        Rectangle {
            width: root.contentWidth - 72
            x: 36
            radius: 14
            color: "#141312"
            border.width: 1
            border.color: "#1AFFFFFF"
            implicitHeight: bioCol.implicitHeight + 36

            ColumnLayout {
                id: bioCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18
                spacing: 8
                property bool expanded: false

                Text {
                    id: bioText
                    Layout.fillWidth: true
                    text: root.artistBio
                    wrapMode: Text.Wrap
                    color: "#B0ACA5"
                    font.family: "Space Grotesk"
                    font.pixelSize: 13
                    lineHeight: 1.45
                    maximumLineCount: bioCol.expanded ? 1000 : 5
                    elide: Text.ElideRight
                }

                Label {
                    visible: root.artistBio.length > 300
                    text: bioCol.expanded ? "Show Less" : "Read More"
                    color: "#C23B30"
                    font.family: "Space Grotesk"
                    font.pixelSize: 12
                    font.weight: Font.Bold

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bioCol.expanded = !bioCol.expanded
                    }
                }
            }
        }
    }
}
