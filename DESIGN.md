# CassetteCat Desktop design

The visual system the app uses today, so new screens match it. Values come from `qml/Main.qml`.

## Color

Record red (`#C23B30`, hover `#D64337`) is CassetteCat's brand color. The other accent choices in Settings (amber, cyan, emerald, magenta, silver, custom) are user preferences that replace it in the interface only.

Surfaces are warm near-black, darkest to lightest:

| Token | Value | Use |
|---|---|---|
| `surfaceDeep` | `#0B0A09` | Behind full-bleed artwork: Now Playing, album and artist pages |
| `surfaceBase` | `#0E0D0C` | Window background |
| `surfaceSidebar` | `#131211` | Sidebar |
| `surfaceDock` | `#151412` | Player dock |
| `surfaceCard` | `#181715` | Cards, rows |
| `surfaceInput` | `#1A1917` | Text fields |
| `surfaceCardHover` | `#22201D` | Hovered cards |
| `surfaceElevated` | `#282623` | Popups, menus |

Text, brightest to dimmest. Each meets WCAG AA (4.5:1) on every surface above:

| Token | Value | Use |
|---|---|---|
| `textPrimary` | `#F5F0EC` | Titles, body |
| `textSecondary` | `#A8A49E` | Supporting text |
| `silverDim` | `#918E88` | Metadata, idle icons |
| `accentText` | accent, lightened to 4.5:1 | Small text in the accent color |

Status colors: `danger` (`#FF6B6B`) for errors and destructive actions, `success` (`#34D399`) for confirmations. Tints of them, the accent and the surfaces come from `Qt.alpha()` on the token, not new hex values.

Use `accentText`, never the raw accent, for text under 18px. Icons and shapes need 3:1: the raw accent meets it on `surfaceBase` and `surfaceCard` but not on `surfaceElevated` (2.85:1), so use `accentText` there. Text over cover art needs a dark overlay strong enough to hold 4.5:1 over pale art.

## Type

- Headings: Space Grotesk (`displayFont`).
- Body: IBM Plex Sans (`bodyFont`).
- Numbers, counts, small labels: IBM Plex Mono (`monoFont`).

## Icons

Lucide for interface icons, Simple Icons for brand marks.

## Direction

This system is settled and is not being redesigned. New screens reuse these tokens, fonts and icons and follow the existing screens; they do not introduce a new style.
