import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

AppDialog {
    id: root

    required property var remote
    property bool enabledSetting: true
    property bool offlineBlackout: false
    signal enableRequested(bool enabled)

    readonly property bool remoteOn: enabledSetting && !offlineBlackout
    // A phone playing its own music is never controlling this computer, whatever else it last asked for.
    readonly property bool controlled: remote.controllerName !== "" && !remote.phonePlayback.isPlaying
    readonly property string phoneName: remote.phonePlayback.name || remote.controllerName
    property bool showAddress: false

    maxWidth: 440
    onClosed: showAddress = false

    component Body: Label {
        Layout.fillWidth: true
        color: textSecondary
        font.family: bodyFont
        font.pixelSize: 13
        lineHeight: 1.3
        wrapMode: Text.WordWrap
    }

    contentItem: ColumnLayout {
        spacing: 16

        DialogHeader {
            iconName: "smartphone"
            title: qsTr("Phone Remote")
            subtitle: root.offlineBlackout ? qsTr("Paused by Offline Blackout Mode")
                : !root.enabledSetting ? qsTr("Off")
                : root.controlled ? "Controlled from " + root.remote.controllerName
                : root.phoneName !== "" ? root.phoneName + " is playing"
                : "Ready on " + root.remote.computerName

            TransportButton {
                Layout.alignment: Qt.AlignTop
                Accessible.name: qsTr("Close")
                buttonSize: 32
                iconName: "x"
                tooltipText: qsTr("Close")
                onClicked: root.close()
            }
        }

        Body {
            visible: !root.remoteOn
            text: root.offlineBlackout
                  ? qsTr("Turn off Offline Blackout Mode in Settings to use your phone as a remote.")
                  : qsTr("Control this computer from the CassetteCat Android app, move music between them, and keep likes, playlists and backups in sync over your Wi-Fi.")
        }

        Body {
            visible: root.remoteOn && root.phoneName === ""
            text: root.remote.address === ""
                  ? qsTr("Connect this computer to Wi-Fi to use your phone as a remote.")
                  : "On your phone, open CassetteCat on the same Wi-Fi, tap the devices button in Now Playing and choose "
                    + root.remote.computerName + ". Then click Allow here."
        }

        Body {
            visible: root.remoteOn && root.phoneName !== ""
            text: root.controlled
                  ? qsTr("Playback here follows your phone. Continue on the phone to move the music back to it.")
                  : (root.remote.phonePlayback.title || qsTr("Music")) + " is playing on your phone. Play it here to move it to this computer."
        }

        // Only for networks where the phone can't find the computer by itself.
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.remoteOn && root.remote.address !== "" && root.phoneName === ""
            spacing: 8

            Label {
                text: root.showAddress ? qsTr("Enter this in the app under Settings > Desktop Remote:") : qsTr("Phone can't find this computer?")
                color: root.showAddress ? textSecondary : accentText
                font.family: bodyFont
                font.pixelSize: 13

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.showAddress
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.showAddress = true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.showAddress
                spacing: 8

                Label {
                    Layout.fillWidth: true
                    text: root.remote.address + "#" + root.remote.code
                    color: textPrimary
                    font.family: monoFont
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                SettingButton {
                    text: qsTr("Copy")
                    onClicked: appSettings.copyToClipboard(root.remote.address + "#" + root.remote.code)
                }

                SettingButton {
                    iconName: "refresh-cw"
                    accessibleName: qsTr("New pairing code. Paired phones will need to pair again.")
                    onClicked: root.remote.regenerateCode()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10

            Item { Layout.fillWidth: true }

            // Keeps the pairing, so the phone can connect again from its devices button.
            SettingButton {
                visible: root.remoteOn && root.phoneName !== ""
                text: qsTr("Disconnect")
                onClicked: {
                    root.remote.disconnectPhone()
                    root.close()
                }
            }

            SettingButton {
                visible: root.remoteOn && root.controlled
                text: "Continue on " + root.phoneName
                primary: true
                onClicked: {
                    root.remote.continueOnPhone()
                    root.close()
                }
            }

            SettingButton {
                visible: root.remoteOn && !root.controlled && !!root.remote.phonePlayback.title
                text: qsTr("Play Here")
                primary: true
                onClicked: {
                    root.remote.sendToPhone("handoff")
                    root.close()
                }
            }

            SettingButton {
                visible: !root.enabledSetting && !root.offlineBlackout
                text: qsTr("Turn On")
                primary: true
                onClicked: root.enableRequested(true)
            }
        }
    }
}
