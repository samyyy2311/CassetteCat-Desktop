import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 230
    property bool isCurrent: !!(player.currentTrack && track && player.currentTrack.filePath === track.filePath)
    property bool isPlaying: isCurrent && player.isPlaying

    signal clicked()
    signal favoriteClicked()

    readonly property bool highlighted: cardMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: root.track.title || root.track.fileName || ""
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onMenuPressed: contextMenu.popup(root, 0, root.height)

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
                radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12
                highlighted: root.highlighted
                current: root.isCurrent

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: coverContainer.radius
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
                text: root.track.title || root.track.fileName || "Unknown Track"
                color: root.isCurrent ? recordRed : (root.highlighted ? recordRedHover : textPrimary)
                font.family: displayFont
                font.pixelSize: 13
                font.weight: root.isCurrent ? Font.Bold : Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }

            Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 0
                Layout.minimumWidth: 0
                text: root.track.artist || "Unknown Artist"
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 11
                elide: Text.ElideRight
                maximumLineCount: 1
                clip: true
            }
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
        id: cardMouse
        anchors.fill: parent
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
                root.clicked()
            }
        }
    }
}
