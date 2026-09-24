import QtQuick.Controls
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root
    property string name: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 230
    property string artistImageUrl: ""
    property string subtitle: ""
    property bool imageAllowed: true
    property bool imageRequested: false

    signal clicked()

    readonly property bool highlighted: artistMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: root.name
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    width: cardWidth
    height: cardHeight

    function loadArtistImage() {
        if (!root.name || !root.imageAllowed || root.imageRequested || typeof services === "undefined") return
        root.imageRequested = true
        const cached = services.getArtistImage(root.name)
        if (cached && cached.length > 0) {
            artistImageUrl = cached
        } else {
            services.fetchArtistImage(root.name)
        }
    }

    Component.onCompleted: loadArtistImage()
    onNameChanged: {
        root.imageRequested = false
        root.artistImageUrl = ""
        loadArtistImage()
    }
    onImageAllowedChanged: if (imageAllowed) loadArtistImage()

    Connections {
        target: typeof services !== "undefined" ? services : null
        function onArtistImageLoaded(artist, imageUrl) {
            const a = (artist || "").toLowerCase().replace(/[^a-z0-9]/g, "")
            const b = (root.name || "").toLowerCase().replace(/[^a-z0-9]/g, "")
            if (a.length > 0 && a === b) {
                root.artistImageUrl = imageUrl
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            id: avatarItem
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(root.cardWidth - 20, 140)
            Layout.preferredHeight: width
            scale: root.highlighted ? 1.04 : 1.0

            Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }

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
                border.width: root.highlighted ? 2 : 1
                border.color: root.highlighted ? recordRed : "#30FFFFFF"
                clip: true
                z: 2

                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Dark studio fallback when no photo or track artwork exists
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: surfaceCard
                    visible: (artistPhoto.status !== Image.Ready || root.artistImageUrl === "") && (!root.track || !root.track.filePath)
                    z: 0

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        icon: "mic"
                        color: root.highlighted ? recordRedHover : silverDim
                    }
                }

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: avatarCircle.radius
                    visible: (artistPhoto.status !== Image.Ready || root.artistImageUrl === "") && !!(root.track && root.track.filePath)
                }

                Image {
                    id: artistPhoto
                    anchors.fill: parent
                    source: root.artistImageUrl
                    sourceSize.width: Math.max(140, Math.ceil(Math.max(width, 140) * Screen.devicePixelRatio))
                    sourceSize.height: Math.max(140, Math.ceil(Math.max(height, 140) * Screen.devicePixelRatio))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready && source !== ""
                    layer.enabled: visible
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: maskCircle
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }
                }

                // Subtle inner border ensuring pure black album art (e.g. Donda) has crisp definition
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1
                    border.color: "#18FFFFFF"
                    z: 10
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
                color: root.highlighted ? recordRedHover : textPrimary
                font.family: displayFont
                font.pixelSize: 14
                font.weight: Font.Bold
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true

                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                horizontalAlignment: Text.AlignHCenter
                text: root.subtitle.length > 0 ? root.subtitle : (root.count + (root.count === 1 ? " song" : " songs"))
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
        onPressed: {
            root.mouseFocused = true
            root.forceActiveFocus()
        }
        onClicked: root.clicked()
    }
}
