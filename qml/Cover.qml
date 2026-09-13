import QtQuick
import QtQuick.Effects
import QtQuick.Window

Item {
    id: root
    property var track: ({})
    property real radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 8
    property bool keepPreviousArtwork: false
    property bool cacheArtwork: true
    property real stableSourceSize: 0
    property bool showTonearm: false
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

    property bool useB: false
    readonly property var activeImage: useB ? imageB : imageA
    readonly property var previousImage: useB ? imageA : imageB

    readonly property real artworkImplicitWidth: activeImage ? activeImage.implicitWidth : 0
    readonly property real artworkImplicitHeight: activeImage ? activeImage.implicitHeight : 0
    readonly property real artworkAspectRatio: (artworkImplicitHeight > 0 && artworkImplicitWidth > 0)
        ? (artworkImplicitWidth / artworkImplicitHeight)
        : 1.0

    readonly property bool hasArtwork: artworkSource.toString() !== ""
    readonly property bool currentHasError: useB ? (imageB.status === Image.Error) : (imageA.status === Image.Error)
    readonly property bool anyArtVisible: (imageA.status === Image.Ready && imageA.opacity > 0.01)
                                       || (imageB.status === Image.Ready && imageB.opacity > 0.01)
    readonly property bool showingFallback: (!hasArtwork || currentHasError) && !anyArtVisible
    readonly property bool currentTrackPlaying: player.isPlaying && root.track && player.currentTrack
                                              && root.track.filePath === player.currentTrack.filePath

    function coverColor(value) {
        const colors = [
            "#221E1B", "#1C1F26", "#241820", "#18221D", "#201B24", "#241F18"
        ]
        let hash = 0
        const str = value || "CassetteCat"
        for (let i = 0; i < str.length; ++i) hash = (hash * 31 + str.charCodeAt(i)) >>> 0
        return colors[hash % colors.length]
    }

    onArtworkSourceChanged: {
        applyArtworkSource()
    }

    Component.onCompleted: {
        applyArtworkSource()
    }

    function applyArtworkSource() {
        const next = artworkSource.toString()
        const curr = activeImage.source.toString()

        if (next === curr && activeImage.status === Image.Ready) return

        if (!next) {
            imageA.opacity = 0
            imageB.opacity = 0
            return
        }

        if (root.keepPreviousArtwork && activeImage.status === Image.Ready && curr !== "") {
            if (useB) {
                imageA.opacity = 0
                imageA.source = next
                useB = false
                if (imageA.status === Image.Ready) {
                    imageA.opacity = 1
                    imageB.opacity = 0
                }
            } else {
                imageB.opacity = 0
                imageB.source = next
                useB = true
                if (imageB.status === Image.Ready) {
                    imageB.opacity = 1
                    imageA.opacity = 0
                }
            }
        } else {
            activeImage.opacity = 0
            activeImage.source = next
            if (activeImage.status === Image.Ready) {
                activeImage.opacity = 1
            }
        }
    }

    Rectangle {
        id: bgPlaceholder
        anchors.fill: parent
        radius: root.radius
        color: "#000000"

        VinylFallback {
            showTonearm: root.showTonearm
            anchors.fill: parent
            visible: opacity > 0.001
            opacity: root.showingFallback ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            playing: root.currentTrackPlaying && root.showingFallback
            progress: root.currentTrackPlaying && player.duration > 0 ? player.position / player.duration : 0
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
        id: imageA
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
        visible: opacity > 0.001

        onStatusChanged: {
            if (status === Image.Ready && !root.useB) {
                imageA.opacity = 1
                if (imageB.opacity > 0) imageB.opacity = 0
            } else if (status === Image.Error && !root.useB) {
                imageA.opacity = 0
                if (imageB.opacity > 0) imageB.opacity = 0
            }
        }
        onOpacityChanged: {
            if (opacity === 0 && root.useB && status !== Image.Loading) {
                source = ""
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        layer.enabled: root.radius > 0 && imageA.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }

    Image {
        id: imageB
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
        visible: opacity > 0.001

        onStatusChanged: {
            if (status === Image.Ready && root.useB) {
                imageB.opacity = 1
                if (imageA.opacity > 0) imageA.opacity = 0
            } else if (status === Image.Error && root.useB) {
                imageB.opacity = 0
                if (imageA.opacity > 0) imageA.opacity = 0
            }
        }
        onOpacityChanged: {
            if (opacity === 0 && !root.useB && status !== Image.Loading) {
                source = ""
            }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        layer.enabled: root.radius > 0 && imageB.visible
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: maskItem
        }
    }
}
