import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var playerController
    anchors.fill: parent
    property alias searchBox: radSearchBar
    property alias searchInput: radSearchBar.searchInput
    property alias searchVisible: radSearchBar.expanded

    readonly property bool radioUnavailable: appWindow.offlineBlackout || !appWindow.svcRadio
    readonly property string unavailableTitle: appWindow.offlineBlackout
                                             ? "Online services are paused"
                                             : "Radio Browser is turned off"
    readonly property string unavailableSubtitle: appWindow.offlineBlackout && !appWindow.svcRadio
                                                ? "Offline Blackout Mode and Radio Browser are both disabled"
                                                : (appWindow.offlineBlackout
                                                   ? "Offline Blackout Mode prevents Radio Browser from connecting"
                                                   : "Enable Radio Browser to discover and play live stations")

    readonly property var displayedStations: {
        let list = []
        if (appWindow.radioActiveTag === "FAVORITES") {
            list = appWindow.radioFavoriteStations || []
        } else if (appWindow.radioActiveTag === "RECENTS") {
            list = appWindow.radioRecentStations || []
        } else if (appWindow.radioActiveTag === "CUSTOM") {
            list = appWindow.radioCustomStations || []
        } else {
            list = appWindow.radioStations || []
        }
        const q = (appWindow.radioSearchQuery || "").trim().toLowerCase()
        if (q.length > 0 && (appWindow.radioActiveTag === "FAVORITES" || appWindow.radioActiveTag === "RECENTS" || appWindow.radioActiveTag === "CUSTOM")) {
            list = list.filter(s => {
                const name = (s.name || "").toLowerCase()
                const country = (s.country || "").toLowerCase()
                const tags = (s.tags || "").toLowerCase()
                return name.includes(q) || country.includes(q) || tags.includes(q)
            })
        }
        return list
    }

    function stationTrack(station) {
        return {
            title: station.name || "Live Radio Stream",
            artist: station.country || (station.tags ? station.tags.split(",")[0].trim() : "Internet Radio"),
            album: station.tags || "Internet Radio Broadcast",
            filePath: station.streamUrl,
            format: "STREAM",
            duration: "LIVE",
            artworkUrl: station.favicon || ""
        }
    }

    function playStation(station) {
        const stations = root.displayedStations || []
        const index = stations.findIndex(candidate => candidate.streamUrl === station.streamUrl)
        appWindow.recordRadioRecent(station)
        appWindow.startRadioPlayback(stations.map(candidate => root.stationTrack(candidate)), Math.max(0, index), station)
    }

    function toggleStation(station) {
        if (root.playerController.currentTrack && root.playerController.currentTrack.filePath === station.streamUrl) {
            root.playerController.togglePlay()
        } else {
            root.playStation(station)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RowLayout {
            z: 100
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.topMargin: 16
            Layout.bottomMargin: 8
            spacing: 14

            Row {
                spacing: 12
                Layout.alignment: Qt.AlignVCenter

                Item {
                    width: tabLbl.implicitWidth
                    height: 32

                    Label {
                        id: tabLbl
                        anchors.centerIn: parent
                        text: "Radio Stations"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 2.5
                        radius: 1.25
                        color: recordRed
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: countTagLbl.implicitWidth + 14
                    radius: 11
                    color: surfaceTag
                    border.width: 1
                    border.color: borderSubtle

                    Label {
                        id: countTagLbl
                        anchors.centerIn: parent
                        text: root.displayedStations.length + " stations"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Row {
                spacing: 8
                Layout.alignment: Qt.AlignVCenter

                ExpandableSearchBar {
                    id: radSearchBar
                    enabled: !root.radioUnavailable || (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS" || root.appWindow.radioActiveTag === "CUSTOM")
                    boxSize: 34
                    iconSize: 16
                    expandedWidth: 175
                    placeholder: "Search live stations..."
                    text: root.appWindow.radioSearchQuery
                    onTextChanged: root.appWindow.radioSearchQuery = text
                    onSubmitted: {
                        if (root.appWindow.radioActiveTag !== "FAVORITES" && root.appWindow.radioActiveTag !== "RECENTS" && root.appWindow.radioActiveTag !== "CUSTOM") {
                            root.appWindow.refreshRadio()
                        }
                    }
                    onCleared: {
                        root.appWindow.radioSearchQuery = ""
                        if (root.appWindow.radioActiveTag !== "FAVORITES" && root.appWindow.radioActiveTag !== "RECENTS" && root.appWindow.radioActiveTag !== "CUSTOM") {
                            root.appWindow.refreshRadio()
                        }
                    }
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "radio"
                    tint: textPrimary
                    tooltipText: "Add Custom Station"
                    onClicked: customStationPopup.open()
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: root.appWindow.radioViewMode === "grid" ? "grid-2x2" : "list"
                    tint: textPrimary
                    tooltipText: root.appWindow.radioViewMode === "grid" ? "Detailed Grid View (Click for List)" : "List View (Click for Grid)"
                    onClicked: root.appWindow.radioViewMode = (root.appWindow.radioViewMode === "grid" ? "list" : "grid")
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "refresh-cw"
                    enabled: !root.radioUnavailable && root.appWindow.radioActiveTag !== "FAVORITES" && root.appWindow.radioActiveTag !== "RECENTS" && root.appWindow.radioActiveTag !== "CUSTOM"
                    tint: textPrimary
                    tooltipText: "Refresh Stations"
                    onClicked: root.appWindow.refreshRadio()
                }

                PressDepthIconButton {
                    boxSize: 34
                    iconSize: 16
                    iconName: "sliders-horizontal"
                    enabled: !root.radioUnavailable && root.appWindow.radioActiveTag !== "FAVORITES" && root.appWindow.radioActiveTag !== "RECENTS" && root.appWindow.radioActiveTag !== "CUSTOM"
                    tint: textPrimary
                    highlighted: root.appWindow.radioIsCustomized || root.appWindow.radioRefineOpen
                    tooltipText: "Refine & Sort Stations"
                    onClicked: root.appWindow.radioRefineOpen = !root.appWindow.radioRefineOpen
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.bottomMargin: 12
            height: 32
            contentWidth: pillsRow.implicitWidth
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: UiConstants.flickDeceleration
            maximumFlickVelocity: UiConstants.maximumFlickVelocity
            pixelAligned: UiConstants.pixelAligned
            flickableDirection: Flickable.HorizontalFlick

            Row {
                id: pillsRow
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: ["ALL", "FAVORITES", "RECENTS", "CUSTOM", "pop", "rock", "electronic", "jazz", "lofi", "classical", "news", "ambient"]

                    Rectangle {
                        id: qPill
                        property bool isSelected: root.appWindow.radioActiveTag === modelData
                        width: qPillLbl.implicitWidth + 22
                        height: 28
                        radius: 14
                        color: isSelected
                            ? (typeof surfaceElevated !== "undefined" ? surfaceElevated : "#262320")
                            : (qPillMouse.containsMouse ? (typeof surfaceCardHover !== "undefined" ? surfaceCardHover : "#1C1A18") : (typeof surfaceInput !== "undefined" ? surfaceInput : "#141312"))
                        border.width: 1
                        border.color: isSelected ? recordRed : (qPillMouse.containsMouse ? borderVariant : borderSubtle)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        Label {
                            id: qPillLbl
                            anchors.centerIn: parent
                            text: modelData.toUpperCase()
                            color: qPill.isSelected ? recordRedHover : (qPillMouse.containsMouse ? textPrimary : textSecondary)
                            font.family: monoFont
                            font.pixelSize: 11
                            font.weight: qPill.isSelected ? Font.Bold : Font.Medium
                        }

                        MouseArea {
                            id: qPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.appWindow.radioActiveTag = modelData
                                if (modelData !== "FAVORITES" && modelData !== "RECENTS" && modelData !== "CUSTOM") {
                                    root.appWindow.refreshRadio()
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridView {
                id: radGrid
                visible: root.appWindow.radioViewMode === "grid" && root.displayedStations.length > 0
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 8
                bottomMargin: 32
                clip: true
                model: root.displayedStations
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                cacheBuffer: UiConstants.cacheBuffer
                pixelAligned: UiConstants.pixelAligned
                reuseItems: true
                ScrollBar.vertical: AutoHideScrollBar {}
                readonly property int cols: Math.max(2, Math.floor((width - 16) / 185))
                cellWidth: Math.floor((width - 16) / cols)
                cellHeight: cellWidth + 56

                delegate: Item {
                    width: radGrid.cellWidth
                    height: radGrid.cellHeight

                    readonly property bool isCurrent: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl
                    readonly property bool isPlaying: isCurrent && root.playerController.isPlaying

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleStation(modelData)
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: width
                            Layout.alignment: Qt.AlignHCenter

                            CoverFrame {
                                id: coverBox
                                anchors.fill: parent
                                radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12
                                highlighted: cardMouse.containsMouse
                                current: isCurrent

                                Image {
                                    id: stationImg
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    source: modelData.favicon || ""
                                    sourceSize.width: Math.ceil(120 * Screen.devicePixelRatio)
                                    sourceSize.height: Math.ceil(120 * Screen.devicePixelRatio)
                                    fillMode: Image.PreserveAspectCrop
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }

                                VinylFallback { anchors.fill: parent; visible: stationImg.status !== Image.Ready }

                                TransportButton {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    buttonSize: 36
                                    iconName: isPlaying ? "pause" : "play"
                                    accented: true
                                    opacity: (cardMouse.containsMouse || isCurrent) ? 1.0 : 0.0
                                    scale: (cardMouse.containsMouse || isCurrent) ? 1.0 : 0.6

                                    Behavior on opacity { NumberAnimation { duration: UiConstants.durationStd } }
                                    Behavior on scale { NumberAnimation { duration: UiConstants.durationStd; easing.type: UiConstants.easingBounce } }

                                    tooltipText: isPlaying ? "Pause station" : "Play station"
                                    onClicked: root.toggleStation(modelData)
                                }

                                PressDepthIconButton {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    boxSize: 32
                                    iconSize: 14
                                    iconName: "heart"
                                    tint: root.appWindow.isRadioFavorite(modelData.streamUrl) ? recordRed : textPrimary
                                    accented: root.appWindow.isRadioFavorite(modelData.streamUrl)
                                    opacity: (cardMouse.containsMouse || root.appWindow.isRadioFavorite(modelData.streamUrl)) ? 1.0 : 0.0
                                    tooltipText: root.appWindow.isRadioFavorite(modelData.streamUrl) ? "Remove from Favorites" : "Add to Favorites"
                                    onClicked: root.appWindow.toggleRadioFavorite(modelData)
                                }

                                PressDepthIconButton {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 8
                                    boxSize: 32
                                    iconSize: 14
                                    iconName: "x"
                                    tint: silverDim
                                    visible: root.appWindow.isRadioCustom(modelData.streamUrl)
                                    opacity: cardMouse.containsMouse ? 1.0 : 0.0
                                    tooltipText: "Delete Station"
                                    onClicked: root.appWindow.removeCustomRadioStation(modelData.streamUrl)
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 0
                                text: modelData.name || "Live Station"
                                color: isCurrent ? recordRed : (cardMouse.containsMouse ? recordRedHover : textPrimary)
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                clip: true
                            }

                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 0
                                text: modelData.country ? (modelData.country + (modelData.bitrate ? (" \u2022 " + modelData.bitrate + " kbps") : (modelData.tags ? (" \u2022 " + modelData.tags.split(",")[0].trim()) : ""))) : (modelData.tags || "Internet Radio")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                clip: true
                            }
                        }
                    }
                }
            }

            ListView {
                id: radList
                visible: root.appWindow.radioViewMode === "list" && root.displayedStations.length > 0
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                bottomMargin: 32
                clip: true
                model: root.displayedStations
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                cacheBuffer: UiConstants.cacheBuffer
                pixelAligned: UiConstants.pixelAligned
                reuseItems: true
                ScrollBar.vertical: AutoHideScrollBar {}

                delegate: Rectangle {
                    width: radList.width
                    height: 52
                    radius: 10

                    readonly property bool isCurrent: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl
                    readonly property bool isPlaying: isCurrent && root.playerController.isPlaying

                    color: rowMouse.containsMouse ? surfaceElevated : (isCurrent ? surfaceCard : "transparent")
                    border.width: isCurrent ? 1 : 0
                    border.color: isCurrent ? recordRed : "transparent"

                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleStation(modelData)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 16
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                            radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 8
                            color: surfaceCard
                            clip: true
                            border.width: 1
                            border.color: isCurrent ? recordRed : "#15FFFFFF"

                            Image {
                                id: listImg
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.favicon || ""
                                sourceSize.width: Math.ceil(40 * Screen.devicePixelRatio)
                                sourceSize.height: Math.ceil(40 * Screen.devicePixelRatio)
                                fillMode: Image.PreserveAspectCrop
                                visible: status === Image.Ready
                                asynchronous: true
                            }

                            VinylFallback { anchors.fill: parent; visible: listImg.status !== Image.Ready }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 0
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            clip: true

                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 0
                                text: modelData.name || "Live Station"
                                color: isCurrent ? recordRed : (rowMouse.containsMouse ? recordRedHover : textPrimary)
                                font.family: displayFont
                                font.pixelSize: 13
                                font.weight: isCurrent ? Font.Bold : Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Label {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 0
                                Layout.minimumWidth: 0
                                text: modelData.country ? (modelData.country + (modelData.tags ? (" \u2022 " + modelData.tags.split(",")[0].trim()) : "")) : (modelData.tags || "Internet Radio")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Label {
                            visible: !!(modelData.bitrate && modelData.bitrate > 0)
                            text: modelData.bitrate + " kbps"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }

                        TransportButton {
                            buttonSize: 32
                            iconName: isPlaying ? "pause" : "play"
                            accented: isCurrent
                            tooltipText: isPlaying ? "Pause station" : "Play station"
                            onClicked: root.toggleStation(modelData)
                        }

                        PressDepthIconButton {
                            boxSize: 32
                            iconSize: 14
                            iconName: "heart"
                            tint: root.appWindow.isRadioFavorite(modelData.streamUrl) ? recordRed : textPrimary
                            accented: root.appWindow.isRadioFavorite(modelData.streamUrl)
                            tooltipText: root.appWindow.isRadioFavorite(modelData.streamUrl) ? "Remove from Favorites" : "Add to Favorites"
                            onClicked: root.appWindow.toggleRadioFavorite(modelData)
                        }

                        PressDepthIconButton {
                            visible: root.appWindow.isRadioCustom(modelData.streamUrl)
                            boxSize: 32
                            iconSize: 14
                            iconName: "x"
                            tint: silverDim
                            tooltipText: "Delete Station"
                            onClicked: root.appWindow.removeCustomRadioStation(modelData.streamUrl)
                        }
                    }
                }
            }

            LoadingBar {
                anchors.fill: parent
                visible: root.appWindow.radioLoading && root.displayedStations.length === 0
            }

            EmptyState {
                anchors.fill: parent
                visible: !root.appWindow.radioLoading && root.displayedStations.length === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
                readonly property bool hasQuery: (root.appWindow.radioSearchQuery || "").trim().length > 0
                readonly property bool sourceEmpty: {
                    if (root.appWindow.radioActiveTag === "FAVORITES") return (root.appWindow.radioFavoriteStations || []).length === 0
                    if (root.appWindow.radioActiveTag === "RECENTS") return (root.appWindow.radioRecentStations || []).length === 0
                    if (root.appWindow.radioActiveTag === "CUSTOM") return (root.appWindow.radioCustomStations || []).length === 0
                    return false
                }
                title: {
                    if (hasQuery && (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS" || root.appWindow.radioActiveTag === "CUSTOM") && !sourceEmpty) {
                        return "No Matching Stations"
                    }
                    if (root.appWindow.radioActiveTag === "FAVORITES") return "No Favorite Stations"
                    if (root.appWindow.radioActiveTag === "RECENTS") return "No Recent Stations"
                    if (root.appWindow.radioActiveTag === "CUSTOM") return "No Custom Stations"
                    if (root.radioUnavailable) return root.unavailableTitle
                    return "No Radio Stations Found"
                }
                subtitle: {
                    if (hasQuery && (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS" || root.appWindow.radioActiveTag === "CUSTOM") && !sourceEmpty) {
                        return "No stations match \"" + root.appWindow.radioSearchQuery.trim() + "\""
                    }
                    if (root.appWindow.radioActiveTag === "FAVORITES") return "Click the heart icon on any station to bookmark it here"
                    if (root.appWindow.radioActiveTag === "RECENTS") return "Stations you play will appear in your history"
                    if (root.appWindow.radioActiveTag === "CUSTOM") return "Add your own direct Icecast, Shoutcast, or radio stream URLs"
                    if (root.radioUnavailable) return root.unavailableSubtitle
                    return "Try clearing filters or searching for another keyword"
                }
                actionLabel: {
                    if (hasQuery && (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS" || root.appWindow.radioActiveTag === "CUSTOM") && !sourceEmpty) {
                        return "Clear Search"
                    }
                    if (root.appWindow.radioActiveTag === "CUSTOM") return "Add Custom Station"
                    if (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS") return "Browse All Stations"
                    if (root.radioUnavailable) return (root.appWindow.offlineBlackout ? "Enable online services" : "Enable Radio Browser")
                    return "Retry Connection"
                }
                onActionClicked: {
                    if (hasQuery && (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS" || root.appWindow.radioActiveTag === "CUSTOM") && !sourceEmpty) {
                        root.appWindow.radioSearchQuery = ""
                    } else if (root.appWindow.radioActiveTag === "CUSTOM") {
                        customStationPopup.open()
                    } else if (root.appWindow.radioActiveTag === "FAVORITES" || root.appWindow.radioActiveTag === "RECENTS") {
                        root.appWindow.radioActiveTag = "ALL"
                        root.appWindow.refreshRadio()
                    } else if (root.radioUnavailable) {
                        root.appWindow.offlineBlackout = false
                        root.appWindow.svcRadio = true
                        Qt.callLater(root.appWindow.refreshRadio)
                    } else {
                        root.appWindow.refreshRadio()
                    }
                }
            }
        }
    }

    Popup {
        id: customStationPopup
        parent: Overlay.overlay
        modal: true
        focus: true
        x: Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        width: Math.min(parent.width - 48, 440)
        padding: 24
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        readonly property bool isUrlValid: {
            const u = customUrlInput.text.trim()
            const match = u.match(/^https?:\/\/([^/\s:]+)/i)
            return match !== null && match[1].length > 0
        }

        Overlay.modal: Rectangle {
            color: "#B8000000"
        }

        background: Rectangle {
            radius: 14
            color: surfaceCard
            border.width: 1
            border.color: borderSubtle
        }

        contentItem: ColumnLayout {
            spacing: 14

            Label {
                text: "Add Custom Station"
                font.family: displayFont
                font.pixelSize: 16
                font.weight: Font.Bold
                color: textPrimary
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Station Name *"
                    font.family: bodyFont
                    font.pixelSize: 11
                    color: textSecondary
                }

                RefineTextInput {
                    id: customNameInput
                    Layout.fillWidth: true
                    placeholder: "e.g. Radio Paradise"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Stream URL (HTTP / HTTPS) *"
                    font.family: bodyFont
                    font.pixelSize: 11
                    color: textSecondary
                }

                RefineTextInput {
                    id: customUrlInput
                    Layout.fillWidth: true
                    placeholder: "https://stream.radioparadise.com/mp3-128"
                }

                Label {
                    visible: customUrlInput.text.trim().length > 0 && !customStationPopup.isUrlValid
                    text: "Must be a valid HTTP or HTTPS stream URL"
                    font.family: bodyFont
                    font.pixelSize: 11
                    color: root.appWindow.recordRed
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Genre / Tags (Optional)"
                    font.family: bodyFont
                    font.pixelSize: 11
                    color: textSecondary
                }

                RefineTextInput {
                    id: customTagsInput
                    Layout.fillWidth: true
                    placeholder: "e.g. eclectic, rock, indie"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "Favicon / Logo URL (Optional)"
                    font.family: bodyFont
                    font.pixelSize: 11
                    color: textSecondary
                }

                RefineTextInput {
                    id: customFaviconInput
                    Layout.fillWidth: true
                    placeholder: "https://example.com/logo.png"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 12

                Item { Layout.fillWidth: true }

                SettingButton {
                    text: "Cancel"
                    onClicked: customStationPopup.close()
                }

                SettingButton {
                    text: "Add Station"
                    primary: true
                    enabled: customNameInput.text.trim().length > 0 && customStationPopup.isUrlValid
                    onClicked: {
                        const name = customNameInput.text.trim()
                        const streamUrl = customUrlInput.text.trim()
                        if (!name || !streamUrl || !customStationPopup.isUrlValid) return
                        root.appWindow.addCustomRadioStation({
                            name: name,
                            streamUrl: streamUrl,
                            tags: customTagsInput.text.trim(),
                            favicon: customFaviconInput.text.trim()
                        })
                        customNameInput.text = ""
                        customUrlInput.text = ""
                        customTagsInput.text = ""
                        customFaviconInput.text = ""
                        customStationPopup.close()
                        root.appWindow.radioActiveTag = "CUSTOM"
                    }
                }
            }
        }
    }
}

