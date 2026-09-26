import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "TrackTitles.js" as TrackTitles

CardBase {
    id: root

    property var track: ({})
    property real cardWidth: 150
    property real cardHeight: 225
    property real coverRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12

    accessibleName: root.track.title || root.track.fileName || ""

    width: cardWidth
    height: cardHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        CoverFrame {
            Layout.preferredWidth: root.cardWidth
            Layout.preferredHeight: root.cardWidth
            radius: root.coverRadius
            highlighted: root.highlighted

            Cover {
                anchors.fill: parent
                track: root.track
                radius: root.coverRadius
            }
        }

        Label {
            Layout.fillWidth: true
            text: TrackTitles.title(root.track) || root.track.fileName
            color: root.highlighted ? recordRedHover : textPrimary
            font.family: displayFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            Layout.fillWidth: true
            text: TrackTitles.artist(root.track) || "Unknown Artist"
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }
    }
}
