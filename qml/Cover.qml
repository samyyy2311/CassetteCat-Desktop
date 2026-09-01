import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Item {
    id: root
    property var track: ({})
    property real radius: 8

    function coverColor(value) {
        const colors = [
            "#221E1B", "#1C1F26", "#241820", "#18221D", "#201B24", "#241F18"
        ]
        let hash = 0
        const str = value || "CassetteCat"
        for (let i = 0; i < str.length; ++i) hash = (hash * 31 + str.charCodeAt(i)) >>> 0
        return colors[hash % colors.length]
    }

    Rectangle {
        id: bgPlaceholder
        anchors.fill: parent
        radius: root.radius
        color: root.coverColor(root.track ? (root.track.title || root.track.album || root.track.artist || "CassetteCat") : "CassetteCat")
        clip: true

        LucideIcon {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready || !artImage.visible
            width: Math.max(16, Math.min(parent.width * 0.46, parent.height * 0.46))
            height: width
            icon: "disc"
            color: "#8E8A84"
        }
    }

    Image {
        id: artImage
        anchors.fill: parent
        source: root.track ? (root.track.artworkUrl || "") : ""
        fillMode: Image.PreserveAspectCrop
        visible: status === Image.Ready && source.toString() !== ""
        asynchronous: true
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }

    Item {
        id: maskItem
        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "white"
        }
    }
}
