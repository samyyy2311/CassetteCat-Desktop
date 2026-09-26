import QtQuick
import QtTest
import "../qml"

TestCase {
    name: "CatalogTrackList"
    width: 1000
    height: 600
    when: windowShown

    AlbumDetailBody {
        id: list
        anchors.fill: parent
        property int liveRows: 0
        header: Item { width: list.width; height: 320 }
        footer: Item { width: 1; height: 100 }
        delegate: Item {
            required property var modelData
            width: list.width
            height: 54
            Component.onCompleted: list.liveRows++
            Component.onDestruction: list.liveRows--
        }
    }

    function test_largeFolder() {
        const tracks = []
        for (let i = 0; i < 608; ++i)
            tracks.push({ filePath: "English/" + i + ".mp3" })
        list.tracks = tracks
        tryCompare(list, "count", 608)
        tryVerify(() => list.liveRows > 0)
        verify(list.liveRows < 40, "Opening a folder must not create every row")
        list.positionViewAtIndex(607, ListView.End)
        tryVerify(() => list.itemAtIndex(607) !== null)
        compare(list.itemAtIndex(607).modelData.filePath, "English/607.mp3")
        verify(list.liveRows < 40, "Scrolling must keep delegate creation bounded")
        list.tracks = []
        tryCompare(list, "count", 0)
    }

    function test_keyboardNavigation() {
        const tracks = []
        for (let i = 0; i < 100; ++i)
            tracks.push({ filePath: i + ".mp3" })
        list.tracks = tracks
        tryCompare(list, "count", 100)
        tryCompare(list.populate, "running", false)
        list.forceActiveFocus()
        for (let i = 0; i < 20; ++i)
            keyClick(Qt.Key_Down)
        compare(list.currentIndex, 20)
        verify(list.currentItem.activeFocus, "The current row must receive keyboard focus")
        verify(list.contentY > 0, "Keyboard navigation must scroll the current row into view")
        list.tracks = []
        tryCompare(list, "count", 0)
    }
}
