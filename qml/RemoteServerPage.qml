import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var streamingController
    required property string protocol
    required property string serviceName
    required property string serviceLabel
    required property string serviceColor
    required property string description
    required property string urlPlaceholder

    readonly property bool connected: protocol === "jellyfin" ? streamingController.jellyfinConnected : streamingController.subsonicConnected
    readonly property bool connecting: protocol === "jellyfin" ? appWindow.jellyfinConnecting : appWindow.subsonicConnecting
    readonly property string status: protocol === "jellyfin" ? streamingController.jellyfinStatus : streamingController.subsonicStatus
    readonly property string errorText: protocol === "jellyfin" ? appWindow.jellyfinError : appWindow.subsonicError
    readonly property var trackModel: protocol === "jellyfin" ? streamingController.jellyfinModel : streamingController.subsonicModel

    anchors.fill: parent

    function setError(message) {
        if (protocol === "jellyfin")
            appWindow.jellyfinError = message
        else
            appWindow.subsonicError = message
    }

    function connect() {
        if (connecting)
            return

        const url = serverUrl.text.trim()
        const username = serverUser.text.trim()
        const password = serverPassword.text
        if (!url || !username || !password) {
            setError("Enter server URL, username, and password.")
            return
        }

        setError("")
        if (protocol === "jellyfin") {
            appWindow.jellyfinConnecting = true
            streamingController.connectJellyfin(url, username, password)
        } else {
            appWindow.subsonicConnecting = true
            streamingController.connectSubsonic(url, username, password)
        }
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: pageContent.implicitHeight + 48
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: SleekScrollBar {}

        Column {
            id: pageContent
            width: pageScroll.availableWidth
            spacing: 24
            topPadding: 24
            bottomPadding: 36

            RowLayout {
                x: 32
                width: parent.width - 64
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        icon: root.protocol
                        preserveColor: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    Label {
                        text: root.serviceLabel + " LIBRARY"
                        color: root.serviceColor
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.1
                    }

                    Label {
                        text: root.connected ? "Connected" : "Connect your server"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 20
                        font.weight: Font.Bold
                    }

                    Label {
                        Layout.fillWidth: true
                        text: root.connected ? root.status : root.description
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Row {
                    visible: root.connected
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    SettingButton {
                        text: "Refresh"
                        iconName: "refresh-cw"
                        onClicked: root.streamingController.refreshLibrary()
                    }

                    SettingButton {
                        text: "Disconnect"
                        destructive: true
                        onClicked: root.streamingController.disconnectServer(root.protocol)
                    }
                }
            }

            Rectangle {
                visible: !root.connected
                x: 32
                width: parent.width - 64
                implicitHeight: connectionForm.implicitHeight + 40
                radius: 14
                color: surfaceCard
                border.width: 1
                border.color: borderSubtle

                ColumnLayout {
                    id: connectionForm
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Label {
                        text: "Server details"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    RefineTextInput {
                        id: serverUrl
                        Layout.fillWidth: true
                        placeholder: root.urlPlaceholder
                        text: {
                            const snapshot = root.streamingController.serverConfigSnapshot()
                            return snapshot[root.protocol + "/url"] || ""
                        }
                    }

                    RefineTextInput {
                        id: serverUser
                        Layout.fillWidth: true
                        placeholder: "Username"
                        text: {
                            const snapshot = root.streamingController.serverConfigSnapshot()
                            return snapshot[root.protocol + "/username"] || ""
                        }
                    }

                    RefineTextInput {
                        id: serverPassword
                        Layout.fillWidth: true
                        placeholder: "Password"
                        echoMode: TextInput.Password
                    }

                    Label {
                        visible: root.errorText.length > 0
                        Layout.fillWidth: true
                        text: root.errorText
                        color: recordRedHover
                        font.family: displayFont
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        SettingButton {
                            text: root.connecting ? "Connecting…" : "Connect"
                            primary: true
                            onClicked: root.connect()
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Credentials are stored securely in Windows Credential Store."
                            color: silverDim
                            font.family: bodyFont
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            ColumnLayout {
                visible: root.connected
                x: 32
                width: parent.width - 64
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true

                    Label {
                        text: "TRACKS"
                        color: recordRed
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.1
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: trackList.count + " available"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(160, Math.min(trackList.contentHeight + 12, 572))
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle

                    ListView {
                        id: trackList
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        interactive: contentHeight > height
                        spacing: 2
                        model: root.trackModel
                        ScrollBar.vertical: SleekScrollBar {}

                        delegate: SongRow {
                            width: ListView.view.width
                            track: model.track
                            showSourceBadge: false
                            showFormatBadge: false
                            cardBg: "transparent"
                            hoverBg: surfaceElevated
                            activeBg: "transparent"
                            onClicked: root.appWindow.playTrack(model.track)
                            onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
                        }
                    }

                    EmptyState {
                        anchors.fill: parent
                        visible: trackList.count === 0
                        title: "No tracks yet"
                        subtitle: "Refresh the server library to load its music"
                    }
                }
            }
        }
    }
}
