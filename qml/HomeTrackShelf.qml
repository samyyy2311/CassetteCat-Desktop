import QtQuick

Column {
    id: root
    property string title: ""
    property string subtitle: ""
    property var tracks: []
    property real sideMargin: 32

    signal trackSelected(var track)
    signal shuffleSelected()

    x: sideMargin
    width: parent ? parent.width - sideMargin * 2 : 0
    visible: tracks.length > 0
    spacing: 16

    HomeSectionHeader {
        title: root.title
        subtitle: root.subtitle
        onPlayClicked: {
            if (root.tracks.length > 0) root.trackSelected(root.tracks[0])
        }
        onShuffleClicked: root.shuffleSelected()
    }

    ListView {
        width: parent.width
        height: 225
        orientation: ListView.Horizontal
        spacing: 16
        clip: false
        boundsBehavior: Flickable.StopAtBounds
        model: root.tracks

        delegate: SongCard {
            cardWidth: 150
            cardHeight: 225
            track: modelData
            onClicked: root.trackSelected(track)
        }
    }
}
