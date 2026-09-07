import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool resumeQueueOnLaunch: true
    property bool autoplayEnabled: false
    property bool globalShortcutsEnabled: false
    property bool globalShortcutsSupported: false
    property string globalShortcutStatus: ""
    property var globalShortcutBindings: ({})
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: "Off"
    property bool sleepFadeOut: true
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80

    signal resumeQueueOnLaunchSelected(bool value)
    signal autoplaySelected(bool value)
    signal globalShortcutsEnabledSelected(bool value)
    signal globalShortcutSelected(string action, string shortcut)
    signal sleepTimerSelected(string value)
    signal sleepTimerCancelled()
    signal sleepFadeOutSelected(bool value)
    signal volumeLimitSelected(bool value)
    signal maxVolumeSelected(int value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Queue & Playback" }

    SettingCard {
        SettingRow {
            iconName: "play"
            title: "Resume Queue on Launch"
            subtitle: "Restore active track, queue, and playback position"

            SettingSwitch {
                checked: root.resumeQueueOnLaunch
                onToggled: val => root.resumeQueueOnLaunchSelected(val)
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "repeat"
            title: "Autoplay"
            subtitle: "Shuffle music from library when queue reaches the end"

            SettingSwitch {
                checked: root.autoplayEnabled
                onToggled: val => root.autoplaySelected(val)
            }
        }
    }

    SectionLabel { text: "Global Shortcuts" }

    SettingCard {
        SettingRow {
            iconName: "zap"
            title: "System-Wide Hotkeys"
            subtitle: root.globalShortcutsSupported ? root.globalShortcutStatus : "Not available on this platform"

            SettingSwitch {
                enabled: root.globalShortcutsSupported
                checked: root.globalShortcutsEnabled
                onToggled: val => root.globalShortcutsEnabledSelected(val)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.globalShortcutsSupported && root.globalShortcutsEnabled
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            spacing: 6

            SettingDivider {}

            Repeater {
                model: [
                    { action: "playPause", label: "Play / Pause", defaultKey: "Ctrl+Alt+Space" },
                    { action: "previous", label: "Previous Track", defaultKey: "Ctrl+Alt+Left" },
                    { action: "next", label: "Next Track", defaultKey: "Ctrl+Alt+Right" },
                    { action: "favorite", label: "Toggle Favorite", defaultKey: "Ctrl+Alt+F" },
                    { action: "search", label: "Focus Search", defaultKey: "Ctrl+Alt+S" },
                    { action: "miniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+Alt+M" }
                ]
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    spacing: 12

                    Label {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 12
                    }

                    ShortcutCaptureField {
                        shortcut: (root.globalShortcutBindings && root.globalShortcutBindings[modelData.action]) || modelData.defaultKey
                        onShortcutCaptured: value => root.globalShortcutSelected(modelData.action, value)
                    }
                }
            }
        }
    }

    SectionLabel { text: "Sleep Timer" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "clock"
            title: "Sleep Timer"
            subtitle: root.sleepTimerMode === "off" ? "Stop playback automatically after a duration or track" : ("Active countdown: " + root.sleepTimerStatus)
            options: [
                { value: "off", label: "OFF" },
                { value: "15", label: "15 MIN" },
                { value: "30", label: "30 MIN" },
                { value: "45", label: "45 MIN" },
                { value: "60", label: "60 MIN" },
                { value: "track", label: "END OF TRACK" }
            ]
            selectedValue: root.sleepTimerMode
            onOptionSelected: val => {
                if (val === "off") {
                    root.sleepTimerCancelled()
                } else {
                    root.sleepTimerSelected(String(val))
                }
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "volume-1"
            title: "Gentle Fade-Out"
            subtitle: "Smoothly ramp down volume before stopping playback"

            SettingSwitch {
                checked: root.sleepFadeOut
                onToggled: val => root.sleepFadeOutSelected(val)
            }
        }
    }

    SectionLabel { text: "Audio Protection" }

    SettingCard {
        SettingRow {
            iconName: "volume-2"
            title: "Volume Limit"
            subtitle: "Cap the maximum output level to protect your hearing"

            SettingSwitch {
                checked: root.volumeLimitEnabled
                onToggled: val => root.volumeLimitSelected(val)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.volumeLimitEnabled
            spacing: 0

            SettingDivider {}

            SettingChoiceGroup {
                iconName: "sliders-horizontal"
                title: "Maximum Volume Limit"
                subtitle: "Ceiling threshold applied to the master volume slider"
                options: [
                    { value: 50, label: "50%" },
                    { value: 60, label: "60%" },
                    { value: 70, label: "70%" },
                    { value: 80, label: "80%" },
                    { value: 90, label: "90%" },
                    { value: 100, label: "100%" }
                ]
                selectedValue: root.maxVolumePercent
                onOptionSelected: val => root.maxVolumeSelected(Number(val))
            }
        }
    }
}
