import QtQuick
import QtTest
import "../qml/QueueOrder.js" as QueueOrder

TestCase {
    name: "QueueOrder"

    function id(track) { return track }

    function test_played_songs_stay_when_shuffle_turns_off() {
        // Played E, B, then H is playing; the rest was shuffled.
        const queue = ["E", "B", "H", "D", "J", "A", "I"]
        const original = ["A", "B", "D", "E", "H", "I", "J"]
        compare(QueueOrder.unshuffled(queue, 2, original, id), ["E", "B", "H", "I", "J", "A", "D"])
    }

    function test_nothing_upcoming_is_dropped() {
        const queue = ["C", "A", "B"]
        compare(QueueOrder.unshuffled(queue, 0, ["A", "B", "C"], id), ["C", "A", "B"])
        compare(QueueOrder.unshuffled(queue, 2, ["A", "B", "C"], id), ["C", "A", "B"])
    }

    function test_songs_missing_from_the_original_go_last() {
        compare(QueueOrder.unshuffled(["A", "X", "C", "B"], 0, ["A", "B", "C"], id), ["A", "B", "C", "X"])
    }

    function test_play_next_lands_after_the_current_song() {
        compare(QueueOrder.withNext(["A", "B", "C", "D"], "B", "D", id), ["A", "B", "D", "C"])
        compare(QueueOrder.withNext(["A", "B"], "B", "Z", id), ["A", "B", "Z"])
        compare(QueueOrder.withNext(["A", "B"], "Q", "Z", id), ["Z", "A", "B"])
    }

    function test_play_next_survives_turning_shuffle_off() {
        const original = QueueOrder.withNext(["A", "B", "C", "D"], "B", "D", id)
        // Shuffled while on B, with D chosen to play next.
        compare(QueueOrder.unshuffled(["A", "B", "D", "C"], 1, original, id), ["A", "B", "D", "C"])
    }
}
