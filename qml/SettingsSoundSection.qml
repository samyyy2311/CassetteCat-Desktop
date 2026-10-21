import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var audioOutputs: []
    property string audioDeviceId: ""
    property int crossfadeSeconds: 0
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80
    property string replayGainMode: "off"

    signal audioDeviceSelected(string value)
    signal crossfadeSelected(int value)
    signal volumeLimitSelected(bool value)
    signal maxVolumeSelected(int value)
    signal replayGainModeSelected(string value)

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Audio Output") }

    SettingCard {
        SettingChoiceGroup {
            iconName: "speaker"
            title: qsTr("Playback Device")
            subtitle: qsTr("Choose where CassetteCat sends audio output")
            forceMenu: true
            options: root.audioOutputs
            selectedValue: root.audioDeviceId
            onOptionSelected: value => root.audioDeviceSelected(String(value))
        }

        SettingDivider {}

        SettingChoiceGroup {
            iconName: "blend"
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

    SectionLabel { text: qsTr("Audio Protection") }

    SettingCard {
        SettingRow {
            iconName: "shield"
            title: qsTr("Volume Limit")
            subtitle: qsTr("Turns all playback down, to protect your hearing")

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
                subtitle: qsTr("How loud full volume plays")
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
