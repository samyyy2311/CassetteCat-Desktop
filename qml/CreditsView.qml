import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal backClicked()

    component CreditItemRow: Rectangle {
        id: itemRoot
        property var itemData: ({})
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        color: m.containsMouse ? surfaceCardHover : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        Item {
            id: iconBadge
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24

            LucideIcon {
                anchors.centerIn: parent
                width: 20
                height: 20
                icon: itemRoot.itemData.icon || ""
                preserveColor: !!itemRoot.itemData.preserveColor
                color: m.containsMouse ? recordRedHover : textPrimary
            }
        }

        Column {
            anchors.left: iconBadge.right
            anchors.leftMargin: 14
            anchors.right: linkIcon.left
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Label {
                width: parent.width
                text: itemRoot.itemData.title || ""
                color: m.containsMouse ? recordRedHover : textPrimary
                font.family: displayFont
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                text: itemRoot.itemData.subtitle || ""
                color: textSecondary
                font.family: bodyFont
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        LucideIcon {
            id: linkIcon
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            icon: "external-link"
            color: m.containsMouse ? recordRedHover : silverDim
        }

        MouseArea {
            id: m
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: itemRoot.clicked()
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth
        contentHeight: bodyCol.implicitHeight + 48
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical: SleekScrollBar {}

        Column {
            id: bodyCol
            width: scroll.availableWidth
            spacing: 10
            topPadding: 24
            bottomPadding: 36

            ColumnLayout {
                x: 32
                width: scroll.availableWidth - 64
                spacing: 10

                // ---- Header matching SubPageHeader with rotated left-pointing chevron ----
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    PressDepthIconButton {
                        boxSize: 36
                        iconSize: 18
                        iconName: "chevron-left"
                        tint: textPrimary
                        tooltipText: "Back to Settings"
                        onClicked: root.backClicked()
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Credits & Open Source"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        font.letterSpacing: -0.3
                        elide: Text.ElideRight
                    }
                }

                // ---- Section 1: Services & Data ----
                SectionLabel { text: "Services & Data" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: s1Col.implicitHeight
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle
                    clip: true

                    ColumnLayout {
                        id: s1Col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

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

                                Rectangle {
                                    visible: index > 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: borderSubtle
                                    opacity: 0.6
                                }

                                CreditItemRow {
                                    itemData: modelData
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }

                // ---- Section 2: Core Audio & Architecture ----
                SectionLabel { text: "Core Audio & Architecture" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: s2Col.implicitHeight
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle
                    clip: true

                    ColumnLayout {
                        id: s2Col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        Repeater {
                            model: [
                                { title: "AutoEq", subtitle: "Calibrated headphone equalizer response curves by Jaakko Pasanen", icon: "autoeq", preserveColor: true, url: "https://github.com/jaakkopasanen/AutoEq" },
                                { title: "Qt Multimedia", subtitle: "Hardware audio playback, streaming, and audio sinks", icon: "music", preserveColor: false, url: "https://doc.qt.io/qt-6/qtmultimedia-index.html" },
                                { title: "Qt Network", subtitle: "High-performance HTTP/REST client for lyrics and data sync", icon: "globe", preserveColor: false, url: "https://doc.qt.io/qt-6/qtnetwork-index.html" },
                                { title: "TagLib", subtitle: "Audio metadata and embedded ID3/MP4/FLAC tag parser", icon: "disc", preserveColor: false, url: "https://taglib.org" },
                                { title: "DWM Windows Frameless", subtitle: "Hardware-accelerated Windows Desktop Window Manager composition", icon: "shield", preserveColor: false, url: "https://learn.microsoft.com/en-us/windows/win32/dwm/dwm-overview" }
                            ]

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Rectangle {
                                    visible: index > 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: borderSubtle
                                    opacity: 0.6
                                }

                                CreditItemRow {
                                    itemData: modelData
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }

                // ---- Section 3: Design & Typography ----
                SectionLabel { text: "Design & Typography" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: s3Col.implicitHeight
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle
                    clip: true

                    ColumnLayout {
                        id: s3Col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

                        Repeater {
                            model: [
                                { title: "Lucide Icons", subtitle: "App logo & open-source iconography (lucide.dev, ISC License)", icon: "logo", preserveColor: false, url: "https://lucide.dev" },
                                { title: "Simple Icons", subtitle: "Authentic brand SVG icons (simpleicons.org, CC0 1.0)", icon: "simpleicons", preserveColor: true, url: "https://simpleicons.org" },
                                { title: "IBM Plex (Sans & Mono)", subtitle: "Designed by Mike Abbink and Bold Monday for IBM (OFL 1.1)", icon: "ibm", preserveColor: true, url: "https://github.com/IBM/plex" },
                                { title: "Space Grotesk", subtitle: "Proportional monospace display typeface by Florian Karsten (OFL 1.1)", icon: "quote", preserveColor: false, url: "https://github.com/floriankarsten/space-grotesk" }
                            ]

                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Rectangle {
                                    visible: index > 0
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: borderSubtle
                                    opacity: 0.6
                                }

                                CreditItemRow {
                                    itemData: modelData
                                    onClicked: Qt.openUrlExternally(modelData.url)
                                }
                            }
                        }
                    }
                }

                // ---- Section 4: Open Source License ----
                SectionLabel { text: "Open Source License" }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: s4Col.implicitHeight
                    radius: 12
                    color: surfaceCard
                    border.width: 1
                    border.color: borderSubtle
                    clip: true

                    ColumnLayout {
                        id: s4Col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        spacing: 0

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
            }
        }
    }
}
