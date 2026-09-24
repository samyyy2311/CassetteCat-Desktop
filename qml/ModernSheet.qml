import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property bool isOpen: false
    property int maxWidth: 540
    property int maxHeight: Math.min(parent ? parent.height - 30 : 600, 680)
    property var appWindow: (typeof window !== "undefined") ? window : null
    property color sheetColor: root.appWindow ? root.appWindow.surfaceCard : "#181715"
    property color sheetBorderColor: root.appWindow ? root.appWindow.borderVariant : Qt.rgba(1, 1, 1, 0.09)

    signal closed()

    function open() {
        isOpen = true
    }

    function close() {
        if (!isOpen) return
        isOpen = false
        closed()
    }

    onClosed: {
        isOpen = false
    }

    default property alias sheetContent: contentColumn.data

    anchors.fill: parent
    visible: isOpen || opacity > 0.005
    enabled: isOpen
    opacity: isOpen ? 1.0 : 0.0
    z: 9999

    Behavior on opacity {
        NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
    }

    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "#90000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: sheetContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 32, root.maxWidth)
        height: Math.min(root.maxHeight, mainLayout.implicitHeight + 40)
        radius: 24
        color: root.sheetColor
        border.width: 1
        border.color: root.sheetBorderColor
        clip: true

        transform: Translate {
            y: root.isOpen ? 0 : (sheetContainer.height + 60)
            Behavior on y { NumberAnimation { duration: UiConstants.durationEmphasis; easing.type: UiConstants.easingStd } }
        }

        MouseArea {
            anchors.fill: parent
            // Prevent clicks inside sheet from closing the modal
        }

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 20
            anchors.bottomMargin: 24
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 36
                Layout.preferredHeight: 4
                radius: 2
                color: "#40FFFFFF"
            }

            ColumnLayout {
                id: contentColumn
                Layout.fillWidth: true
                spacing: 12
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.isOpen
        onActivated: root.close()
    }
}
