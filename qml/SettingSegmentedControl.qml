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
    radius: 8
    color: (typeof surfaceInput !== "undefined" ? surfaceInput : "#1A1917")
    border.width: 0
    border.color: "transparent"

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

                height: 24
                width: segLabel.implicitWidth + 20
                radius: 6
                color: isSelected
                    ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#2E2B27")
                    : (segMouse.containsMouse ? (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#22201D") : "transparent")
                border.width: 0
                border.color: "transparent"
                scale: segMouse.pressed ? 0.97 : 1.0

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 80 } }

                Label {
                    id: segLabel
                    anchors.centerIn: parent
                    text: segItem.optLabel
                    color: segItem.isSelected
                        ? textPrimary
                        : (segMouse.containsMouse ? textPrimary : textSecondary)
                    font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
                    font.pixelSize: 11
                    font.weight: segItem.isSelected ? Font.DemiBold : Font.Normal

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
