import QtQuick
import QtQuick.Controls

Rectangle {
    property alias text: countLabel.text

    implicitWidth: countLabel.implicitWidth + 14
    implicitHeight: 22
    radius: height / 2
    color: surfaceTag
    border.width: 1
    border.color: borderSubtle

    Label {
        id: countLabel
        anchors.centerIn: parent
        color: silverDim
        font.family: monoFont
        font.pixelSize: 10
        font.weight: Font.DemiBold
    }
}
