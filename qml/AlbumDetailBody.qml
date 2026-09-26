import QtQuick
import QtQuick.Controls

ListView {
    id: root
    activeFocusOnTab: true
    onCurrentIndexChanged: if (activeFocus) positionViewAtIndex(currentIndex, ListView.Contain)
    property var tracks: []
    property var appWindow
    // Album pages only: numbered rows without the album artist.
    property string albumArtist: ""
    property bool showFormatBadge: true

    clip: true
    spacing: 4
    model: root.tracks
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: UiConstants.flickDeceleration
    maximumFlickVelocity: UiConstants.maximumFlickVelocity
    cacheBuffer: UiConstants.cacheBuffer
    pixelAligned: UiConstants.pixelAligned
    reuseItems: true
    ScrollBar.vertical: AutoHideScrollBar {}

    delegate: FocusScope {
        width: root.width
        height: songRow.height

        SongRow {
            id: songRow
            focus: true
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            track: modelData
            number: root.albumArtist ? index + 1 : 0
            omitArtist: root.albumArtist
            showAlbum: !root.albumArtist
            showFormatBadge: root.showFormatBadge && (typeof window === "undefined" || window.showFormatBadges !== false)
            onClicked: root.appWindow.playTrack(modelData)
            onFavoriteClicked: if (root.appWindow) root.appWindow.toggleFavorite(modelData.filePath)
        }
    }
}
