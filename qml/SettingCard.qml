import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    default property alias content: inner.data

    Layout.fillWidth: true
    implicitHeight: inner.implicitHeight + 12
    radius: 14
    clip: true
    color: (typeof surfaceCard !== "undefined" ? surfaceCard : "#161514")
    border.width: 0
    border.color: "transparent"

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
