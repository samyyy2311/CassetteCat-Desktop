import QtQuick

Item {
    id: root
    property string text: ""
    property bool visibleTarget: false
    property bool below: false
    property int delay: 250

    readonly property bool isAutoBelow: {
        if (below) return true
        if (!parent) return false
        try {
            const pos = parent.mapToItem(null, 0, 0)
            return pos ? (pos.y < 60) : false
        } catch (e) {
            return false
        }
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: isAutoBelow ? parent.bottom : undefined
    anchors.topMargin: isAutoBelow ? 8 : 0
    anchors.bottom: isAutoBelow ? undefined : parent.top
    anchors.bottomMargin: isAutoBelow ? 0 : 8
    z: 9999

    width: pill.width
    height: pill.height

    property bool shouldShow: false

    Timer {
        id: delayTimer
        interval: root.delay
        running: root.visibleTarget && root.text.length > 0
        onTriggered: root.shouldShow = true
    }

    onVisibleTargetChanged: {
        if (!visibleTarget) {
            delayTimer.stop()
            root.shouldShow = false
        }
    }

    opacity: root.shouldShow && root.visibleTarget ? 1.0 : 0.0
    scale: root.shouldShow && root.visibleTarget ? 1.0 : 0.94
    transformOrigin: isAutoBelow ? Item.Top : Item.Bottom
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: 130; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: pill
        width: Math.max(36, label.implicitWidth + 20)
        height: 28
        radius: 8
        color: "#22201D"
        border.width: 1
        border.color: "#45FFFFFF"

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            font.family: "Space Grotesk"
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: "#FFFFFF"
        }
    }
}
