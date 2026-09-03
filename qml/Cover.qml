import QtQuick
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root
    property var track: ({})
    property real radius: 8
    property bool keepPreviousArtwork: false
    property bool cacheArtwork: false
    property real stableSourceSize: 0
    readonly property url artworkSource: {
        const currentTrack = root.track || ({})
        return currentTrack.artworkUrl || (currentTrack.filePath ? library.artworkFor(currentTrack.filePath) : "")
    }
    property url displayedSource: artworkSource

    onArtworkSourceChanged: {
        if (artworkSource === displayedSource) return
        if (keepPreviousArtwork && artImage.status === Image.Ready && displayedSource) {
            previousArt.source = displayedSource
            previousArt.opacity = 1
        }
        displayedSource = artworkSource
    }

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

        LucideIcon {
            anchors.centerIn: parent
            visible: artImage.status !== Image.Ready || !artImage.visible
            width: Math.max(16, Math.min(parent.width * 0.46, parent.height * 0.46))
            height: width
            icon: "disc"
            color: "#8E8A84"
        }
    }

    Rectangle {
        id: maskItem
        width: Math.max(1, root.width)
        height: Math.max(1, root.height)
        radius: root.radius
        color: "#FFFFFF"
        visible: false
        layer.enabled: root.radius > 0
        layer.smooth: true
    }

    Image {
        id: previousArt
        anchors.fill: parent
        sourceSize.width: Math.max(1, Math.ceil((root.stableSourceSize || width) * Screen.devicePixelRatio))
        sourceSize.height: Math.max(1, Math.ceil((root.stableSourceSize || height) * Screen.devicePixelRatio))
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: root.cacheArtwork
        smooth: true
        mipmap: false
        autoTransform: true
        opacity: 0
        visible: opacity > 0 && source.toString() !== ""

        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        layer.enabled: root.radius > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }

    Image {
        id: artImage
        anchors.fill: parent
        source: root.displayedSource
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.max(1, Math.ceil((root.stableSourceSize || width) * Screen.devicePixelRatio))
        sourceSize.height: Math.max(1, Math.ceil((root.stableSourceSize || height) * Screen.devicePixelRatio))
        visible: status === Image.Ready && source.toString() !== ""
        opacity: visible ? 1 : 0
        asynchronous: true
        cache: root.cacheArtwork
        smooth: true
        mipmap: false
        autoTransform: true

        onStatusChanged: {
            if (status === Image.Ready || status === Image.Error) previousArt.opacity = 0
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        layer.enabled: root.radius > 0
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }
}
