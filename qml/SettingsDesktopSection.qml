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

    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal audioDeviceSelected(string value)

    Layout.fillWidth: true
    spacing: 16

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
            iconName: "pip"
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
                    { value: "off", label: "OFF" },
                    { value: "minimized", label: "WHEN MINIMIZED" },
                    { value: "always", label: "ALWAYS" }
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
            title: "Playback Device"
            subtitle: "Choose where CassetteCat sends audio"
            options: root.audioOutputs
            selectedValue: root.audioDeviceId
            onOptionSelected: value => root.audioDeviceSelected(String(value))
        }
    }

}
