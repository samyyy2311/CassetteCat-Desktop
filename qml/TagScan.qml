import QtQuick
import "LibraryTidy.js" as LibraryTidy

// Checks songs against MusicBrainz one at a time, a second apart as MusicBrainz asks, and collects what would change.
// It lives with the window, so a long check keeps going while Settings is closed.
QtObject {
    id: root

    property var songs: []
    property int checkedCount: 0
    property bool running: false
    property string problem: ""
    // Lookups in a row that MusicBrainz refused; a few in a row pause the check instead of skipping on.
    property int failuresInARow: 0
    readonly property bool paused: !running && checkedCount > 0 && checkedCount < songs.length
    // Songs whose details would change: { song, changes }
    property var details: []
    // Albums missing a cover, one per MusicBrainz release: { releaseId, album, artist, songs }
    property var covers: []
    // Items turned off in the review: songs by file path, covers by release.
    property var skippedDetails: ({})
    property var skippedCovers: ({})
    // Songs waiting for a cover being fetched, by the file path the fetch was made for.
    property var pendingCovers: ({})

    readonly property int acceptedDetails: details.filter(item => !skippedDetails[item.song.filePath]).length
    readonly property int acceptedCovers: covers.filter(item => !skippedCovers[item.releaseId]).length
    readonly property bool hasResults: details.length > 0 || covers.length > 0

    function start(list) {
        songs = (list || []).filter(song => song && song.filePath && !song.remoteId && song.format !== "STREAM" && song.title)
        checkedCount = 0
        details = []
        covers = []
        skippedDetails = ({})
        skippedCovers = ({})
        problem = ""
        failuresInARow = 0
        running = songs.length > 0
        lookUpNext()
    }

    function stop() {
        running = false
    }

    function resume() {
        problem = ""
        failuresInARow = 0
        running = true
        lookUpNext()
    }

    function setDetailSkipped(filePath, skip) {
        skippedDetails = Object.assign({}, skippedDetails, { [filePath]: skip })
    }

    function setCoverSkipped(releaseId, skip) {
        skippedCovers = Object.assign({}, skippedCovers, { [releaseId]: skip })
    }

    function setAllDetailsSkipped(skip) {
        const next = {}
        if (skip) details.forEach(item => next[item.song.filePath] = true)
        skippedDetails = next
    }

    function setAllCoversSkipped(skip) {
        const next = {}
        if (skip) covers.forEach(item => next[item.releaseId] = true)
        skippedCovers = next
    }

    function lookUpNext() {
        if (!running) return
        if (checkedCount >= songs.length) {
            running = false
            return
        }
        services.findMusicBrainzTags(songs[checkedCount])
    }

    // Writes the accepted details into the files, and fetches each accepted album's cover once.
    function apply() {
        const updates = details.filter(item => !skippedDetails[item.song.filePath]).map(item => {
            const update = { filePath: item.song.filePath }
            item.changes.forEach(change => update[change.field] = change.to)
            return update
        })
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
        details = []
        covers = []
        skippedDetails = ({})
        skippedCovers = ({})
    }

    function addCover(song, tags) {
        const index = covers.findIndex(item => item.releaseId === tags.releaseId)
        if (index >= 0) {
            const next = covers.slice()
            next[index] = Object.assign({}, next[index], { songs: next[index].songs.concat([song]) })
            covers = next
        } else {
            covers = covers.concat([{ releaseId: tags.releaseId, album: tags.album || song.album,
                                      artist: tags.artist || song.artist, songs: [song] }])
        }
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
            if (!root.running || root.checkedCount >= root.songs.length || filePath !== root.songs[root.checkedCount].filePath)
                return
            if (problem === "off") {
                root.running = false
                root.problem = "MusicBrainz is turned off. Turn it on in Network & Services, then continue."
                return
            }
            if (problem === "busy") {
                root.failuresInARow += 1
                if (root.failuresInARow >= 3) {
                    root.running = false
                    root.problem = "MusicBrainz is busy right now. Continue in a few minutes, from where it stopped."
                    return
                }
                root.checkedCount += 1
                root.lookUpNext()
                return
            }
            root.failuresInARow = 0
            const song = root.songs[root.checkedCount]
            const changes = LibraryTidy.tagChanges(song, tags, { missingNumbersOnly: true })
            if (changes.length > 0)
                root.details = root.details.concat([{ song: song, changes: changes }])
            if (tags.releaseId && !song.artworkUrl && !library.hasEmbeddedArtwork(song.filePath))
                root.addCover(song, tags)
            root.checkedCount += 1
            root.lookUpNext()
        }
    }
}
