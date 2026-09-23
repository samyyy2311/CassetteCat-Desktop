import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var options: []
    property var selectedValue: ""
    signal optionSelected(var value)

    readonly property color accentColor: (typeof recordRed !== "undefined" ? recordRed : "#C23B30")
    readonly property color accentHoverColor: (typeof recordRedHover !== "undefined" ? recordRedHover : "#D64337")

    implicitHeight: 32
    implicitWidth: rowLayout.implicitWidth + 8
    radius: height / 2
    color: (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917")
    border.width: 1
    border.color: (typeof borderSubtle !== "undefined" ? borderSubtle : "#22201D")

    activeFocusOnTab: true
    Accessible.role: Accessible.PageTabList

    function selectDelta(delta) {
        if (!options || options.length === 0) return
        let currentIndex = -1
        for (let i = 0; i < options.length; ++i) {
            const opt = options[i]
            const val = (opt && typeof opt === "object" && "value" in opt) ? opt.value : opt
            if (root.selectedValue !== undefined && (root.selectedValue === val || String(root.selectedValue).toLowerCase() === String(val).toLowerCase())) {
                currentIndex = i
                break
            }
        }
        let nextIndex = currentIndex + delta
        if (nextIndex < 0) nextIndex = options.length - 1
        else if (nextIndex >= options.length) nextIndex = 0
        const nextOpt = options[nextIndex]
        const nextVal = (nextOpt && typeof nextOpt === "object" && "value" in nextOpt) ? nextOpt.value : nextOpt
        root.optionSelected(nextVal)
    }

    Keys.onLeftPressed: event => {
        event.accepted = true
        selectDelta(-1)
    }
    Keys.onRightPressed: event => {
        event.accepted = true
        selectDelta(1)
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: segItem
                readonly property var optVal: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                readonly property string optLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                readonly property bool isSelected: root.selectedValue !== undefined && (root.selectedValue === optVal || String(root.selectedValue).toLowerCase() === String(optVal).toLowerCase())

                height: 26
                width: segLabel.implicitWidth + 16
                radius: height / 2
                color: isSelected
                    ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#262320")
                    : (segMouse.containsMouse ? (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#22201D") : "transparent")
                border.width: isSelected ? 1 : 0
                border.color: root.accentColor
                scale: segMouse.pressed ? 0.97 : 1.0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                Label {
                    id: segLabel
                    anchors.centerIn: parent
                    text: segItem.optLabel
                    color: segItem.isSelected
                        ? root.accentHoverColor
                        : (segMouse.containsMouse ? textPrimary : textSecondary)
                    font.family: (typeof monoFont !== "undefined" ? monoFont : "IBM Plex Mono")
                    font.pixelSize: 11
                    font.weight: segItem.isSelected ? Font.Bold : Font.Medium
                    font.letterSpacing: 0.3

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.forceActiveFocus()
                        root.optionSelected(segItem.optVal)
                    }
                }
            }
        }
    }
}
