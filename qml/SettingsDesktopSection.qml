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
    property string updateStatusText: ""
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
            title: qsTr("Default Launch Page")
            subtitle: qsTr("View displayed immediately upon opening CassetteCat")
            options: [
                { value: "last", label: qsTr("Last Visited") },
                { value: "home", label: qsTr("Home") },
                { value: "library", label: qsTr("Library") },
                { value: "radio", label: qsTr("Radio") },
                { value: "search", label: qsTr("Search") },
                { value: "settings", label: qsTr("Settings") }
            ]
            selectedValue: root.defaultLaunchPage
            onOptionSelected: val => root.defaultLaunchPageSelected(String(val))
        }
    }

    SectionLabel { text: "Window & System Tray" }

    SettingCard {
        SettingRow {
            iconName: "shield"
            title: qsTr("Close to System Tray")
            subtitle: qsTr("Keep CassetteCat running in the background when the window is closed")

            SettingSwitch {
                enabled: root.trayAvailable
                checked: root.closeToTray
                onToggled: val => root.closeToTraySelected(val)
            }
        }

        SettingDivider {}

        SettingRow {
            iconName: "minus"
            title: qsTr("Start Minimized")
            subtitle: qsTr("Launch silently in the system tray without showing the main window")

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
            title: qsTr("Now-Playing Notifications")
            subtitle: qsTr("Show native system notification when the track changes")

            SettingSegmentedControl {
                options: [
                    { value: "off", label: qsTr("Off") },
                    { value: "minimized", label: qsTr("When Minimized") },
                    { value: "always", label: qsTr("Always") }
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
            title: qsTr("Keep Mini Player on Top")
            subtitle: qsTr("Float compact mini player above other application windows")

            SettingSwitch {
                checked: root.miniPlayerAlwaysOnTop
                onToggled: val => root.miniPlayerAlwaysOnTopSelected(val)
            }
        }
    }

    SectionLabel {
        visible: !installedFromStore
        text: qsTr("Application Updates")
    }

    SettingCard {
        visible: !installedFromStore
        SettingRow {
            iconName: "arrow-up"
            title: qsTr("Check for Updates")
            subtitle: root.updateStatusText

            SettingButton {
                text: root.updateChecking ? qsTr("Checking...") : qsTr("Check Now")
                iconName: "refresh-cw"
                enabled: !root.updateChecking
                onClicked: root.checkUpdatesRequested()
            }

            SettingButton {
                visible: root.updateAvailable
                text: qsTr("Download Update")
                iconName: "external-link"
                primary: true
                onClicked: root.downloadUpdateRequested()
            }
        }
    }
}
