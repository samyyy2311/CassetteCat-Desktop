.pragma library

// WCAG 2 relative luminance, for colors with r, g and b from 0 to 1.
function luminance(color) {
    const channel = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
    return 0.2126 * channel(color.r) + 0.7152 * channel(color.g) + 0.0722 * channel(color.b)
}

function contrast(a, b) {
    const la = luminance(a)
    const lb = luminance(b)
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05)
}

// Reads a theme file, which is also how a theme is kept in settings. Accent is optional.
function parse(text) {
    let data
    try {
        data = JSON.parse(text)
    } catch (error) {
        throw new Error("This file isn't a theme")
    }
    if (!data || typeof data !== "object")
        throw new Error("This file isn't a theme")
    const theme = {}
    for (const key of ["background", "text", "textMuted", "accent"]) {
        if (key === "accent" && data[key] === undefined)
            continue
        if (typeof data[key] !== "string" || !/^#[0-9A-Fa-f]{6}$/.test(data[key]))
            throw new Error("The theme's " + key + " isn't a color like #1A1917")
        theme[key] = data[key].toUpperCase()
    }
    return theme
}
