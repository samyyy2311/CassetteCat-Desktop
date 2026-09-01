import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property real volume: 1.0
    signal volumeAdjusted(real newVolume)

    implicitWidth: 160
    implicitHeight: 30

    readonly property color recordRed: "#C23B30"
    readonly property color recordRedHover: "#D14337"
    readonly property color surfaceElevated: "#2A2825"
    readonly property color surfaceTooltip: "#1A1816"
    readonly property color borderVariant: "#2E2B28"
    readonly property color silver: "#C4C4C0"
    readonly property color silverDim: "#6E6C68"
    readonly property color textPrimary: "#F5F0EC"
    readonly property color textSecondary: "#A8A29A"
    readonly property string monoFont: "IBM Plex Mono"

    property real lastNonZeroVolume: 0.8
    property bool isDragging: false

    function toggleMute() {
        if (root.volume > 0.001) {
            root.lastNonZeroVolume = root.volume
            root.volumeAdjusted(0.0)
        } else {
            root.volumeAdjusted(root.lastNonZeroVolume > 0.05 ? root.lastNonZeroVolume : 0.8)
        }
    }

    function iconForVolume(v) {
        if (v <= 0.001) return "volume-x"
        if (v < 0.5) return "volume-1"
        return "volume-2"
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            LucideIcon {
                anchors.centerIn: parent
                width: 16
                height: 16
                icon: root.iconForVolume(root.volume)
                color: iconMouse.containsMouse
                    ? root.recordRedHover
                    : (root.volume <= 0.001 ? root.recordRed : (volTrackMouse.containsMouse ? root.textPrimary : root.silverDim))
            }

            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleMute()
            }
        }

        Item {
            id: sliderContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 22

            Rectangle {
                id: trackGroove
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: (volTrackMouse.containsMouse || root.isDragging) ? 5 : 3
                radius: height / 2
                color: root.surfaceElevated
                border.width: 1
                border.color: root.borderVariant

                Behavior on height {
                    NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.round(trackGroove.width * Math.min(1.0, Math.max(0.0, root.volume)))
                    radius: height / 2
                    color: root.recordRed
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(trackGroove.width - width, Math.round(trackGroove.width * Math.min(1.0, Math.max(0.0, root.volume))) - width / 2))
                    width: (volTrackMouse.containsMouse || root.isDragging) ? 10 : 7
                    height: (volTrackMouse.containsMouse || root.isDragging) ? 16 : 11
                    radius: 4
                    color: "#FFFFFF"
                    border.width: 1.5
                    border.color: root.recordRed

                    Behavior on width {
                        NumberAnimation { duration: 80 }
                    }
                    Behavior on height {
                        NumberAnimation { duration: 80 }
                    }
                }
            }

            Rectangle {
                id: volTooltip
                visible: volTrackMouse.containsMouse && sliderContainer.width > 0
                y: -24
                x: Math.max(0, Math.min(sliderContainer.width - width, volTrackMouse.mouseX - width / 2))
                width: volTooltipText.implicitWidth + 10
                height: 18
                radius: 4
                color: root.surfaceTooltip
                border.width: 1
                border.color: root.recordRed

                Label {
                    id: volTooltipText
                    anchors.centerIn: parent
                    text: Math.round(Math.max(0.0, Math.min(1.0, volTrackMouse.mouseX / Math.max(1, sliderContainer.width))) * 100) + "%"
                    color: root.textPrimary
                    font.family: root.monoFont
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }

            MouseArea {
                id: volTrackMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function applyVolume(mouseX) {
                    const fraction = Math.max(0.0, Math.min(1.0, mouseX / sliderContainer.width))
                    root.volumeAdjusted(fraction)
                }

                onPressed: mouse => {
                    root.isDragging = true
                    applyVolume(mouse.x)
                }

                onPositionChanged: mouse => {
                    if (root.isDragging) {
                        applyVolume(mouse.x)
                    }
                }

                onReleased: {
                    root.isDragging = false
                }

                onCanceled: {
                    root.isDragging = false
                }

                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                    const newVol = Math.max(0.0, Math.min(1.0, root.volume + step))
                    root.volumeAdjusted(newVol)
                }
            }
        }

        Label {
            id: pctLabel
            Layout.preferredWidth: 34
            text: Math.round(root.volume * 100) + "%"
            color: (volTrackMouse.containsMouse || root.isDragging || pctMouse.containsMouse) ? root.textPrimary : root.silverDim
            font.family: root.monoFont
            font.pixelSize: 11
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignRight

            MouseArea {
                id: pctMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.volume >= 0.99) root.volumeAdjusted(0.75)
                    else if (root.volume >= 0.74) root.volumeAdjusted(0.50)
                    else if (root.volume >= 0.49) root.volumeAdjusted(0.25)
                    else if (root.volume >= 0.24) root.volumeAdjusted(0.0)
                    else root.volumeAdjusted(1.0)
                }
                onDoubleClicked: {
                    root.volumeAdjusted(1.0)
                }
            }
        }
    }
}
