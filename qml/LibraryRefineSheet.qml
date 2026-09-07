import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property bool isOpen: false
    property string activeTab: "songs"
    property string currentFilter: "ALL"
    property string currentSongSort: "title"
    property string currentArtistSort: "name"
    property string currentAlbumSort: "album"
    property string currentGenreSort: "count"
    property string currentFolderSort: "name"
    property string currentRadioSort: "votes"
    property bool currentSortAscending: true
    property string radioCountry: ""
    property string radioLanguage: ""
    property string radioTag: "ALL"

    signal filterSelected(string filterId)
    signal sortSelected(string sortId)
    signal sortDirectionToggled()
    signal resetRequested()
    signal radioCountrySelected(string country)
    signal radioLanguageSelected(string language)
    signal radioTagSelected(string tag)
    signal radioFiltersSubmitted()
    signal closed()

    property bool isCustomized: {
        if (activeTab === "radio") return radioCountry.length > 0 || radioLanguage.length > 0 || radioTag !== "ALL" || currentRadioSort !== "votes" || currentSortAscending
        if (currentFilter !== "ALL") return true
        if (activeTab === "songs" && (!currentSortAscending || currentSongSort !== "title")) return true
        if (activeTab === "artists" && (!currentSortAscending || currentArtistSort !== "name")) return true
        if (activeTab === "albums" && (!currentSortAscending || currentAlbumSort !== "album")) return true
        if (activeTab === "genres" && (currentSortAscending || currentGenreSort !== "count")) return true
        if (activeTab === "folders" && (!currentSortAscending || currentFolderSort !== "name")) return true
        return false
    }

    anchors.fill: parent
    color: "#90000000"
    visible: opacity > 0.01
    opacity: isOpen ? 1.0 : 0.0
    z: 9999

    Behavior on opacity { NumberAnimation { duration: 180 } }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    Rectangle {
        id: sheetContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(parent.width - 32, 540)
        height: Math.min(parent.height - 30, sheetContent.implicitHeight + 40)
        radius: 24
        color: "#121212"
        border.width: 1
        border.color: "#282828"
        clip: true

        transform: Translate {
            y: root.isOpen ? 0 : 120
            Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: sheetContent
            anchors.fill: parent
            anchors.margins: 22
            anchors.bottomMargin: 26
            spacing: 16

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 36
                Layout.preferredHeight: 4
                radius: 2
                color: "#40FFFFFF"
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Label {
                    text: "Refine & Sort"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: rstContentRow.implicitWidth + 28
                    radius: 16
                    color: rstMouse.containsMouse ? "#20FF3344" : "transparent"
                    border.width: 1.2
                    border.color: root.isCustomized ? recordRed : "#40FF3344"

                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        id: rstContentRow
                        anchors.centerIn: parent
                        spacing: 8

                        LucideIcon {
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            icon: "rotate-ccw"
                            color: recordRedHover
                        }

                        Label {
                            text: "Reset"
                            color: recordRedHover
                            font.family: displayFont
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        id: rstMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetRequested()
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: closeMouse.containsMouse ? "#20FFFFFF" : "transparent"
                    border.width: 1
                    border.color: closeMouse.containsMouse ? "#40FFFFFF" : "transparent"

                    LucideIcon {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        icon: "x"
                        color: textPrimary
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closed()
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.activeTab === "songs" ? implicitHeight : 0
                visible: root.activeTab === "songs"
                spacing: 8

                Label {
                    text: "FILTER BY"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "ALL", label: "All songs", icon: "music" },
                            { id: "FAVORITES", label: "Favorites", icon: "heart" },
                            { id: "FLAC", label: "FLAC / Lossless", icon: "audio-lines" },
                            { id: "MP3", label: "MP3", icon: "music" },
                            { id: "AAC", label: "AAC / M4A", icon: "music" }
                        ]

                        Rectangle {
                            property bool isSelected: root.currentFilter === modelData.id
                            width: fRow.implicitWidth + 24
                            height: 36
                            radius: 18
                            color: "transparent"
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? recordRed : (fMouse.containsMouse ? "#45FFFFFF" : "#282828")

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                id: fRow
                                anchors.centerIn: parent
                                spacing: 8

                                LucideIcon {
                                    Layout.preferredWidth: 14
                                    Layout.preferredHeight: 14
                                    icon: modelData.icon
                                    color: parent.parent.isSelected ? recordRedHover : (fMouse.containsMouse ? textPrimary : textSecondary)
                                }

                                Label {
                                    text: modelData.label
                                    color: parent.parent.isSelected ? recordRedHover : (fMouse.containsMouse ? textPrimary : textSecondary)
                                    font.family: displayFont
                                    font.pixelSize: 13
                                    font.weight: parent.parent.isSelected ? Font.DemiBold : Font.Normal
                                }
                            }

                            MouseArea {
                                id: fMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.filterSelected(modelData.id)
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.activeTab === "radio" ? implicitHeight : 0
                visible: root.activeTab === "radio"
                spacing: 8

                Label {
                    text: "FILTER BY"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RefineTextInput {
                        Layout.fillWidth: true
                        placeholder: "Country (e.g. India)"
                        text: root.radioCountry
                        onEdited: function(country) { root.radioCountrySelected(country) }
                        onSubmitted: root.radioFiltersSubmitted()
                    }

                    RefineTextInput {
                        Layout.fillWidth: true
                        placeholder: "Language (e.g. English)"
                        text: root.radioLanguage
                        onEdited: function(language) { root.radioLanguageSelected(language) }
                        onSubmitted: root.radioFiltersSubmitted()
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: ["ALL", "electronic", "pop", "rock", "jazz", "classical", "lofi", "ambient", "news"]

                        Rectangle {
                            property bool isSelected: root.radioTag === modelData
                            width: tagLabel.implicitWidth + 24
                            height: 36
                            radius: 18
                            color: "transparent"
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? recordRed : (tagMouse.containsMouse ? "#45FFFFFF" : "#282828")

                            Label {
                                id: tagLabel
                                anchors.centerIn: parent
                                text: modelData.toUpperCase()
                                color: parent.isSelected ? recordRedHover : (tagMouse.containsMouse ? textPrimary : textSecondary)
                                font.family: monoFont
                                font.pixelSize: 11
                                font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                            }

                            MouseArea {
                                id: tagMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.radioTagSelected(modelData)
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#222222" }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "SORT BY"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: {
                            if (root.activeTab === "radio") return [
                                { id: "votes", label: "Popularity", icon: "radio", isNumeric: true },
                                { id: "clicktrend", label: "Trending", icon: "radio", isNumeric: true },
                                { id: "name", label: "Station Name", icon: "arrow-up-down", isNumeric: false },
                                { id: "country", label: "Country", icon: "globe", isNumeric: false },
                                { id: "bitrate", label: "Bitrate", icon: "audio-lines", isNumeric: true }
                            ]
                            if (root.activeTab === "songs") return [
                                { id: "title", label: "Title", icon: "arrow-up-down", isNumeric: false },
                                { id: "artist", label: "Artist", icon: "mic", isNumeric: false },
                                { id: "album", label: "Album", icon: "disc", isNumeric: false },
                                { id: "duration", label: "Duration", icon: "clock", isNumeric: true }
                            ]
                            if (root.activeTab === "artists") return [
                                { id: "name", label: "Artist Name", icon: "mic", isNumeric: false },
                                { id: "count", label: "Song Count", icon: "list-music", isNumeric: true }
                            ]
                            if (root.activeTab === "albums") return [
                                { id: "album", label: "Album Title", icon: "disc", isNumeric: false },
                                { id: "artist", label: "Artist", icon: "mic", isNumeric: false },
                                { id: "count", label: "Song Count", icon: "list-music", isNumeric: true }
                            ]
                            if (root.activeTab === "genres") return [
                                { id: "name", label: "Genre Name", icon: "disc", isNumeric: false },
                                { id: "count", label: "Song Count", icon: "list-music", isNumeric: true }
                            ]
                            return [
                                { id: "name", label: "Folder Name", icon: "folder", isNumeric: false },
                                { id: "count", label: "Song Count", icon: "list-music", isNumeric: true }
                            ]
                        }

                        Rectangle {
                            id: sortCard
                            readonly property bool isSelected: {
                                if (root.activeTab === "radio") return root.currentRadioSort === modelData.id
                                if (root.activeTab === "songs") return root.currentSongSort === modelData.id
                                if (root.activeTab === "artists") return root.currentArtistSort === modelData.id
                                if (root.activeTab === "albums") return root.currentAlbumSort === modelData.id
                                if (root.activeTab === "genres") return root.currentGenreSort === modelData.id
                                return root.currentFolderSort === modelData.id
                            }

                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            radius: 12
                            color: "transparent"
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? recordRed : (sMouse.containsMouse ? "#45FFFFFF" : "#242424")

                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 12

                                LucideIcon {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    icon: modelData.icon
                                    color: sortCard.isSelected ? recordRedHover : (sMouse.containsMouse ? textPrimary : textSecondary)
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: sortCard.isSelected ? textPrimary : textSecondary
                                    font.family: displayFont
                                    font.pixelSize: 14
                                    font.weight: sortCard.isSelected ? Font.DemiBold : Font.Normal
                                }

                                Rectangle {
                                    visible: sortCard.isSelected
                                    Layout.preferredHeight: 28
                                    Layout.preferredWidth: dirText.implicitWidth + 20
                                    radius: 14
                                    color: "transparent"
                                    border.width: 1.2
                                    border.color: recordRed

                                    Label {
                                        id: dirText
                                        anchors.centerIn: parent
                                        text: {
                                            if (modelData.isNumeric) {
                                                return root.currentSortAscending ? "1 → 9  ▲" : "9 → 1  ▼"
                                            }
                                            return root.currentSortAscending ? "A → Z  ▲" : "Z → A  ▼"
                                        }
                                        color: recordRedHover
                                        font.family: monoFont
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.sortDirectionToggled()
                                    }
                                }
                            }

                            MouseArea {
                                id: sMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (sortCard.isSelected) {
                                        root.sortDirectionToggled()
                                    } else {
                                        root.sortSelected(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
