import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool offlineBlackout: false
    property bool svcPhoneRemote: false
    readonly property bool remoteOn: svcPhoneRemote && !offlineBlackout
    readonly property string phoneName: phoneRemote.controllerName || (phoneRemote.phonePlayback.name || "")

    signal serviceToggleRequested(string name, bool value)

    spacing: 0

    component Value: Label {
        color: textPrimary
        font.family: monoFont
        font.pixelSize: 13
    }

    SectionLabel { text: "Phone Remote" }

    SettingCard {
        SettingRow {
            iconName: "smartphone"
            title: "Control From Your Phone" + (root.offlineBlackout ? " (paused)" : "")
            subtitle: root.offlineBlackout
                      ? "Turn off Offline Blackout Mode to use your phone as a remote"
                      : "The CassetteCat Android app on the same Wi-Fi can control playback, move music between devices and sync likes, playlists and backups"

            SettingSwitch {
                enabled: !root.offlineBlackout
                checked: root.remoteOn
                onToggled: val => root.serviceToggleRequested("phoneRemote", val)
            }
        }

        SettingDivider { visible: root.remoteOn }

        SettingRow {
            visible: root.remoteOn
            iconName: root.phoneName !== "" ? "smartphone" : "link"
            title: phoneRemote.controllerName !== "" ? "Controlled from " + phoneRemote.controllerName
                 : root.phoneName !== "" ? root.phoneName + " is playing"
                 : phoneRemote.address !== "" ? "Pair a Phone" : "No Network Connection"
            subtitle: root.phoneName !== "" ? "Connected over Wi-Fi to " + phoneRemote.computerName
                    : phoneRemote.address !== ""
                      ? "In the app, tap the devices button in Now Playing and choose " + phoneRemote.computerName + ", then allow it here"
                      : "Connect this computer to Wi-Fi to pair a phone"
        }
    }

    SectionLabel {
        visible: root.remoteOn && phoneRemote.address !== ""
        text: "Pair Manually"
    }

    SettingCard {
        visible: root.remoteOn && phoneRemote.address !== ""

        SettingRow {
            iconName: "globe"
            title: "Address"
            subtitle: "If your phone can't find this computer, enter this in the app under Settings, Desktop Remote"

            Value { text: phoneRemote.address + "#" + phoneRemote.code }

            SettingButton {
                text: copiedTimer.running ? "Copied" : "Copy"
                iconName: copiedTimer.running ? "check" : ""
                onClicked: {
                    appSettings.copyToClipboard(phoneRemote.address + "#" + phoneRemote.code)
                    copiedTimer.restart()
                }

                Timer {
                    id: copiedTimer
                    interval: 2000
                }
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "key-round"
            title: "Pairing Code"
            subtitle: "Phones ask for it when they pair by address or after the code changes. A new code unpairs every phone"

            Value { text: phoneRemote.code }

            SettingButton {
                text: "New Code"
                iconName: "refresh-cw"
                onClicked: phoneRemote.regenerateCode()
            }
        }
    }
}
