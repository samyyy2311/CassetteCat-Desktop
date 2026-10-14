.pragma library

const tagFields = ["title", "artist", "album", "year", "trackNumber", "discNumber"]
const tagLabels = { title: "Title", artist: "Artist", album: "Album", year: "Year", trackNumber: "Track", discNumber: "Disc" }
const losslessFormats = ["FLAC", "ALAC", "WAV", "AIFF", "APE"]

// What a MusicBrainz match would change in a song; a field the song leaves empty counts as missing.
function tagChanges(song, tags) {
    return tagFields
        .filter(field => tags[field] !== undefined && String(tags[field]) !== String(song[field] || ""))
        .map(field => ({ field: field, label: tagLabels[field], from: String(song[field] || ""), to: String(tags[field]) }))
}

// Songs that share a title, artist and album. Each group lists the copy to keep first: lossless, then the largest file.
function duplicateGroups(songs) {
    const groups = {}
    songs.forEach(song => {
        const parts = [song.title, song.artist, song.album].map(value => String(value || "").trim().toLowerCase())
        if (!parts.join("")) return
        const key = parts.join("\u001f")
        groups[key] = (groups[key] || []).concat([song])
    })
    const quality = song => (losslessFormats.includes(String(song.format || "").toUpperCase()) ? 1e15 : 0) + Number(song.fileSize || 0)
    return Object.keys(groups)
        .filter(key => groups[key].length > 1)
        .map(key => groups[key].slice().sort((a, b) => quality(b) - quality(a)))
}
