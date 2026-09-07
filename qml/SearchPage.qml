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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                spacing: 2

                Label {
                    text: "SEARCH YOUR LIBRARY"
                    color: recordRed
                    font.family: monoFont
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.1
                }

                Label {
                    text: "Find the track you want"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Label {
                    text: root.appWindow.searchQuery.trim().length > 0 ? root.libraryModel.visibleTrackCount + " matching tracks" : root.libraryModel.trackCount + " tracks in your library"
                    color: silverDim
                    font.family: monoFont
                    font.pixelSize: 11
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PressDepthIconButton {
                visible: root.appWindow.searchQuery.length > 0 || root.appWindow.activeFormatFilter !== "ALL"
                boxSize: 32
                iconSize: 15
                iconName: "rotate-ccw"
                tint: recordRedHover
                tooltipText: "Clear Search"
                onClicked: {
                    root.appWindow.searchQuery = "";
                    root.appWindow.activeFormatFilter = "ALL";
                }
            }
        }

        Rectangle {
            id: pageSearchBox
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 16
            color: pageSearchInput.activeFocus ? surfaceElevated : surfaceCard
            border.width: pageSearchInput.activeFocus ? 1.5 : 1
            border.color: pageSearchInput.activeFocus ? recordRed : borderVariant

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                LucideIcon {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    icon: "search"
                    color: pageSearchInput.activeFocus ? recordRed : silverDim
                }

                TextInput {
                    id: pageSearchInput
                    Layout.fillWidth: true
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 15
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
                        font.pixelSize: 15
                    }
                }

                Label {
                    visible: pageSearchInput.text.length > 0
                    text: "✕"
                    color: textSecondary
                    font.pixelSize: 16
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            pageSearchInput.text = "";
                            root.appWindow.searchQuery = "";
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: "FORMAT"
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
                        {
                            id: "ALL",
                            label: "All formats"
                        },
                        {
                            id: "FLAC",
                            label: "Lossless"
                        },
                        {
                            id: "MP3",
                            label: "MP3"
                        },
                        {
                            id: "AAC",
                            label: "AAC / M4A"
                        }
                    ]

                    Rectangle {
                        property bool isSelected: root.appWindow.activeFormatFilter === modelData.id
                        width: formatLabel.implicitWidth + 24
                        height: 30
                        radius: 15
                        color: "transparent"
                        border.width: isSelected ? 1.2 : 1
                        border.color: isSelected ? recordRed : (formatMouse.containsMouse ? "#45FFFFFF" : borderSubtle)

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Label {
                            id: formatLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            color: parent.isSelected ? recordRedHover : (formatMouse.containsMouse ? textPrimary : textSecondary)
                            font.family: monoFont
                            font.pixelSize: 10
                            font.weight: parent.isSelected ? Font.Bold : Font.DemiBold
                        }

                        MouseArea {
                            id: formatMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.appWindow.activeFormatFilter = modelData.id
                        }
                    }
                }
            }

            Label {
                text: root.libraryModel.visibleTrackCount + " results"
                color: textSecondary
                font.family: monoFont
                font.pixelSize: 11
            }
        }

        ListView {
            id: searchResults
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: root.libraryModel
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: SleekScrollBar {
                anchors.rightMargin: 8
            }

            header: Item {
                width: searchResults.width - 24
                height: 38

                RowLayout {
                    anchors.fill: parent
                    anchors.rightMargin: 12

                    Label {
                        text: "RESULTS"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        text: root.appWindow.searchQuery.length > 0 ? "Best matches first" : "All tracks"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 10
                    }
                }
            }

            delegate: Rectangle {
                width: ListView.view.width - 24
                height: 64
                radius: 12
                color: searchRowMouse.containsMouse ? surfaceElevated : (root.playerController.currentTrack.filePath === model.track.filePath ? surfaceCard : "#121110")
                border.width: root.playerController.currentTrack.filePath === model.track.filePath ? 1 : 0
                border.color: recordRed

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16
                    spacing: 12

                    Cover {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 8
                        track: model.track
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            Layout.fillWidth: true
                            text: model.track.title || model.track.fileName
                            color: root.playerController.currentTrack.filePath === model.track.filePath ? recordRed : textPrimary
                            font.family: displayFont
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (model.track.artist || "Unknown Artist") + " • " + (model.track.album || "Unknown Album")
                            color: textSecondary
                            font.family: bodyFont
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        visible: !!model.track.format
                        Layout.preferredHeight: 20
                        Layout.preferredWidth: formatText.implicitWidth + 10
                        radius: 4
                        color: "#18FFFFFF"
                        border.width: 1
                        border.color: "#30FFFFFF"

                        Label {
                            id: formatText
                            anchors.centerIn: parent
                            text: (model.track.format || "").toUpperCase()
                            color: textSecondary
                            font.family: monoFont
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    Label {
                        text: model.track.duration || "—"
                        color: silverDim
                        font.family: monoFont
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: searchRowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.appWindow.playTrack(model.track)
                }
            }

            EmptyState {
                anchors.centerIn: parent
                visible: root.libraryModel.visibleTrackCount === 0
                catImage: "qrc:/qt/qml/CassetteCat/assets/01-orange-headphones.png"
                title: root.appWindow.searchQuery.length > 0 || root.appWindow.activeFormatFilter !== "ALL" ? "No matching tracks" : "Your library is empty"
                subtitle: root.appWindow.searchQuery.length > 0 || root.appWindow.activeFormatFilter !== "ALL" ? "Try a different search or clear the format filter" : "Choose a music folder in Settings to start searching"
                actionLabel: root.appWindow.searchQuery.length > 0 || root.appWindow.activeFormatFilter !== "ALL" ? "Clear Search" : ""
                onActionClicked: {
                    root.appWindow.searchQuery = "";
                    root.appWindow.activeFormatFilter = "ALL";
                }
            }
        }
    }
}
