import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var paletteSource
    property var entry: ({})
    property bool compact: false
    property bool allowCurrentActivation: false
    property bool removeEnabled: false
    property bool playNextEnabled: false
    property bool reorderEnabled: false

    signal trackActivated(var track)
    signal playNextRequested(var track)
    signal trackRemovalRequested(var track)
    signal trackReorderRequested(var srcTrack, var targetTrack, int srcIndex, int targetIndex)
    readonly property int queueIndex: entry && entry.queueIndex !== undefined ? entry.queueIndex : -1

    readonly property bool header: entry && entry.type === "header"
    readonly property bool current: entry && entry.type === "current"
    readonly property var track: entry && (entry.track || entry)
    readonly property color textPrimary: paletteSource ? paletteSource.textPrimary : "#F5F2ED"
    readonly property color surfaceCard: paletteSource ? paletteSource.surfaceCard : "#151412"
    readonly property color surfaceElevated: paletteSource ? paletteSource.surfaceElevated : "#211F1C"
    readonly property color recordRed: paletteSource ? paletteSource.recordRed : "#D83B31"
    readonly property color recordRedHover: paletteSource ? paletteSource.recordRedHover : "#F04A40"
    readonly property color borderVariant: paletteSource && paletteSource.borderVariant ? paletteSource.borderVariant : "#403B35"
    readonly property color borderSubtle: paletteSource && paletteSource.borderSubtle ? paletteSource.borderSubtle : "#2A2723"
    readonly property color borderCard: paletteSource && paletteSource.borderCard ? paletteSource.borderCard : borderVariant

    readonly property bool isCompactDensity: compact || (typeof window !== "undefined" && window.trackDensity === "compact")
    readonly property bool highlighted: rowMouse.containsMouse || (rowMouse.enabled && activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.ListItem
    Accessible.name: track ? (track.title || track.fileName || "") : ""
    Accessible.ignored: header
    Accessible.onPressAction: if (rowMouse.enabled) trackActivated(track)
    Keys.onReturnPressed: if (rowMouse.enabled) trackActivated(track)
    Keys.onEnterPressed: if (rowMouse.enabled) trackActivated(track)
    Keys.onMenuPressed: if (!header) contextMenu.popup(root, 0, root.height)

    implicitHeight: header ? (isCompactDensity ? 22 : 30) : (isCompactDensity ? 40 : 52)

    Rectangle {
        anchors.fill: parent
        radius: root.isCompactDensity ? 5 : 8
        color: root.header ? "transparent" : (root.highlighted
            ? root.paletteSource.surfaceElevated
            : (root.current ? (root.compact ? "#1E1C1A" : "#1C1A18") : "transparent"))
        border.width: root.current && root.compact ? 1 : 0
        border.color: root.borderCard
        opacity: (root.reorderEnabled && gripMouse.drag.active) ? 0.35 : 1.0

        DropArea {
            id: dropArea
            anchors.fill: parent
            enabled: root.reorderEnabled
            keys: ["queue-track"]
            onDropped: drop => {
                if (drop.source && drop.source.dragTrack) {
                    root.trackReorderRequested(drop.source.dragTrack, root.track, drop.source.dragIndex !== undefined ? drop.source.dragIndex : -1, root.queueIndex)
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            radius: 1
            color: root.paletteSource && root.paletteSource.recordRed ? root.paletteSource.recordRed : "#D83B31"
            visible: dropArea.containsDrag && !(root.reorderEnabled && gripMouse.drag.active)
            z: 2
        }

        Item {
            id: dragSourceItem
            Drag.active: root.reorderEnabled && gripMouse.drag.active
            Drag.source: dragSourceItem
            Drag.keys: ["queue-track"]
            property var dragTrack: root.track
            property int dragIndex: root.queueIndex
        }

        Label {
            anchors.left: parent.left
            anchors.leftMargin: root.compact ? 4 : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: root.header
            text: root.entry.title || ""
            color: root.entry.title === "NOW PLAYING" ? root.paletteSource.recordRed : root.paletteSource.silverDim
            font.family: root.paletteSource.monoFont
            font.pixelSize: root.compact ? 9 : 11
            font.weight: Font.Bold
            font.letterSpacing: root.compact ? 0 : 1.0
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: !root.header && (!root.current || root.allowCurrentActivation)
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: {
                root.mouseFocused = true
                root.forceActiveFocus()
            }
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    contextMenu.popup()
                } else {
                    root.trackActivated(root.track)
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 6 : 12
            anchors.rightMargin: root.compact ? 6 : 14
            spacing: root.compact ? 8 : 12
            visible: !root.header

            Cover {
                Layout.preferredWidth: root.compact ? 28 : 38
                Layout.preferredHeight: root.compact ? 28 : 38
                radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined && window.albumArtRadius === 0)
                        ? 0 : (root.compact ? 4 : 6)
                track: root.track
                cacheArtwork: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: root.compact ? 0 : 1

                Label {
                    Layout.fillWidth: true
                    text: root.entry.title || root.entry.fileName || ""
                    color: root.current ? root.paletteSource.recordRed : root.paletteSource.textPrimary
                    font.family: root.paletteSource.displayFont
                    font.pixelSize: root.compact ? 11 : 13
                    font.weight: root.current ? Font.Bold : (root.compact ? Font.Medium : Font.DemiBold)
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    text: root.compact
                        ? (root.entry.artist || "Unknown Artist")
                        : ((root.entry.artist || "Unknown Artist") + " • " + (root.entry.album || "Unknown Album"))
                    color: root.paletteSource.textSecondary
                    font.family: root.paletteSource.bodyFont
                    font.pixelSize: root.compact ? 9 : 11
                    elide: Text.ElideRight
                }
            }

            Label {
                visible: !root.removeEnabled && !root.playNextEnabled
                text: root.entry.duration || (root.compact ? "" : "—")
                color: root.paletteSource.silverDim
                font.family: root.paletteSource.monoFont
                font.pixelSize: root.compact ? 9 : 11
            }

            PressDepthIconButton {
                visible: root.playNextEnabled
                z: 1
                Layout.preferredWidth: root.compact ? 24 : 28
                Layout.preferredHeight: root.compact ? 24 : 28
                boxSize: root.compact ? 24 : 28
                iconSize: root.compact ? 13 : 15
                iconName: "arrow-up"
                tooltipText: "Play next"
                onClicked: root.playNextRequested(root.track)
            }
            PressDepthIconButton {
                visible: root.removeEnabled
                z: 1
                Layout.preferredWidth: root.compact ? 24 : 28
                Layout.preferredHeight: root.compact ? 24 : 28
                boxSize: root.compact ? 24 : 28
                iconSize: root.compact ? 13 : 15
                iconName: "x"
                tooltipText: "Remove from queue"
                onClicked: root.trackRemovalRequested(root.track)
            }
            Item {
                id: dragGrip
                visible: root.reorderEnabled
                z: 1
                Layout.preferredWidth: root.compact ? 24 : 28
                Layout.preferredHeight: root.compact ? 24 : 28

                LucideIcon {
                    anchors.centerIn: parent
                    icon: "arrow-up-down"
                    color: gripMouse.containsMouse || gripMouse.drag.active
                        ? (root.paletteSource ? root.paletteSource.textPrimary : "#F5F2ED")
                        : (root.paletteSource ? root.paletteSource.silverDim : "#6E6C68")
                    width: root.compact ? 13 : 15
                    height: root.compact ? 13 : 15
                }

                MouseArea {
                    id: gripMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: Qt.SizeVerCursor
                    drag.target: dragSourceItem
                    drag.axis: Drag.YAxis
                    onPressed: mouse => {
                        dragSourceItem.Drag.hotSpot = gripMouse.mapToItem(dragSourceItem, mouse.x, mouse.y)
                    }
                    onReleased: {
                        if (dragSourceItem.Drag.active) {
                            dragSourceItem.Drag.drop()
                        }
                        dragSourceItem.y = 0
                    }
                    onCanceled: {
                        dragSourceItem.y = 0
                    }
                }
            }
        }

        TrackContextMenu {
            id: contextMenu
            track: root.track
        }
    }
}


