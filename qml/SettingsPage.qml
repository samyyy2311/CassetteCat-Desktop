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
    property string accentName
    property string customAccentColor
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
    property string sleepTimerStatus: qsTr("Off")
    property bool sleepFadeOut: true
    property bool autoplayEnabled: false
    property int crossfadeSeconds: 0
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
    property bool svcDiscord: false
    property bool svcPhoneRemote: false
    property string backupStatus: ""
    property string currentSection: "library"
    property bool scrobbleListenBrainzEnabled: false
    property string scrobbleListenBrainzUser: ""
    property bool scrobbleListenBrainzConnected: false
    property bool scrobbleLibreFmEnabled: false
    property string scrobbleLibreFmUser: ""
    property bool scrobbleLibreFmConnected: false
    property bool scrobbleLastFmEnabled: false
    property string scrobbleLastFmUser: ""
    property bool scrobbleLastFmConnected: false
    property string updateStatusText: ""
    property bool updateChecking: false
    property bool updateAvailable: false
    property string updateUrl: ""

    property var appWindow
    property var tagScan

    readonly property var categories: [
        { id: "library", label: qsTr("Music Library"), icon: "library" },
        { id: "health", label: qsTr("Library Health"), icon: "list-music" },
        { id: "appearance", label: qsTr("Look & Feel"), icon: "sliders-horizontal" },
        { id: "sound", label: qsTr("Sound"), icon: "speaker" },
        { id: "playback", label: qsTr("Playback"), icon: "play" },
        { id: "shortcuts", label: qsTr("Keyboard Shortcuts"), icon: "keyboard" },
        { id: "desktop", label: qsTr("General & System"), icon: "settings" },
        { id: "lyrics", label: qsTr("Lyrics"), icon: "quote" },
        { id: "scrobble", label: qsTr("Scrobbling"), icon: "audio-lines" },
        { id: "network", label: qsTr("Network & Services"), icon: "globe" },
        { id: "phone", label: qsTr("Phone Remote"), icon: "smartphone" },
        { id: "data", label: qsTr("Backup & Diagnostics"), icon: "save" },
        { id: "credits", label: qsTr("Credits & Legal"), icon: "info" }
    ]

    readonly property real activeSectionHeight: {
        switch (currentSection) {
            case "library": return secLibrary.item ? secLibrary.item.implicitHeight : 0
            case "health": return secHealth.item ? secHealth.item.implicitHeight : 0
            case "appearance": return secAppearance.item ? secAppearance.item.implicitHeight : 0
            case "sound": return secSound.item ? secSound.item.implicitHeight : 0
            case "playback": return secPlayback.item ? secPlayback.item.implicitHeight : 0
            case "shortcuts": return secShortcuts.item ? secShortcuts.item.implicitHeight : 0
            case "desktop": return secDesktop.item ? secDesktop.item.implicitHeight : 0
            case "lyrics": return secLyrics.item ? secLyrics.item.implicitHeight : 0
            case "scrobble": return secScrobble.item ? secScrobble.item.implicitHeight : 0
            case "network": return secNetwork.item ? secNetwork.item.implicitHeight : 0
            case "phone": return secPhoneRemote.item ? secPhoneRemote.item.implicitHeight : 0
            case "data": return secBackup.item ? secBackup.item.implicitHeight : 0
            case "credits": return secCredits.item ? secCredits.item.implicitHeight : 0
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
    signal crossfadeSelected(int value)
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
    signal scrobbleLastFmToggled(bool value)
    signal disconnectLastFmRequested()
    signal checkUpdatesRequested()
    signal whatsNewRequested()
    signal downloadUpdateRequested()
    signal sectionSelected(string section)

    property string pendingSection: ""
    property var pendingRow: null
    // Typed in the search field in the window's title bar.
    readonly property string searchQuery: appWindow ? appWindow.settingsSearchQuery : ""
    // While searching, the results take the place of the section.
    readonly property string shownSection: searchQuery.trim() ? "" : currentSection
    readonly property var searchResults: findSettings(searchQuery)
    // Library Health lists songs and Credits lists projects, so those two are found by their names only.
    readonly property var searchableSections: ({
        library: secLibrary.item, appearance: secAppearance.item, sound: secSound.item, playback: secPlayback.item,
        shortcuts: secShortcuts.item, desktop: secDesktop.item, lyrics: secLyrics.item, scrobble: secScrobble.item,
        network: secNetwork.item, phone: secPhoneRemote.item, data: secBackup.item
    })

    // Only the open section is built with the page, so Settings opens quickly. The rest follow in the background, for
    // switching sections and searching.
    property bool buildAllSections: false
    Timer {
        interval: 600
        running: true
        onTriggered: root.buildAllSections = true
    }

    // Settings are read from the rows in each section, so a new setting is found without a list to keep up to date.
    function settingRows(item, found) {
        for (let i = 0; i < item.children.length; ++i) {
            const child = item.children[i]
            if (typeof child.title === "string" && typeof child.subtitle === "string" && child.title.length > 0)
                found.push(child)
            settingRows(child, found)
        }
        return found
    }

    function findSettings(query) {
        const words = query.toLowerCase().split(/\s+/).filter(word => word.length > 0)
        if (words.length === 0) return []
        const matches = text => words.every(word => text.toLowerCase().includes(word))
        const results = []
        categories.forEach(category => {
            if (matches(category.label))
                results.push({ section: category.id, sectionLabel: category.label, title: category.label, row: null })
            const section = searchableSections[category.id]
            if (!section) return
            const seen = {}
            settingRows(section, []).forEach(row => {
                if (seen[row.title] || !matches(row.title + " " + row.subtitle + " " + category.label)) return
                seen[row.title] = true
                results.push({ section: category.id, sectionLabel: category.label, title: row.title, row: row })
            })
        })
        return results
    }

    function openSearchResult(result) {
        pendingRow = result.row
        appWindow.clearSettingsSearch()
        if (currentSection === result.section) Qt.callLater(scrollToPendingRow)
        else chooseSection(result.section)
    }

    function scrollToPendingRow() {
        if (!pendingRow) return
        const top = pendingRow.mapToItem(sectionContent, 0, 0).y - 16
        contentScroll.contentY = Math.max(0, Math.min(top, contentScroll.contentHeight - contentScroll.height))
        pendingRow = null
    }

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
                if (pendingRow) Qt.callLater(root.scrollToPendingRow)
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
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                readonly property bool compact: width < 840

                AppFlickable {
                    id: compactNav
                    visible: parent.compact
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 48
                    contentWidth: compactRow.implicitWidth
                    clip: true

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

                AppFlickable {
                    id: navigation
                    visible: !parent.compact
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.topMargin: 4
                    anchors.bottomMargin: 8
                    width: 184
                    contentHeight: navigationColumn.implicitHeight
                    clip: true

                    Column {
                        id: navigationColumn
                        width: navigation.width
                        spacing: 6

                        Repeater {
                            model: root.categories

                            delegate: SettingsNavigationItem {
                                width: navigationColumn.width
                                label: modelData.label
                                iconName: modelData.icon
                                selected: root.currentSection === modelData.id
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
                    color: Qt.rgba(255, 255, 255, 0.05)
                }

                AppFlickable {
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
                    ScrollBar.vertical: AutoHideScrollBar {}

                        ColumnLayout {
                            id: sectionContent
                            opacity: 1.0
                            x: Math.max(0, (contentScroll.availableWidth - width) / 2)
                            width: Math.min(contentScroll.availableWidth - 20, 960)
                            spacing: 18

                            SectionLabel {
                                visible: root.searchQuery.trim() !== ""
                                text: root.searchResults.length > 0
                                      ? qsTr("%n Setting(s) Found", "", root.searchResults.length)
                                      : qsTr("No Settings Found")
                            }

                            SettingCard {
                                visible: root.searchResults.length > 0

                                Repeater {
                                    model: root.searchResults

                                    SettingRow {
                                        required property var modelData
                                        title: modelData.title
                                        subtitle: modelData.row ? modelData.sectionLabel : qsTr("Settings section")

                                        SettingButton {
                                            text: qsTr("Open")
                                            accessibleName: qsTr("Open %1").arg(modelData.title)
                                            onClicked: root.openSearchResult(modelData)
                                        }
                                    }
                                }
                            }

                            Loader {
                                id: secLibrary
                                readonly property bool shown: root.shownSection === "library"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsLibrarySection {
                                        trackCount: root.trackCount
                                        libraryFolders: root.libraryFolders
                                        excludedFolders: root.excludedFolders
                                        ignoreShortClips: root.ignoreShortClips
                                        songSortMetric: root.songSortMetric
                                        onAddLibraryFolderRequested: root.addLibraryFolderRequested()
                                        onRemoveLibraryFolderRequested: path => root.removeLibraryFolderRequested(path)
                                        onAddExcludeRequested: root.addExcludeRequested()
                                        onRemoveExcludeRequested: path => root.removeExcludeRequested(path)
                                        onIgnoreShortClipsSelected: value => root.ignoreShortClipsSelected(value)
                                        onSongSortSelected: value => root.songSortSelected(value)
                                    }
                                }
                            }

                            Loader {
                                id: secHealth
                                readonly property bool shown: root.shownSection === "health"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsLibraryHealthSection {
                                        appWindow: root.appWindow
                                        tagScan: root.tagScan
                                    }
                                }
                            }

                            Loader {
                                id: secAppearance
                                readonly property bool shown: root.shownSection === "appearance"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsAppearanceSection {
                                        accentName: root.accentName
                                        customAccentColor: root.customAccentColor
                                        albumArtRadius: root.albumArtRadius
                                        nowPlayingBackdrop: root.nowPlayingBackdrop
                                        showRemainingTime: root.showRemainingTime
                                        appFont: root.appWindow.appFont
                                        fontFamilies: root.appWindow.fontFamilies
                                        trackDensity: root.trackDensity
                                        showFormatBadges: root.showFormatBadges
                                        onAppFontSelected: value => root.appWindow.appFont = value
                                        onTrackDensitySelected: value => root.trackDensitySelected(value)
                                        onShowFormatBadgesSelected: value => root.showFormatBadgesSelected(value)
                                        onAccentSelected: value => root.accentSelected(value)
                                        onCustomAccentSelected: value => root.customAccentSelected(value)
                                        onAlbumArtRadiusSelected: value => root.albumArtRadiusSelected(value)
                                        onNowPlayingBackdropSelected: value => root.nowPlayingBackdropSelected(value)
                                        onShowRemainingTimeSelected: value => root.showRemainingTimeSelected(value)
                                    }
                                }
                            }

                            Loader {
                                id: secSound
                                readonly property bool shown: root.shownSection === "sound"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsSoundSection {
                                        audioOutputs: root.audioOutputs
                                        audioDeviceId: root.audioDeviceId
                                        crossfadeSeconds: root.crossfadeSeconds
                                        volumeLimitEnabled: root.volumeLimitEnabled
                                        maxVolumePercent: root.maxVolumePercent
                                        replayGainMode: root.replayGainMode
                                        onAudioDeviceSelected: value => root.audioDeviceSelected(value)
                                        onCrossfadeSelected: value => root.crossfadeSelected(value)
                                        onVolumeLimitSelected: value => root.volumeLimitSelected(value)
                                        onMaxVolumeSelected: value => root.maxVolumeSelected(value)
                                        onReplayGainModeSelected: value => root.replayGainModeSelected(value)
                                    }
                                }
                            }

                            Loader {
                                id: secPlayback
                                readonly property bool shown: root.shownSection === "playback"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsPlaybackSection {
                                        resumeQueueOnLaunch: root.resumeQueueOnLaunch
                                        autoplayEnabled: root.autoplayEnabled
                                        sleepTimerMode: root.sleepTimerMode
                                        sleepTimerStatus: root.sleepTimerStatus
                                        sleepFadeOut: root.sleepFadeOut
                                        onResumeQueueOnLaunchSelected: value => root.resumeQueueOnLaunchSelected(value)
                                        onAutoplaySelected: value => root.autoplaySelected(value)
                                        onSleepTimerSelected: value => root.sleepTimerSelected(value)
                                        onSleepTimerCancelled: root.sleepTimerCancelled()
                                        onSleepFadeOutSelected: value => root.sleepFadeOutSelected(value)
                                    }
                                }
                            }

                            Loader {
                                id: secShortcuts
                                readonly property bool shown: root.shownSection === "shortcuts"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsShortcutsSection {
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
                                }
                            }

                            Loader {
                                id: secDesktop
                                readonly property bool shown: root.shownSection === "desktop"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsDesktopSection {
                                        defaultLaunchPage: root.defaultLaunchPage
                                        sidebarOrder: root.appWindow.sidebarOrder
                                        sidebarHidden: root.appWindow.sidebarHidden
                                        sidebarPageLabel: root.appWindow.sidebarPageLabel
                                        sidebarPageIcon: root.appWindow.sidebarPageIcon
                                        onSidebarPagesSelected: (order, hidden) => root.appWindow.setSidebarPages(order, hidden)
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
                                }
                            }

                            Loader {
                                id: secLyrics
                                readonly property bool shown: root.shownSection === "lyrics"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsLyricsSection {
                                        lyricsFontSize: root.lyricsFontSize
                                        lyricsAlignment: root.lyricsAlignment
                                        lyricsActiveStyle: root.lyricsActiveStyle
                                        preferLocalLyrics: root.preferLocalLyrics
                                        lyricsFont: root.appWindow.lyricsFont
                                        lyricsFontWeight: root.appWindow.lyricsFontWeight
                                        fontFamilies: root.appWindow.fontFamilies
                                        libraryLyricsEnabled: root.appWindow.libraryLyricsEnabled
                                        lrclibAvailable: root.svcLrclib && !root.offlineBlackout
                                        onLibraryLyricsSelected: value => root.appWindow.libraryLyricsEnabled = value
                                        onLyricsFontSelected: value => root.appWindow.lyricsFont = value
                                        onLyricsFontWeightSelected: value => root.appWindow.lyricsFontWeight = value
                                        onLyricsFontSizeSelected: value => root.lyricsFontSizeSelected(value)
                                        onLyricsAlignmentSelected: value => root.lyricsAlignmentSelected(value)
                                        onLyricsActiveStyleSelected: value => root.lyricsActiveStyleSelected(value)
                                        onPreferLocalLyricsSelected: value => root.preferLocalLyricsSelected(value)
                                    }
                                }
                            }

                            Loader {
                                id: secScrobble
                                readonly property bool shown: root.shownSection === "scrobble"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsScrobbleSection {
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
                                        lastFmEnabled: root.scrobbleLastFmEnabled
                                        lastFmUser: root.scrobbleLastFmUser
                                        lastFmConnected: root.scrobbleLastFmConnected
                                        onLastFmEnabledToggled: value => root.scrobbleLastFmToggled(value)
                                        onDisconnectLastFmRequested: root.disconnectLastFmRequested()
                                    }
                                }
                            }

                            Loader {
                                id: secNetwork
                                readonly property bool shown: root.shownSection === "network"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsNetworkSection {
                                        offlineBlackout: root.offlineBlackout
                                        svcLrclib: root.svcLrclib
                                        svcRadio: root.svcRadio
                                        svcDeezer: root.svcDeezer
                                        svcAudiodb: root.svcAudiodb
                                        svcWiki: root.svcWiki
                                        svcArchive: root.svcArchive
                                        svcDiscord: root.svcDiscord
                                        onOfflineBlackoutSelected: value => root.offlineBlackoutSelected(value)
                                        onServiceToggleRequested: (name, value) => root.serviceToggleRequested(name, value)
                                        onOpenJellyfinRequested: root.openJellyfinRequested()
                                        onOpenSubsonicRequested: root.openSubsonicRequested()
                                    }
                                }
                            }

                            Loader {
                                id: secPhoneRemote
                                readonly property bool shown: root.shownSection === "phone"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsPhoneRemoteSection {
                                        offlineBlackout: root.offlineBlackout
                                        svcPhoneRemote: root.svcPhoneRemote
                                        onServiceToggleRequested: (name, value) => root.serviceToggleRequested(name, value)
                                    }
                                }
                            }

                            Loader {
                                id: secBackup
                                readonly property bool shown: root.shownSection === "data"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    SettingsBackupSection {
                                        backupStatus: root.backupStatus
                                        onExportBackupRequested: root.exportBackupRequested()
                                        onImportBackupRequested: root.importBackupRequested()
                                    }
                                }
                            }

                            Loader {
                                id: secCredits
                                readonly property bool shown: root.shownSection === "credits"
                                visible: shown
                                active: shown || root.buildAllSections
                                asynchronous: !shown
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible && item ? item.implicitHeight : 0
                                sourceComponent: Component {
                                    CreditsView {
                                        onWhatsNewRequested: root.whatsNewRequested()
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
}
