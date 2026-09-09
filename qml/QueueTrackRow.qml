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

    signal trackActivated(var track)
    signal playNextRequested(var track)
    signal trackRemovalRequested(var track)

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

    implicitHeight: header ? (compact ? 22 : 30) : (compact ? 40 : 52)

    Rectangle {
        anchors.fill: parent
        radius: root.compact ? 5 : 8
        color: root.header ? "transparent" : (rowMouse.containsMouse
            ? root.paletteSource.surfaceElevated
            : (root.current ? (root.compact ? "#1E1C1A" : "#1C1A18") : "transparent"))
        border.width: root.current && root.compact ? 1 : 0
        border.color: root.paletteSource.borderCard

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

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.compact ? 6 : 12
            anchors.rightMargin: root.compact ? 6 : 14
            spacing: root.compact ? 8 : 12
            visible: !root.header

            Cover {
                Layout.preferredWidth: root.compact ? 28 : 38
                Layout.preferredHeight: root.compact ? 28 : 38
                radius: root.compact ? 4 : 6
                track: root.track
                cacheArtwork: root.compact
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
                        : ((root.entry.artist || "Unknown Artist") + " â€¢ " + (root.entry.album || "Unknown Album"))
                    color: root.paletteSource.textSecondary
                    font.family: root.paletteSource.bodyFont
                    font.pixelSize: root.compact ? 9 : 11
                    elide: Text.ElideRight
                }
            }

            Label {
                visible: !root.removeEnabled && !root.playNextEnabled
                text: root.entry.duration || (root.compact ? "" : "â€”")
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
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            enabled: !root.header && (!root.current || root.allowCurrentActivation)
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.trackActivated(root.track)
        }
    }
}


