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

    // Mirrors the row order, so lookups avoid reading rows back out of the model.
    property var rowKeys: []

    function sync() {
        const seen = {}
        const lookup = {}
        const keys = entries.map(entry => {
            const key = keyFor(entry, seen)
            lookup[key] = entry
            return key
        })
        entryByKey = lookup
        if (count === 0) {
            append(keys.map(key => ({ key: key })))
            rowKeys = keys
            return
        }
        let changed = 0
        for (let i = 0; i < keys.length && changed <= 64; ++i) {
            if (rowKeys[i] !== keys[i]) ++changed
        }
        if (changed > 64) {
            clear()
            append(keys.map(key => ({ key: key })))
            rowKeys = keys
            return
        }
        const rows = rowKeys.slice()
        for (let i = 0; i < keys.length; ++i) {
            if (rows[i] === keys[i]) continue
            const found = rows.indexOf(keys[i], i + 1)
            if (found >= 0) {
                move(found, i, 1)
                rows.splice(i, 0, rows.splice(found, 1)[0])
            } else {
                insert(i, { key: keys[i] })
                rows.splice(i, 0, keys[i])
            }
        }
        if (rows.length > keys.length) {
            remove(keys.length, rows.length - keys.length)
            rows.length = keys.length
        }
        rowKeys = rows
    }

    onEntriesChanged: sync()
}
