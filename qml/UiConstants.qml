pragma Singleton
import QtQuick

QtObject {
    // Animation durations (ms)
    readonly property int durationFast: 120
    readonly property int durationStd: 200
    readonly property int durationEmphasis: 240
    readonly property int durationOverlay: 280

    // Easing curves
    readonly property int easingStd: Easing.OutCubic
    readonly property int easingBounce: Easing.OutBack

    // Scroll physics
    readonly property real flickDeceleration: 900
    readonly property real maximumFlickVelocity: 4500
    readonly property int cacheBuffer: 350

    // Lyrics highlight scroll durations
    readonly property int highlightDurationFull: 500
    readonly property int highlightDurationMini: 400
}
