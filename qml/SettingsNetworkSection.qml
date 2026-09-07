import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool offlineBlackout: false
    property bool svcLrclib: true
    property bool svcRadio: true
    property bool svcDeezer: true
    property bool svcAudiodb: true
    property bool svcWiki: true

    signal offlineBlackoutSelected(bool value)
    signal serviceToggleRequested(string name, bool value)
    signal openJellyfinRequested()
    signal openSubsonicRequested()

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: "Offline Mode" }

    SettingCard {
        SettingRow {
            iconName: "shield"
            title: "Offline Blackout Mode"
            subtitle: root.offlineBlackout
                      ? "All network connections, metadata lookups, and remote streams are disabled"
                      : "Completely disable all internet lookups and remote telemetry"

            SettingSwitch {
                checked: root.offlineBlackout
                onToggled: val => root.offlineBlackoutSelected(val)
            }
        }
    }

    SectionLabel { text: "Remote Music Servers" }

    SettingCard {
        SettingRow {
            iconName: "disc"
            title: "Streaming Server Integration"
            subtitle: "Configure credentials, stream audio catalogs, and manage server synchronization"
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 8
            spacing: 12

            SettingButton {
                text: "Open Jellyfin"
                iconName: "jellyfin"
                onClicked: root.openJellyfinRequested()
            }

            SettingButton {
                text: "Open Subsonic"
                iconName: "subsonic"
                onClicked: root.openSubsonicRequested()
            }
        }
    }

    SectionLabel { text: "Online Metadata & Lyrics" }

    SettingCard {
        Repeater {
            model: [
                { id: "lrclib", title: "LrcLib Lyrics", subtitle: "Synced lyrics when none are found locally", icon: "quote", on: root.svcLrclib },
                { id: "radio", title: "Radio Browser", subtitle: "Internet radio station discovery and streaming", icon: "radio", on: root.svcRadio },
                { id: "deezer", title: "Deezer Artwork", subtitle: "High-resolution artist portraits and imagery", icon: "disc", on: root.svcDeezer },
                { id: "audiodb", title: "TheAudioDB", subtitle: "Artist imagery and biography metadata fallback", icon: "mic", on: root.svcAudiodb },
                { id: "wiki", title: "Wikipedia", subtitle: "Artist biographies and summaries", icon: "globe", on: root.svcWiki }
            ]
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                SettingRow {
                    iconName: modelData.icon
                    title: modelData.title + (root.offlineBlackout ? " (paused)" : "")
                    subtitle: modelData.subtitle

                    SettingSwitch {
                        enabled: !root.offlineBlackout
                        checked: modelData.on && !root.offlineBlackout
                        onToggled: val => root.serviceToggleRequested(modelData.id, val)
                    }
                }
            }
        }
    }
}
