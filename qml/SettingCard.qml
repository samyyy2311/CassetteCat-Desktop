import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: inner.data

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 12
    radius: 16
    color: (typeof surfaceCard !== "undefined" ? surfaceCard : "#141312")
    border.width: 1
    border.color: (typeof borderVariant !== "undefined" ? borderVariant : "#2A2825")

    Behavior on border.color { ColorAnimation { duration: 120 } }

    ColumnLayout {
        id: inner
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 6
        anchors.bottomMargin: 6
        spacing: 0
    }
}
