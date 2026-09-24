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

        Rectangle {
            id: coverBox
            Layout.preferredWidth: root.cardWidth
            Layout.preferredHeight: root.cardWidth
            radius: root.coverRadius
            clip: true
            color: surfaceCard
            border.width: 1
            border.color: root.highlighted ? borderVariant : borderSubtle
            scale: root.highlighted ? 1.03 : 1.0

            Behavior on scale {
                NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
            }

            Cover {
                anchors.fill: parent
                track: root.track
                radius: root.coverRadius
            }

            TransportButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 8
                buttonSize: 38
                activeFocusOnTab: false
                iconName: "play"
                accented: true
                iconColor: recordRed
                opacity: root.highlighted ? 1.0 : 0.0
                scale: root.highlighted ? 1.0 : 0.6
                z: 10

                Behavior on opacity { NumberAnimation { duration: UiConstants.durationStd } }
                Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingBounce } }

                onClicked: root.clicked()
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.track.title || root.track.fileName
            color: textPrimary
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
