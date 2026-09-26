import QtQuick
import QtTest
import "../qml"

TestCase {
    name: "QueueModel"

    QueueModel { id: model }

    function next(path, index) {
        return { type: "track", filePath: path, queueEditable: true, queueIndex: index }
    }

    function keys() {
        const result = []
        for (let i = 0; i < model.count; ++i) result.push(model.get(i).key)
        return result.join(",")
    }

    function test_reorder_moves_rows_instead_of_rebuilding() {
        model.entries = [{ type: "current", filePath: "now" }, next("a", 1), next("b", 2), next("c", 3)]
        compare(keys(), "current#0,next:a#0,next:b#0,next:c#0")

        let moves = 0
        const count = () => ++moves
        model.rowsMoved.connect(count)
        model.entries = [{ type: "current", filePath: "now" }, next("c", 1), next("a", 2), next("b", 3)]
        model.rowsMoved.disconnect(count)
        compare(keys(), "current#0,next:c#0,next:a#0,next:b#0")
        verify(moves > 0)
        compare(model.entryByKey["next:c#0"].queueIndex, 1)
    }

    function test_insert_remove_and_duplicates() {
        model.entries = [next("a", 0), next("a", 1), next("b", 2)]
        compare(keys(), "next:a#0,next:a#1,next:b#0")
        model.entries = [next("b", 0)]
        compare(keys(), "next:b#0")
        model.entries = []
        compare(model.count, 0)
    }

    function test_large_queue_loads_quickly() {
        const big = []
        for (let i = 0; i < 2000; ++i) big.push(next("song" + i, i))
        model.entries = []
        const started = Date.now()
        model.entries = big
        compare(model.count, 2000)
        // The quadratic version took seconds; this bound catches that without being timing-sensitive.
        verify(Date.now() - started < 1000, "loading 2000 rows took " + (Date.now() - started) + " ms")
        big.push(big.shift())
        model.entries = big.slice()
        compare(model.get(1999).key, "next:song0#0")
    }

    function test_single_change_in_large_queue_keeps_other_rows() {
        const songs = []
        for (let i = 0; i < 200; ++i) songs.push(next("s" + i, i))
        model.entries = []
        model.entries = songs.slice()

        let removed = 0
        let inserted = 0
        const onRemoved = () => ++removed
        const onInserted = () => ++inserted
        model.rowsRemoved.connect(onRemoved)
        model.rowsInserted.connect(onInserted)
        model.entries = [next("new", 0)].concat(songs)
        compare(inserted, 1)
        compare(removed, 0)
        model.entries = songs.slice(1)
        model.rowsRemoved.disconnect(onRemoved)
        model.rowsInserted.disconnect(onInserted)
        compare(removed, 2)
        compare(model.count, 199)
        compare(model.get(0).key, "next:s1#0")
    }
}
