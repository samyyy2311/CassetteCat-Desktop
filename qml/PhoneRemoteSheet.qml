import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    required property var remote
    property bool enabledSetting: true
    property bool offlineBlackout: false
    signal enableRequested(bool enabled)

    readonly property bool remoteOn: enabledSetting && !offlineBlackout
    readonly property string phoneName: remote.controllerName || (remote.phonePlayback.name || "")
    property bool showAddress: false

    parent: Overlay.overlay
    modal: true
    focus: true
    x: Math.round(((parent ? parent.width : 800) - width) / 2)
    y: Math.round(((parent ? parent.height : 600) - height) / 2)
    width: Math.min((parent ? parent.width - 64 : 440), 440)
    padding: 24
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onClosed: showAddress = false

    Overlay.modal: Rectangle { color: "#B8000000" }

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: UiConstants.durationFast }
        NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: UiConstants.durationStd; easing.type: UiConstants.easingStd }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: UiConstants.durationFast }
    }

    background: Rectangle {
        radius: 14
        color: surfaceCard
        border.width: 1
        border.color: borderSubtle
    }

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

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: root.phoneName !== "" ? Qt.alpha(recordRed, 0.14) : surfaceElevated

                LucideIcon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    icon: "smartphone"
                    color: root.phoneName !== "" ? accentText : textSecondary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: "Phone Remote"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Label {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.offlineBlackout ? "Paused by Offline Blackout Mode"
                        : !root.enabledSetting ? "Off"
                        : root.remote.controllerName !== "" ? "Controlled from " + root.remote.controllerName
                        : root.phoneName !== "" ? root.phoneName + " is playing"
                        : "Ready on " + root.remote.computerName
                    color: silverDim
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }

            SettingSwitch {
                enabled: !root.offlineBlackout
                checked: root.remoteOn
                onToggled: val => root.enableRequested(val)
            }
        }

        Body {
            visible: !root.remoteOn
            text: root.offlineBlackout
                  ? "Turn off Offline Blackout Mode in Settings to use your phone as a remote."
                  : "Control this computer from the CassetteCat Android app, move music between them, and keep likes, playlists and backups in sync over your Wi-Fi."
        }

        Body {
            visible: root.remoteOn && root.phoneName === ""
            text: root.remote.address === ""
                  ? "Connect this computer to Wi-Fi to use your phone as a remote."
                  : "On your phone, open CassetteCat on the same Wi-Fi, tap the devices button in Now Playing and choose "
                    + root.remote.computerName + ". Then click Allow here."
        }

        Body {
            visible: root.remoteOn && root.phoneName !== ""
            text: root.remote.controllerName !== ""
                  ? "Playback here follows your phone. Continue on the phone to move the music back to it."
                  : (root.remote.phonePlayback.title || "Music") + " is playing on your phone. Play it here to move it to this computer."
        }

        // Only for networks where the phone can't find the computer by itself.
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.remoteOn && root.remote.address !== "" && root.phoneName === ""
            spacing: 8

            Label {
                text: root.showAddress ? "Enter this in the app under Settings > Desktop Remote:" : "Phone can't find this computer?"
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
                    text: "Copy"
                    onClicked: appSettings.copyToClipboard(root.remote.address + "#" + root.remote.code)
                }

                SettingButton {
                    iconName: "refresh-cw"
                    accessibleName: "New pairing code. Paired phones will need to pair again."
                    onClicked: root.remote.regenerateCode()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 10

            Item { Layout.fillWidth: true }

            SettingButton {
                text: "Close"
                onClicked: root.close()
            }

            SettingButton {
                visible: root.remoteOn && root.remote.controllerName !== ""
                text: "Continue on " + root.phoneName
                iconName: "smartphone"
                primary: true
                onClicked: {
                    root.remote.continueOnPhone()
                    root.close()
                }
            }

            SettingButton {
                visible: root.remoteOn && root.remote.controllerName === "" && !!root.remote.phonePlayback.title
                text: "Play Here"
                iconName: "play"
                primary: true
                onClicked: {
                    root.remote.sendToPhone("handoff")
                    root.close()
                }
            }

            SettingButton {
                visible: !root.enabledSetting && !root.offlineBlackout
                text: "Turn On"
                primary: true
                onClicked: root.enableRequested(true)
            }
        }
    }
}
