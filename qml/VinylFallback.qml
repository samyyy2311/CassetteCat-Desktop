import QtQuick

Item {
    id: root

    property color accent: "#D14337"
    property bool playing: false
    readonly property real discSize: Math.max(18, Math.min(width, height) * 0.76)

    Item {
        id: record
        anchors.centerIn: parent
        width: root.discSize
        height: width

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#080807"
            border.width: Math.max(1, width * 0.018)
            border.color: "#4A4742"
        }

        Repeater {
            model: 5

            delegate: Rectangle {
                anchors.centerIn: parent
                width: parent.width * (0.86 - index * 0.12)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: Math.max(1, parent.width * 0.008)
                border.color: index % 2 ? "#211F1C" : "#302D29"
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.34
            height: width
            radius: width / 2
            color: "#2D2A26"
            border.width: Math.max(1, parent.width * 0.012)
            border.color: "#5A554D"

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.68
                height: width
                radius: width / 2
                color: root.accent
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.max(2, parent.width * 0.16)
                height: width
                radius: width / 2
                color: "#EEE8E0"
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.13
            width: Math.max(1, parent.width * 0.08)
            height: width
            radius: width / 2
            color: "#B8B0A6"
            opacity: 0.55
        }

        RotationAnimation on rotation {
            running: root.playing
            from: 0
            to: 360
            duration: 3000
            loops: Animation.Infinite
        }
    }

    Item {
        visible: root.discSize >= 72
        anchors.fill: parent
        transformOrigin: Item.TopRight
        rotation: root.playing ? -5 : -27

        Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
            x: parent.width * 0.77
            y: parent.height * 0.08
            width: Math.max(8, parent.width * 0.12)
            height: width
            radius: width / 2
            color: "#161514"
            border.width: 1
            border.color: "#787168"
        }

        Rectangle {
            x: parent.width * 0.70
            y: parent.height * 0.16
            width: Math.max(2, parent.width * 0.026)
            height: parent.height * 0.46
            radius: width / 2
            color: "#C1B9AF"
            rotation: 24
            transformOrigin: Item.Top
        }

        Rectangle {
            x: parent.width * 0.52
            y: parent.height * 0.53
            width: Math.max(7, parent.width * 0.11)
            height: Math.max(5, parent.height * 0.055)
            radius: height / 2
            color: "#D8D0C6"
            rotation: 24
        }
    }
}
