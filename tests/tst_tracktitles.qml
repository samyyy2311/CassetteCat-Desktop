import QtQuick
import QtTest
import "../qml/TrackTitles.js" as TrackTitles

TestCase {
    name: "TrackTitles"

    function test_featuring_moves_to_artist() {
        const track = { title: "10 Freaky Girls (feat. 21 Savage)", artist: "Metro Boomin" }
        compare(TrackTitles.title(track), "10 Freaky Girls")
        compare(TrackTitles.artist(track), "Metro Boomin, 21 Savage")
    }

    function test_guests_already_credited_are_not_repeated() {
        const track = { title: "3500 (feat. Future & 2 Chainz)", artist: "Travis Scott, Future" }
        compare(TrackTitles.title(track), "3500")
        compare(TrackTitles.artist(track), "Travis Scott, Future, 2 Chainz")
    }

    function test_with_and_brackets() {
        const track = { title: "30 For 30 [with Kendrick Lamar]", artist: "SZA" }
        compare(TrackTitles.title(track), "30 For 30")
        compare(TrackTitles.artist(track), "SZA, Kendrick Lamar")
    }

    function test_other_artists_leave_out_the_page_artist() {
        const track = { title: "2000 EXCURSION", artist: "Travis Scott, Sheck Wes & Don Toliver" }
        compare(TrackTitles.otherArtists(track, "travis scott"), "Sheck Wes, Don Toliver")
        compare(TrackTitles.otherArtists({ title: "SICKO MODE", artist: "Travis Scott" }, "Travis Scott"), "")
        compare(TrackTitles.otherArtists({ title: "Mr. Brightside", artist: "The Killers" }, "Travis Scott"), "The Killers")
        const albumTrack = { title: "ALL THE LOVE", artist: "Kanye West & Andre Troutman" }
        compare(TrackTitles.otherArtists(albumTrack, "Kanye West & Travis Scott"), "Andre Troutman")
        compare(TrackTitles.otherArtists({ title: "FATHER", artist: "Kanye West & Travis Scott" }, "Kanye West & Travis Scott"), "")
    }

    function test_plain_titles_are_unchanged() {
        const track = { title: "Runnin (Remix)", artist: "21 Savage" }
        compare(TrackTitles.title(track), "Runnin (Remix)")
        compare(TrackTitles.artist(track), "21 Savage")
        compare(TrackTitles.title({ title: "" }), "")
    }
}
