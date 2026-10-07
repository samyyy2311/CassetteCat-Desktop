import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root

    property var track: ({})
    // Set when editing several songs: only shared fields are shown and only edited ones are saved.
    property var tracks: []
    readonly property bool batch: tracks.length > 1
    property var edited: ({})
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

    // Returns the field's value when every song agrees, otherwise empty so the input shows "Mixed".
    function shared(field) {
        const first = tracks[0][field]
        return tracks.every(item => String(item[field] || "") === String(first || "")) ? (first || "") : ""
    }

    function openForMany(list) {
        tracks = list || []
        if (tracks.length === 1) return openFor(tracks[0])
        track = ({})
        edited = ({})
        errorText = ""
        artistInput.text = shared("artist")
        albumInput.text = shared("album")
        genreInput.text = shared("genre")
        labelInput.text = shared("label")
        yearInput.text = shared("year") || ""
        discInput.text = shared("discNumber") || ""
        commentInput.text = shared("comment")
        open()
    }

    function markEdited(field) {
        edited = Object.assign({}, edited, { [field]: true })
    }

    function placeholderFor(field, label) {
        return batch && shared(field) === "" ? "Mixed" : label
    }

    function openFor(value) {
        tracks = []
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
                Label { text: root.batch ? "Edit " + root.tracks.length + " songs" : "Edit metadata"; color: textPrimary; font.family: displayFont; font.pixelSize: 20; font.weight: Font.Bold }
                Label {
                    Layout.fillWidth: true
                    text: root.batch ? "Only the fields you change are saved" : (root.track.fileName || "")
                    color: textSecondary
                    font.family: bodyFont
                    font.pixelSize: 12
                    elide: Text.ElideMiddle
                }
            }

            TransportButton { buttonSize: 32; iconName: "x"; tooltipText: "Close"; onClicked: root.close() }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: borderSubtle }

        AppFlickable {
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
            ScrollBar.vertical: AutoHideScrollBar {}

            GridLayout {
                id: metadataGrid
                width: metadataScroll.availableWidth
                columns: 2
                columnSpacing: 14
                rowSpacing: 12

                Label { visible: !root.batch; text: "Title"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12; Layout.preferredWidth: 110 }
                RefineTextInput { id: titleInput; visible: !root.batch; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Title" }
                Label { text: "Artist"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: artistInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("artist", "Artist"); onEdited: root.markEdited("artist") }
                Label { text: "Album"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: albumInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("album", "Album"); onEdited: root.markEdited("album") }
                Label { text: "Genre"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: genreInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("genre", "Genre"); onEdited: root.markEdited("genre") }
                Label { text: "Label"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: labelInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("label", "Label"); onEdited: root.markEdited("label") }
                Label { text: "Year"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: yearInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("year", "Year"); onEdited: root.markEdited("year") }
                Label { visible: !root.batch; text: "Track number"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: trackInput; visible: !root.batch; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: "Track number" }
                Label { text: "Disc number"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12 }
                RefineTextInput { id: discInput; Layout.fillWidth: true; Layout.minimumWidth: 0; placeholder: root.placeholderFor("discNumber", "Disc number"); onEdited: root.markEdited("discNumber") }
                Label { text: "Comment"; color: textSecondary; font.family: bodyFont; font.pixelSize: 12; Layout.columnSpan: 2 }
                TextArea {
                    id: commentInput
                    onTextChanged: if (activeFocus) root.markEdited("comment")
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
                    visible: !root.batch
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
                    visible: !root.batch
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
            color: accentText
            font.family: bodyFont
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 20
            SettingButton {
                visible: !root.batch
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
                    if (root.batch) {
                        const values = { artist: artistInput.text, album: albumInput.text, genre: genreInput.text,
                                         label: labelInput.text, year: yearInput.text, discNumber: discInput.text,
                                         comment: commentInput.text }
                        const changes = {}
                        Object.keys(root.edited).forEach(field => changes[field] = values[field])
                        if (Object.keys(changes).length === 0) return root.close()
                        const paths = root.tracks.map(item => item.filePath)
                        const saved = library.updateTracksMetadata(paths, changes)
                        const playing = library.tracksForPaths([player.currentTrack.filePath])[0]
                        if (playing)
                            player.updateCurrentTrackMetadata(playing)
                        if (saved === paths.length) {
                            root.appWindow.clearTrackSelection()
                            root.close()
                        } else {
                            root.errorText = (paths.length - saved) + " of " + paths.length + " files could not be saved."
                        }
                        return
                    }
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
