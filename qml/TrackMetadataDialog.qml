import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    property var track: ({})
    required property var appWindow
    property string errorText: ""

    parent: Overlay.overlay
    modal: true
    focus: true
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    width: Math.min(parent.width - 64, 640)
    height: Math.min(parent.height - 64, 720)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    function openFor(value) {
        track = value || ({})
        errorText = ""
        titleInput.text = track.title || ""
        artistInput.text = track.artist || ""
        albumInput.text = track.album || ""
        genreInput.text = track.genre || ""
        labelInput.text = track.label || ""
        yearInput.text = track.year || ""
        trackInput.text = track.trackNumber || ""
        discInput.text = track.discNumber || ""
        commentInput.text = track.comment || ""
        lyricsInput.text = track.lyrics || ""
        open()
    }

    background: Rectangle {
        radius: 14
        color: surfaceCard
        border.width: 1
        border.color: borderSubtle
    }

    contentItem: ColumnLayout {
        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 18
            Layout.topMargin: 18
            Layout.bottomMargin: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Label { text: "Edit metadata"; color: textPrimary; font.family: displayFont; font.pixelSize: 20; font.weight: Font.Bold }
                Label { Layout.fillWidth: true; text: root.track.fileName || ""; color: textSecondary; font.family: bodyFont; font.pixelSize: 12; elide: Text.ElideMiddle }
            }

            TransportButton { buttonSize: 32; iconName: "x"; tooltipText: "Close"; onClicked: root.close() }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: borderSubtle }

        Flickable {
            id: metadataScroll
            readonly property real availableWidth: width
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 18
            clip: true
            contentWidth: availableWidth
            contentHeight: metadataGrid.implicitHeight + 24
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: UiConstants.flickDeceleration
            maximumFlickVelocity: UiConstants.maximumFlickVelocity
            pixelAligned: UiConstants.pixelAligned
            ScrollBar.vertical: AutoHideScrollBar {}

            GridLayout {
                id: metadataGrid
                width: metadataScroll.availableWidth
                columns: 2
                columnSpacing: 14
                rowSpacing: 12

                Label { text: "Title"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12; Layout.preferredWidth: 110 }
                RefineTextInput { id: titleInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Title" }
                Label { text: "Artist"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: artistInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Artist" }
                Label { text: "Album"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: albumInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Album" }
                Label { text: "Genre"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: genreInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Genre" }
                Label { text: "Label"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: labelInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Label" }
                Label { text: "Year"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: yearInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Year" }
                Label { text: "Track number"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: trackInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Track number" }
                Label { text: "Disc number"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: discInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Disc number" }
                Label { text: "Comment"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12; Layout.columnSpan: 2 }
                TextArea {
                    id: commentInput
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    wrapMode: TextArea.Wrap
                    color: textPrimary
                    font.family: bodyFont
                    font.pixelSize: 13
                    selectByMouse: true
                    background: Rectangle { radius: 10; color: surfaceInput; border.width: 1; border.color: commentInput.activeFocus ? recordRed : borderSubtle }
                }
                RowLayout {
                    Layout.columnSpan: 2
                    Layout.fillWidth: true

                    Label { text: "Lyrics"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                    Item { Layout.fillWidth: true }
                    SettingButton {
                        text: "Find with LRCLIB"
                        iconName: "search"
                        onClicked: root.appWindow.openLyricsSearch(function(lyrics) { lyricsInput.text = lyrics })
                    }
                }
                TextArea {
                    id: lyricsInput
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 112
                    wrapMode: TextArea.Wrap
                    color: textPrimary
                    font.family: bodyFont
                    font.pixelSize: 13
                    selectByMouse: true
                    background: Rectangle { radius: 10; color: surfaceInput; border.width: 1; border.color: lyricsInput.activeFocus ? recordRed : borderSubtle }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            Layout.topMargin: 8
            visible: root.errorText.length > 0
            text: root.errorText
            color: recordRedHover
            font.family: bodyFont
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            SettingButton {
                text: "Change cover art"
                iconName: "disc"
                onClicked: root.appWindow.openCoverSearch(albumInput.text, artistInput.text, root.track.filePath)
            }
            Item { Layout.fillWidth: true }
            SettingButton { text: "Cancel"; onClicked: root.close() }
            SettingButton {
                text: "Save"
                primary: true
                onClicked: {
                    const updated = library.updateTrackMetadata({
                        filePath: root.track.filePath,
                        title: titleInput.text,
                        artist: artistInput.text,
                        album: albumInput.text,
                        genre: genreInput.text,
                        label: labelInput.text,
                        year: yearInput.text,
                        trackNumber: trackInput.text,
                        discNumber: discInput.text,
                        comment: commentInput.text,
                        lyrics: lyricsInput.text
                    })
                    if (updated.filePath) {
                        player.updateCurrentTrackMetadata(updated)
                        root.close()
                    } else {
                        root.errorText = "Could not save metadata for this file."
                    }
                }
            }
        }
    }
}
