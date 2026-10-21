import QtQuick
import QtTest
import "../qml/LyricsText.js" as LyricsText

TestCase {
    name: "LyricsText"

    function test_timestamps_round_to_hundredths() {
        compare(LyricsText.lrcTimestamp(0), "[00:00.00]")
        compare(LyricsText.lrcTimestamp(61234), "[01:01.23]")
        compare(LyricsText.lrcTimestamp(59996), "[01:00.00]")
    }

    function test_tapped_lines_become_lrc() {
        const lines = [{ text: "First" }, { text: "Second" }]
        compare(LyricsText.toLrc(lines, [1500, 4250]), "[00:01.50]First\n[00:04.25]Second")
    }

    function test_a_closing_word_time_ends_the_last_word() {
        const timed = LyricsText.timedWords("<00:12.30>Hello <00:12.80>world<00:13.50>", 0)
        compare(timed.text, "Hello world")
        compare(timed.endMs, 13500)
        const words = LyricsText.wordTimings({ timeMs: 12300, words: timed.words, wordsEndMs: timed.endMs }, 20000)
        compare(words[0].endMs, 12800)
        compare(words[1].endMs, 13500)
        compare(LyricsText.timedWords("<00:12.30>Hello <00:12.80>world", 0).endMs, -1)
    }
}
