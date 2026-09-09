import QtQuick
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root
    property var track: ({})
    property real radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 8
    property bool keepPreviousArtwork: false
    property bool cacheArtwork: false
    property real stableSourceSize: 0
    property int fillMode: Image.PreserveAspectCrop
    readonly property int requestedSourceSize: Math.max(1, Math.min(1024,
        Math.ceil((stableSourceSize > 0 ? stableSourceSize : Math.max(width, height)) * Screen.devicePixelRatio)))
    function normalizeUrl(val) {
        if (!val) return ""
        const str = String(val).trim()
        if (!str || str === "null" || str === "undefined") return ""
        if (str.startsWith("file://") || str.startsWith("http://") || str.startsWith("https://") || str.startsWith("qrc:/") || str.startsWith("image://")) {
            return str
        }
        return "file:///" + str.replace(/\\/g, "/")
    }

    readonly property url artworkSource: {
        // Depend on the remote revision so lazily downloaded server artwork appears.
        streaming.remoteArtRevision
        const currentTrack = root.track || ({})
        if (currentTrack.artworkUrl) return normalizeUrl(currentTrack.artworkUrl)
        const path = currentTrack.filePath || ""
        if (!path) return ""
        if (path.startsWith("subsonic:") || path.startsWith("jellyfin:")) {
            return normalizeUrl(streaming.remoteArtwork(path))
        }
        return normalizeUrl(library.artworkFor(path))
    }
    property url displayedSource: artworkSource
    readonly property real artworkImplicitWidth: artImage.implicitWidth
    readonly property real artworkImplicitHeight: artImage.implicitHeight
    readonly property real artworkAspectRatio: (artImage.implicitHeight > 0 && artImage.implicitWidth > 0)
        ? (artImage.implicitWidth / artImage.implicitHeight)
        : 1.0
    readonly property bool showingFallback: !artImage.visible && !previousArt.visible
    readonly property bool currentTrackPlaying: player.isPlaying && root.track && player.currentTrack
                                              && root.track.filePath === player.currentTrack.filePath

    onArtworkSourceChanged: {
        if (artworkSource.toString() === displayedSource.toString()) return
        if (keepPreviousArtwork && artImage.status === Image.Ready && displayedSource.toString() !== "") {
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

        VinylFallback {
            anchors.fill: parent
            visible: root.showingFallback
            accent: recordRed
            playing: root.currentTrackPlaying && visible
        }
    }

    Rectangle {
        id: maskItem
        anchors.fill: parent
        radius: root.radius
        color: "#FFFFFF"
        visible: false
        layer.enabled: root.radius > 0
        layer.smooth: true
    }

    Image {
        id: previousArt
        anchors.fill: parent
        sourceSize.width: root.requestedSourceSize
        sourceSize.height: root.requestedSourceSize
        fillMode: root.fillMode
        asynchronous: true
        cache: root.cacheArtwork
        smooth: true
        mipmap: false
        autoTransform: true
        opacity: 0
        visible: opacity > 0 && source.toString() !== ""

        onOpacityChanged: {
            if (opacity === 0 && source.toString() !== "") source = ""
        }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        layer.enabled: root.radius > 0 && previousArt.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }

    Image {
        id: artImage
        anchors.fill: parent
        source: root.displayedSource
        fillMode: root.fillMode
        sourceSize.width: root.requestedSourceSize
        sourceSize.height: root.requestedSourceSize
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
