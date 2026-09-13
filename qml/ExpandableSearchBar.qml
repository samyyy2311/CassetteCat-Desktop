import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property alias text: inputField.text
    property alias input: inputField
    property alias searchInput: inputField
    property string placeholder: "Search..."
    property bool expanded: false
    property int boxSize: 34
    property int iconSize: 16
    property int expandedWidth: 200
    property color activeColor: recordRed
    property color placeholderColor: silverDim
    property color textColor: textPrimary

    signal submitted()
    signal cleared()

    implicitWidth: expanded ? expandedWidth : boxSize
    implicitHeight: boxSize
    Layout.minimumWidth: boxSize
    Layout.preferredWidth: expanded ? expandedWidth : boxSize
    Layout.maximumWidth: expandedWidth
    Layout.preferredHeight: boxSize
    clip: true

    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on implicitWidth {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: height / 2
        color: (root.expanded && inputField.activeFocus) ? surfaceCard : (collapsedMouseArea.containsMouse ? surfaceElevated : surfaceCard)
        border.width: (root.expanded && inputField.activeFocus) ? 1.5 : 1.0
        border.color: (root.expanded && inputField.activeFocus) ? root.activeColor : (collapsedMouseArea.containsMouse ? borderVariant : borderSubtle)

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on border.width { NumberAnimation { duration: 100 } }
    }

    Item {
        id: iconItem
        width: root.iconSize
        height: root.iconSize
        anchors.verticalCenter: parent.verticalCenter
        x: Math.round((root.boxSize - root.iconSize) / 2)

        LucideIcon {
            anchors.fill: parent
            icon: "search"
            color: (root.expanded && inputField.activeFocus) ? root.activeColor : (collapsedMouseArea.containsMouse ? "#FFFFFF" : root.textColor)
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        MouseArea {
            id: searchIconMouseArea
            anchors.fill: parent
            anchors.margins: -4
            visible: root.expanded
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.collapse()
        }

        AppToolTip {
            targetItem: searchIconMouseArea
            text: "Close search"
            visibleTarget: searchIconMouseArea.containsMouse
        }
    }

    RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.boxSize
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        visible: root.width > root.boxSize + 15
        opacity: root.expanded ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 120 } }

        TextInput {
            id: inputField
            Layout.fillWidth: true
            color: root.textColor
            font.family: displayFont
            font.pixelSize: 12
            selectByMouse: true
            clip: true
            Accessible.name: root.placeholder

            Text {
                anchors.fill: parent
                visible: !inputField.text && !inputField.activeFocus
                text: root.placeholder
                color: root.placeholderColor
                font: inputField.font
                elide: Text.ElideRight
            }

            Keys.onEscapePressed: root.collapse()
            Keys.onReturnPressed: {
                root.submitted()
                inputField.focus = false
            }
            onActiveFocusChanged: {
                if (!activeFocus && !text.length) {
                    root.collapse()
                }
            }
        }

        PressDepthIconButton {
            boxSize: 22
            iconSize: 12
            iconName: "x"
            tint: root.placeholderColor
            tooltipText: inputField.text.length > 0 ? "Clear search" : "Close search"
            Accessible.name: tooltipText
            onClicked: root.collapse()
        }
    }

    MouseArea {
        id: collapsedMouseArea
        anchors.fill: parent
        visible: !root.expanded
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expand()
    }

    AppToolTip {
        targetItem: collapsedMouseArea
        text: root.placeholder
        visibleTarget: collapsedMouseArea.containsMouse
    }

    function expand() {
        root.expanded = true
        Qt.callLater(inputField.forceActiveFocus)
    }

    function collapse() {
        if (inputField.text.length > 0) {
            inputField.clear()
            root.cleared()
        }
        inputField.focus = false
        root.expanded = false
    }

    function clear() {
        inputField.clear()
        root.cleared()
    }

    function toggle() {
        if (root.expanded) {
            collapse()
        } else {
            expand()
        }
    }
}
