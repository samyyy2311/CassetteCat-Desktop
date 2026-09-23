import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: 16

    component CreditItemRow: Rectangle {
        id: itemRoot
        property var itemData: ({})
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 8
        color: m.containsMouse ? (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#282623") : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 14

            LucideIcon {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                icon: itemRoot.itemData.icon || ""
                preserveColor: !!itemRoot.itemData.preserveColor
                color: itemRoot.itemData.iconColor ? itemRoot.itemData.iconColor : (typeof textSecondary !== "undefined" ? textSecondary : "#96918A")
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Label {
                    Layout.fillWidth: true
                    text: itemRoot.itemData.title || ""
                    color: textPrimary
                    font.family: (typeof displayFont !== "undefined" ? displayFont : "Space Grotesk")
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    Layout.fillWidth: true
                    text: itemRoot.itemData.subtitle || ""
                    color: textSecondary
                    font.family: (typeof bodyFont !== "undefined" ? bodyFont : "IBM Plex Sans")
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            LucideIcon {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                Layout.alignment: Qt.AlignVCenter
                icon: "external-link"
                color: m.containsMouse ? textPrimary : (typeof silverDim !== "undefined" ? silverDim : "#6B6762")
            }
        }

        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: itemRoot.clicked()
        }
    }

    SectionLabel { text: "Services & Data" }

    SettingCard {
        Repeater {
            model: [
                { title: "LRCLIB", subtitle: "Synchronized and plain lyrics (lrclib.net)", icon: "lrclib", preserveColor: true, url: "https://lrclib.net" },
                { title: "Deezer", subtitle: "Artist portraits and high-res imagery (deezer.com)", icon: "deezer", preserveColor: true, url: "https://deezer.com" },
                { title: "TheAudioDB", subtitle: "Fallback artist images and biographies (theaudiodb.com)", icon: "theaudiodb", preserveColor: true, url: "https://theaudiodb.com" },
                { title: "Radio Browser", subtitle: "Community-run internet radio station directory (radio-browser.info)", icon: "radio", preserveColor: false, url: "https://radio-browser.info" },
                { title: "Wikipedia & Wikimedia", subtitle: "Artist biographies and album background (CC BY-SA 4.0)", icon: "wikipedia", preserveColor: true, url: "https://wikipedia.org" },
                { title: "MusicBrainz", subtitle: "Open music encyclopedia and metadata references", icon: "musicbrainz", preserveColor: true, url: "https://musicbrainz.org" },
                { title: "Cover Art Archive", subtitle: "Archival CD and vinyl cover scans (Internet Archive & MusicBrainz)", icon: "archive", preserveColor: true, url: "https://coverartarchive.org" },
                { title: "ListenBrainz", subtitle: "Open scrobbling platform and CC0 listening data", icon: "listenbrainz", preserveColor: true, url: "https://listenbrainz.org" },
                { title: "Libre.fm", subtitle: "Free software music scrobbling network (GNU FM)", icon: "librefm", preserveColor: true, url: "https://libre.fm" },
                { title: "GitHub", subtitle: "Release update checks (github.com)", icon: "github", preserveColor: true, url: "https://github.com" }
            ]

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                CreditItemRow {
                    itemData: modelData
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }

    SectionLabel { text: "Core Audio & Architecture" }

    SettingCard {
        Repeater {
            model: [
                { title: "AutoEq", subtitle: "Calibrated headphone equalizer response curves by Jaakko Pasanen (Planned)", icon: "autoeq", preserveColor: true, url: "https://github.com/jaakkopasanen/AutoEq" },
                { title: "Qt Multimedia", subtitle: "Hardware audio playback, streaming, and audio sinks", icon: "music", preserveColor: false, url: "https://doc.qt.io/qt-6/qtmultimedia-index.html" },
                { title: "Qt Network", subtitle: "High-performance HTTP/REST client for lyrics and data sync", icon: "globe", preserveColor: false, url: "https://doc.qt.io/qt-6/qtnetwork-index.html" },
                { title: "TagLib", subtitle: "Audio metadata and embedded ID3/MP4/FLAC tag parser", icon: "disc", preserveColor: false, url: "https://taglib.org" },
                { title: "DWM Windows Frameless", subtitle: "Hardware-accelerated Windows Desktop Window Manager composition", icon: "shield", preserveColor: false, url: "https://learn.microsoft.com/en-us/windows/win32/dwm/dwm-overview" }
            ]

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                CreditItemRow {
                    itemData: modelData
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }

    SectionLabel { text: "Design & Typography" }

    SettingCard {
        Repeater {
            model: [
                { title: "Lucide Icons", subtitle: "App logo & open-source iconography (lucide.dev, ISC License)", icon: "lucide", preserveColor: true, url: "https://lucide.dev" },
                { title: "Simple Icons", subtitle: "Authentic brand SVG icons (simpleicons.org, CC0 1.0)", icon: "simpleicons", preserveColor: true, url: "https://simpleicons.org" },
                { title: "IBM Plex (Sans & Mono)", subtitle: "Designed by Mike Abbink and Bold Monday for IBM (OFL 1.1)", icon: "ibm", preserveColor: true, url: "https://github.com/IBM/plex" },
                { title: "Space Grotesk", subtitle: "Proportional monospace display typeface by Florian Karsten (OFL 1.1)", icon: "quote", preserveColor: false, url: "https://github.com/floriankarsten/space-grotesk" }
            ]

            delegate: ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                SettingDivider { visible: index > 0 }

                CreditItemRow {
                    itemData: modelData
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }

    SectionLabel { text: "Open Source License" }

    SettingCard {
        CreditItemRow {
            itemData: ({
                title: "GNU General Public License v3.0",
                subtitle: "View source code and contribute on GitHub",
                icon: "gpl",
                preserveColor: true,
                url: "https://github.com/samyyy2311/CassetteCat"
            })
            onClicked: Qt.openUrlExternally("https://github.com/samyyy2311/CassetteCat")
        }
    }
}
