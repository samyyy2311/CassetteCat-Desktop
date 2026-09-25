import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string defaultLaunchPage: "last"
    property bool closeToTray: true
    property bool startMinimizedToTray: false
    property string nowPlayingNotifications: "minimized"
    property bool miniPlayerAlwaysOnTop: true
    property bool trayAvailable: true
    property string updateStatusText: "Current version: v0.6.0"
    property bool updateChecking: false
    property bool updateAvailable: false
    property string updateUrl: ""

    signal defaultLaunchPageSelected(string value)
    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal checkUpdatesRequested()
    signal downloadUpdateRequested()

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Startup & Navigation" }

    SettingCard {
        SettingChoiceGroup {
            iconName: "compass"
            title: "Default Launch Page"
            subtitle: "View displayed immediately upon opening CassetteCat"
            options: [
                { value: "last", label: "Last Visited" },
                { value: "home", label: "Home" },
                { value: "library", label: "Library" },
                { value: "radio", label: "Radio" },
                { value: "search", label: "Search" },
                { value: "settings", label: "Settings" }
            ]
            selectedValue: root.defaultLaunchPage
            onOptionSelected: val => root.defaultLaunchPageSelected(String(val))
        }
    }

    SectionLabel { text: "Window & System Tray" }

    SettingCard {
        SettingRow {
            iconName: "shield"
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
            iconName: "minus"
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
            iconName: "pin"
            title: "Keep Mini Player on Top"
            subtitle: "Float compact mini player above other application windows"

            SettingSwitch {
                checked: root.miniPlayerAlwaysOnTop
                onToggled: val => root.miniPlayerAlwaysOnTopSelected(val)
            }
        }
    }

    SectionLabel { text: "Application Updates" }

    SettingCard {
        SettingRow {
            iconName: "arrow-up"
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
}
