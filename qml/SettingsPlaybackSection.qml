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
    // Saved by the streaming controller, which builds the stream links.
    property int streamQuality: streaming.serverConfigSnapshot()["quality/normal"] || 0
    property int meteredStreamQuality: streaming.serverConfigSnapshot()["quality/metered"] || 0
    readonly property var qualityOptions: [
        { value: "0", label: qsTr("Original") },
        { value: "320", label: qsTr("320 kbps") },
        { value: "256", label: qsTr("256 kbps") },
        { value: "192", label: qsTr("192 kbps") },
        { value: "128", label: qsTr("128 kbps") }
    ]

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

    SectionLabel { text: qsTr("Streaming") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "audio-lines"
            title: qsTr("Stream Quality")
            subtitle: qsTr("How good songs from your server sound")
            options: root.qualityOptions
            selectedValue: String(root.streamQuality)
            onOptionSelected: val => {
                root.streamQuality = Number(val)
                streaming.setStreamQuality(false, root.streamQuality)
            }
        }

        SettingDivider {}

        SettingChoiceGroup {
            iconName: "smartphone"
            title: qsTr("On Metered Connections")
            subtitle: qsTr("Such as your phone's hotspot. A lower quality uses less data")
            options: root.qualityOptions
            selectedValue: String(root.meteredStreamQuality)
            onOptionSelected: val => {
                root.meteredStreamQuality = Number(val)
                streaming.setStreamQuality(true, root.meteredStreamQuality)
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
