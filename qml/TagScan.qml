import QtQuick
import "LibraryTidy.js" as LibraryTidy

// Checks songs against MusicBrainz one at a time, a second apart as MusicBrainz asks, and collects what would change.
// It lives with the window, so a long check keeps going while Settings is closed, and it is saved, so its progress
// and results survive closing the app.
QtObject {
    id: root

    // The songs this check covers, by file path; the full songs are looked up from the library as they're checked.
    property var songPaths: []
    property int checkedCount: 0
    property bool running: false
    property string problem: ""
    // Lookups in a row that MusicBrainz refused; a few in a row pause the check instead of skipping on.
    property int failuresInARow: 0
    readonly property bool paused: !running && checkedCount > 0 && checkedCount < songPaths.length
    // Songs whose details would change: { song, changes }
    property var details: []
    // Albums missing a cover, one per MusicBrainz release: { releaseId, album, artist, songs }
    property var covers: []
    // Items turned off in the review: songs by file path, covers by release.
    property var skippedDetails: ({})
    property var skippedCovers: ({})
    // Every song checked so far, by file path, so a new check of the whole library starts with the others.
    property var checkedBefore: ({})
    // Songs waiting for a cover being fetched, by the file path the fetch was made for.
    property var pendingCovers: ({})
    property var currentSong: null

    readonly property int acceptedDetails: details.filter(item => !skippedDetails[item.song.filePath]).length
    readonly property int acceptedCovers: covers.filter(item => !skippedCovers[item.releaseId]).length
    readonly property bool hasResults: details.length > 0 || covers.length > 0

    Component.onCompleted: {
        const saved = JSON.parse(appSettings.value("libraryHealth/tagScan", "{}") || "{}")
        songPaths = saved.songPaths || []
        checkedCount = saved.checkedCount || 0
        details = saved.details || []
        covers = saved.covers || []
        skippedDetails = saved.skippedDetails || {}
        skippedCovers = saved.skippedCovers || {}
        checkedBefore = saved.checkedBefore || {}
    }

    function save() {
        appSettings.setValue("libraryHealth/tagScan", JSON.stringify({
            songPaths: songPaths, checkedCount: checkedCount, details: details, covers: covers,
            skippedDetails: skippedDetails, skippedCovers: skippedCovers, checkedBefore: checkedBefore
        }))
    }

    // Only what the review shows and applies is kept for a song.
    function brief(song) {
        return { filePath: song.filePath, title: song.title || "", artist: song.artist || "", album: song.album || "" }
    }

    function isCheckable(song) {
        return song && song.filePath && !song.remoteId && song.format !== "STREAM" && song.title
    }

    // A check of the whole library starts with the songs not checked before; chosen songs are checked again.
    function startLibrary(songs) {
        begin(songs.filter(song => isCheckable(song) && !checkedBefore[song.filePath]))
    }

    function start(songs) {
        begin(songs.filter(isCheckable))
    }

    function checkAllAgain(songs) {
        checkedBefore = ({})
        startLibrary(songs)
    }

    function begin(songs) {
        songPaths = songs.map(song => song.filePath)
        checkedCount = 0
        details = []
        covers = []
        skippedDetails = ({})
        skippedCovers = ({})
        problem = ""
        failuresInARow = 0
        running = songPaths.length > 0
        save()
        lookUpNext()
    }

    function stop() {
        running = false
        save()
    }

    function resume() {
        problem = ""
        failuresInARow = 0
        running = true
        lookUpNext()
    }

    function setDetailSkipped(filePath, skip) {
        skippedDetails = Object.assign({}, skippedDetails, { [filePath]: skip })
        save()
    }

    function setCoverSkipped(releaseId, skip) {
        skippedCovers = Object.assign({}, skippedCovers, { [releaseId]: skip })
        save()
    }

    function setAllDetailsSkipped(skip) {
        const next = {}
        if (skip) details.forEach(item => next[item.song.filePath] = true)
        skippedDetails = next
        save()
    }

    function setAllCoversSkipped(skip) {
        const next = {}
        if (skip) covers.forEach(item => next[item.releaseId] = true)
        skippedCovers = next
        save()
    }

    function lookUpNext() {
        while (running && checkedCount < songPaths.length) {
            // A song removed from the library since the check began is passed over.
            const song = library.tracksForPaths([songPaths[checkedCount]])[0]
            if (song) {
                currentSong = song
                services.findMusicBrainzTags(song)
                return
            }
            checkedCount += 1
        }
        running = false
        currentSong = null
        save()
    }

    // Writes the accepted details into the files, and fetches each accepted album's cover once.
    function apply() {
        const updates = details.filter(item => !skippedDetails[item.song.filePath]).map(item => {
            const update = { filePath: item.song.filePath }
            item.changes.forEach(change => update[change.field] = change.to)
            return update
        })
        // A check can still be running, so only what was reviewed here leaves the lists; new finds stay.
        const reviewedSongs = details.map(item => item.song.filePath)
        const reviewedCovers = covers.map(item => item.releaseId)
        library.updateEachTrackMetadata(updates)
        const pending = {}
        covers.filter(item => !skippedCovers[item.releaseId]).forEach(item => {
            pending[item.songs[0].filePath] = item.songs.map(song => song.filePath)
            services.applyAlbumCover(item.album, item.artist, "https://coverartarchive.org/release/" + item.releaseId + "/front-1200",
                                     item.songs[0].filePath)
        })
        pendingCovers = Object.assign({}, pendingCovers, pending)
        const playing = player.currentTrack && player.currentTrack.filePath
                        ? library.tracksForPaths([player.currentTrack.filePath])[0] : null
        if (playing) player.updateCurrentTrackMetadata(playing)
        details = details.filter(item => !reviewedSongs.includes(item.song.filePath))
        covers = covers.filter(item => !reviewedCovers.includes(item.releaseId))
        skippedDetails = ({})
        skippedCovers = ({})
        save()
    }

    function addCover(song, tags) {
        const index = covers.findIndex(item => item.releaseId === tags.releaseId)
        if (index >= 0) {
            const next = covers.slice()
            next[index] = Object.assign({}, next[index], { songs: next[index].songs.concat([brief(song)]) })
            covers = next
        } else {
            covers = covers.concat([{ releaseId: tags.releaseId, album: tags.album || song.album,
                                      artist: tags.artist || song.artist, songs: [brief(song)] }])
        }
    }

    function markChecked(song) {
        checkedBefore = Object.assign({}, checkedBefore, { [song.filePath]: true })
        checkedCount += 1
        // Saving every few songs keeps a closed app from losing more than a few seconds of the check.
        if (checkedCount % 10 === 0) save()
    }

    property Connections lookups: Connections {
        target: services
        // Only the songs that were missing a cover get it in their files; the album's others keep their own.
        function onCoverApplied(album, artist, artworkPath, filePath) {
            const paths = root.pendingCovers[filePath]
            if (!paths) return
            library.embedArtwork(paths, artworkPath)
            const next = Object.assign({}, root.pendingCovers)
            delete next[filePath]
            root.pendingCovers = next
        }
        function onMusicBrainzTagsReady(filePath, tags, problem) {
            const song = root.currentSong
            if (!root.running || !song || filePath !== song.filePath)
                return
            if (problem === "off") {
                root.running = false
                root.problem = qsTr("MusicBrainz is turned off. Turn it on in Network & Services, then continue.")
                root.save()
                return
            }
            if (problem === "busy") {
                root.failuresInARow += 1
                if (root.failuresInARow >= 3) {
                    // Continue starts again from the first song refused in this run, so none of them is missed.
                    root.checkedCount -= root.failuresInARow - 1
                    root.running = false
                    root.problem = qsTr("MusicBrainz is busy right now. Continue in a few minutes, from where it stopped.")
                    root.save()
                    return
                }
                root.checkedCount += 1
                root.lookUpNext()
                return
            }
            root.failuresInARow = 0
            const changes = LibraryTidy.tagChanges(song, tags, { missingNumbersOnly: true })
            if (changes.length > 0)
                root.details = root.details.concat([{ song: root.brief(song), changes: changes }])
            if (tags.releaseId && !song.artworkUrl && !library.hasEmbeddedArtwork(song.filePath))
                root.addCover(song, tags)
            root.markChecked(song)
            root.lookUpNext()
        }
    }
}
