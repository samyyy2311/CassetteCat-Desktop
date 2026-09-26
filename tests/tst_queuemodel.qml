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
}
