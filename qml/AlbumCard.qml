import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

CardBase {
    id: root
    property string name: ""
    property string artist: ""
    property string subtitle: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 235
    property real imageRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12

    accessibleName: root.name
    onRightClicked: {
        if (typeof window !== "undefined" && window.openCoverSearch) {
            window.openCoverSearch(root.name, root.artist, root.track ? root.track.filePath : "")
        }
    }

    width: cardWidth
    height: cardHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.alignment: Qt.AlignHCenter

            CoverFrame {
                id: coverContainer
                anchors.fill: parent
                radius: root.imageRadius
                highlighted: root.highlighted

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: root.imageRadius
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.name
                color: root.highlighted ? recordRedHover : textPrimary
                font.family: displayFont
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                maximumLineCount: 2
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.subtitle.length > 0 ? root.subtitle : (root.artist ? root.artist : (root.count + (root.count === 1 ? " song" : " songs")))
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }
        }

        // Keeps the cover at the top when the title wraps to two lines.
        Item { Layout.fillHeight: true }
    }
}
