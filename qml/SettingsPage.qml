import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    property int trackCount: 0
    property bool resumeQueueOnLaunch: true
    property bool miniPlayerAlwaysOnTop: true
    property int lyricsFontSize: 28
    property bool creditsOpen: false

    signal chooseFolderRequested()
    signal backRequested()
    signal resumeQueueOnLaunchSelected(bool value)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal lyricsFontSizeSelected(int value)

    // Centered readable column, matching CreditsView's max width.
    // On narrow windows this collapses to 32px side margins like Home.
    readonly property real maxContentWidth: 720

    StackLayout {
        anchors.fill: parent
        currentIndex: root.creditsOpen ? 1 : 0

        ScrollView {
            id: scroll
            clip: true
            contentWidth: availableWidth
            contentHeight: bodyCol.implicitHeight + 48
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical: SleekScrollBar {}

            Column {
                id: bodyCol
                width: scroll.availableWidth
                spacing: 26
                topPadding: 24
                bottomPadding: 36

                // ---- Header: same kicker / title / stats pattern as Home ----
                ColumnLayout {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    spacing: 4

                    Label {
                        text: "SETTINGS"
                        color: recordRed
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Label {
                        text: "Preferences & library"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 28
                        font.weight: Font.Bold
                        font.letterSpacing: -0.4
                    }
                    Label {
                        text: root.trackCount > 0
                              ? (root.trackCount + " songs in library • changes save automatically")
                              : "Scan a music folder to populate your library"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 11
                    }
                }

                // ---- Music library ----
                ColumnLayout {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    spacing: 10

                    SectionLabel { text: "MUSIC LIBRARY" }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: libRow.implicitHeight + 32
                        radius: 12
                        color: surfaceCard
                        border.width: 1
                        border.color: borderSubtle

                        RowLayout {
                            id: libRow
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 16
                            anchors.bottomMargin: 16
                            spacing: 14

                            IconBadge {
                                Layout.alignment: Qt.AlignVCenter
                                iconName: "folder"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Label {
                                    Layout.fillWidth: true
                                    text: "Audio Directory"
                                    color: textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: root.trackCount + " tracks loaded from library"
                                    color: textSecondary
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: chooseLbl.implicitWidth + 28
                                Layout.preferredHeight: 34
                                radius: 17
                                color: chooseMouse.containsMouse ? "#20FF3344" : "transparent"
                                border.width: 1.5
                                border.color: recordRed

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Label {
                                    id: chooseLbl
                                    anchors.centerIn: parent
                                    text: "Choose folder"
                                    color: recordRedHover
                                    font.family: displayFont
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: chooseMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.chooseFolderRequested()
                                }
                            }
                        }
                    }
                }

                // ---- Playback: grouped rows with inset divider ----
                ColumnLayout {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    spacing: 10

                    SectionLabel { text: "PLAYBACK" }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: playCol.implicitHeight
                        radius: 12
                        color: surfaceCard
                        border.width: 1
                        border.color: borderSubtle

                        ColumnLayout {
                            id: playCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 8
                            anchors.bottomMargin: 8
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 64
                                spacing: 14

                                IconBadge {
                                    Layout.alignment: Qt.AlignVCenter
                                    iconName: "play"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Resume Queue on Launch"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: "Restore the active track, position, and queue"
                                        color: textSecondary
                                        font.family: bodyFont
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6
                                    SettingsChoicePill { label: "ON"; selected: root.resumeQueueOnLaunch; onClicked: root.resumeQueueOnLaunchSelected(true) }
                                    SettingsChoicePill { label: "OFF"; selected: !root.resumeQueueOnLaunch; onClicked: root.resumeQueueOnLaunchSelected(false) }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 54
                                Layout.preferredHeight: 1
                                color: borderSubtle
                                opacity: 0.7
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 64
                                spacing: 14

                                IconBadge {
                                    Layout.alignment: Qt.AlignVCenter
                                    iconName: "pip"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Keep Mini Player on Top"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: "Keep the compact player visible above other windows"
                                        color: textSecondary
                                        font.family: bodyFont
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }

                                Row {
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 6
                                    SettingsChoicePill { label: "ON"; selected: root.miniPlayerAlwaysOnTop; onClicked: root.miniPlayerAlwaysOnTopSelected(true) }
                                    SettingsChoicePill { label: "OFF"; selected: !root.miniPlayerAlwaysOnTop; onClicked: root.miniPlayerAlwaysOnTopSelected(false) }
                                }
                            }
                        }
                    }
                }

                // ---- Lyrics: vertical card so pills wrap on narrow windows ----
                ColumnLayout {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    spacing: 10

                    SectionLabel { text: "LYRICS" }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: lyricsCol.implicitHeight + 32
                        radius: 12
                        color: surfaceCard
                        border.width: 1
                        border.color: borderSubtle

                        ColumnLayout {
                            id: lyricsCol
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 16
                            anchors.bottomMargin: 16
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14

                                IconBadge {
                                    Layout.alignment: Qt.AlignVCenter
                                    iconName: "quote"
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 2

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Lyrics Text Size"
                                        color: textPrimary
                                        font.family: displayFont
                                        font.pixelSize: 14
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: "Choose the scale used in the lyrics view"
                                        color: textSecondary
                                        font.family: bodyFont
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8
                                SettingsChoicePill { label: "SMALL"; selected: root.lyricsFontSize === 24; onClicked: root.lyricsFontSizeSelected(24) }
                                SettingsChoicePill { label: "DEFAULT"; selected: root.lyricsFontSize === 28; onClicked: root.lyricsFontSizeSelected(28) }
                                SettingsChoicePill { label: "LARGE"; selected: root.lyricsFontSize === 32; onClicked: root.lyricsFontSizeSelected(32) }
                            }
                        }
                    }
                }

                // ---- About: same hover treatment as CreditsView cards ----
                ColumnLayout {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    spacing: 10

                    SectionLabel { text: "ABOUT & ACKNOWLEDGEMENTS" }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: aboutRow.implicitHeight + 32
                        radius: 12
                        color: aboutMouse.containsMouse ? surfaceElevated : surfaceCard
                        border.width: aboutMouse.containsMouse ? 1.5 : 1
                        border.color: aboutMouse.containsMouse ? recordRed : borderSubtle

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: aboutRow
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 16
                            anchors.bottomMargin: 16
                            spacing: 14

                            IconBadge {
                                Layout.alignment: Qt.AlignVCenter
                                iconName: "info"
                                iconColor: aboutMouse.containsMouse ? recordRedHover : textPrimary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Label {
                                    Layout.fillWidth: true
                                    text: "Credits & Open Source Services"
                                    color: aboutMouse.containsMouse ? recordRedHover : textPrimary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }
                                Label {
                                    Layout.fillWidth: true
                                    text: "LRCLIB, Cover Art Archive, MusicBrainz, Radio Browser, Wikipedia, and more"
                                    color: textSecondary
                                    font.family: bodyFont
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }
                            }

                            LucideIcon {
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16
                                Layout.alignment: Qt.AlignVCenter
                                icon: "chevron-down"
                                rotation: -90
                                color: aboutMouse.containsMouse ? recordRedHover : silverDim
                            }
                        }

                        MouseArea {
                            id: aboutMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.creditsOpen = true
                        }
                    }
                }

                Label {
                    x: (scroll.availableWidth - width) / 2
                    width: Math.min(scroll.availableWidth - 64, root.maxContentWidth)
                    horizontalAlignment: Text.AlignHCenter
                    text: "Preferences save automatically • GPL-3.0"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    opacity: 0.75
                }
            }
        }

        CreditsView {
            onBackClicked: root.creditsOpen = false
        }
    }

    component SectionLabel: Label {
        color: recordRedHover
        font.family: monoFont
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.8
    }

    component IconBadge: Rectangle {
        property string iconName: "settings"
        property color iconColor: recordRedHover

        implicitWidth: 40
        implicitHeight: 40
        radius: 10
        color: surfaceElevated
        border.width: 1
        border.color: borderVariant

        LucideIcon {
            anchors.centerIn: parent
            width: 20
            height: 20
            icon: parent.iconName
            color: parent.iconColor
        }
    }
}
