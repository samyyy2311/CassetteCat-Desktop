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
}
