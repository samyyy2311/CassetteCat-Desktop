import QtQuick

// Keeps queue rows in place across updates. Rebuilding the list on every change reset the view,
// which flashed on each song change and destroyed a row mid-drag.
ListModel {
    id: root
    property var entries: []
    property var entryByKey: ({})

    function keyFor(entry, seen) {
        let base
        if (entry.type === "header") base = "header:" + entry.title
        else if (entry.type === "current") base = "current"
        else base = (entry.queueEditable ? "next:" : "history:") + (entry.filePath || entry.title || "")
        const n = seen[base] || 0
        seen[base] = n + 1
        return base + "#" + n
    }

    function indexOfKey(key, from) {
        for (let i = from; i < count; ++i) {
            if (get(i).key === key) return i
        }
        return -1
    }

    function sync() {
        const seen = {}
        const lookup = {}
        const keys = entries.map(entry => {
            const key = keyFor(entry, seen)
            lookup[key] = entry
            return key
        })
        entryByKey = lookup
        for (let i = 0; i < keys.length; ++i) {
            if (i < count && get(i).key === keys[i]) continue
            const found = indexOfKey(keys[i], i + 1)
            if (found >= 0) move(found, i, 1)
            else insert(i, { key: keys[i] })
        }
        if (count > keys.length) remove(keys.length, count - keys.length)
    }

    onEntriesChanged: sync()
}
