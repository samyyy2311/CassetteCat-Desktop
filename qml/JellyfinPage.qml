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
        contentHeight: jfContentCol.implicitHeight + 48
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: SleekScrollBar {}

        Column {
            id: jfContentCol
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
                        icon: "jellyfin"
                        preserveColor: true
                    }
                    Label {
                        text: "JELLYFIN"
                        color: "#00A4DC"
                        font.family: monoFont
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }
                }

                Label {
                    text: "Jellyfin Media Server"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 28
                    font.weight: Font.Bold
                }

                Label {
                    text: root.streamingController.jellyfinConnected ? ("Connected • " + root.streamingController.jellyfinStatus) : "Stream your music directly from your home Jellyfin server"
                    color: silverDim
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }

            Rectangle {
                visible: !root.streamingController.jellyfinConnected
                x: 32
                width: parent.width - 64
                implicitHeight: jfFormCol.implicitHeight + 40
                radius: 14
                color: surfaceCard
                border.width: 1
                border.color: borderSubtle

                ColumnLayout {
                    id: jfFormCol
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
                        id: jfUrlInput
                        Layout.fillWidth: true
                        placeholder: "Server URL (e.g. 192.168.1.112:8096 or https://jellyfin.example.com)"
                        text: {
                            const snap = root.streamingController.serverConfigSnapshot();
                            return snap["jellyfin/url"] || "";
                        }
                    }

                    RefineTextInput {
                        id: jfUserInput
                        Layout.fillWidth: true
                        placeholder: "Username"
                        text: {
                            const snap = root.streamingController.serverConfigSnapshot();
                            return snap["jellyfin/username"] || "";
                        }
                    }

                    RefineTextInput {
                        id: jfPassInput
                        Layout.fillWidth: true
                        placeholder: "Password"
                        echoMode: TextInput.Password
                    }

                    Label {
                        visible: root.appWindow.jellyfinError.length > 0
                        text: root.appWindow.jellyfinError
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
                            label: root.appWindow.jellyfinConnecting ? "CONNECTING..." : "CONNECT TO JELLYFIN"
                            selected: true
                            enabled: !root.appWindow.jellyfinConnecting
                            onClicked: {
                                if (root.appWindow.jellyfinConnecting)
                                    return;
                                root.appWindow.jellyfinError = "";
                                const url = jfUrlInput.text.trim();
                                const user = jfUserInput.text.trim();
                                const pass = jfPassInput.text;
                                if (!url || !user || !pass) {
                                    root.appWindow.jellyfinError = "Enter server URL, username, and password.";
                                    return;
                                }
                                root.appWindow.jellyfinConnecting = true;
                                root.streamingController.connectJellyfin(url, user, pass);
                            }
                        }
                    }

                    Label {
                        text: "Credentials are saved securely in Windows Credential Store."
                        color: silverDim
                        font.family: bodyFont
                        font.pixelSize: 11
                    }
                }
            }

            ColumnLayout {
                visible: root.streamingController.jellyfinConnected
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
                        onClicked: root.streamingController.disconnectServer("jellyfin")
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, 480)
                    clip: true
                    interactive: true
                    model: root.streamingController.jellyfinModel
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
