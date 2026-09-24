import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property var track: ({})
    property bool isCurrent: !!(player.currentTrack && track && player.currentTrack.filePath === track.filePath)
    property bool showAlbum: true
    property bool showCover: true
    property bool showDuration: true
    property bool showHeart: true
    property bool showSourceBadge: true
    property color defaultTextColor: textPrimary
    property color activeTextColor: recordRed
    property color cardBg: "transparent"
    property color hoverBg: surfaceElevated
    property color activeBg: surfaceCard
    property real rowHeight: (typeof window !== "undefined" && window.trackDensity === "compact") ? 42 : 54
    property real rowRadius: 10
    property real coverRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined)
                               ? (window.albumArtRadius === 0 ? 0 : (window.albumArtRadius <= 8 ? 5 : 8))
                               : 8
    property bool showFormatBadge: (typeof window !== "undefined" && window.showFormatBadges !== undefined) ? window.showFormatBadges : true
    property bool selectable: false
    property bool selected: false
    property bool showPlayCount: false
    readonly property int playCount: (typeof window !== "undefined" && window.playCounts && root.track && root.track.filePath) ? (window.playCounts[root.track.filePath] || 0) : 0

    signal clicked(var modifiers)
    signal favoriteClicked()

    readonly property bool highlighted: rowMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.ListItem
    Accessible.name: root.track ? (root.track.title || root.track.fileName || "") : ""
    Accessible.onPressAction: root.clicked(Qt.NoModifier)
    Keys.onReturnPressed: root.clicked(Qt.NoModifier)
    Keys.onEnterPressed: root.clicked(Qt.NoModifier)
    Keys.onMenuPressed: contextMenu.popup(root, 0, root.height)

    Drag.active: trackDrag.active
    Drag.source: root
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2
    Drag.supportedActions: Qt.CopyAction
    Drag.dragType: Drag.Automatic

    DragHandler {
        id: trackDrag
        target: null
    }

    height: rowHeight
    implicitHeight: rowHeight
    radius: rowRadius
    color: root.highlighted ? hoverBg : (selected ? activeBg : (isCurrent ? activeBg : cardBg))
    border.width: selected || isCurrent ? 1 : 0
    border.color: selected ? recordRed : (isCurrent ? Qt.rgba(recordRed.r, recordRed.g, recordRed.b, 0.3) : "transparent")

    Behavior on color { ColorAnimation { duration: 120 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 16
        spacing: 12

        Cover {
            visible: showCover
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40
            Layout.alignment: Qt.AlignVCenter
            radius: root.coverRadius
            track: root.track
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.preferredWidth: 0
            Layout.minimumWidth: 0
            Layout.alignment: Qt.AlignVCenter
            spacing: 2
            clip: true

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.track ? (root.track.title || root.track.fileName || "Untitled Track") : ""
                color: isCurrent ? activeTextColor : defaultTextColor
                font.family: displayFont
                font.pixelSize: 14
                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                elide: Text.ElideRight
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: {
                    if (!root.track) return ""
                    const art = root.track.artist || "Unknown Artist"
                    const alb = root.track.album || ""
                    return (showAlbum && alb.length > 0) ? (art + " • " + alb) : art
                }
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }

        Rectangle {
            visible: showSourceBadge && !!(root.track && root.track.filePath
                && (String(root.track.filePath).startsWith("subsonic:") || String(root.track.filePath).startsWith("jellyfin:")))
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 20
            Layout.preferredWidth: srcText.implicitWidth + 10
            radius: 4
            color: "#18FFFFFF"
            border.width: 1
            border.color: "#30FFFFFF"

            Label {
                id: srcText
                anchors.centerIn: parent
                text: {
                    const p = String(root.track ? root.track.filePath : "")
                    if (p.startsWith("subsonic:")) return "SUBSONIC"
                    if (p.startsWith("jellyfin:")) return "JELLYFIN"
                    return ""
                }
                color: textSecondary
                font.family: monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Rectangle {
            visible: showFormatBadge && !!(root.track && root.track.format)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredHeight: 20
            Layout.preferredWidth: fmtText.implicitWidth + 10
            radius: 4
            color: "#18FFFFFF"
            border.width: 1
            border.color: "#30FFFFFF"

            Label {
                id: fmtText
                anchors.centerIn: parent
                text: root.track ? (root.track.format || "").toUpperCase() : ""
                color: textSecondary
                font.family: monoFont
                font.pixelSize: 9
                font.weight: Font.Bold
            }
        }

        Item {
            visible: showHeart && !!(root.track && root.track.filePath)
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            LucideIcon {
                anchors.centerIn: parent
                width: 16
                height: 16
                icon: "heart"
                color: isFavorite(root.track ? root.track.filePath : "") ? recordRed : (root.highlighted ? textSecondary : "transparent")
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.track && root.track.filePath) {
                        root.favoriteClicked()
                    }
                }
            }
        }

        Label {
            visible: showPlayCount && playCount > 0
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 60
            horizontalAlignment: Text.AlignRight
            text: playCount + (playCount === 1 ? " play" : " plays")
            color: silverDim
            font.family: monoFont
            font.pixelSize: 11
        }

        Label {
            visible: showDuration
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 44
            horizontalAlignment: Text.AlignRight
            text: root.track ? (root.track.duration || "-") : "-"
            color: textSecondary
            font.family: monoFont
            font.pixelSize: 12
        }
    }

    // Built on first use: a Menu per list delegate makes scrolling allocate menus nobody opens.
    Loader {
        id: contextMenu
        active: false
        sourceComponent: TrackContextMenu { track: root.track }

        function popup(...args) {
            active = true
            item.popup(...args)
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            root.mouseFocused = true
            root.forceActiveFocus()
        }
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                contextMenu.popup()
            } else {
                root.clicked(mouse.modifiers)
            }
        }
    }
}
