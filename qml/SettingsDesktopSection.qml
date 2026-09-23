import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool closeToTray: true
    property bool startMinimizedToTray: false
    property string nowPlayingNotifications: "minimized"
    property bool miniPlayerAlwaysOnTop: true
    property bool trayAvailable: true
    property var audioOutputs: []
    property string audioDeviceId: ""
    property string updateStatusText: "Current version: v0.5.1"
    property bool updateChecking: false
    property bool updateAvailable: false
    property string updateUrl: ""
    property bool logsVisible: false
    property string recentLogs: ""

    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal audioDeviceSelected(string value)
    signal checkUpdatesRequested()
    signal downloadUpdateRequested()

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Window & System Tray" }

    SettingCard {
        SettingRow {
            iconName: "shield"
            iconColor: "#10B981"
            title: "Close to System Tray"
            subtitle: "Keep CassetteCat running in the background when the window is closed"

            SettingSwitch {
                enabled: root.trayAvailable
                checked: root.closeToTray
                onToggled: val => root.closeToTraySelected(val)
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "pip"
            iconColor: "#A5B4FC"
            title: "Start Minimized"
            subtitle: "Launch silently in the system tray without showing the main window"

            SettingSwitch {
                enabled: root.trayAvailable
                checked: root.startMinimizedToTray
                onToggled: val => root.startMinimizedToTraySelected(val)
            }
        }
    }

    SectionLabel { text: "Desktop Notifications" }

    SettingCard {
        SettingRow {
            iconName: "disc"
            iconColor: "#38BDF8"
            title: "Now-Playing Notifications"
            subtitle: "Show native system notification when the track changes"

            SettingSegmentedControl {
                options: [
                    { value: "off", label: "Off" },
                    { value: "minimized", label: "When Minimized" },
                    { value: "always", label: "Always" }
                ]
                selectedValue: root.nowPlayingNotifications
                onOptionSelected: val => root.nowPlayingNotificationsSelected(String(val))
            }
        }
    }

    SectionLabel { text: "Mini Player Window" }

    SettingCard {
        SettingRow {
            iconName: "pip"
            iconColor: "#F59E0B"
            title: "Keep Mini Player on Top"
            subtitle: "Float compact mini player above other application windows"

            SettingSwitch {
                checked: root.miniPlayerAlwaysOnTop
                onToggled: val => root.miniPlayerAlwaysOnTopSelected(val)
            }
        }
    }

    SectionLabel { text: "Audio Output" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "volume-2"
            iconColor: "#F59E0B"
            title: "Playback Device"
            subtitle: "Choose where CassetteCat sends audio"
            forceMenu: true
            options: root.audioOutputs
            selectedValue: root.audioDeviceId
            onOptionSelected: value => root.audioDeviceSelected(String(value))
        }
    }

    SectionLabel { text: "Application Updates" }

    SettingCard {
        SettingRow {
            iconName: "refresh-cw"
            iconColor: "#38BDF8"
            title: "Check for Updates"
            subtitle: root.updateStatusText

            SettingButton {
                text: root.updateChecking ? "Checking..." : "Check Now"
                iconName: "refresh-cw"
                enabled: !root.updateChecking
                onClicked: root.checkUpdatesRequested()
            }

            SettingButton {
                visible: root.updateAvailable
                text: "Download Update"
                iconName: "external-link"
                primary: true
                onClicked: root.downloadUpdateRequested()
            }
        }
    }

    SectionLabel { text: "Diagnostics & Logs" }

    SettingCard {
        SettingRow {
            iconName: "info"
            iconColor: "#C4C4C0"
            title: "Application Logs"
            subtitle: appSettings.getLogFilePath()

            SettingButton {
                text: root.logsVisible ? "Hide Logs" : "Logs"
                iconName: "list"
                onClicked: {
                    root.logsVisible = !root.logsVisible
                    if (root.logsVisible) {
                        root.recentLogs = appSettings.readRecentLogs(150)
                    }
                }
            }

            SettingButton {
                text: "Open"
                iconName: "external-link"
                onClicked: appSettings.openLogFile()
            }

            SettingButton {
                text: "Copy"
                onClicked: appSettings.copyToClipboard(appSettings.readRecentLogs(200))
            }

            SettingButton {
                text: "Clear"
                iconName: "x"
                destructive: true
                onClicked: {
                    appSettings.clearLogs()
                    root.recentLogs = appSettings.readRecentLogs(150)
                }
            }
        }

        Rectangle {
            visible: root.logsVisible
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 8
            color: "#121110"
            border.width: 1
            border.color: "#2C2926"
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: logText.paintedWidth
                contentHeight: logText.paintedHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: SleekScrollBar {}
                ScrollBar.horizontal: SleekScrollBar {}

                TextEdit {
                    id: logText
                    readOnly: true
                    selectByMouse: true
                    text: root.recentLogs
                    color: "#F5F0EC"
                    font.family: (typeof monoFont !== "undefined") ? monoFont : "IBM Plex Mono"
                    font.pixelSize: 11
                }
            }
        }
    }
}
