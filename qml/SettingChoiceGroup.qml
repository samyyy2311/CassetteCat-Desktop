import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

SettingRow {
    id: root
    property var options: []
    property var selectedValue: ""
    property bool forceMenu: false
    readonly property bool useMenu: forceMenu || options.length > 3
    signal optionSelected(var value)

    Item {
        implicitWidth: root.useMenu ? menuButton.implicitWidth : segmentedControl.implicitWidth
        implicitHeight: root.useMenu ? menuButton.implicitHeight : segmentedControl.implicitHeight

        SettingSegmentedControl {
            id: segmentedControl
            visible: !root.useMenu
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            options: root.options
            selectedValue: root.selectedValue
            onOptionSelected: value => root.optionSelected(value)
        }

        SettingButton {
            id: menuButton
            visible: root.useMenu
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (!root.options || root.options.length === 0) return "Choose"
                for (let i = 0; i < root.options.length; ++i) {
                    const option = root.options[i]
                    const value = (option && typeof option === "object" && "value" in option) ? option.value : option
                    if (root.selectedValue === value || (root.selectedValue !== undefined && value !== undefined && String(root.selectedValue).toLowerCase() === String(value).toLowerCase()))
                        return (option && typeof option === "object" && "label" in option) ? option.label : String(option)
                }
                return "Choose"
            }
            iconName: choicePopup.visible ? "chevron-up" : "chevron-down"
            iconRight: true
            onClicked: {
                if (choicePopup.visible) {
                    choicePopup.close()
                } else {
                    choicePopup.open()
                }
            }
        }

        Popup {
            id: choicePopup
            parent: Overlay.overlay
            x: {
                if (!menuButton) return 0
                const pt = menuButton.mapToItem(Overlay.overlay, 0, 0)
                const ovW = Overlay.overlay ? Overlay.overlay.width : 800
                return Math.max(10, Math.min(ovW - width - 10, pt.x + menuButton.width - width))
            }
            y: {
                if (!menuButton) return 0
                const pt = menuButton.mapToItem(Overlay.overlay, 0, 0)
                const ovH = Overlay.overlay ? Overlay.overlay.height : 600
                if (pt.y + menuButton.height + height + 10 > ovH) {
                    return Math.max(10, pt.y - height - 4)
                }
                return pt.y + menuButton.height + 4
            }
            width: Math.max(menuButton ? menuButton.width : 160, 220)
            implicitHeight: Math.min(260, Math.max(48, (root.options ? root.options.length * 38 : 0) + 12))
            padding: 6
            modal: false
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            onOpened: {
                let selIdx = 0
                if (root.options) {
                    for (let i = 0; i < root.options.length; ++i) {
                        const opt = root.options[i]
                        const val = (opt && typeof opt === "object" && "value" in opt) ? opt.value : opt
                        if (root.selectedValue === val || (root.selectedValue !== undefined && val !== undefined && String(root.selectedValue).toLowerCase() === String(val).toLowerCase())) {
                            selIdx = i
                            break
                        }
                    }
                }
                optionList.currentIndex = selIdx
                optionList.positionViewAtIndex(selIdx, ListView.Contain)
                optionList.forceActiveFocus()
            }

            background: Rectangle {
                color: (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#1C1B18")
                radius: 10
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)
            }

            contentItem: ListView {
                id: optionList
                implicitHeight: contentHeight
                clip: true
                model: root.options
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                focus: true
                keyNavigationWraps: true

                Keys.onReturnPressed: event => activateCurrent(event)
                Keys.onEnterPressed: event => activateCurrent(event)
                Keys.onSpacePressed: event => activateCurrent(event)

                function activateCurrent(event) {
                    if (currentIndex >= 0 && currentIndex < count) {
                        const item = model[currentIndex]
                        const val = (item && typeof item === "object" && "value" in item) ? item.value : item
                        root.optionSelected(val)
                        choicePopup.close()
                        event.accepted = true
                    }
                }

                ScrollBar.vertical: SleekScrollBar {
                    visible: optionList.contentHeight > optionList.height
                }

                delegate: Rectangle {
                    id: optItem
                    readonly property var optionValue: (modelData && typeof modelData === "object" && "value" in modelData) ? modelData.value : modelData
                    readonly property string optionLabel: (modelData && typeof modelData === "object" && "label" in modelData) ? modelData.label : String(modelData)
                    readonly property bool isSelected: root.selectedValue !== undefined && optionValue !== undefined && (root.selectedValue === optionValue || String(root.selectedValue).toLowerCase() === String(optionValue).toLowerCase())
                    readonly property bool isCurrent: ListView.isCurrentItem

                    width: optionList.width
                    height: 36
                    radius: 7
                    color: isSelected
                        ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#282623")
                        : (optMouse.containsMouse || (optItem.isCurrent && optionList.activeFocus) ? (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#282623") : "transparent")
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: optItem.optionLabel
                            color: optItem.isSelected
                                ? textPrimary
                                : (optMouse.containsMouse || (optItem.isCurrent && optionList.activeFocus) ? textPrimary : textSecondary)
                            font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
                            font.pixelSize: 12
                            font.weight: optItem.isSelected ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        LucideIcon {
                            visible: optItem.isSelected
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            icon: "check"
                            color: root.accentColor
                        }
                    }

                    MouseArea {
                        id: optMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            optionList.currentIndex = index
                            root.optionSelected(optItem.optionValue)
                            choicePopup.close()
                        }
                    }
                }
            }
        }
    }
}
