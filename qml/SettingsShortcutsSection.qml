import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool globalShortcutsEnabled: false
    property bool globalShortcutsSupported: false
    property string globalShortcutStatus: ""
    property var globalShortcutBindings: ({})
    property var inAppActions: []
    property var inAppShortcutBindings: ({})
    property string inAppShortcutStatus: ""

    signal globalShortcutsEnabledSelected(bool value)
    signal globalShortcutSelected(string action, string shortcut)
    signal inAppShortcutSelected(string action, string shortcut)

    readonly property var globalActions: [
        { action: "playPause", label: "Play / Pause", defaultKey: "Ctrl+Alt+Space", icon: "play" },
        { action: "previous", label: "Previous Track", defaultKey: "Ctrl+Alt+Left", icon: "skip-back" },
        { action: "next", label: "Next Track", defaultKey: "Ctrl+Alt+Right", icon: "skip-forward" },
        { action: "favorite", label: "Toggle Favorite", defaultKey: "Ctrl+Alt+F", icon: "heart" },
        { action: "search", label: "Focus Search", defaultKey: "Ctrl+Alt+S", icon: "search" },
        { action: "miniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+Alt+M", icon: "pip" }
    ]

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "System-Wide Hotkeys" }

    SettingCard {
        SettingRow {
            iconName: "keyboard"
            title: "Enable Global Shortcuts"
            subtitle: root.globalShortcutsSupported ? root.globalShortcutStatus : "Not available on this platform"

            SettingSwitch {
                enabled: root.globalShortcutsSupported
                checked: root.globalShortcutsEnabled
                onToggled: value => root.globalShortcutsEnabledSelected(value)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.globalShortcutsSupported
            opacity: root.globalShortcutsEnabled ? 1.0 : 0.4
            enabled: root.globalShortcutsEnabled
            spacing: 0

            Repeater {
                model: root.globalActions

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    SettingDivider {}

                    SettingRow {
                        iconName: modelData.icon || ""
                        title: modelData.label

                        ShortcutCaptureField {
                            enabled: root.globalShortcutsEnabled
                            shortcut: (root.globalShortcutBindings && root.globalShortcutBindings.hasOwnProperty(modelData.action))
                                ? root.globalShortcutBindings[modelData.action]
                                : modelData.defaultKey
                            onShortcutCaptured: value => root.globalShortcutSelected(modelData.action, value)
                        }
                    }
                }
            }
        }
    }

    SectionLabel { text: "In-App Controls" }

    SettingCard {
        Label {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 4
            text: "Click a shortcut field to record keys. Press Backspace to clear, Escape to cancel."
            color: (typeof textSecondary !== "undefined" ? textSecondary : "#96918A")
            font.family: (typeof bodyFont !== "undefined" ? bodyFont : "Space Grotesk")
            font.pixelSize: 11
        }

        Label {
            visible: root.inAppShortcutStatus.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 2
            Layout.bottomMargin: 6
            text: root.inAppShortcutStatus
            color: root.inAppShortcutStatus.toLowerCase().includes("already")
                ? "#FF5555"
                : (root.inAppShortcutStatus.toLowerCase().includes("cleared") ? textSecondary : "#10B981")
            font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
            font.pixelSize: 12
            font.weight: Font.Medium
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.inAppActions

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                SettingRow {
                    iconName: modelData.icon || ""
                    title: modelData.label

                    ShortcutCaptureField {
                        allowPlainKey: true
                        allowClear: true
                        shortcut: (root.inAppShortcutBindings && root.inAppShortcutBindings.hasOwnProperty(modelData.action))
                            ? root.inAppShortcutBindings[modelData.action]
                            : modelData.defaultKey
                        onShortcutCaptured: value => root.inAppShortcutSelected(modelData.action, value)
                    }
                }
            }
        }
    }
}
