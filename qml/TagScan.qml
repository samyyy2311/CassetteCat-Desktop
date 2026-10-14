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
    // Each: { song, tags, changes, addsCover }
    property var suggestions: []
    // Suggestions turned off in the review, by file path.
    property var skipped: ({})

    readonly property int acceptedCount: suggestions.filter(item => !skipped[item.song.filePath]).length

    function start(list) {
        songs = (list || []).filter(song => song && song.filePath && !song.remoteId && song.format !== "STREAM" && song.title)
        checkedCount = 0
        suggestions = []
        skipped = ({})
        problem = ""
        running = songs.length > 0
        lookUpNext()
    }

    function stop() {
        running = false
    }

    function setSkipped(filePath, skip) {
        skipped = Object.assign({}, skipped, { [filePath]: skip })
    }

    function lookUpNext() {
        if (!running) return
        if (checkedCount >= songs.length) {
            running = false
            return
        }
        services.findMusicBrainzTags(songs[checkedCount])
    }

    // Writes the accepted changes into the files, and fetches a cover for each album that was missing one.
    function apply() {
        const accepted = suggestions.filter(item => !skipped[item.song.filePath])
        const updates = accepted.filter(item => item.changes.length > 0).map(item => {
            const update = { filePath: item.song.filePath }
            item.changes.forEach(change => update[change.field] = change.to)
            return update
        })
        library.updateEachTrackMetadata(updates)
        const albums = {}
        accepted.filter(item => item.addsCover).forEach(item => albums[item.tags.releaseId] = albums[item.tags.releaseId] || item)
        Object.keys(albums).forEach(releaseId => {
            const item = albums[releaseId]
            services.applyAlbumCover(item.tags.album || item.song.album, item.tags.artist || item.song.artist,
                                     "https://coverartarchive.org/release/" + releaseId + "/front-1200", item.song.filePath)
        })
        const playing = player.currentTrack && player.currentTrack.filePath
                        ? library.tracksForPaths([player.currentTrack.filePath])[0] : null
        if (playing) player.updateCurrentTrackMetadata(playing)
        suggestions = []
        skipped = ({})
    }

    property Connections lookups: Connections {
        target: services
        function onMusicBrainzTagsReady(filePath, tags, reached) {
            if (!root.running || root.checkedCount >= root.songs.length || filePath !== root.songs[root.checkedCount].filePath)
                return
            if (!reached) {
                root.running = false
                root.problem = "Couldn't reach MusicBrainz. Check that it's on in Network & Services."
                return
            }
            const song = root.songs[root.checkedCount]
            const changes = LibraryTidy.tagChanges(song, tags)
            const addsCover = !song.artworkUrl && !!tags.releaseId
            if (changes.length > 0 || addsCover)
                root.suggestions = root.suggestions.concat([{ song: song, tags: tags, changes: changes, addsCover: addsCover }])
            root.checkedCount += 1
            root.lookUpNext()
        }
    }
}
