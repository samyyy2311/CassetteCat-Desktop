import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string defaultLaunchPage: "last"
    property var sidebarOrder: []
    property var sidebarHidden: []
    property var sidebarPageLabel: page => page
    property var sidebarPageIcon: page => page
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
    signal sidebarPagesSelected(var order, var hidden)
    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal checkUpdatesRequested()
    signal downloadUpdateRequested()

    function moveSidebarPage(index, offset) {
        const order = root.sidebarOrder.slice()
        order.splice(index + offset, 0, order.splice(index, 1)[0])
        root.sidebarPagesSelected(order, root.sidebarHidden)
    }

    function showSidebarPage(page, shown) {
        const hidden = root.sidebarHidden.filter(other => other !== page)
        root.sidebarPagesSelected(root.sidebarOrder, shown ? hidden : hidden.concat([page]))
    }

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Startup & Navigation") }

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

    SectionLabel { text: qsTr("Sidebar") }

    SettingCard {
        Repeater {
            model: root.sidebarOrder

            delegate: ColumnLayout {
                id: sidebarEntry
                required property string modelData
                required property int index
                readonly property string label: root.sidebarPageLabel(modelData)
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: sidebarEntry.index > 0 }

                SettingRow {
                    iconName: root.sidebarPageIcon(sidebarEntry.modelData)
                    preserveIconColor: sidebarEntry.modelData === "jellyfin" || sidebarEntry.modelData === "subsonic"
                    title: sidebarEntry.label
                    subtitle: sidebarEntry.modelData === "library" ? qsTr("Always shown") : ""

                    SettingButton {
                        iconName: "arrow-up"
                        accessibleName: qsTr("Move %1 up").arg(sidebarEntry.label)
                        enabled: sidebarEntry.index > 0
                        opacity: enabled ? 1 : 0.35
                        onClicked: root.moveSidebarPage(sidebarEntry.index, -1)
                    }

                    SettingButton {
                        iconName: "arrow-down"
                        accessibleName: qsTr("Move %1 down").arg(sidebarEntry.label)
                        enabled: sidebarEntry.index < root.sidebarOrder.length - 1
                        opacity: enabled ? 1 : 0.35
                        onClicked: root.moveSidebarPage(sidebarEntry.index, 1)
                    }

                    // Invisible for Library, but keeps the arrows aligned.
                    SettingSwitch {
                        opacity: sidebarEntry.modelData === "library" ? 0 : 1
                        enabled: sidebarEntry.modelData !== "library"
                        checked: !root.sidebarHidden.includes(sidebarEntry.modelData)
                        onToggled: val => root.showSidebarPage(sidebarEntry.modelData, val)
                    }
                }
            }
        }
    }

    SectionLabel { text: qsTr("Language") }

    SettingCard {
        SettingChoiceGroup {
            id: languageChoice
            // A list that grows with every translation, so always a menu.
            forceMenu: true
            property string language: appSettings.value("ui/language", "")
            iconName: "languages"
            title: qsTr("Language")
            subtitle: qsTr("The language CassetteCat's menus and messages use")
            options: [{ value: "", label: qsTr("System Default") }].concat(
                appSettings.languages().map(language => ({ value: language.code, label: language.name })))
            selectedValue: language
            onOptionSelected: val => {
                language = String(val)
                appSettings.setLanguage(language)
            }
        }
    }

    SectionLabel { text: qsTr("Window & System Tray") }

    SettingCard {
        SettingRow {
            iconName: "monitor-down"
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

    SectionLabel { text: qsTr("Desktop Notifications") }

    SettingCard {
        SettingRow {
            iconName: "bell"
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

    SectionLabel { text: qsTr("Mini Player Window") }

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
