import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    signal backClicked()

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.implicitHeight + 80
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: SleekScrollBar {}

        ColumnLayout {
            id: contentCol
            width: Math.min(parent.width - 64, 760)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 24

            Item { Layout.preferredHeight: 12 }

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                PressDepthIconButton {
                    boxSize: 36
                    iconSize: 18
                    iconName: "chevron-down"
                    tint: textPrimary
                    tooltipText: "Back to Settings"
                    onClicked: root.backClicked()
                }

                ColumnLayout {
                    spacing: 2
                    Label {
                        text: "Credits & Open Source"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 24
                        font.weight: Font.Bold
                    }
                    Label {
                        text: "Services, data providers, and open-source libraries"
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 12
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "SERVICES & DATA"
                    color: recordRedHover
                    font.family: monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Repeater {
                    model: [
                        {
                            title: "LRCLIB",
                            subtitle: "Synchronized and plain lyrics (lrclib.net)",
                            icon: "music",
                            url: "https://lrclib.net"
                        },
                        {
                            title: "Deezer",
                            subtitle: "Artist portraits and high-res imagery (deezer.com)",
                            icon: "disc",
                            url: "https://deezer.com"
                        },
                        {
                            title: "TheAudioDB",
                            subtitle: "Fallback artist images and biographies (theaudiodb.com)",
                            icon: "mic",
                            url: "https://theaudiodb.com"
                        },
                        {
                            title: "Radio Browser",
                            subtitle: "Community-run internet radio station directory (radio-browser.info)",
                            icon: "radio",
                            url: "https://radio-browser.info"
                        },
                        {
                            title: "Wikipedia & Wikimedia",
                            subtitle: "Artist biographies and album background (CC BY-SA 4.0)",
                            icon: "globe",
                            url: "https://wikipedia.org"
                        },
                        {
                            title: "MusicBrainz",
                            subtitle: "Open music encyclopedia and metadata references",
                            icon: "disc",
                            url: "https://musicbrainz.org"
                        },
                        {
                            title: "Cover Art Archive",
                            subtitle: "Archival CD and vinyl cover scans (Internet Archive & MusicBrainz)",
                            icon: "disc",
                            url: "https://coverartarchive.org"
                        },
                        {
                            title: "ListenBrainz",
                            subtitle: "Open scrobbling platform and CC0 listening data",
                            icon: "audio-lines",
                            url: "https://listenbrainz.org"
                        },
                        {
                            title: "Libre.fm",
                            subtitle: "Free software music scrobbling network (GNU FM)",
                            icon: "radio",
                            url: "https://libre.fm"
                        },
                        {
                            title: "GitHub",
                            subtitle: "Release update checks (github.com)",
                            icon: "external-link",
                            url: "https://github.com"
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 14
                        color: credMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: credMouse.containsMouse ? 1.5 : 1.0
                        border.color: credMouse.containsMouse ? recordRed : borderSubtle

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            LucideIcon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                icon: modelData.icon
                                color: credMouse.containsMouse ? recordRedHover : textPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.title
                                    color: credMouse.containsMouse ? recordRedHover : textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    text: modelData.subtitle
                                    color: textSecondary
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            LucideIcon {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                icon: "external-link"
                                color: credMouse.containsMouse ? recordRedHover : silverDim
                            }
                        }

                        MouseArea {
                            id: credMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "CORE AUDIO & ARCHITECTURE"
                    color: recordRedHover
                    font.family: monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Repeater {
                    model: [
                        {
                            title: "AutoEq",
                            subtitle: "Calibrated headphone equalizer response curves by Jaakko Pasanen",
                            icon: "audio-lines",
                            url: "https://github.com/jaakkopasanen/AutoEq"
                        },
                        {
                            title: "Qt Multimedia",
                            subtitle: "Hardware audio playback, streaming, and audio sinks",
                            icon: "music",
                            url: "https://doc.qt.io/qt-6/qtmultimedia-index.html"
                        },
                        {
                            title: "Qt Network",
                            subtitle: "High-performance HTTP/REST client for lyrics and data sync",
                            icon: "globe",
                            url: "https://doc.qt.io/qt-6/qtnetwork-index.html"
                        },
                        {
                            title: "TagLib",
                            subtitle: "Audio metadata and embedded ID3/MP4/FLAC tag parser",
                            icon: "info",
                            url: "https://taglib.org"
                        },
                        {
                            title: "DWM Windows Frameless",
                            subtitle: "Hardware-accelerated Windows Desktop Window Manager composition",
                            icon: "shield",
                            url: "https://learn.microsoft.com/en-us/windows/win32/dwm/dwm-overview"
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 14
                        color: coreMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: coreMouse.containsMouse ? 1.5 : 1.0
                        border.color: coreMouse.containsMouse ? recordRed : borderSubtle

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            LucideIcon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                icon: modelData.icon
                                color: coreMouse.containsMouse ? recordRedHover : textPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.title
                                    color: coreMouse.containsMouse ? recordRedHover : textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    text: modelData.subtitle
                                    color: textSecondary
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            LucideIcon {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                icon: "external-link"
                                color: coreMouse.containsMouse ? recordRedHover : silverDim
                            }
                        }

                        MouseArea {
                            id: coreMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "DESIGN & TYPOGRAPHY"
                    color: recordRedHover
                    font.family: monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Repeater {
                    model: [
                        {
                            title: "Lucide Icons",
                            subtitle: "App logo & open-source iconography (lucide.dev, ISC License)",
                            icon: "info",
                            url: "https://lucide.dev"
                        },
                        {
                            title: "Simple Icons",
                            subtitle: "Authentic brand SVG icons (simpleicons.org, CC0 1.0)",
                            icon: "shield",
                            url: "https://simpleicons.org"
                        },
                        {
                            title: "IBM Plex (Sans & Mono)",
                            subtitle: "Designed by Mike Abbink and Bold Monday for IBM (OFL 1.1)",
                            icon: "info",
                            url: "https://github.com/IBM/plex"
                        },
                        {
                            title: "Space Grotesk",
                            subtitle: "Proportional monospace display typeface by Florian Karsten (OFL 1.1)",
                            icon: "info",
                            url: "https://github.com/floriankarsten/space-grotesk"
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        radius: 14
                        color: desMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: desMouse.containsMouse ? 1.5 : 1.0
                        border.color: desMouse.containsMouse ? recordRed : borderSubtle

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 14

                            LucideIcon {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                icon: modelData.icon
                                color: desMouse.containsMouse ? recordRedHover : textPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: modelData.title
                                    color: desMouse.containsMouse ? recordRedHover : textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Label {
                                    text: modelData.subtitle
                                    color: textSecondary
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            LucideIcon {
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                icon: "external-link"
                                color: desMouse.containsMouse ? recordRedHover : silverDim
                            }
                        }

                        MouseArea {
                            id: desMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.url)
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "OPEN SOURCE LICENSE"
                    color: recordRedHover
                    font.family: monoFont
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 14
                    color: licMouse.containsMouse ? surfaceElevated : surfaceCard
                    border.width: licMouse.containsMouse ? 1.5 : 1.0
                    border.color: licMouse.containsMouse ? recordRed : borderSubtle

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 14

                        LucideIcon {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            icon: "shield"
                            color: licMouse.containsMouse ? recordRedHover : textPrimary
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "GNU General Public License v3.0"
                                color: licMouse.containsMouse ? recordRedHover : textPrimary
                                font.family: displayFont
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Label {
                                text: "View source code and contribute on GitHub"
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        LucideIcon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            icon: "external-link"
                            color: licMouse.containsMouse ? recordRedHover : silverDim
                        }
                    }

                    MouseArea {
                        id: licMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally("https://github.com/samyyy2311/CassetteCat")
                    }
                }
            }

            Item { Layout.preferredHeight: 32 }
        }
    }
}
