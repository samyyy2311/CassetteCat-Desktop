import QtQuick

Item {
    id: root
    property var targetView

    property bool active: false
    property point originPoint: Qt.point(0, 0)
    property point currentPoint: Qt.point(0, 0)

    anchors.fill: parent
    z: 9999
    visible: active

    Timer {
        id: scrollTimer
        interval: 16
        running: root.active
        repeat: true
        onTriggered: {
            if (!root.targetView) return
            const flick = root.targetView.contentY !== undefined
                ? root.targetView
                : root.targetView.contentItem
            if (!flick || flick.contentY === undefined) return
            const dy = root.currentPoint.y - root.originPoint.y
            const deadZone = 12
            if (Math.abs(dy) > deadZone) {
                const speed = (dy - (dy > 0 ? deadZone : -deadZone)) * 0.16
                const maxScroll = Math.max(0, flick.contentHeight - flick.height)
                flick.contentY = Math.max(0, Math.min(maxScroll, flick.contentY + speed))
            }
        }
    }

    Rectangle {
        x: root.originPoint.x - width / 2
        y: root.originPoint.y - height / 2
        width: 32
        height: 32
        radius: 16
        color: "#E0181715"
        border.width: 1.5
        border.color: "#C23B30"

        LucideIcon {
            anchors.centerIn: parent
            width: 16
            height: 16
            icon: "arrow-up-down"
            color: "#FFFFFF"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: {
            const dy = root.currentPoint.y - root.originPoint.y
            if (Math.abs(dy) <= 12) return Qt.SizeAllCursor
            return dy > 0 ? Qt.SizeVerCursor : Qt.SizeVerCursor
        }
        onPositionChanged: mouse => {
            root.currentPoint = Qt.point(mouse.x, mouse.y)
        }
        onClicked: root.stop()
    }

    function start(startX, startY) {
        originPoint = Qt.point(startX, startY)
        currentPoint = Qt.point(startX, startY)
        active = true
    }

    function stop() {
        active = false
    }
}
