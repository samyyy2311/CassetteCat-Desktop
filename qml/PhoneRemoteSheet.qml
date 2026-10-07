import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

BottomSheet {
    id: root

    required property var remote
    property bool enabledSetting: true
    property bool offlineBlackout: false
    signal enableRequested(bool enabled)

    readonly property string pairingAddress: remote.address + "#" + remote.code
    readonly property string phoneName: remote.controllerName || (remote.phonePlayback.name || "")
    maxWidth: 460

    onClosed: isOpen = false

    component BodyText: Label {
        Layout.fillWidth: true
        color: root.appWindow.textSecondary
        font.family: root.appWindow.bodyFont
        font.pixelSize: 13
        wrapMode: Text.WordWrap
    }

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 12

        Label {
            text: "Phone Remote"
            color: root.appWindow.textPrimary
            font.family: root.appWindow.displayFont
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        BodyText {
            visible: root.offlineBlackout
            text: "Paused while Offline Blackout Mode is on. Turn it off in Settings to use your phone as a remote."
        }

        // Off: one button turns it on.
        ColumnLayout {
            Layout.fillWidth: true
            visible: !root.offlineBlackout && !root.enabledSetting
            spacing: 12

            BodyText {
                text: "Control this computer from the CassetteCat Android app, move music between them, and keep likes, playlists and backups in sync over your Wi-Fi."
            }

            SettingButton {
                text: "Turn On"
                iconName: "smartphone"
                primary: true
                onClicked: root.enableRequested(true)
            }
        }

        // A phone is connected.
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.remote.enabled && root.phoneName !== ""
            spacing: 12

            BodyText {
                color: root.appWindow.textPrimary
                text: root.remote.controllerName !== ""
                      ? "Controlled from " + root.remote.controllerName + "."
                      : root.phoneName + " is playing " + (root.remote.phonePlayback.title || "music") + "."
            }

            SettingButton {
                text: "Continue on " + root.phoneName
                iconName: "smartphone"
                visible: root.remote.controllerName !== ""
                onClicked: {
                    root.remote.continueOnPhone()
                    root.close()
                }
            }

            SettingButton {
                text: "Play Here"
                iconName: "play"
                visible: root.remote.controllerName === "" && !!root.remote.phonePlayback.title
                onClicked: {
                    root.remote.sendToPhone("handoff")
                    root.close()
                }
            }
        }

        // On, waiting for a phone.
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.remote.enabled && root.phoneName === ""
            spacing: 8

            BodyText {
                visible: root.remote.address === ""
                text: "Connect this computer to Wi-Fi to use your phone as a remote."
            }

            Repeater {
                model: root.remote.address === "" ? [] : [
                    "Open CassetteCat on your Android phone, on the same Wi-Fi as this computer.",
                    "In Now Playing, tap the devices button and choose " + root.remote.computerName + ".",
                    "Click Allow when this computer asks."
                ]

                delegate: RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Label {
                        Layout.alignment: Qt.AlignTop
                        text: index + 1
                        color: root.appWindow.accentText
                        font.family: root.appWindow.monoFont
                        font.pixelSize: 13
                    }

                    BodyText {
                        color: root.appWindow.textPrimary
                        text: modelData
                    }
                }
            }
        }

        // Pairing by address, for networks where the phone can't find the computer.
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.remote.enabled && root.remote.address !== ""
            spacing: 8

            BodyText {
                text: "Not listed on your phone? Enter this address in the app instead:"
            }

            Label {
                text: root.pairingAddress
                color: root.appWindow.textPrimary
                font.family: root.appWindow.monoFont
                font.pixelSize: 14
            }

            RowLayout {
                spacing: 8

                SettingButton {
                    text: "Copy Address"
                    onClicked: appSettings.copyToClipboard(root.pairingAddress)
                }

                SettingButton {
                    text: "New Code"
                    iconName: "refresh-cw"
                    accessibleName: "New pairing code. Paired phones will need to pair again."
                    onClicked: root.remote.regenerateCode()
                }
            }
        }

        SettingButton {
            Layout.topMargin: 4
            visible: root.enabledSetting && !root.offlineBlackout
            text: "Turn Off"
            onClicked: root.enableRequested(false)
        }
    }
}
