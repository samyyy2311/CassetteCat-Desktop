import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string icon: ""
    property color color: textPrimary
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
        // With QSG_TRANSIENT_IMAGES a cached icon keeps no pixels once the main window has uploaded it, so the
        // same icon in another window, such as the mini player, would draw blank. Those load their own copy.
        cache: !Window.window || Window.window === window
        smooth: true
        visible: true
        opacity: root.preserveColor ? 1 : 0
    }

    MultiEffect {
        anchors.fill: iconImg
        source: iconImg
        colorization: 1.0
        colorizationColor: root.color
        visible: !root.preserveColor
    }
}
