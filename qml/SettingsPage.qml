import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int trackCount: 0
    property string libraryFolder: ""
    property var excludedFolders: []
    property bool ignoreShortClips: false
    property string defaultLaunchPage: "last"
    property string songSortMetric: "title"
    property string trackDensity: "comfortable"
    property bool showFormatBadges: true
    property string accentName: "recordRed"
    property string customAccentColor: "#C23B30"
    property int albumArtRadius: 16
    property string nowPlayingBackdrop: "tinted"
    property bool showRemainingTime: true
    property bool resumeQueueOnLaunch: true
    property bool globalShortcutsEnabled: false
    property bool globalShortcutsSupported: false
    property string globalShortcutStatus: ""
    property var globalShortcutBindings: ({})
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: "Off"
    property bool sleepFadeOut: true
    property bool autoplayEnabled: false
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80
    property bool closeToTray: true
    property bool startMinimizedToTray: false
    property string nowPlayingNotifications: "minimized"
    property bool trayAvailable: true
    property bool miniPlayerAlwaysOnTop: true
    property int lyricsFontSize: 28
    property string lyricsAlignment: "left"
    property string lyricsActiveStyle: "white"
    property bool preferLocalLyrics: true
    property bool offlineBlackout: false
    property bool svcLrclib: true
    property bool svcRadio: true
    property bool svcDeezer: true
    property bool svcAudiodb: true
    property bool svcWiki: true
    property string backupStatus: ""
    property bool creditsOpen: false
    property string currentSection: "library"

    readonly property var categories: [
        { id: "library", label: "Music Library", icon: "folder" },
        { id: "appearance", label: "Appearance", icon: "sliders-horizontal" },
        { id: "playback", label: "Playback", icon: "play" },
        { id: "desktop", label: "Desktop", icon: "pip" },
        { id: "lyrics", label: "Lyrics", icon: "quote" },
        { id: "network", label: "Network & Privacy", icon: "shield" },
        { id: "data", label: "Backup & Data", icon: "refresh-cw" },
        { id: "credits", label: "Credits", icon: "info" }
    ]

    signal chooseFolderRequested()
    signal backRequested()
    signal resumeQueueOnLaunchSelected(bool value)
    signal globalShortcutsEnabledSelected(bool value)
    signal globalShortcutSelected(string action, string shortcut)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal lyricsFontSizeSelected(int value)
    signal defaultLaunchPageSelected(string value)
    signal addExcludeRequested()
    signal removeExcludeRequested(string path)
    signal ignoreShortClipsSelected(bool value)
    signal songSortSelected(string value)
    signal trackDensitySelected(string value)
    signal showFormatBadgesSelected(bool value)
    signal accentSelected(string value)
    signal customAccentSelected(string hexColor)
    signal albumArtRadiusSelected(int value)
    signal nowPlayingBackdropSelected(string value)
    signal showRemainingTimeSelected(bool value)
    signal sleepTimerSelected(string value)
    signal sleepTimerCancelled()
    signal sleepFadeOutSelected(bool value)
    signal autoplaySelected(bool value)
    signal volumeLimitSelected(bool value)
    signal maxVolumeSelected(int value)
    signal preferLocalLyricsSelected(bool value)
    signal lyricsAlignmentSelected(string value)
    signal lyricsActiveStyleSelected(string value)
    signal offlineBlackoutSelected(bool value)
    signal serviceToggleRequested(string name, bool value)
    signal openJellyfinRequested()
    signal openSubsonicRequested()
    signal exportBackupRequested()
    signal importBackupRequested()
    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)

    function chooseSection(id) {
        if (id === "credits") {
            creditsOpen = true
            return
        }
        creditsOpen = false
        currentSection = id
        contentScroll.contentItem.contentY = 0
    }

    StackLayout {
        anchors.fill: parent
        currentIndex: root.creditsOpen ? 1 : 0

        Item {
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 32
                    Layout.rightMargin: 32
                    Layout.topMargin: 24
                    Layout.bottomMargin: 20
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "Settings"
                            color: textPrimary
                            font.family: displayFont
                            font.pixelSize: 28
                            font.weight: Font.Bold
                        }

                        Label {
                            text: root.trackCount > 0
                                ? root.trackCount + " tracks in your library"
                                : "Playback, library, and privacy preferences"
                            color: textSecondary
                            font.family: bodyFont
                            font.pixelSize: 12
                        }
                    }

                    Label {
                        text: "Changes save immediately"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: borderSubtle
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property bool compact: width < 840

                    Flickable {
                        id: compactNav
                        visible: parent.compact
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 24
                        anchors.rightMargin: 24
                        height: 48
                        contentWidth: compactRow.implicitWidth
                        clip: true

                        Row {
                            id: compactRow
                            spacing: 6

                            Repeater {
                                model: root.categories

                                delegate: Rectangle {
                                    readonly property bool selected: root.currentSection === modelData.id && modelData.id !== "credits"
                                    width: compactLabel.implicitWidth + 24
                                    height: 32
                                    radius: 16
                                    color: selected ? recordRed : "transparent"
                                    border.width: selected ? 0 : 1
                                    border.color: borderSubtle

                                    Label {
                                        id: compactLabel
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: parent.selected ? "white" : textSecondary
                                        font.family: displayFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.chooseSection(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: navigation
                        visible: !parent.compact
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        width: 184
                        spacing: 3

                        Repeater {
                            model: root.categories

                            delegate: Rectangle {
                                readonly property bool selected: root.currentSection === modelData.id && modelData.id !== "credits"
                                width: navigation.width
                                height: 38
                                radius: 8
                                color: selected ? surfaceCard : (navMouse.containsMouse ? surfaceCardHover : "transparent")

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    LucideIcon {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16
                                        icon: modelData.icon
                                        color: parent.parent.selected ? recordRedHover : silverDim
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        color: parent.parent.selected ? textPrimary : textSecondary
                                        font.family: displayFont
                                        font.pixelSize: 12
                                        font.weight: parent.parent.selected ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: navMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.chooseSection(modelData.id)
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: !parent.compact
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: navigation.right
                        anchors.leftMargin: 20
                        width: 1
                        color: borderSubtle
                    }

                    ScrollView {
                        id: contentScroll
                        anchors.top: parent.compact ? compactNav.bottom : parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.compact ? parent.left : navigation.right
                        anchors.leftMargin: parent.compact ? 24 : 40
                        anchors.right: parent.right
                        anchors.rightMargin: 24
                        clip: true
                        contentWidth: availableWidth
                        contentHeight: sectionContent.implicitHeight + 48
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        ScrollBar.vertical: SleekScrollBar {}

                        ColumnLayout {
                            id: sectionContent
                            x: Math.max(0, (contentScroll.availableWidth - width) / 2)
                            width: Math.min(contentScroll.availableWidth - 20, 960)
                            spacing: 18

                            SettingsLibrarySection {
                                visible: root.currentSection === "library"
                                trackCount: root.trackCount
                                libraryFolder: root.libraryFolder
                                excludedFolders: root.excludedFolders
                                ignoreShortClips: root.ignoreShortClips
                                defaultLaunchPage: root.defaultLaunchPage
                                songSortMetric: root.songSortMetric
                                trackDensity: root.trackDensity
                                showFormatBadges: root.showFormatBadges
                                onChooseFolderRequested: root.chooseFolderRequested()
                                onAddExcludeRequested: root.addExcludeRequested()
                                onRemoveExcludeRequested: path => root.removeExcludeRequested(path)
                                onIgnoreShortClipsSelected: value => root.ignoreShortClipsSelected(value)
                                onDefaultLaunchPageSelected: value => root.defaultLaunchPageSelected(value)
                                onSongSortSelected: value => root.songSortSelected(value)
                                onTrackDensitySelected: value => root.trackDensitySelected(value)
                                onShowFormatBadgesSelected: value => root.showFormatBadgesSelected(value)
                            }

                            SettingsAppearanceSection {
                                visible: root.currentSection === "appearance"
                                accentName: root.accentName
                                customAccentColor: root.customAccentColor
                                albumArtRadius: root.albumArtRadius
                                nowPlayingBackdrop: root.nowPlayingBackdrop
                                showRemainingTime: root.showRemainingTime
                                onAccentSelected: value => root.accentSelected(value)
                                onCustomAccentSelected: value => root.customAccentSelected(value)
                                onAlbumArtRadiusSelected: value => root.albumArtRadiusSelected(value)
                                onNowPlayingBackdropSelected: value => root.nowPlayingBackdropSelected(value)
                                onShowRemainingTimeSelected: value => root.showRemainingTimeSelected(value)
                            }

                            SettingsPlaybackSection {
                                visible: root.currentSection === "playback"
                                resumeQueueOnLaunch: root.resumeQueueOnLaunch
                                autoplayEnabled: root.autoplayEnabled
                                globalShortcutsEnabled: root.globalShortcutsEnabled
                                globalShortcutsSupported: root.globalShortcutsSupported
                                globalShortcutStatus: root.globalShortcutStatus
                                globalShortcutBindings: root.globalShortcutBindings
                                sleepTimerMode: root.sleepTimerMode
                                sleepTimerStatus: root.sleepTimerStatus
                                sleepFadeOut: root.sleepFadeOut
                                volumeLimitEnabled: root.volumeLimitEnabled
                                maxVolumePercent: root.maxVolumePercent
                                onResumeQueueOnLaunchSelected: value => root.resumeQueueOnLaunchSelected(value)
                                onAutoplaySelected: value => root.autoplaySelected(value)
                                onGlobalShortcutsEnabledSelected: value => root.globalShortcutsEnabledSelected(value)
                                onGlobalShortcutSelected: (action, shortcut) => root.globalShortcutSelected(action, shortcut)
                                onSleepTimerSelected: value => root.sleepTimerSelected(value)
                                onSleepTimerCancelled: root.sleepTimerCancelled()
                                onSleepFadeOutSelected: value => root.sleepFadeOutSelected(value)
                                onVolumeLimitSelected: value => root.volumeLimitSelected(value)
                                onMaxVolumeSelected: value => root.maxVolumeSelected(value)
                            }

                            SettingsDesktopSection {
                                visible: root.currentSection === "desktop"
                                closeToTray: root.closeToTray
                                startMinimizedToTray: root.startMinimizedToTray
                                nowPlayingNotifications: root.nowPlayingNotifications
                                miniPlayerAlwaysOnTop: root.miniPlayerAlwaysOnTop
                                trayAvailable: root.trayAvailable
                                onCloseToTraySelected: value => root.closeToTraySelected(value)
                                onStartMinimizedToTraySelected: value => root.startMinimizedToTraySelected(value)
                                onNowPlayingNotificationsSelected: value => root.nowPlayingNotificationsSelected(value)
                                onMiniPlayerAlwaysOnTopSelected: value => root.miniPlayerAlwaysOnTopSelected(value)
                            }

                            SettingsLyricsSection {
                                visible: root.currentSection === "lyrics"
                                lyricsFontSize: root.lyricsFontSize
                                lyricsAlignment: root.lyricsAlignment
                                lyricsActiveStyle: root.lyricsActiveStyle
                                preferLocalLyrics: root.preferLocalLyrics
                                onLyricsFontSizeSelected: value => root.lyricsFontSizeSelected(value)
                                onLyricsAlignmentSelected: value => root.lyricsAlignmentSelected(value)
                                onLyricsActiveStyleSelected: value => root.lyricsActiveStyleSelected(value)
                                onPreferLocalLyricsSelected: value => root.preferLocalLyricsSelected(value)
                            }

                            SettingsNetworkSection {
                                visible: root.currentSection === "network"
                                offlineBlackout: root.offlineBlackout
                                svcLrclib: root.svcLrclib
                                svcRadio: root.svcRadio
                                svcDeezer: root.svcDeezer
                                svcAudiodb: root.svcAudiodb
                                svcWiki: root.svcWiki
                                onOfflineBlackoutSelected: value => root.offlineBlackoutSelected(value)
                                onServiceToggleRequested: (name, value) => root.serviceToggleRequested(name, value)
                                onOpenJellyfinRequested: root.openJellyfinRequested()
                                onOpenSubsonicRequested: root.openSubsonicRequested()
                            }

                            SettingsBackupSection {
                                visible: root.currentSection === "data"
                                backupStatus: root.backupStatus
                                onExportBackupRequested: root.exportBackupRequested()
                                onImportBackupRequested: root.importBackupRequested()
                            }
                        }
                    }
                }
            }
        }

        CreditsView {
            onBackClicked: root.creditsOpen = false
        }
    }
}
