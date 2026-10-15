import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "LyricsText.js" as LyricsText

// The lines of a song's lyrics, shared by Now Playing and the mini player. It keeps the line being sung in view,
// fills its words as they're sung, and softens the lines around it.
AppListView {
    id: root
    required property var items
    required property var lines
    // The item kept in view, and the line drawn as the one being sung. They differ while tapping to sync.
    required property int activeItemIndex
    required property int activeLineIndex
    required property real positionMs
    required property bool playing
    property int fontSize: 28
    property string fontFamily
    property bool centered: false
    property color activeColor: "#FFFFFF"
    property int sidePadding: 36
    property int maxLineWidth: 920
    property real anchorRatio: 0.36
    signal lineClicked(var item)

    // After the user scrolls, the list stays where they left it for a while, with nothing blurred.
    property bool browsing: false
    // How far the last line change moved the list, so the lines below can follow a moment later.
    property real followShift: 0
    property int followTick: 0
    property double followAt: 0
    // The player reports its position a few times a second; in between it's estimated so the fill moves every frame.
    property real livePositionMs: positionMs
    property double positionAt: Date.now()

    function follow(animated) {
        if (browsing || activeItemIndex < 0)
            return
        let item = itemAtIndex(activeItemIndex)
        // A line far from the view has no item yet; jumping near it creates one.
        if (!item) {
            positionViewAtIndex(activeItemIndex, ListView.Center)
            item = itemAtIndex(activeItemIndex)
            animated = false
        }
        if (!item)
            return
        // Whole pixels, so the text and its effects stay sharp.
        const target = Math.round(Math.max(originY - topMargin, item.y + item.height / 2 - height * anchorRatio))
        followShift = animated ? target - contentY : 0
        followAt = Date.now()
        contentY = target
        if (animated)
            followTick++
    }

    // Lines fade out toward the top and bottom edges instead of being cut off.
    readonly property Item edgeFade: Rectangle {
        parent: root
        width: root.width
        height: root.height
        visible: false
        layer.enabled: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.16; color: "white" }
            GradientStop { position: 0.8; color: "white" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: root.edgeFade
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    model: items
    interactive: items.length > 0
    clip: true
    topMargin: Math.round(height * anchorRatio)
    bottomMargin: Math.round(height * (1 - anchorRatio))
    ScrollBar.vertical: AutoHideScrollBar {}

    onPositionMsChanged: {
        livePositionMs = positionMs
        positionAt = Date.now()
    }
    onItemsChanged: {
        browsing = false
        Qt.callLater(follow, false)
    }
    // Scrolled here rather than through currentIndex, whose own scrolling keeps the line at the edge of the view.
    onActiveItemIndexChanged: Qt.callLater(follow, true)
    onHeightChanged: Qt.callLater(follow, false)
    onVisibleChanged: if (visible) Qt.callLater(follow, false)
    onMovementStarted: {
        browsing = true
        browseTimer.stop()
    }
    onMovementEnded: browseTimer.restart()

    Timer {
        id: browseTimer
        interval: 3000
        onTriggered: {
            root.browsing = false
            root.follow(true)
        }
    }

    FrameAnimation {
        running: root.playing && root.visible && root.activeLineIndex >= 0
        onTriggered: root.livePositionMs = root.positionMs + (Date.now() - root.positionAt)
    }

    delegate: Item {
        id: entry
        required property var modelData
        required property int index
        readonly property bool isGap: modelData.type === "gap"
        readonly property bool synced: modelData.startMs >= 0
        readonly property bool current: !isGap && modelData.lineIndex === root.activeLineIndex
        readonly property bool gapActive: isGap && root.positionMs >= modelData.startMs && root.positionMs <= modelData.endMs
        readonly property var words: current && synced ? LyricsText.wordTimings(root.lines[modelData.lineIndex], modelData.endMs) : []

        width: ListView.view.width
        height: isGap ? (gapActive ? Math.round(root.fontSize * 2.2) : 0) : lineText.contentHeight + Math.round(root.fontSize * 0.9)
        transform: Translate { id: trail }

        Behavior on height {
            enabled: entry.isGap
            NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd }
        }

        // Lines further down start moving a little later, so the list settles like a wave.
        function followCurrent() {
            trailAnimation.stop()
            trail.y = root.followShift
            trailDelay.duration = Math.min(4, Math.max(0, index - root.activeItemIndex + 1)) * 25
            trailAnimation.start()
        }
        Component.onCompleted: if (Date.now() - root.followAt < 60) followCurrent()
        Connections {
            target: root
            function onFollowTickChanged() { entry.followCurrent() }
        }
        SequentialAnimation {
            id: trailAnimation
            PauseAnimation { id: trailDelay }
            NumberAnimation { target: trail; property: "y"; to: 0; duration: 650; easing.type: Easing.OutCubic }
        }

        Item {
            id: lineBox
            property real blur: entry.current || !entry.synced || root.browsing || lineMouse.containsMouse
                ? 0 : Math.min(0.5, Math.max(0, Math.abs(entry.index - root.activeItemIndex) - 2) * 0.12)
            visible: !entry.isGap
            width: Math.min(entry.width - root.sidePadding * 2, root.maxLineWidth)
            height: lineText.contentHeight
            x: root.centered ? Math.round((entry.width - width) / 2) : root.sidePadding
            y: Math.round((entry.height - height) / 2)
            transformOrigin: root.centered ? Item.Center : Item.Left
            scale: entry.current ? 1.0 : 0.97
            // Lines already sung disappear, and the ones to come fade the further away they are. Hovering or
            // scrolling brings them all back.
            opacity: {
                if (entry.current) return 1.0
                if (lineMouse.containsMouse) return 0.8
                if (!entry.synced) return 0.85
                if (root.browsing) return 0.45
                const ahead = entry.index - root.activeItemIndex
                return ahead > 0 ? Math.max(0.12, 0.45 - (ahead - 1) * 0.1) : 0.0
            }
            layer.enabled: blur > 0.01
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: lineBox.blur
                blurMax: 24
            }

            Behavior on opacity { NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd } }
            Behavior on scale { NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd } }
            Behavior on blur { NumberAnimation { duration: UiConstants.durationOverlay } }

            TextEdit {
                id: lineText
                width: parent.width
                readOnly: true
                selectByMouse: false
                activeFocusOnPress: false
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap
                horizontalAlignment: root.centered ? TextEdit.AlignHCenter : TextEdit.AlignLeft
                text: entry.isGap ? "" : entry.modelData.text
                // The line being sung starts faint and fills in; the others are faded as a whole.
                color: entry.current && entry.synced ? Qt.rgba(1, 1, 1, 0.4) : (entry.current ? root.activeColor : "#FFFFFF")
                font.family: root.fontFamily
                font.pixelSize: root.fontSize
                font.weight: Font.Bold
                font.letterSpacing: -0.3
            }

            // The words sung so far, lit one by one.
            TextEdit {
                visible: entry.words.length > 0
                width: lineText.width
                readOnly: true
                selectByMouse: false
                activeFocusOnPress: false
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.Wrap
                horizontalAlignment: lineText.horizontalAlignment
                text: lineText.text
                color: root.activeColor
                font: lineText.font
                layer.enabled: visible
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: fillMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
            }

            // Each word fades in over the time it's sung.
            Item {
                id: fillMask
                width: lineText.width
                height: lineText.height
                visible: false
                layer.enabled: true

                Repeater {
                    model: entry.words

                    Rectangle {
                        required property var modelData
                        readonly property rect from: {
                            lineText.contentHeight
                            return lineText.positionToRectangle(modelData.start)
                        }
                        readonly property rect to: {
                            lineText.contentHeight
                            return lineText.positionToRectangle(modelData.end)
                        }
                        readonly property real lit: Math.max(0, Math.min(1,
                            (root.livePositionMs - modelData.startMs) / Math.max(250, modelData.endMs - modelData.startMs)))
                        x: from.x
                        y: from.y
                        width: (to.y === from.y ? to.x : lineText.width) - from.x
                        height: from.height
                        color: "white"
                        opacity: lit * lit * (3 - 2 * lit)
                    }
                }
            }
        }

        // A pause between lines: the dots light up one by one as it passes.
        Row {
            readonly property real progress: entry.isGap
                ? (root.positionMs - entry.modelData.startMs) / Math.max(1, entry.modelData.endMs - entry.modelData.startMs) : 0
            x: root.centered ? Math.round((entry.width - width) / 2) : root.sidePadding
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(root.fontSize * 0.3)
            visible: entry.isGap
            opacity: entry.gapActive ? 1.0 : 0.0
            transformOrigin: root.centered ? Item.Center : Item.Left

            Behavior on opacity { NumberAnimation { duration: UiConstants.durationOverlay; easing.type: UiConstants.easingStd } }

            SequentialAnimation on scale {
                running: entry.gapActive && root.playing
                loops: Animation.Infinite
                NumberAnimation { to: 1.15; duration: 1100; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
            }

            Repeater {
                model: 3

                Rectangle {
                    required property int index
                    width: Math.round(root.fontSize * 0.36)
                    height: width
                    radius: width / 2
                    color: root.activeColor
                    opacity: parent.progress > index / 3 ? 1.0 : 0.3

                    Behavior on opacity { NumberAnimation { duration: UiConstants.durationOverlay } }
                }
            }
        }

        MouseArea {
            id: lineMouse
            anchors.fill: parent
            enabled: !entry.isGap
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.lineClicked(entry.modelData)
        }
    }
}
