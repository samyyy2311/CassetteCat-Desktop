.pragma library

function escape(text) {
    return String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

// Rich text for a lyric line; the active line fades each word in as the song reaches it.
function karaoke(lines, index, activeIndex, positionMs, color, text) {
    if (index !== activeIndex || !lines || !lines[index] || lines[index].timeMs < 0)
        return escape(text)
    const r = Math.round(color.r * 255)
    const g = Math.round(color.g * 255)
    const b = Math.round(color.b * 255)
    const words = String(text || "").split(/(\s+)/)
    const start = lines[index].timeMs
    const next = lines[index + 1] && lines[index + 1].timeMs >= 0 ? lines[index + 1].timeMs : start + 3000
    const progress = Math.max(0, Math.min(1, (positionMs - start) / Math.max(800, next - start)))
    const characters = Math.max(1, String(text || "").replace(/\s/g, "").length)
    let consumed = 0
    return words.map(function(word) {
        if (/^\s+$/.test(word))
            return word
        const middle = (consumed + word.length * 0.5) / characters
        consumed += word.length
        const t = Math.max(0, Math.min(1, (progress - middle + 0.16) / 0.16))
        const alpha = 0.42 + t * t * (3 - 2 * t) * 0.58
        return "<span style=\"color:rgba(" + r + "," + g + "," + b + "," + alpha.toFixed(2) + ")\">" + escape(word) + "</span>"
    }).join("")
}
