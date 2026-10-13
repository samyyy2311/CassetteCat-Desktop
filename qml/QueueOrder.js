.pragma library

// Turning shuffle off keeps the songs already heard where they were, so Previous still goes back to what was
// played. Only the songs still to come return to their original order, starting after the current song and
// wrapping round so none are dropped.
function unshuffled(queue, currentIndex, original, identity) {
    const position = {}
    original.forEach((track, index) => { position[identity(track)] = index })
    const start = position[identity(queue[currentIndex])] ?? -1
    const rank = track => {
        const index = position[identity(track)]
        return index === undefined ? original.length : (index - start - 1 + original.length) % original.length
    }
    const upcoming = queue.slice(currentIndex + 1).sort((a, b) => rank(a) - rank(b))
    return queue.slice(0, currentIndex + 1).concat(upcoming)
}

// Play Next has to survive turning shuffle off, so the original order gets the song right after the current one.
function withNext(original, current, track, identity) {
    const rest = original.filter(candidate => identity(candidate) !== identity(track))
    const at = rest.findIndex(candidate => identity(candidate) === identity(current))
    return rest.slice(0, at + 1).concat([track], rest.slice(at + 1))
}
