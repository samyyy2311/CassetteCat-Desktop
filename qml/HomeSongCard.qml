import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var track: ({})
    property real cardWidth: 150
    property real cardHeight: 225
    property real coverRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12

    signal clicked()

    readonly property bool highlighted: cardMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: root.track.title || root.track.fileName || ""
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

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
            text: root.track.title || root.track.fileName
            color: root.highlighted ? recordRedHover : textPrimary
            font.family: displayFont
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            Layout.fillWidth: true
            text: root.track.artist || "Unknown Artist"
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Item { Layout.fillHeight: true }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: {
            root.mouseFocused = true
            root.forceActiveFocus()
        }
        onClicked: root.clicked()
    }
}
