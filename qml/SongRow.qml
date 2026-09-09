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
    property real coverRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 8
    property bool showFormatBadge: (typeof window !== "undefined" && window.showFormatBadges !== undefined) ? window.showFormatBadges : true

    signal clicked()
    signal favoriteClicked()

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
    radius: rowRadius
    color: rowMouse.containsMouse ? hoverBg : (isCurrent ? activeBg : cardBg)
    border.width: isCurrent ? 1 : 0
    border.color: isCurrent ? recordRed : "transparent"

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
                color: isFavorite(root.track ? root.track.filePath : "") ? recordRed : (rowMouse.containsMouse ? textSecondary : "transparent")
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
            visible: showDuration
            Layout.alignment: Qt.AlignVCenter
            text: root.track ? (root.track.duration || "-") : "-"
            color: textSecondary
            font.family: monoFont
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
