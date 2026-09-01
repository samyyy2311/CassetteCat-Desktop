import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property int position: 0
    property int duration: 0
    property bool showRemainingTime: true
    signal seekRequested(int positionMs)

    implicitWidth: 400
    implicitHeight: 28

    readonly property color recordRed: "#C23B30"
    readonly property color recordRedHover: "#D14337"
    readonly property color surfaceElevated: "#2A2825"
    readonly property color surfaceTooltip: "#1A1816"
    readonly property color borderSubtle: "#2E2B28"
    readonly property color silver: "#C4C4C0"
    readonly property color silverDim: "#6E6C68"
    readonly property color textPrimary: "#F5F0EC"
    readonly property string monoFont: "IBM Plex Mono"

    property bool isDragging: false
    property int dragPositionMs: 0

    function formatTime(ms) {
        if (!ms || ms <= 0) return "0:00"
        const totalSec = Math.floor(ms / 1000)
        const m = Math.floor(totalSec / 60)
        const s = totalSec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    function formatRemaining(pos, dur) {
        if (!dur || dur <= 0) return "-0:00"
        if (pos > dur) return "-0:00"
        const remMs = dur - pos
        return "-" + formatTime(remMs)
    }

    readonly property int currentPosMs: isDragging ? dragPositionMs : root.position
    readonly property real progressFraction: (root.duration > 0) ? Math.min(1.0, Math.max(0.0, currentPosMs / root.duration)) : 0.0

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Label {
            Layout.preferredWidth: 42
            Layout.alignment: Qt.AlignVCenter
            text: root.formatTime(root.currentPosMs)
            color: (trackMouse.containsMouse || root.isDragging) ? root.textPrimary : root.silverDim
            font.family: root.monoFont
            font.pixelSize: 11
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignLeft
        }

        Item {
            id: trackContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: groove
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: (trackMouse.containsMouse || root.isDragging) ? 5 : 3
                radius: height / 2
                color: root.surfaceElevated
                border.width: 1
                border.color: root.borderSubtle

                Behavior on height {
                    NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }

                Rectangle {
                    id: fillTrack
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round(groove.width * root.progressFraction)
                    radius: height / 2
                    color: root.recordRed
                }

                Rectangle {
                    id: thumb
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(groove.width - width, Math.round(groove.width * root.progressFraction) - width / 2))
                    width: (trackMouse.containsMouse || root.isDragging) ? 10 : 0
                    height: (trackMouse.containsMouse || root.isDragging) ? 18 : 0
                    radius: 5
                    color: "#FFFFFF"
                    border.width: 1.5
                    border.color: root.recordRed
                    opacity: (trackMouse.containsMouse || root.isDragging) ? 1.0 : 0.0

                    Behavior on opacity { NumberAnimation { duration: 100 } }
                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                    Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }
                }
            }

            Rectangle {
                id: hoverTooltip
                visible: trackMouse.containsMouse && !root.isDragging && root.duration > 0
                y: -26
                x: Math.max(0, Math.min(trackContainer.width - width, trackMouse.mouseX - width / 2))
                width: hoverText.implicitWidth + 12
                height: 20
                radius: 5
                color: root.surfaceTooltip
                border.width: 1
                border.color: root.recordRed

                Label {
                    id: hoverText
                    anchors.centerIn: parent
                    text: root.formatTime(Math.floor((trackMouse.mouseX / Math.max(1, trackContainer.width)) * root.duration))
                    color: root.textPrimary
                    font.family: root.monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            MouseArea {
                id: trackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateDrag(mouseX) {
                    if (root.duration > 0) {
                        const fraction = Math.max(0.0, Math.min(1.0, mouseX / trackContainer.width))
                        root.dragPositionMs = Math.floor(fraction * root.duration)
                    }
                }

                onPressed: mouse => {
                    root.isDragging = true
                    updateDrag(mouse.x)
                }

                onPositionChanged: mouse => {
                    if (root.isDragging) {
                        updateDrag(mouse.x)
                    }
                }

                onReleased: mouse => {
                    if (root.isDragging) {
                        updateDrag(mouse.x)
                        root.isDragging = false
                        root.seekRequested(root.dragPositionMs)
                    }
                }

                onCanceled: {
                    root.isDragging = false
                }

                onWheel: wheel => {
                    if (root.duration > 0) {
                        const step = wheel.angleDelta.y > 0 ? 5000 : -5000
                        const target = Math.max(0, Math.min(root.duration, root.position + step))
                        root.seekRequested(target)
                    }
                }
            }
        }

        Label {
            Layout.preferredWidth: 46
            Layout.alignment: Qt.AlignVCenter
            text: root.showRemainingTime
                ? root.formatRemaining(root.currentPosMs, root.duration)
                : root.formatTime(root.duration)
            color: (trackMouse.containsMouse || root.isDragging || timeMouse.containsMouse) ? root.textPrimary : root.silverDim
            font.family: root.monoFont
            font.pixelSize: 11
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignRight

            MouseArea {
                id: timeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.showRemainingTime = !root.showRemainingTime
                }
            }
        }
    }
}
