import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property var appWindow
    required property var libraryModel
    required property var playerController
    anchors.fill: parent
    property alias searchBox: pageSearchBox
    property alias searchInput: pageSearchInput
    readonly property bool filtering: appWindow.searchQuery.trim().length > 0 || appWindow.activeFormatFilter !== "ALL"

    function getPopularGenres() {
        const groups = root.libraryModel.catalogGroups();
        const raw = groups.genres || [];
        if (!Array.isArray(raw)) return [{ name: "Soundtrack", count: 1 }, { name: "Rock", count: 1 }, { name: "Pop", count: 1 }, { name: "Electronic", count: 1 }];
        const list = raw.map(function(g) {
            if (!g) return null;
            if (typeof g === "object") return { name: (g.name || "").trim(), count: g.count || 0 };
            if (typeof g === "string") return { name: g.trim(), count: 1 };
            return null;
        }).filter(function(g) {
            return g && g.name.length > 0 && g.name.toLowerCase() !== "unknown";
        });
        list.sort(function(a, b) { return b.count - a.count; });
        return list.length > 0 ? list.slice(0, 16) : [
            { name: "Lossless", count: 1 },
            { name: "Rock", count: 1 },
            { name: "Pop", count: 1 },
            { name: "Electronic", count: 1 },
            { name: "Soundtrack", count: 1 },
            { name: "Hip Hop", count: 1 },
            { name: "Jazz", count: 1 }
        ];
    }

    function getTopArtists() {
        const groups = root.libraryModel.catalogGroups();
        const raw = groups.artists || [];
        if (!Array.isArray(raw)) return [];
        const list = raw.map(function(a) {
            if (!a) return null;
            if (typeof a === "object") return { name: (a.name || "").trim(), count: a.count || 0 };
            if (typeof a === "string") return { name: a.trim(), count: 1 };
            return null;
        }).filter(function(a) {
            return a && a.name.length > 0 && a.name.toLowerCase() !== "unknown artist";
        });
        list.sort(function(a, b) { return b.count - a.count; });
        return list.slice(0, 14);
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 20
        anchors.bottomMargin: 16
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 14

            ColumnLayout {
                spacing: 3

                Label {
                    text: "Search Library"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    font.letterSpacing: -0.3
                }

                Label {
                    text: root.filtering
                        ? (root.libraryModel.visibleTrackCount + " matching " + (root.libraryModel.visibleTrackCount === 1 ? "track" : "tracks"))
                        : "Search by title, artist, album, or audio format"
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                }
            }

            Rectangle {
                Layout.preferredHeight: 22
                Layout.preferredWidth: countTagLbl.implicitWidth + 14
                radius: 11
                color: surfaceTag
                border.width: 1
                border.color: borderSubtle

                Label {
                    id: countTagLbl
                    anchors.centerIn: parent
                    text: root.filtering
                        ? (root.libraryModel.visibleTrackCount + " of " + root.libraryModel.trackCount + " songs")
                        : (root.libraryModel.trackCount + " songs")
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PressDepthIconButton {
                visible: root.filtering
                boxSize: 34
                iconSize: 16
                iconName: "rotate-ccw"
                tint: recordRedHover
                tooltipText: "Reset Search"
                onClicked: {
                    root.appWindow.searchQuery = "";
                    root.appWindow.activeFormatFilter = "ALL";
                }
            }
        }

        // Search box
        Rectangle {
            id: pageSearchBox
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: 10
            color: pageSearchInput.activeFocus ? surfaceElevated : surfaceCard
            border.width: pageSearchInput.activeFocus ? 1.5 : 1
            border.color: pageSearchInput.activeFocus ? recordRedHover : borderVariant

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 12
                spacing: 10

                LucideIcon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    icon: "search"
                    color: pageSearchInput.activeFocus ? recordRedHover : silverDim

                    Behavior on color { ColorAnimation { duration: 120 } }
                }

                TextInput {
                    id: pageSearchInput
                    Layout.fillWidth: true
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    selectByMouse: true
                    text: root.appWindow.searchQuery
                    onTextChanged: root.appWindow.searchQuery = text
                    Keys.onEscapePressed: focus = false

                    Text {
                        anchors.fill: parent
                        visible: !pageSearchInput.text && !pageSearchInput.activeFocus
                        text: "Search songs, artists, albums, or audio formats..."
                        color: silverDim
                        font.family: displayFont
                        font.pixelSize: 14
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    visible: pageSearchInput.text.length > 0
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    color: clearMouse.containsMouse ? surfaceElevated : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        Layout.preferredWidth: 12
                        Layout.preferredHeight: 12
                        icon: "x"
                        color: clearMouse.containsMouse ? textPrimary : silverDim
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pageSearchInput.text = "";
                            root.appWindow.searchQuery = "";
                        }
                    }
                }
            }
        }

        // Format chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "FORMAT"
                color: silverDim
                font.family: monoFont
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 1.0
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: [
                        { id: "ALL", label: "All formats", icon: "music" },
                        { id: "FLAC", label: "Lossless", icon: "audio-lines" },
                        { id: "MP3", label: "MP3", icon: "music" },
                        { id: "AAC", label: "AAC / M4A", icon: "sparkles" }
                    ]

                    Rectangle {
                        property bool isSelected: root.appWindow.activeFormatFilter === modelData.id
                        width: chipRow.implicitWidth + 20
                        height: 28
                        radius: height / 2
                        color: isSelected
                            ? "#262320"
                            : (chipMouse.containsMouse ? surfaceElevated : surfaceTag)
                        border.width: 1
                        border.color: isSelected
                            ? recordRed
                            : (chipMouse.containsMouse ? borderVariant : borderSubtle)

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6

                            LucideIcon {
                                Layout.preferredWidth: 12
                                Layout.preferredHeight: 12
                                icon: modelData.icon
                                color: parent.parent.isSelected ? recordRedHover : (chipMouse.containsMouse ? textPrimary : textSecondary)
                            }

                            Label {
                                text: modelData.label
                                color: parent.parent.isSelected ? recordRedHover : (chipMouse.containsMouse ? textPrimary : textSecondary)
                                font.family: monoFont
                                font.pixelSize: 11
                                font.weight: parent.parent.isSelected ? Font.Bold : Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.activeFormatFilter = modelData.id
                        }
                    }
                }
            }

            Label {
                visible: root.filtering
                text: root.libraryModel.visibleTrackCount + (root.libraryModel.visibleTrackCount === 1 ? " match" : " matches")
                color: silverDim
                font.family: monoFont
                font.pixelSize: 11
            }
        }

        // Results
        ListView {
            id: searchResults
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.filtering
            clip: true
            model: root.libraryModel
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar {}

            header: Item {
                width: searchResults.width
                height: 32

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: 8

                    Label {
                        text: "MATCHING TRACKS"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.appWindow.searchQuery.length > 0 ? "Best matches first" : "Filtered by format"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                    }
                }
            }

            delegate: SongRow {
                width: searchResults.width
                track: model.track
                showAlbum: true
                showCover: true
                showDuration: true
                showHeart: true
                onClicked: root.appWindow.playTrack(model.track)
                onFavoriteClicked: root.appWindow.toggleFavorite(model.track.filePath)
            }

            EmptyState {
                anchors.centerIn: parent
                visible: root.libraryModel.visibleTrackCount === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                title: "No matching tracks"
                subtitle: "Try a different search or clear the format filter"
                actionLabel: "Clear Search"
                onActionClicked: {
                    root.appWindow.searchQuery = "";
                    root.appWindow.activeFormatFilter = "ALL";
                }
            }
        }

        // Idle state discovery
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.filtering
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
            ScrollBar.vertical: SleekScrollBar {}
            contentWidth: availableWidth
            contentHeight: idleColumn.implicitHeight + 24

            ColumnLayout {
                id: idleColumn
                width: parent.width
                spacing: 20

                // Quick recent listens (compact list)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: root.appWindow.playbackHistory && root.appWindow.playbackHistory.length > 0

                    RowLayout {
                        Layout.fillWidth: true
                        SectionLabel {
                            text: "Recent Listens"
                        }
                        Item { Layout.fillWidth: true }
                        Label {
                            text: "Jump back in"
                            color: silverDim
                            font.family: monoFont
                            font.pixelSize: 10
                        }
                    }

                    Repeater {
                        model: root.appWindow.playbackHistory ? root.appWindow.playbackHistory.slice(0, 4) : []
                        delegate: SongRow {
                            Layout.fillWidth: true
                            track: modelData
                            showAlbum: true
                            showCover: true
                            showDuration: true
                            showHeart: true
                            onClicked: root.appWindow.playTrack(modelData)
                            onFavoriteClicked: root.appWindow.toggleFavorite(modelData.filePath)
                        }
                    }
                }

                // Top Artists
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: root.libraryModel.trackCount > 0

                    SectionLabel {
                        text: "Top Artists"
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.getTopArtists()

                            Rectangle {
                                height: 28
                                width: artistTagRow.implicitWidth + 20
                                radius: height / 2
                                color: artistTagMouse.containsMouse ? surfaceElevated : surfaceTag
                                border.width: 1
                                border.color: artistTagMouse.containsMouse ? borderVariant : borderSubtle

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: artistTagRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    LucideIcon {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        icon: "user"
                                        color: artistTagMouse.containsMouse ? recordRedHover : silverDim
                                    }

                                    Label {
                                        text: (modelData && modelData.name) ? modelData.name : String(modelData)
                                        color: artistTagMouse.containsMouse ? textPrimary : textSecondary
                                        font.family: monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: artistTagMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const q = (modelData && modelData.name) ? modelData.name : String(modelData);
                                        pageSearchInput.text = q;
                                        root.appWindow.searchQuery = q;
                                    }
                                }
                            }
                        }
                    }
                }

                // Explore Genres
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    visible: root.libraryModel.trackCount > 0

                    SectionLabel {
                        text: "Explore Genres"
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: root.getPopularGenres()

                            Rectangle {
                                height: 28
                                width: genreTagRow.implicitWidth + 20
                                radius: height / 2
                                color: genreTagMouse.containsMouse ? surfaceElevated : surfaceTag
                                border.width: 1
                                border.color: genreTagMouse.containsMouse ? borderVariant : borderSubtle

                                Behavior on color { ColorAnimation { duration: 120 } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: genreTagRow
                                    anchors.centerIn: parent
                                    spacing: 6

                                    LucideIcon {
                                        Layout.preferredWidth: 12
                                        Layout.preferredHeight: 12
                                        icon: "sparkles"
                                        color: genreTagMouse.containsMouse ? recordRedHover : silverDim
                                    }

                                    Label {
                                        text: (modelData && modelData.name) ? modelData.name : String(modelData)
                                        color: genreTagMouse.containsMouse ? textPrimary : textSecondary
                                        font.family: monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: genreTagMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const q = (modelData && modelData.name) ? modelData.name : String(modelData);
                                        pageSearchInput.text = q;
                                        root.appWindow.searchQuery = q;
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty state if library has 0 songs
                EmptyState {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 300
                    visible: root.libraryModel.trackCount === 0
                    catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                    title: "No Music in Library"
                    subtitle: "Choose a music folder in Settings to start exploring"
                    actionLabel: "Open Settings"
                    onActionClicked: root.appWindow.page = "settings"
                }
            }
        }
    }
}
