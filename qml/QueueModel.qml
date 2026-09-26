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

        // Plan the edits on a copy first; a reorder that needs many steps (a shuffle) is cheaper as a reset.
        const wanted = new Set(keys)
        const rows = rowKeys.slice()
        const steps = []
        for (let i = 0; i < keys.length && steps.length <= 64; ++i) {
            while (i < rows.length && !wanted.has(rows[i])) {
                steps.push({ remove: i })
                rows.splice(i, 1)
            }
            if (rows[i] === keys[i]) continue
            const found = rows.indexOf(keys[i], i + 1)
            if (found >= 0) {
                steps.push({ from: found, to: i })
                rows.splice(i, 0, rows.splice(found, 1)[0])
            } else {
                steps.push({ insert: i, key: keys[i] })
                rows.splice(i, 0, keys[i])
            }
        }

        if (steps.length > 64 || count === 0) {
            clear()
            append(keys.map(key => ({ key: key })))
        } else {
            for (const step of steps) {
                if (step.remove !== undefined) remove(step.remove, 1)
                else if (step.insert !== undefined) insert(step.insert, { key: step.key })
                else move(step.from, step.to, 1)
            }
            if (count > keys.length) remove(keys.length, count - keys.length)
        }
        rowKeys = keys
    }

    onEntriesChanged: sync()
}
