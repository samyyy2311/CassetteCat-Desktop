import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool offlineBlackout: false
    property bool listenBrainzEnabled: false
    property string listenBrainzUser: ""
    property bool listenBrainzConnected: false

    property bool libreFmEnabled: false
    property string libreFmUser: ""
    property bool libreFmConnected: false

    signal listenBrainzEnabledToggled(bool value)
    signal disconnectListenBrainzRequested()
    signal libreFmEnabledToggled(bool value)
    signal disconnectLibreFmRequested()

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Open Scrobbler Services" }

    SettingCard {
        SettingRow {
            iconName: "listenbrainz"
            preserveIconColor: true
            iconSize: 22
            title: root.listenBrainzConnected
                   ? ("ListenBrainz (@" + root.listenBrainzUser + ")")
                   : "ListenBrainz"
            subtitle: root.listenBrainzConnected
                      ? "Open music database run by the MetaBrainz Foundation"
                      : "Connect your ListenBrainz profile using a User Token"

            RowLayout {
                spacing: 10

                SettingSwitch {
                    visible: root.listenBrainzConnected
                    enabled: !root.offlineBlackout
                    checked: root.listenBrainzEnabled
                    onToggled: val => root.listenBrainzEnabledToggled(val)
                }

                SettingButton {
                    visible: root.listenBrainzConnected
                    text: "Disconnect"
                    destructive: true
                    onClicked: root.disconnectListenBrainzRequested()
                }

                SettingButton {
                    visible: !root.listenBrainzConnected
                    text: "Connect"
                    primary: true
                    iconName: "plug"
                    enabled: !root.offlineBlackout
                    onClicked: accountDialog.openFor("listenbrainz")
                }
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "librefm"
            preserveIconColor: true
            iconSize: 22
            title: root.libreFmConnected
                   ? ("Libre.fm (@" + root.libreFmUser + ")")
                   : "Libre.fm"
            subtitle: root.libreFmConnected
                      ? "Free software music scrobbling powered by GNU FM"
                      : "Log in with your Libre.fm username and password"

            RowLayout {
                spacing: 10

                SettingSwitch {
                    visible: root.libreFmConnected
                    enabled: !root.offlineBlackout
                    checked: root.libreFmEnabled
                    onToggled: val => root.libreFmEnabledToggled(val)
                }

                SettingButton {
                    visible: root.libreFmConnected
                    text: "Disconnect"
                    destructive: true
                    onClicked: root.disconnectLibreFmRequested()
                }

                SettingButton {
                    visible: !root.libreFmConnected
                    text: "Connect"
                    primary: true
                    iconName: "plug"
                    enabled: !root.offlineBlackout
                    onClicked: accountDialog.openFor("librefm")
                }
            }
        }
    }

    Popup {
        id: accountDialog
        parent: Overlay.overlay
        modal: true
        focus: true
        x: Math.round(((parent ? parent.width : 800) - width) / 2)
        y: Math.round(((parent ? parent.height : 600) - height) / 2)
        width: Math.min((parent ? parent.width - 64 : 460), 460)
        padding: 24
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property string service: "listenbrainz"
        readonly property bool isListenBrainz: service === "listenbrainz"
        property bool isBusy: false
        property string errorMessage: ""

        function openFor(serviceId) {
            service = serviceId
            errorMessage = ""
            isBusy = false
            lbTokenInput.text = ""
            libreUserInput.text = ""
            librePassInput.text = ""
            open()
            if (serviceId === "listenbrainz") {
                lbTokenInput.forceActiveFocus()
            } else {
                libreUserInput.forceActiveFocus()
            }
        }

        Overlay.modal: Rectangle {
            color: "#B8000000"
        }

        background: Rectangle {
            radius: 14
            color: surfaceCard
            border.width: 1
            border.color: borderSubtle
        }

        contentItem: ColumnLayout {
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                LucideIcon {
                    icon: accountDialog.isListenBrainz ? "listenbrainz" : "librefm"
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    preserveColor: true
                }

                Label {
                    text: accountDialog.isListenBrainz ? "Connect ListenBrainz" : "Connect Libre.fm"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
            }

            Label {
                Layout.fillWidth: true
                text: accountDialog.isListenBrainz
                      ? "Paste your ListenBrainz User Token to enable scrobbling."
                      : "Log in with your Libre.fm account credentials."
                color: textSecondary
                font.family: displayFont
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: accountDialog.isListenBrainz
                spacing: 8

                RefineTextInput {
                    id: lbTokenInput
                    Layout.fillWidth: true
                    placeholder: "User Token"
                    enabled: !accountDialog.isBusy
                    onSubmitted: submitBtn.clicked()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    LucideIcon {
                        icon: "external-link"
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        color: recordRedHover
                    }

                    Label {
                        text: "Get user token from ListenBrainz website"
                        color: recordRedHover
                        font.family: displayFont
                        font.pixelSize: 11
                        font.underline: mouseLink.containsMouse

                        MouseArea {
                            id: mouseLink
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: services.openExternalUrl("https://listenbrainz.org/profile/")
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: !accountDialog.isListenBrainz
                spacing: 10

                RefineTextInput {
                    id: libreUserInput
                    Layout.fillWidth: true
                    placeholder: "Username"
                    enabled: !accountDialog.isBusy
                    onSubmitted: librePassInput.forceActiveFocus()
                }

                RefineTextInput {
                    id: librePassInput
                    Layout.fillWidth: true
                    placeholder: "Password"
                    isPassword: true
                    enabled: !accountDialog.isBusy
                    onSubmitted: submitBtn.clicked()
                }
            }

            Label {
                Layout.fillWidth: true
                visible: accountDialog.errorMessage.length > 0
                text: accountDialog.errorMessage
                color: recordRedHover
                font.family: displayFont
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 10

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: "Cancel"
                    enabled: !accountDialog.isBusy
                    onClicked: accountDialog.close()
                }

                SettingButton {
                    id: submitBtn
                    text: {
                        if (accountDialog.isBusy) {
                            return accountDialog.isListenBrainz ? "Validating..." : "Logging in..."
                        }
                        return accountDialog.isListenBrainz ? "Connect" : "Log In"
                    }
                    primary: true
                    enabled: {
                        if (accountDialog.isBusy) return false
                        if (accountDialog.isListenBrainz) {
                            return lbTokenInput.text.trim().length > 0
                        }
                        return libreUserInput.text.trim().length > 0 && librePassInput.text.trim().length > 0
                    }
                    onClicked: {
                        accountDialog.isBusy = true
                        accountDialog.errorMessage = ""
                        if (accountDialog.isListenBrainz) {
                            services.validateListenBrainzToken(lbTokenInput.text.trim())
                        } else {
                            services.authenticateLibreFm(libreUserInput.text.trim(), librePassInput.text.trim())
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: services

        function onListenBrainzValidationFinished(valid, userName, error) {
            if (accountDialog.service === "listenbrainz") {
                accountDialog.isBusy = false
                if (valid) {
                    accountDialog.close()
                } else {
                    accountDialog.errorMessage = error.length ? error : "Invalid user token or authentication failed"
                }
            }
        }

        function onLibreFmAuthFinished(success, userName, sessionKey, error) {
            if (accountDialog.service === "librefm") {
                accountDialog.isBusy = false
                if (success) {
                    accountDialog.close()
                } else {
                    accountDialog.errorMessage = error.length ? error : "Invalid username or password"
                }
            }
        }
    }
}
