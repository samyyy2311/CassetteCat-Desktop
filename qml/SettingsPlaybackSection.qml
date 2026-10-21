import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool resumeQueueOnLaunch: true
    property bool autoplayEnabled: false
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: qsTr("Off")
    property bool sleepFadeOut: true

    signal resumeQueueOnLaunchSelected(bool value)
    signal autoplaySelected(bool value)
    signal sleepTimerSelected(string value)
    signal sleepTimerCancelled()
    signal sleepFadeOutSelected(bool value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Queue & Playback") }

    SettingCard {
        SettingRow {
            iconName: "rotate-ccw"
            title: qsTr("Resume Queue on Launch")
            subtitle: qsTr("Restore active track, queue, and playback position")

            SettingSwitch {
                checked: root.resumeQueueOnLaunch
                onToggled: val => root.resumeQueueOnLaunchSelected(val)
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "shuffle"
            title: qsTr("Autoplay")
            subtitle: qsTr("Keep playing similar songs when the queue ends")

            SettingSwitch {
                checked: root.autoplayEnabled
                onToggled: val => root.autoplaySelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Sleep Timer") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "moon"
            title: qsTr("Sleep Timer")
            subtitle: root.sleepTimerMode === "off" ? qsTr("Stop playback automatically after a duration or track") : qsTr("Active countdown: %1").arg(root.sleepTimerStatus)
            options: [
                { value: "off", label: qsTr("Off") },
                { value: "15", label: qsTr("15 min") },
                { value: "30", label: qsTr("30 min") },
                { value: "45", label: qsTr("45 min") },
                { value: "60", label: qsTr("60 min") },
                { value: "track", label: qsTr("End of track") }
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
            title: qsTr("Gentle Fade-Out")
            subtitle: qsTr("Smoothly ramp down volume before stopping playback")

            SettingSwitch {
                checked: root.sleepFadeOut
                onToggled: val => root.sleepFadeOutSelected(val)
            }
        }
    }
}
