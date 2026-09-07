import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string text: ""
    property string iconName: ""
    property bool primary: false
    property bool destructive: false
    signal clicked()

    implicitWidth: contentRow.implicitWidth + 24
    implicitHeight: 32
    radius: 16
    color: {
        if (mouseArea.containsMouse) {
            if (root.destructive) return "#25FF3344"
            if (root.primary) return recordRedHover
            return "#2A2825"
        }
        if (root.primary) return recordRed
        return "#1E1C1A"
    }
    border.width: 1
    border.color: {
        if (root.destructive) return mouseArea.containsMouse ? "#FF4455" : "#66FF4455"
        if (root.primary) return recordRedHover
        return mouseArea.containsMouse ? silverDim : borderVariant
    }

    scale: mouseArea.pressed ? 0.96 : 1.0

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
    Behavior on scale { NumberAnimation { duration: 80 } }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        LucideIcon {
            visible: root.iconName.length > 0
            Layout.preferredWidth: 14
            Layout.preferredHeight: 14
            Layout.alignment: Qt.AlignVCenter
            icon: root.iconName
            color: root.destructive ? "#FF6677" : (root.primary ? "#FFFFFF" : textPrimary)
        }

        Label {
            text: root.text
            color: root.destructive ? "#FF6677" : (root.primary ? "#FFFFFF" : textPrimary)
            font.family: displayFont
            font.pixelSize: 11
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
