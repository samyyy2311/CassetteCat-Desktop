.pragma library

function escape(text) {
    return String(text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
}

function stampMs(minutes, seconds, fraction) {
    const ms = !fraction ? 0 : fraction.length === 1 ? Number(fraction) * 100 : fraction.length === 2 ? Number(fraction) * 10 : Number(fraction.substring(0, 3))
    return (Number(minutes) * 60 + Number(seconds)) * 1000 + ms
}

// Enhanced LRC times each word, as in "<00:12.30>Hello <00:12.80>world". Returns the plain text and, when the
// line has word times, each word's characters and start time.
function timedWords(text, offsetMs) {
    const pattern = /<(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?>/g
    if (!pattern.test(text))
        return { text: text, words: null }
    pattern.lastIndex = 0
    const words = []
    let plain = ""
    let startMs = -1
    let last = 0
    let match
    const take = chunk => {
        const leading = chunk.length - chunk.trimStart().length
        const word = chunk.trim()
        if (word && startMs >= 0) {
            const start = plain.length + leading
            words.push({ start: start, end: start + word.length, startMs: startMs })
        }
        plain += chunk
    }
    while ((match = pattern.exec(text)) !== null) {
        take(text.substring(last, match.index))
        startMs = Math.max(0, stampMs(match[1], match[2], match[3]) + offsetMs)
        last = pattern.lastIndex
    }
    take(text.substring(last))
    const trimmed = plain.length - plain.trimStart().length
    words.forEach(word => { word.start -= trimmed; word.end -= trimmed })
    return { text: plain.trim(), words: words }
}

// When each word of a line is sung, from its word times or, without them, spread over the line by length.
function wordTimings(line, endMs) {
    if (line.words && line.words.length)
        return line.words.map((word, i) => ({ start: word.start, end: word.end, startMs: word.startMs,
                                              endMs: i + 1 < line.words.length ? line.words[i + 1].startMs : endMs }))
    const text = String(line.text || "")
    const spans = []
    const pattern = /\S+/g
    let match
    while ((match = pattern.exec(text)) !== null)
        spans.push({ start: match.index, end: match.index + match[0].length })
    const total = spans.reduce((sum, span) => sum + span.end - span.start, 0) || 1
    const duration = Math.max(400, endMs - line.timeMs)
    let sung = 0
    return spans.map(span => {
        const startMs = line.timeMs + duration * sung / total
        sung += span.end - span.start
        return { start: span.start, end: span.end, startMs: startMs, endMs: line.timeMs + duration * sung / total }
    })
}

// "[mm:ss.xx]" as LRC files write it.
function lrcTimestamp(ms) {
    const centis = Math.max(0, Math.round(ms / 10))
    const minutes = Math.floor(centis / 6000)
    const seconds = Math.floor(centis / 100) % 60
    const pad = value => String(value).padStart(2, "0")
    return "[" + pad(minutes) + ":" + pad(seconds) + "." + pad(centis % 100) + "]"
}

// Synced lyrics from plain [lines] and the time each one was tapped.
function toLrc(lines, stampsMs) {
    return lines.map((line, i) => lrcTimestamp(stampsMs[i]) + line.text).join("\n")
}

