import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string accentName: "recordRed"
    property string customAccentColor: "#C23B30"
    property int albumArtRadius: 16
    property string nowPlayingBackdrop: "tinted"
    property bool showRemainingTime: true

    signal accentSelected(string value)
    signal customAccentSelected(string hexColor)
    signal albumArtRadiusSelected(int value)
    signal nowPlayingBackdropSelected(string value)
    signal showRemainingTimeSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Color Scheme" }

    SettingCard {
        SettingRow {
            iconName: "sliders-horizontal"
            title: "Accent Colour"
            subtitle: "Main highlight color used across the interface"
        }

        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            spacing: 14

            Repeater {
                model: [
                    { id: "recordRed", color: "#C23B30", label: "Red" },
                    { id: "amber", color: "#F59E0B", label: "Amber" },
                    { id: "cyan", color: "#06B6D4", label: "Cyan" },
                    { id: "emerald", color: "#10B981", label: "Green" },
                    { id: "magenta", color: "#EC4899", label: "Pink" },
                    { id: "silver", color: "#C4C4C0", label: "Mono" }
                ]
                delegate: Column {
                    spacing: 6

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 18
                        color: modelData.color
                        border.width: root.accentName === modelData.id ? 2.5 : 1
                        border.color: root.accentName === modelData.id ? textPrimary : borderSubtle
                        scale: swatchMouse.pressed ? 0.92 : (swatchMouse.containsMouse ? 1.08 : 1.0)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                        MouseArea {
                            id: swatchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.accentSelected(modelData.id)
                        }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: root.accentName === modelData.id ? textPrimary : textSecondary
                        font.family: displayFont
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }

            Column {
                spacing: 6

                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: root.accentName === "custom" ? root.customAccentColor : "#2C2926"
                    border.width: root.accentName === "custom" ? 2.5 : 1
                    border.color: root.accentName === "custom" ? textPrimary : borderSubtle
                    scale: customMouse.pressed ? 0.92 : (customMouse.containsMouse ? 1.08 : 1.0)

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        icon: "sliders-horizontal"
                        color: textPrimary
                    }

                    MouseArea {
                        id: customMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: colorPicker.open()
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Custom"
                    color: root.accentName === "custom" ? textPrimary : textSecondary
                    font.family: displayFont
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }
        }
    }

    SectionLabel { text: "Cover Art & Backdrop" }

    SettingCard {
        SettingRow {
            iconName: "disc"
            title: "Album Art Corners"
            subtitle: "Corner roundness for artwork thumbnails and cards"

            SettingSegmentedControl {
                options: [
                    { value: 0, label: "SQUARE" },
                    { value: 8, label: "SOFT" },
                    { value: 16, label: "ROUNDED" }
                ]
                selectedValue: root.albumArtRadius
                onOptionSelected: val => root.albumArtRadiusSelected(Number(val))
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "pip"
            title: "Now Playing Backdrop"
            subtitle: "Visual style of the expanded player backdrop"

            SettingSegmentedControl {
                options: [
                    { value: "tinted", label: "TINTED" },
                    { value: "clean", label: "CLEAN" }
                ]
                selectedValue: root.nowPlayingBackdrop
                onOptionSelected: val => root.nowPlayingBackdropSelected(val)
            }
        }
    }

    SectionLabel { text: "Time Counter" }

    SettingCard {
        SettingRow {
            iconName: "clock"
            title: "Time Display"
            subtitle: "Show remaining time countdown or total track duration"

            SettingSegmentedControl {
                options: [
                    { value: true, label: "REMAINING" },
                    { value: false, label: "TOTAL" }
                ]
                selectedValue: root.showRemainingTime
                onOptionSelected: val => root.showRemainingTimeSelected(Boolean(val))
            }
        }
    }

    SettingColorPicker {
        id: colorPicker
        currentColor: root.customAccentColor
        onColorApplied: hex => {
            root.customAccentColor = hex
            root.customAccentSelected(hex)
            root.accentSelected("custom")
        }
    }
}
