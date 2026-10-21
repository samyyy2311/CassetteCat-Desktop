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
    property bool svcArchive: true
    property bool svcDiscord: false

    signal offlineBlackoutSelected(bool value)
    signal serviceToggleRequested(string name, bool value)
    signal openJellyfinRequested()
    signal openSubsonicRequested()

    function serviceEnabled(id) {
        if (id === "lrclib") return root.svcLrclib
        if (id === "radio") return root.svcRadio
        if (id === "deezer") return root.svcDeezer
        if (id === "audiodb") return root.svcAudiodb
        if (id === "wiki") return root.svcWiki
        if (id === "archive") return root.svcArchive
        if (id === "discord") return root.svcDiscord
        return false
    }

    Layout.fillWidth: true
    spacing: 16

    SectionLabel { text: qsTr("Offline Mode") }

    SettingCard {
        SettingRow {
            iconName: "wifi-off"
            title: qsTr("Offline Blackout Mode")
            subtitle: root.offlineBlackout
                      ? qsTr("All network connections, metadata lookups, and remote streams are disabled")
                      : qsTr("Completely disable all internet lookups and remote telemetry")

            SettingSwitch {
                checked: root.offlineBlackout
                onToggled: val => root.offlineBlackoutSelected(val)
            }
        }
    }

    SectionLabel { text: qsTr("Remote Music Servers") }

    SettingCard {
        SettingRow {
            iconName: "server"
            title: qsTr("Streaming Server Integration")
            subtitle: qsTr("Configure credentials, stream audio catalogs, and manage server synchronization")

            SettingButton {
                text: "Jellyfin"
                iconName: "jellyfin"
                preserveIconColor: true
                onClicked: root.openJellyfinRequested()
            }

            SettingButton {
                text: "Subsonic"
                iconName: "subsonic"
                preserveIconColor: true
                onClicked: root.openSubsonicRequested()
            }
        }
    }

    SectionLabel { text: qsTr("Online Metadata & Lyrics") }

    SettingCard {
        Repeater {
            model: [
                { id: "lrclib", title: qsTr("LrcLib Lyrics"), subtitle: qsTr("Synced lyrics when none are found locally"), icon: "lrclib", preserveColor: true, on: root.svcLrclib },
                { id: "radio", title: "Radio Browser", subtitle: qsTr("Internet radio station discovery and streaming"), icon: "radio", preserveColor: false, on: root.svcRadio },
                { id: "deezer", title: qsTr("Deezer Artwork"), subtitle: qsTr("High-resolution artist portraits and imagery"), icon: "deezer", preserveColor: true, on: root.svcDeezer },
                { id: "audiodb", title: "TheAudioDB", subtitle: qsTr("Artist imagery and biography metadata fallback"), icon: "theaudiodb", preserveColor: true, on: root.svcAudiodb },
                { id: "wiki", title: "Wikipedia", subtitle: qsTr("Artist biographies and summaries"), icon: "wikipedia", preserveColor: true, on: root.svcWiki },
                { id: "archive", title: "MusicBrainz", subtitle: qsTr("Song details and album covers from MusicBrainz and the Cover Art Archive"), icon: "archive", preserveColor: true, on: root.svcArchive },
                { id: "discord", title: qsTr("Discord Status"), subtitle: qsTr("Show the song you are playing on your Discord profile"), icon: "discord", preserveColor: true, on: root.svcDiscord }
            ]
            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                SettingRow {
                    iconName: modelData.icon
                    iconColor: modelData.iconColor ? modelData.iconColor : "transparent"
                    preserveIconColor: !!modelData.preserveColor
                    iconSize: 20
                    title: modelData.title + (root.offlineBlackout ? " (paused)" : "")
                    subtitle: modelData.subtitle

                    SettingSwitch {
                        enabled: !root.offlineBlackout
                        checked: root.serviceEnabled(modelData.id) && !root.offlineBlackout
                        onToggled: val => root.serviceToggleRequested(modelData.id, val)
                    }
                }
            }
        }
    }
}
