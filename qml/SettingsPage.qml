import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property int trackCount: 0
    property var libraryFolders: []
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
    property var inAppShortcutBindings: ({})
    property var inAppShortcutActions: []
    property string inAppShortcutStatus: ""
    property string sleepTimerMode: "off"
    property string sleepTimerStatus: "Off"
    property bool sleepFadeOut: true
    property bool autoplayEnabled: false
    property bool volumeLimitEnabled: false
    property int maxVolumePercent: 80
    property string replayGainMode: "off"
    property bool closeToTray: false
    property bool startMinimizedToTray: false
    property string nowPlayingNotifications: "minimized"
    property bool trayAvailable: true
    property var audioOutputs: []
    property string audioDeviceId: ""
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
    property bool svcArchive: true
    property string backupStatus: ""
    property string currentSection: "library"
    property bool scrobbleListenBrainzEnabled: false
    property string scrobbleListenBrainzUser: ""
    property bool scrobbleListenBrainzConnected: false
    property bool scrobbleLibreFmEnabled: false
    property string scrobbleLibreFmUser: ""
    property bool scrobbleLibreFmConnected: false
    property string updateStatusText: "Current version: v0.6.0"
    property bool updateChecking: false
    property bool updateAvailable: false
    property string updateUrl: ""

    readonly property var categories: [
        { id: "library", label: "Music Library", icon: "library" },
        { id: "appearance", label: "Appearance", icon: "sliders-horizontal" },
        { id: "playback", label: "Playback & Audio", icon: "play" },
        { id: "shortcuts", label: "Keyboard Shortcuts", icon: "keyboard" },
        { id: "desktop", label: "General & System", icon: "settings" },
        { id: "lyrics", label: "Lyrics", icon: "mic" },
        { id: "scrobble", label: "Scrobbling", icon: "audio-lines" },
        { id: "network", label: "Network & Services", icon: "globe" },
        { id: "data", label: "Backup & Diagnostics", icon: "refresh-cw" },
        { id: "credits", label: "Credits & Legal", icon: "info" }
    ]

    readonly property real activeSectionHeight: {
        switch (currentSection) {
            case "library": return secLibrary.implicitHeight
            case "appearance": return secAppearance.implicitHeight
            case "playback": return secPlayback.implicitHeight
            case "shortcuts": return secShortcuts.implicitHeight
            case "desktop": return secDesktop.implicitHeight
            case "lyrics": return secLyrics.implicitHeight
            case "scrobble": return secScrobble.implicitHeight
            case "network": return secNetwork.implicitHeight
            case "data": return secBackup.implicitHeight
            case "credits": return secCredits.implicitHeight
            default: return 600
        }
    }

    signal addLibraryFolderRequested()
    signal removeLibraryFolderRequested(string path)
    signal addExcludeRequested()
    signal removeExcludeRequested(string path)
    signal ignoreShortClipsSelected(bool value)
    signal defaultLaunchPageSelected(string value)
    signal songSortSelected(string value)
    signal trackDensitySelected(string value)
    signal showFormatBadgesSelected(bool value)
    signal accentSelected(string value)
    signal customAccentSelected(string value)
    signal albumArtRadiusSelected(int value)
    signal nowPlayingBackdropSelected(string value)
    signal showRemainingTimeSelected(bool value)
    signal resumeQueueOnLaunchSelected(bool value)
    signal autoplaySelected(bool value)
    signal sleepTimerSelected(string value)
    signal sleepTimerCancelled()
    signal sleepFadeOutSelected(bool value)
    signal volumeLimitSelected(bool value)
    signal maxVolumeSelected(int value)
    signal replayGainModeSelected(string value)
    signal globalShortcutsEnabledSelected(bool value)
    signal globalShortcutSelected(string action, string shortcut)
    signal inAppShortcutSelected(string action, string shortcut)
    signal lyricsFontSizeSelected(int value)
    signal lyricsAlignmentSelected(string value)
    signal lyricsActiveStyleSelected(string value)
    signal preferLocalLyricsSelected(bool value)
    signal offlineBlackoutSelected(bool value)
    signal serviceToggleRequested(string service, bool enabled)
    signal openJellyfinRequested()
    signal openSubsonicRequested()
    signal exportBackupRequested()
    signal importBackupRequested()
    signal audioDeviceSelected(string id)
    signal miniPlayerAlwaysOnTopSelected(bool value)
    signal closeToTraySelected(bool value)
    signal startMinimizedToTraySelected(bool value)
    signal nowPlayingNotificationsSelected(string value)
    signal scrobbleListenBrainzToggled(bool value)
    signal disconnectListenBrainzRequested()
    signal scrobbleLibreFmToggled(bool value)
    signal disconnectLibreFmRequested()
    signal checkUpdatesRequested()
    signal downloadUpdateRequested()
    signal sectionSelected(string section)

    property string pendingSection: ""

    function chooseSection(id) {
        if (currentSection === id) return
        pendingSection = id
        sectionFadeAnim.restart()
    }

    SequentialAnimation {
        id: sectionFadeAnim
        NumberAnimation { target: sectionContent; property: "opacity"; to: 0.0; duration: 70; easing.type: Easing.OutQuad }
        ScriptAction {
            script: {
                currentSection = pendingSection
                if (contentScroll) contentScroll.contentY = 0
                sectionSelected(pendingSection)
            }
        }
        NumberAnimation { target: sectionContent; property: "opacity"; to: 1.0; duration: 150; easing.type: Easing.OutCubic }
    }

    Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 28
            anchors.rightMargin: 28
            anchors.topMargin: 14
            anchors.bottomMargin: 16
            spacing: 0

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
                    height: 48
                    contentWidth: compactRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    pixelAligned: UiConstants.pixelAligned

                    Row {
                        id: compactRow
                        spacing: 6

                        Repeater {
                            model: root.categories

                            delegate: SettingsNavigationItem {
                                label: modelData.label
                                iconName: modelData.icon
                                compact: true
                                selected: root.currentSection === modelData.id
                                onClicked: root.chooseSection(modelData.id)
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
                    anchors.topMargin: 4
                    anchors.bottomMargin: 8
                    width: 184
                    spacing: 6

                    Repeater {
                        model: root.categories

                        delegate: SettingsNavigationItem {
                            width: navigation.width
                            label: modelData.label
                            iconName: modelData.icon
                            selected: root.currentSection === modelData.id
                            onClicked: root.chooseSection(modelData.id)
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
                    color: Qt.rgba(255, 255, 255, 0.05)
                }

                Flickable {
                    id: contentScroll
                    readonly property real availableWidth: width
                    anchors.top: parent.compact ? compactNav.bottom : parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.compact ? parent.left : navigation.right
                    anchors.leftMargin: parent.compact ? 0 : 32
                    anchors.right: parent.right
                    anchors.rightMargin: 0
                    clip: true
                    contentWidth: availableWidth
                    contentHeight: Math.max(height, sectionContent.implicitHeight + 48)
                    flickableDirection: Flickable.VerticalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: UiConstants.flickDeceleration
                    maximumFlickVelocity: UiConstants.maximumFlickVelocity
                    pixelAligned: UiConstants.pixelAligned
                    ScrollBar.vertical: AutoHideScrollBar {}

                        ColumnLayout {
                            id: sectionContent
                            opacity: 1.0
                            x: Math.max(0, (contentScroll.availableWidth - width) / 2)
                            width: Math.min(contentScroll.availableWidth - 20, 960)
                            spacing: 18

                            SettingsLibrarySection {
                                id: secLibrary
                                visible: root.currentSection === "library"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                trackCount: root.trackCount
                                libraryFolders: root.libraryFolders
                                excludedFolders: root.excludedFolders
                                ignoreShortClips: root.ignoreShortClips
                                songSortMetric: root.songSortMetric
                                trackDensity: root.trackDensity
                                showFormatBadges: root.showFormatBadges
                                onAddLibraryFolderRequested: root.addLibraryFolderRequested()
                                onRemoveLibraryFolderRequested: path => root.removeLibraryFolderRequested(path)
                                onAddExcludeRequested: root.addExcludeRequested()
                                onRemoveExcludeRequested: path => root.removeExcludeRequested(path)
                                onIgnoreShortClipsSelected: value => root.ignoreShortClipsSelected(value)
                                onSongSortSelected: value => root.songSortSelected(value)
                                onTrackDensitySelected: value => root.trackDensitySelected(value)
                                onShowFormatBadgesSelected: value => root.showFormatBadgesSelected(value)
                            }

                            SettingsAppearanceSection {
                                id: secAppearance
                                visible: root.currentSection === "appearance"
                                Layout.preferredHeight: visible ? implicitHeight : 0
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
                                id: secPlayback
                                visible: root.currentSection === "playback"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                audioOutputs: root.audioOutputs
                                audioDeviceId: root.audioDeviceId
                                resumeQueueOnLaunch: root.resumeQueueOnLaunch
                                autoplayEnabled: root.autoplayEnabled
                                sleepTimerMode: root.sleepTimerMode
                                sleepTimerStatus: root.sleepTimerStatus
                                sleepFadeOut: root.sleepFadeOut
                                volumeLimitEnabled: root.volumeLimitEnabled
                                maxVolumePercent: root.maxVolumePercent
                                replayGainMode: root.replayGainMode
                                onAudioDeviceSelected: value => root.audioDeviceSelected(value)
                                onResumeQueueOnLaunchSelected: value => root.resumeQueueOnLaunchSelected(value)
                                onAutoplaySelected: value => root.autoplaySelected(value)
                                onSleepTimerSelected: value => root.sleepTimerSelected(value)
                                onSleepTimerCancelled: root.sleepTimerCancelled()
                                onSleepFadeOutSelected: value => root.sleepFadeOutSelected(value)
                                onVolumeLimitSelected: value => root.volumeLimitSelected(value)
                                onMaxVolumeSelected: value => root.maxVolumeSelected(value)
                                onReplayGainModeSelected: value => root.replayGainModeSelected(value)
                            }

                            SettingsShortcutsSection {
                                id: secShortcuts
                                visible: root.currentSection === "shortcuts"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                globalShortcutsEnabled: root.globalShortcutsEnabled
                                globalShortcutsSupported: root.globalShortcutsSupported
                                globalShortcutStatus: root.globalShortcutStatus
                                globalShortcutBindings: root.globalShortcutBindings
                                inAppShortcutBindings: root.inAppShortcutBindings
                                inAppActions: root.inAppShortcutActions
                                inAppShortcutStatus: root.inAppShortcutStatus
                                onGlobalShortcutsEnabledSelected: value => root.globalShortcutsEnabledSelected(value)
                                onGlobalShortcutSelected: (action, shortcut) => root.globalShortcutSelected(action, shortcut)
                                onInAppShortcutSelected: (action, shortcut) => root.inAppShortcutSelected(action, shortcut)
                            }

                            SettingsDesktopSection {
                                id: secDesktop
                                visible: root.currentSection === "desktop"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                defaultLaunchPage: root.defaultLaunchPage
                                closeToTray: root.closeToTray
                                startMinimizedToTray: root.startMinimizedToTray
                                nowPlayingNotifications: root.nowPlayingNotifications
                                miniPlayerAlwaysOnTop: root.miniPlayerAlwaysOnTop
                                trayAvailable: root.trayAvailable
                                updateStatusText: root.updateStatusText
                                updateChecking: root.updateChecking
                                updateAvailable: root.updateAvailable
                                updateUrl: root.updateUrl
                                onDefaultLaunchPageSelected: value => root.defaultLaunchPageSelected(value)
                                onCloseToTraySelected: value => root.closeToTraySelected(value)
                                onStartMinimizedToTraySelected: value => root.startMinimizedToTraySelected(value)
                                onNowPlayingNotificationsSelected: value => root.nowPlayingNotificationsSelected(value)
                                onMiniPlayerAlwaysOnTopSelected: value => root.miniPlayerAlwaysOnTopSelected(value)
                                onCheckUpdatesRequested: root.checkUpdatesRequested()
                                onDownloadUpdateRequested: root.downloadUpdateRequested()
                            }

                            SettingsLyricsSection {
                                id: secLyrics
                                visible: root.currentSection === "lyrics"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                lyricsFontSize: root.lyricsFontSize
                                lyricsAlignment: root.lyricsAlignment
                                lyricsActiveStyle: root.lyricsActiveStyle
                                preferLocalLyrics: root.preferLocalLyrics
                                onLyricsFontSizeSelected: value => root.lyricsFontSizeSelected(value)
                                onLyricsAlignmentSelected: value => root.lyricsAlignmentSelected(value)
                                onLyricsActiveStyleSelected: value => root.lyricsActiveStyleSelected(value)
                                onPreferLocalLyricsSelected: value => root.preferLocalLyricsSelected(value)
                            }

                            SettingsScrobbleSection {
                                id: secScrobble
                                visible: root.currentSection === "scrobble"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                offlineBlackout: root.offlineBlackout
                                listenBrainzEnabled: root.scrobbleListenBrainzEnabled
                                listenBrainzUser: root.scrobbleListenBrainzUser
                                listenBrainzConnected: root.scrobbleListenBrainzConnected
                                libreFmEnabled: root.scrobbleLibreFmEnabled
                                libreFmUser: root.scrobbleLibreFmUser
                                libreFmConnected: root.scrobbleLibreFmConnected
                                onListenBrainzEnabledToggled: value => root.scrobbleListenBrainzToggled(value)
                                onDisconnectListenBrainzRequested: root.disconnectListenBrainzRequested()
                                onLibreFmEnabledToggled: value => root.scrobbleLibreFmToggled(value)
                                onDisconnectLibreFmRequested: root.disconnectLibreFmRequested()
                            }

                            SettingsNetworkSection {
                                id: secNetwork
                                visible: root.currentSection === "network"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                offlineBlackout: root.offlineBlackout
                                svcLrclib: root.svcLrclib
                                svcRadio: root.svcRadio
                                svcDeezer: root.svcDeezer
                                svcAudiodb: root.svcAudiodb
                                svcWiki: root.svcWiki
                                svcArchive: root.svcArchive
                                onOfflineBlackoutSelected: value => root.offlineBlackoutSelected(value)
                                onServiceToggleRequested: (name, value) => root.serviceToggleRequested(name, value)
                                onOpenJellyfinRequested: root.openJellyfinRequested()
                                onOpenSubsonicRequested: root.openSubsonicRequested()
                            }

                            SettingsBackupSection {
                                id: secBackup
                                visible: root.currentSection === "data"
                                Layout.preferredHeight: visible ? implicitHeight : 0
                                backupStatus: root.backupStatus
                                onExportBackupRequested: root.exportBackupRequested()
                                onImportBackupRequested: root.importBackupRequested()
                            }

                            CreditsView {
                                id: secCredits
                                visible: root.currentSection === "credits"
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible ? implicitHeight : 0
                            }
                        }
                    }
                }
            }
    }
}
