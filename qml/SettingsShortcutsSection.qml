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
        { action: "playPause", label: "Play / Pause", defaultKey: "Ctrl+Alt+Space" },
        { action: "previous", label: "Previous Track", defaultKey: "Ctrl+Alt+Left" },
        { action: "next", label: "Next Track", defaultKey: "Ctrl+Alt+Right" },
        { action: "favorite", label: "Toggle Favorite", defaultKey: "Ctrl+Alt+F" },
        { action: "search", label: "Focus Search", defaultKey: "Ctrl+Alt+S" },
        { action: "miniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+Alt+M" }
    ]

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "System-Wide Hotkeys" }

    SettingCard {
        SettingRow {
            iconName: "zap"
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
            visible: root.globalShortcutsSupported && root.globalShortcutsEnabled
            spacing: 0

            Repeater {
                model: root.globalActions

                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    SettingDivider { visible: index > 0 }

                    SettingRow {
                        iconName: ""
                        title: modelData.label
                        subtitle: "Works while CassetteCat is in the background"

                        ShortcutCaptureField {
                            shortcut: (root.globalShortcutBindings && root.globalShortcutBindings[modelData.action]) || modelData.defaultKey
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
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            text: root.inAppShortcutStatus || "These shortcuts work while CassetteCat is focused"
            color: textSecondary
            font.family: bodyFont
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.inAppActions

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                SettingRow {
                    iconName: ""
                    title: modelData.label
                    subtitle: "Available while CassetteCat is focused"

                    ShortcutCaptureField {
                        allowPlainKey: true
                        shortcut: (root.inAppShortcutBindings && root.inAppShortcutBindings[modelData.action]) || modelData.defaultKey
                        onShortcutCaptured: value => root.inAppShortcutSelected(modelData.action, value)
                    }
                }
            }
        }
    }
}
