import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string icon: ""
    property color color: "#F5F0EC"
    property bool preserveColor: false

    implicitWidth: 20
    implicitHeight: 20

    Image {
        id: iconImg
        anchors.fill: parent
        source: root.icon ? "qrc:/qt/qml/CassetteCat/qml/icons/" + root.icon + ".svg" : ""
        sourceSize.width: Math.max(1, root.width * 2)
        sourceSize.height: Math.max(1, root.height * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: root.preserveColor
    }

    MultiEffect {
        anchors.fill: iconImg
        source: iconImg
        colorization: 1.0
        colorizationColor: root.color
        visible: !root.preserveColor
    }
}
