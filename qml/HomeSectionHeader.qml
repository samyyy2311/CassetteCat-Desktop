import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property string title: ""
    property string subtitle: ""

    signal playClicked()
    signal shuffleClicked()

    width: parent.width
    height: Math.max(38, headerColumn.implicitHeight)

    ColumnLayout {
        id: headerColumn
        anchors.left: parent.left
        anchors.right: buttonRow.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Label {
            Layout.fillWidth: true
            text: root.title
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 20
            font.weight: Font.Bold
            font.letterSpacing: -0.2
        }

        Label {
            Layout.fillWidth: true
            text: root.subtitle
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
        }
    }

    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        TransportButton {
            buttonSize: 36
            iconName: "play"
            accented: true
            iconColor: recordRed
            onClicked: root.playClicked()
        }

        TransportButton {
            buttonSize: 36
            iconName: "shuffle"
            iconColor: textPrimary
            onClicked: root.shuffleClicked()
        }
    }
}
