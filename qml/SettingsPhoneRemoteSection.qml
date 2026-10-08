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
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
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
            iconName: "link"
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
        visible: root.remoteOn
        text: "Paired Phones"
    }

    SettingCard {
        visible: root.remoteOn

        SettingRow {
            visible: phoneRemote.pairedPhones.length === 0
            iconName: "smartphone"
            title: "No Phones Yet"
            subtitle: "Phones you allow from this computer appear here"
        }

        Repeater {
            model: phoneRemote.pairedPhones

            ColumnLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                SettingRow {
                    iconName: "smartphone"
                    title: modelData.name
                    subtitle: modelData.name === root.phoneName ? "Connected now" : "Paired"

                    SettingButton {
                        text: "Remove"
                        accessibleName: "Remove " + modelData.name
                        onClicked: phoneRemote.unpairPhone(modelData.code)
                    }
                }
            }
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
            subtitle: "For pairing by address. A new code unpairs phones paired that way; phones listed above stay paired"

            Value { text: phoneRemote.code }

            SettingButton {
                text: "New Code"
                iconName: "refresh-cw"
                onClicked: newCodeConfirm.open()
            }
        }
    }

    ConfirmPopup {
        id: newCodeConfirm
        title: "New Pairing Code?"
        subtitle: "Phones paired by address will need it"
        message: "Phones that paired by entering the address lose access until you give them the new code. Phones under Paired Phones stay connected."
        confirmText: "New Code"
        onConfirmed: phoneRemote.regenerateCode()
    }
}
