import QtQuick
import QtTest
import "../qml/LibraryTidy.js" as LibraryTidy

TestCase {
    name: "LibraryTidy"

    function test_changes_list_only_what_differs() {
        const song = { title: "A-Team", artist: "Ed Sheeran", album: "+", year: 0, trackNumber: 1 }
        const tags = { title: "The A Team", artist: "Ed Sheeran", album: "+", year: 2011, trackNumber: 1 }
        compare(LibraryTidy.tagChanges(song, tags).map(change => change.field + ":" + change.from + ">" + change.to),
                ["title:A-Team>The A Team", "year:>2011"])
    }

    function test_cosmetic_and_edition_differences_are_not_changes() {
        const song = { title: "'Cause I'm a Man", artist: "Tame Impala", album: "Miss Anthropocene (Rave Edition)", year: 2020, trackNumber: 3 }
        const tags = { title: "\u2019Cause I\u2019m a Man", artist: "tame  impala", album: "Miss Anthropocene", year: 2024, trackNumber: 2 }
        compare(LibraryTidy.tagChanges(song, tags, { missingNumbersOnly: true }), [])
        // Asked about one song on purpose, numbers are still corrected.
        compare(LibraryTidy.tagChanges(song, tags).map(change => change.field), ["year", "trackNumber"])
    }

    function test_a_version_suffix_is_not_a_title_fix() {
        compare(LibraryTidy.tagChanges({ title: "Aa Jao" }, { title: "Aa Jao - Jhankar" }), [])
        // A longer word isn't a version suffix, so it's still a correction.
        compare(LibraryTidy.tagChanges({ title: "Love" }, { title: "Lovely" }).map(change => change.to), ["Lovely"])
    }

    function test_duplicates_keep_the_lossless_or_largest_copy() {
        const songs = [
            { filePath: "a.mp3", title: "Song", artist: "Band", album: "LP", format: "MP3", fileSize: 9000000 },
            { filePath: "b.flac", title: "song ", artist: "band", album: "lp", format: "FLAC", fileSize: 30000000 },
            { filePath: "c.m4a", title: "Song", artist: "Band", album: "LP", format: "AAC", fileSize: 7000000 },
            { filePath: "d.mp3", title: "Other", artist: "Band", album: "LP", format: "MP3", fileSize: 5000000 },
            { filePath: "e.mp3", title: "", artist: "", album: "" },
            { filePath: "f.mp3", title: "", artist: "", album: "" }
        ]
        compare(LibraryTidy.duplicateGroups(songs).map(group => group.map(song => song.filePath)),
                [["b.flac", "a.mp3", "c.m4a"]])
    }
}
