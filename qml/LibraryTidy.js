.pragma library

const tagFields = ["title", "artist", "album", "year", "trackNumber", "discNumber"]
const tagLabels = { title: "Title", artist: "Artist", album: "Album", year: "Year", trackNumber: "Track", discNumber: "Disc" }
const losslessFormats = ["FLAC", "ALAC", "WAV", "AIFF", "APE"]

const numberFields = ["year", "trackNumber", "discNumber"]

// Spelling that differs only in case, quote or dash style, or spacing reads the same, so it isn't a change.
function comparable(value) {
    return String(value || "").toLowerCase()
        .replace(/[\u2018\u2019\u02bc`\u00b4]/g, "'")
        .replace(/[\u201c\u201d]/g, '"')
        .replace(/[\u2010-\u2015]/g, "-")
        .replace(/\s+/g, " ")
        .trim()
}

// "Currents (Deluxe)" extends "Currents" with more words, but "Lovely" doesn't extend "Love".
function extendsWith(whole, start) {
    return whole.startsWith(start) && /^[\s(\[\-:/,.&]/.test(whole.slice(start.length))
}

// What a MusicBrainz match would change in a song; a field the song leaves empty counts as missing.
// With missingNumbersOnly, year, track and disc are only filled in, since editions of an album share a name but
// not their numbering. An album named as MusicBrainz's plus an edition, such as "(Deluxe)", is kept either way.
function tagChanges(song, tags, options) {
    const missingNumbersOnly = !!(options && options.missingNumbersOnly)
    return tagFields
        .filter(field => {
            if (tags[field] === undefined) return false
            const from = comparable(song[field] || "")
            const to = comparable(tags[field])
            if (from === to) return false
            if (missingNumbersOnly && numberFields.includes(field) && from !== "") return false
            // A title that only gains words, such as " - Remix" or " (Live)", belongs to another version of the song.
            if (field === "title" && from !== "" && extendsWith(to, from)) return false
            return !(field === "album" && extendsWith(from, to))
        })
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
