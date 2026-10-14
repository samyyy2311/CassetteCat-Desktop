import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var audioOutputs: []
    property string audioDeviceId: ""
    property bool resumeQueueOnLaunch: true
    property bool autoplayEnabled: false
    property int crossfadeSeconds: 0
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: qsTr("Off")
    property bool sleepFadeOut: true
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80
    property string replayGainMode: "off"

    signal audioDeviceSelected(string value)
    signal resumeQueueOnLaunchSelected(bool value)
    signal autoplaySelected(bool value)
    signal crossfadeSelected(int value)
    signal sleepTimerSelected(string value)
    signal sleepTimerCancelled()
    signal sleepFadeOutSelected(bool value)
    signal volumeLimitSelected(bool value)
    signal maxVolumeSelected(int value)
    signal replayGainModeSelected(string value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Audio Output") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "plug"
            title: qsTr("Playback Device")
            subtitle: qsTr("Choose where CassetteCat sends audio output")
            forceMenu: true
            options: root.audioOutputs
            selectedValue: root.audioDeviceId
            onOptionSelected: value => root.audioDeviceSelected(String(value))
        }
    }

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

        SettingDivider {}

        SettingChoiceGroup {
            iconName: "audio-lines"
            title: qsTr("Crossfade")
            subtitle: qsTr("Fade each song into the next as it ends")
            options: [
                { value: 0, label: qsTr("Off") },
                { value: 3, label: "3s" },
                { value: 6, label: "6s" },
                { value: 10, label: "10s" }
            ]
            selectedValue: root.crossfadeSeconds
            onOptionSelected: value => root.crossfadeSelected(Number(value))
        }
    }

    SectionLabel { text: qsTr("Audio Protection") }

    SettingCard {
        SettingRow {
            iconName: "shield"
            title: qsTr("Volume Limit")
            subtitle: qsTr("Cap the maximum output level to protect your hearing")

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
                iconName: "volume-2"
                title: qsTr("Maximum Volume Limit")
                subtitle: qsTr("Ceiling threshold applied to the master volume slider")
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

    SectionLabel { text: qsTr("Equalizer") }

    SettingsEqualizerCard {}

    SectionLabel { text: qsTr("Loudness & Normalization") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "audio-lines"
            title: qsTr("Volume Normalization (ReplayGain)")
            subtitle: root.replayGainMode === "off" ? qsTr("Preserve original file loudness") : (root.replayGainMode === "track" ? qsTr("Track gain active: balance volume per song") : qsTr("Album gain active: preserve album dynamic range"))
            options: [
                { value: "off", label: qsTr("Off") },
                { value: "track", label: qsTr("Track") },
                { value: "album", label: qsTr("Album") }
            ]
            selectedValue: root.replayGainMode
            onOptionSelected: val => root.replayGainModeSelected(String(val))
        }
    }

    SectionLabel { text: qsTr("Sleep Timer") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "clock"
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
