import QtQuick.Controls
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property string name: ""
    property string artist: ""
    property string subtitle: ""
    property int count: 0
    property var track: ({})
    property real cardWidth: 170
    property real cardHeight: 235
    property real imageRadius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12

    signal clicked()

    readonly property bool highlighted: albumCardMouse.containsMouse || (activeFocus && !mouseFocused)
    property bool mouseFocused: false
    onActiveFocusChanged: if (!activeFocus) mouseFocused = false

    Accessible.role: Accessible.Button
    Accessible.name: root.name
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    width: cardWidth
    height: cardHeight

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: width
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                id: coverContainer
                anchors.fill: parent
                radius: root.imageRadius
                color: surfaceCard
                clip: true
                border.width: root.highlighted ? 1.5 : 0
                border.color: root.highlighted ? recordRed : "transparent"
                scale: root.highlighted ? 1.03 : 1.0

                Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Cover {
                    anchors.fill: parent
                    track: root.track
                    radius: root.imageRadius
                }

                Rectangle {
                    anchors.fill: parent
                    radius: root.imageRadius
                    color: "transparent"
                    border.width: 1
                    border.color: "#15FFFFFF"
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
    }

    MouseArea {
        id: albumCardMouse
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
                if (typeof window !== "undefined" && window.openCoverSearch) {
                    window.openCoverSearch(root.name, root.artist, root.track ? root.track.filePath : "")
                }
            } else {
                root.clicked()
            }
        }
    }
}
