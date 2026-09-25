import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    property string targetAlbum: ""
    property string targetArtist: ""
    property string targetFilePath: ""
    property bool searchLoading: false
    property bool applyingCover: false
    property var searchResults: []

    parent: Overlay.overlay
    modal: true
    focus: true
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(parent.width - 64, 680)
    height: Math.min(parent.height - 60, 600)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: "#B8000000"
    }

    background: Rectangle {
        radius: 14
        color: surfaceCard
        border.width: 1
        border.color: borderSubtle
    }

    function openFor(album, artist, filePath) {
        targetAlbum = album || ""
        targetArtist = artist || ""
        targetFilePath = filePath || ""
        albumInput.text = targetAlbum
        artistInput.text = targetArtist
        searchResults = []
        applyingCover = false
        open()
        triggerSearch()
    }

    function triggerSearch() {
        if (!albumInput.text.trim().length) return
        searchLoading = true
        services.searchAlbumCovers(albumInput.text.trim(), artistInput.text.trim())
    }

    Connections {
        target: services
        function onCoverSearchResultsReady(results) {
            root.searchLoading = false
            root.searchResults = results
        }
        function onCoverSearchFailed(error) {
            root.searchLoading = false
            root.applyingCover = false
        }
        function onCoverApplied(album, artist, artworkPath, filePath) {
            root.applyingCover = false
            root.close()
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 18
            Layout.topMargin: 16
            Layout.bottomMargin: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: root.searchLoading ? "Searching artwork…" : "Choose album cover"
                    color: textPrimary
                    font.family: displayFont
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Label {
                    Layout.fillWidth: true
                    text: root.targetAlbum.length ? (root.targetAlbum + (root.targetArtist.length ? " • " + root.targetArtist : "")) : "Search online album artwork"
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            TransportButton {
                Accessible.name: "Close"
                buttonSize: 30
                iconName: "x"
                onClicked: root.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 12
            spacing: 10

            RefineTextInput {
                id: albumInput
                Layout.fillWidth: true
                placeholder: "Album title"
                onSubmitted: root.triggerSearch()
            }

            RefineTextInput {
                id: artistInput
                Layout.preferredWidth: 160
                placeholder: "Artist (optional)"
                onSubmitted: root.triggerSearch()
            }

            TransportButton {
                Accessible.name: "Search"
                buttonSize: 36
                iconName: "search"
                accented: true
                onClicked: root.triggerSearch()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.bottomMargin: 8
            visible: !root.searchLoading && root.searchResults.length > 0

            Label {
                Layout.fillWidth: true
                text: root.searchResults.length + (root.searchResults.length === 1 ? " artwork found" : " artworks found")
                color: recordRedHover
                font.family: monoFont
                font.pixelSize: 10
                font.weight: Font.Bold
            }

            Label {
                text: "Select a cover to apply"
                color: silverDim
                font.family: bodyFont
                font.pixelSize: 10
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Item {
                anchors.centerIn: parent
                visible: root.searchLoading
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Label {
                        text: "Searching catalog for covers…"
                        color: textSecondary
                        font.family: displayFont
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item {
                anchors.centerIn: parent
                visible: !root.searchLoading && root.searchResults.length === 0
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Label {
                        text: "No album covers found"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        text: "Try refining the album title or artist above."
                        color: textSecondary
                        font.family: bodyFont
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            GridView {
                id: grid
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 16
                visible: !root.searchLoading && root.searchResults.length > 0
                cellWidth: Math.max(140, Math.floor((grid.width - 4) / 4))
                cellHeight: cellWidth + 58
                clip: true
                model: root.searchResults
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: UiConstants.flickDeceleration
                maximumFlickVelocity: UiConstants.maximumFlickVelocity
                cacheBuffer: UiConstants.cacheBuffer
                pixelAligned: UiConstants.pixelAligned
                reuseItems: true
                ScrollBar.vertical: AutoHideScrollBar {}

                delegate: Item {
                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: card
                        anchors.fill: parent
                        anchors.margins: 4
                        radius: 10
                        clip: true
                        color: itemMouse.containsMouse ? surfaceElevated : surfaceInput
                        border.width: 1
                        border.color: itemMouse.containsMouse ? recordRedHover : borderSubtle

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: width
                                clip: true

                                Image {
                                    id: thumbImg
                                    anchors.fill: parent
                                    source: modelData.thumbUrl || modelData.fullUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 4
                                    radius: 3
                                    color: "#D00E0D0C"
                                    implicitWidth: resLabel.implicitWidth + 6
                                    implicitHeight: resLabel.implicitHeight + 2

                                    Label {
                                        id: resLabel
                                        anchors.centerIn: parent
                                        text: modelData.resolution || "HD"
                                        color: textPrimary
                                        font.family: monoFont
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                    }
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.margins: 4
                                    radius: 3
                                    color: "#D00E0D0C"
                                    implicitWidth: srcLabel.implicitWidth + 6
                                    implicitHeight: srcLabel.implicitHeight + 2

                                    Label {
                                        id: srcLabel
                                        anchors.centerIn: parent
                                        text: modelData.source || ""
                                        color: recordRedHover
                                        font.family: monoFont
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: modelData.album || ""
                                color: textPrimary
                                font.family: displayFont
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Label {
                                Layout.fillWidth: true
                                text: (modelData.artist || "") + (modelData.year ? " (" + modelData.year + ")" : "")
                                color: textSecondary
                                font.family: bodyFont
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !root.applyingCover
                            onClicked: {
                                root.applyingCover = true
                                services.applyAlbumCover(
                                    modelData.album || root.targetAlbum,
                                    modelData.artist || root.targetArtist,
                                    modelData.fullUrl,
                                    root.targetFilePath
                                )
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#A0000000"
                visible: root.applyingCover

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: "Downloading & applying artwork…"
                        color: textPrimary
                        font.family: displayFont
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
