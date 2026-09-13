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

    function stationTrack(station) {
        return {
            title: station.name || "Live Radio Stream",
            artist: station.country || "Radio Browser",
            album: "Internet Radio Broadcast",
            filePath: station.streamUrl,
            format: "STREAM",
            duration: "LIVE",
            artworkUrl: station.favicon || ""
        }
    }

    function playStation(station) {
        const stations = appWindow.radioStations || []
        const index = stations.findIndex(candidate => candidate.streamUrl === station.streamUrl)
        appWindow.startRadioPlayback(stations.map(candidate => root.stationTrack(candidate)), index)
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

        // ----------------------------------------------------
        // Top Toolbar
        // ----------------------------------------------------
        RowLayout {
            z: 100
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.rightMargin: 28
            Layout.topMargin: 16
            Layout.bottomMargin: 14
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
                        text: root.appWindow.radioStations.length + " stations"
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
                spacing: 6
                Layout.alignment: Qt.AlignVCenter

                Repeater {
                    model: ["ALL", "pop", "rock", "electronic", "jazz", "lofi", "classical", "news", "ambient"]

                    Rectangle {
                        id: qPill
                        property bool isSelected: root.appWindow.radioActiveTag === modelData
                        width: qPillLbl.implicitWidth + 18
                        height: 28
                        radius: 14
                        color: "transparent"
                        border.width: isSelected ? 1.5 : 1
                        border.color: isSelected ? recordRed : (qPillMouse.containsMouse ? "#45FFFFFF" : "#282828")

                        Behavior on border.color {
                            ColorAnimation { duration: 100 }
                        }

                        Label {
                            id: qPillLbl
                            anchors.centerIn: parent
                            text: modelData.toUpperCase()
                            color: qPill.isSelected ? recordRedHover : (qPillMouse.containsMouse ? textPrimary : textSecondary)
                            font.family: monoFont
                            font.pixelSize: 10
                            font.weight: qPill.isSelected ? Font.Bold : Font.DemiBold
                        }

                        MouseArea {
                            id: qPillMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.appWindow.radioActiveTag = modelData
                                root.appWindow.refreshRadio()
                            }
                        }
                    }
                }
            }

            // View Mode Toggle (Grid vs List)
            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: root.appWindow.radioViewMode === "grid" ? "grid-2x2" : "list"
                tint: textPrimary
                tooltipText: root.appWindow.radioViewMode === "grid" ? "Detailed Grid View (Click for List)" : "List View (Click for Grid)"
                onClicked: root.appWindow.radioViewMode = (root.appWindow.radioViewMode === "grid" ? "list" : "grid")
            }

            // Refresh Button
            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "refresh-cw"
                enabled: !root.radioUnavailable
                tint: textPrimary
                tooltipText: "Refresh Stations"
                onClicked: root.appWindow.refreshRadio()
            }

            // Expandable Search Bar
            ExpandableSearchBar {
                id: radSearchBar
                enabled: !root.radioUnavailable
                boxSize: 34
                iconSize: 16
                expandedWidth: 175
                placeholder: "Search live stations..."
                text: root.appWindow.radioSearchQuery
                onTextChanged: root.appWindow.radioSearchQuery = text
                onSubmitted: root.appWindow.refreshRadio()
                onCleared: {
                    root.appWindow.radioSearchQuery = ""
                    root.appWindow.refreshRadio()
                }
            }

            // Refine & Sort Drawer Button
            PressDepthIconButton {
                boxSize: 34
                iconSize: 16
                iconName: "sliders-horizontal"
                enabled: !root.radioUnavailable
                tint: textPrimary
                highlighted: root.appWindow.radioIsCustomized || root.appWindow.radioRefineOpen
                tooltipText: "Refine & Sort Stations"
                onClicked: root.appWindow.radioRefineOpen = !root.appWindow.radioRefineOpen
            }
        }

        // ----------------------------------------------------
        // Main Content Area (Grid View, List View & Empty State)
        // ----------------------------------------------------
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 1. Grid View Mode (Consistent with SongCard & AlbumCard)
            GridView {
                id: radGrid
                visible: root.appWindow.radioViewMode === "grid" && root.appWindow.radioStations.length > 0
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 8
                bottomMargin: 32
                clip: true
                model: root.appWindow.radioStations
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar {}
                readonly property int cols: Math.max(2, Math.floor((width - 16) / 185))
                cellWidth: Math.floor((width - 16) / cols)
                cellHeight: cellWidth + 56

                delegate: Item {
                    width: radGrid.cellWidth
                    height: radGrid.cellHeight

                    readonly property bool isCurrent: root.playerController.currentTrack && root.playerController.currentTrack.filePath === modelData.streamUrl
                    readonly property bool isPlaying: isCurrent && root.playerController.isPlaying

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 8

                        // Square Artwork Container
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: width
                            Layout.alignment: Qt.AlignHCenter

                            Rectangle {
                                id: coverBox
                                anchors.fill: parent
                                radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 12
                                color: stationImg.status === Image.Ready ? surfaceCard : "#000000"
                                clip: true
                                border.width: isCurrent ? 1.5 : (cardMouse.containsMouse ? 1.5 : 0)
                                border.color: isCurrent ? recordRed : (cardMouse.containsMouse ? recordRed : "transparent")
                                scale: cardMouse.containsMouse ? 1.03 : 1.0

                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                // Favicon Image
                                Image {
                                    id: stationImg
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    source: modelData.favicon || ""
                                    fillMode: Image.PreserveAspectFit
                                    visible: status === Image.Ready
                                    asynchronous: true
                                    smooth: true
                                    mipmap: true
                                }


                                VinylFallback { anchors.fill: parent; visible: stationImg.status !== Image.Ready }

                                // Subtle inner border
                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: 1
                                    border.color: isCurrent ? recordRed : "#15FFFFFF"
                                }

                                // Hover / Active Transport Button
                                TransportButton {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    buttonSize: 36
                                    iconName: isPlaying ? "pause" : "play"
                                    accented: true
                                    opacity: (cardMouse.containsMouse || isCurrent) ? 1.0 : 0.0
                                    scale: (cardMouse.containsMouse || isCurrent) ? 1.0 : 0.6

                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                    tooltipText: isPlaying ? "Pause station" : "Play station"
                                    onClicked: root.toggleStation(modelData)
                                }
                            }
                        }

                        // Station Typography (Matches SongCard / AlbumCard)
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
                                text: modelData.country ? (modelData.country + (modelData.bitrate ? (" â€¢ " + modelData.bitrate + " kbps") : (modelData.tags ? (" â€¢ " + modelData.tags.split(",")[0].trim()) : ""))) : (modelData.tags || "Internet Radio")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                clip: true
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleStation(modelData)
                    }
                }
            }

            // 2. List View Mode (Consistent with SongRow)
            ListView {
                id: radList
                visible: root.appWindow.radioViewMode === "list" && root.appWindow.radioStations.length > 0
                anchors.fill: parent
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                bottomMargin: 32
                clip: true
                model: root.appWindow.radioStations
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: SleekScrollBar {}

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

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 16
                        spacing: 12

                        // Cover box
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                            radius: (typeof window !== "undefined" && window.albumArtRadius !== undefined) ? window.albumArtRadius : 8
                            color: listImg.status === Image.Ready ? surfaceCard : "#000000"
                            clip: true
                            border.width: 1
                            border.color: isCurrent ? recordRed : "#15FFFFFF"

                            Image {
                                id: listImg
                                anchors.fill: parent
                                anchors.margins: 4
                                source: modelData.favicon || ""
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                                asynchronous: true
                            }

                            VinylFallback { anchors.fill: parent; visible: listImg.status !== Image.Ready }
                        }

                        // Title & Metadata
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
                                text: modelData.country ? (modelData.country + (modelData.tags ? (" â€¢ " + modelData.tags.split(",")[0].trim()) : "")) : (modelData.tags || "Internet Radio")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        // Bitrate
                        Label {
                            visible: !!(modelData.bitrate && modelData.bitrate > 0)
                            text: modelData.bitrate + " kbps"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }

                        // Play Button
                        TransportButton {
                            buttonSize: 32
                            iconName: isPlaying ? "pause" : "play"
                            accented: isCurrent
                            tooltipText: isPlaying ? "Pause station" : "Play station"
                            onClicked: root.toggleStation(modelData)
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleStation(modelData)
                    }
                }
            }

            // 3. Empty State
            EmptyState {
                anchors.fill: parent
                visible: root.appWindow.radioStations.length === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/06-calico-player.png"
                title: root.radioUnavailable ? root.unavailableTitle : "Loading Radio Stations..."
                subtitle: root.radioUnavailable ? root.unavailableSubtitle : "Connecting to the global Radio Browser directory"
                actionLabel: root.radioUnavailable
                             ? (root.appWindow.offlineBlackout ? "Enable online services" : "Enable Radio Browser")
                             : "Retry Connection"
                onActionClicked: {
                    if (root.radioUnavailable) {
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
}

