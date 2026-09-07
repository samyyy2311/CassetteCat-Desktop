import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    property string currentColor: "#C23B30"
    signal colorApplied(string hexColor)

    function normalizeHex(h) {
        let val = String(h || "").trim()
        if (!val.startsWith("#")) val = "#" + val
        return val
    }

    function isValidHex(h) {
        return /^#[0-9A-Fa-f]{6}$/.test(normalizeHex(h))
    }

    modal: true
    focus: true
    width: 380
    padding: 22
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#B3000000"
    }

    background: Rectangle {
        radius: 16
        color: surfaceCard
        border.width: 1
        border.color: borderVariant
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Label {
            text: "Custom Accent Colour"
            color: textPrimary
            font.family: displayFont
            font.pixelSize: 17
            font.weight: Font.Bold
        }

        Label {
            text: "Pick a color swatch or enter a hex code"
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: root.isValidHex(hexInput.text) ? root.normalizeHex(hexInput.text) : root.currentColor
                border.width: 2
                border.color: textPrimary
            }

            RefineTextInput {
                id: hexInput
                Layout.fillWidth: true
                placeholder: "#C23B30"
                text: root.currentColor
            }
        }

        Label {
            text: "PRESET PALETTE"
            color: silverDim
            font.family: monoFont
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.8
            Layout.topMargin: 4
        }

        Flow {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: [
                    "#8B5CF6", "#6366F1", "#3B82F6", "#06B6D4",
                    "#10B981", "#84CC16", "#EAB308", "#F97316",
                    "#EF4444", "#EC4899", "#D946EF", "#14B8A6"
                ]
                delegate: Rectangle {
                    width: 30
                    height: 30
                    radius: 15
                    color: modelData
                    border.width: root.normalizeHex(hexInput.text).toLowerCase() === modelData.toLowerCase() ? 2.5 : 1
                    border.color: root.normalizeHex(hexInput.text).toLowerCase() === modelData.toLowerCase() ? textPrimary : borderSubtle

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: hexInput.text = modelData
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 10

            Item { Layout.fillWidth: true }

            SettingButton {
                text: "Cancel"
                onClicked: root.close()
            }

            SettingButton {
                text: "Apply"
                primary: true
                onClicked: {
                    const hex = root.normalizeHex(hexInput.text)
                    if (root.isValidHex(hex)) {
                        root.currentColor = hex
                        root.colorApplied(hex)
                        root.close()
                    }
                }
            }
        }
    }
}
