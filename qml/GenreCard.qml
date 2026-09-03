import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property string name: ""
    property int count: 0
    property string iconName: "disc"
    property real cardWidth: 190
    property real cardHeight: 110
    property real cardRadius: 16

    signal clicked()

    readonly property var genrePalettes: [
        { bg1: "#C0392B", bg2: "#8E44AD", border: "#E74C3C", icon: "disc" },         // Velvet Sunset
        { bg1: "#2980B9", bg2: "#6DD5FA", border: "#3498DB", icon: "radio" },        // Neon Cyan
        { bg1: "#11998E", bg2: "#38EF7D", border: "#2ECC71", icon: "music" },        // Electric Emerald
        { bg1: "#8A2387", bg2: "#E94057", border: "#F27121", icon: "zap" },          // Synthwave Horizon
        { bg1: "#4A00E0", bg2: "#8E2DE2", border: "#7B1FA2", icon: "disc" },         // Deep Cosmic Violet
        { bg1: "#FF416C", bg2: "#FF4B2B", border: "#FF3366", icon: "heart" },        // Cyber Coral
        { bg1: "#F7971E", bg2: "#FFD200", border: "#F39C12", icon: "disc" },         // Golden Sun
        { bg1: "#1A2980", bg2: "#26D0CE", border: "#00BCD4", icon: "audio-lines" },  // Ocean Aurora
        { bg1: "#3A1C71", bg2: "#D76D77", border: "#E08283", icon: "mic" },          // Dusk Twilight
        { bg1: "#134E5E", bg2: "#71B280", border: "#27AE60", icon: "folder" }        // Forest Mist
    ]

    readonly property var currentPalette: {
        let hash = 0
        const str = root.name || "Music"
        for (let i = 0; i < str.length; i++) {
            hash = (hash * 31 + str.charCodeAt(i)) & 0xFFFFFF
        }
        return genrePalettes[Math.abs(hash) % genrePalettes.length]
    }

    width: cardWidth
    height: cardHeight
    radius: cardRadius
    clip: true
    color: "#181615"
    border.width: genreMouse.containsMouse ? 1.5 : 1.0
    border.color: genreMouse.containsMouse ? currentPalette.border : "#2A2825"
    scale: genreMouse.containsMouse ? 1.03 : 1.0

    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.currentPalette.bg1 }
            GradientStop { position: 1.0; color: root.currentPalette.bg2 }
        }
        opacity: genreMouse.containsMouse ? 0.85 : 0.65
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cardRadius
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#20000000" }
            GradientStop { position: 1.0; color: "#95000000" }
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -25
        anchors.bottomMargin: -25
        width: 100
        height: 100
        radius: 50
        color: "transparent"
        border.width: 10
        border.color: "#25FFFFFF"
        opacity: genreMouse.containsMouse ? 0.9 : 0.5
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Rectangle {
            anchors.centerIn: parent
            width: 50
            height: 50
            radius: 25
            color: "transparent"
            border.width: 6
            border.color: "#18FFFFFF"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 16
                color: "#35000000"
                border.width: 1
                border.color: "#25FFFFFF"

                LucideIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    icon: root.currentPalette.icon
                    color: "#FFFFFF"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: gCountLbl.implicitWidth + 14
                radius: 11
                color: "#40000000"
                border.width: 1
                border.color: "#30FFFFFF"

                Label {
                    id: gCountLbl
                    anchors.centerIn: parent
                    text: root.count + " songs"
                    color: "#FFFFFF"
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }
        }

        Item { Layout.fillHeight: true }

        Label {
            Layout.fillWidth: true
            text: root.name
            color: "#FFFFFF"
            font.family: displayFont
            font.pixelSize: 16
            font.weight: Font.Bold
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: genreMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
