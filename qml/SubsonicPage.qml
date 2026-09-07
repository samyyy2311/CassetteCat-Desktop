import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var streamingController
    anchors.fill: parent

    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: subContentCol.implicitHeight + 48
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: SleekScrollBar {}

        Column {
            id: subContentCol
            width: parent.width
            spacing: 24
            topPadding: 24
            bottomPadding: 36

            ColumnLayout {
                x: 32
                width: parent.width - 64
                spacing: 6

                RowLayout {
                    spacing: 12
                    LucideIcon {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        icon: "subsonic"
                        preserveColor: true
                    }
                    Label {
                        text: "SUBSONIC"
                        color: "#FF8500"
                        font.family: monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                Label {
                    text: "Subsonic / Navidrome Server"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }

                Label {
                    text: root.streamingController.subsonicConnected ? ("Connected • " + root.streamingController.subsonicStatus) : "Connect to Navidrome, gonic, or any Subsonic-compatible server"
                    color: silverDim
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }

            Rectangle {
                visible: !root.streamingController.subsonicConnected
                x: 32
                width: parent.width - 64
                implicitHeight: subFormCol.implicitHeight + 40
                radius: 14
                color: surfaceCard
                border.width: 1
                border.color: borderSubtle

                ColumnLayout {
                    id: subFormCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    Label {
                        text: "Connect to Server"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    RefineTextInput {
                        id: subUrlInput
                        Layout.fillWidth: true
                        placeholder: "Server URL (e.g. 192.168.1.112:4533 or https://music.example.com)"
                        text: {
                            const snap = root.streamingController.serverConfigSnapshot();
                            return snap["subsonic/url"] || "";
                        }
                    }

                    RefineTextInput {
                        id: subUserInput
                        Layout.fillWidth: true
                        placeholder: "Username"
                        text: {
                            const snap = root.streamingController.serverConfigSnapshot();
                            return snap["subsonic/username"] || "";
                        }
                    }

                    RefineTextInput {
                        id: subPassInput
                        Layout.fillWidth: true
                        placeholder: "Password"
                        echoMode: TextInput.Password
                    }

                    Label {
                        visible: root.appWindow.subsonicError.length > 0
                        text: root.appWindow.subsonicError
                        color: recordRedHover
                        font.family: displayFont
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        SettingsChoicePill {
                            label: root.appWindow.subsonicConnecting ? "CONNECTING..." : "CONNECT TO SUBSONIC"
                            selected: true
                            enabled: !root.appWindow.subsonicConnecting
                            onClicked: {
                                if (root.appWindow.subsonicConnecting)
                                    return;
                                root.appWindow.subsonicError = "";
                                const url = subUrlInput.text.trim();
                                const user = subUserInput.text.trim();
                                const pass = subPassInput.text;
                                if (!url || !user || !pass) {
                                    root.appWindow.subsonicError = "Enter server URL, username, and password.";
                                    return;
                                }
                                root.appWindow.subsonicConnecting = true;
                                root.streamingController.connectSubsonic(url, user, pass);
                            }
                        }
                    }

                    Label {
                        text: "Credentials are stored securely in Windows Credential Store."
                        color: silverDim
                        font.family: bodyFont
                        font.pixelSize: 11
                    }
                }
            }

            ColumnLayout {
                visible: root.streamingController.subsonicConnected
                x: 32
                width: parent.width - 64
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    SettingsChoicePill {
                        label: "REFRESH LIBRARY"
                        selected: false
                        onClicked: root.streamingController.refreshLibrary()
                    }

                    SettingsChoicePill {
                        label: "DISCONNECT"
                        selected: false
                        onClicked: root.streamingController.disconnectServer("subsonic")
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 480)
                    clip: true
                    interactive: true
                    model: root.streamingController.subsonicModel
                    delegate: SongRow {
                        width: ListView.view.width
                        track: model.track
                        onClicked: root.appWindow.playTrack(model.track)
                    }
                }
            }
        }
    }
}
