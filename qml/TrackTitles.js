.pragma library

// Card and row labels move "(feat. X)" / "[with X]" from the title to the artist line, so titles fit.
// The stored title stays untouched for search, scrobbling and metadata.
const featuring = /\s*[(\[]\s*(?:feat\.?|ft\.?|featuring|with)\s+([^)\]]+)[)\]]/i

function title(track) {
    const full = track.title || ""
    return full.replace(featuring, "").trim() || full
}

function artist(track) {
    const main = track.artist || ""
    const match = (track.title || "").match(featuring)
    if (!match)
        return main
    const known = main.toLowerCase()
    const guests = match[1].split(/\s*(?:,|&|\band\b)\s*/i).filter(name => name && known.indexOf(name.toLowerCase()) < 0)
    if (guests.length === 0)
        return main
    return main ? main + ", " + guests.join(", ") : guests.join(", ")
}
