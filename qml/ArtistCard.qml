import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Item {
    id: root
    property string name: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 230
    property string artistImageUrl: ""

    signal clicked()

    width: cardWidth
    height: cardHeight

    Component.onCompleted: {
        if (root.name && typeof services !== "undefined") {
            const cached = services.getArtistImage(root.name)
            if (cached && cached.length > 0) {
                artistImageUrl = cached
            } else {
                services.fetchArtistImage(root.name)
            }
        }
    }

    Connections {
        target: typeof services !== "undefined" ? services : null
        function onArtistImageLoaded(artist, imageUrl) {
            if (artist.trim().toLowerCase() === root.name.trim().toLowerCase()) {
                root.artistImageUrl = imageUrl
            }
        }
    }

    Rectangle {
        id: artistBg
        anchors.fill: parent
        radius: 16
        color: artistMouse.containsMouse ? surfaceElevated : "transparent"
        border.width: artistMouse.containsMouse ? 1.5 : 0
        border.color: artistMouse.containsMouse ? recordRed : "transparent"
        scale: artistMouse.containsMouse ? 1.03 : 1.0

        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on color { ColorAnimation { duration: 120 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Item {
                id: avatarItem
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Math.min(root.cardWidth - 28, 140)
                Layout.preferredHeight: width

                Rectangle {
                    id: maskCircle
                    width: avatarItem.width
                    height: avatarItem.height
                    radius: width / 2
                    color: "#FFFFFF"
                    visible: false
                    layer.enabled: true
                    layer.smooth: true
                }

                Rectangle {
                    id: avatarCircle
                    anchors.fill: parent
                    radius: width / 2
                    color: surfaceCard
                    border.width: artistMouse.containsMouse ? 2 : 1
                    border.color: artistMouse.containsMouse ? recordRed : "#20FFFFFF"
                    z: 2

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    Cover {
                        anchors.fill: parent
                        track: root.track
                        radius: avatarCircle.radius
                        visible: artistPhoto.status !== Image.Ready || root.artistImageUrl === ""
                    }

                    Image {
                        id: artistPhoto
                        anchors.fill: parent
                        source: root.artistImageUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready && source !== ""
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: maskCircle
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: root.name
                    color: artistMouse.containsMouse ? recordRedHover : textPrimary
                    font.family: displayFont
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    clip: true
                }

                Label {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 0
                    Layout.minimumWidth: 0
                    horizontalAlignment: Text.AlignHCenter
                    text: root.count + " songs"
                    color: textSecondary
                    font.family: monoFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    clip: true
                }
            }
        }

        MouseArea {
            id: artistMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }
}
