import QtQml

QtObject {
    readonly property var inAppActions: [
        { action: "toggleMiniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+M", icon: "pip" },
        { action: "toggleSidebar", label: "Toggle Sidebar", defaultKey: "Ctrl+B", icon: "panel-left" },
        { action: "search", label: "Open Search", defaultKey: "Ctrl+F", icon: "search" },
        { action: "quickSwitcher", label: "Quick Switcher", defaultKey: "Ctrl+K", icon: "command" },
        { action: "closePlayerView", label: "Close Player View", defaultKey: "Escape", icon: "chevron-down" },
        { action: "playPause", label: "Play / Pause", defaultKey: "Space", icon: "play" },
        { action: "volumeUp", label: "Volume Up", defaultKey: "Ctrl+Up", icon: "volume-2" },
        { action: "volumeDown", label: "Volume Down", defaultKey: "Ctrl+Down", icon: "volume-1" },
        { action: "seekForward", label: "Seek Forward (5s)", defaultKey: "Ctrl+Right", icon: "fast-forward" },
        { action: "seekBackward", label: "Seek Backward (5s)", defaultKey: "Ctrl+Left", icon: "rewind" },
        { action: "nowPlayingNext", label: "Next Track (Player View)", defaultKey: "Right", icon: "skip-forward" },
        { action: "nowPlayingPrevious", label: "Previous Track (Player View)", defaultKey: "Left", icon: "skip-back" },
        { action: "mute", label: "Mute", defaultKey: "M", icon: "volume-x" }
    ]

    function defaultKey(action) {
        for (let index = 0; index < inAppActions.length; ++index) {
            if (inAppActions[index].action === action) return inAppActions[index].defaultKey
        }
        return ""
    }

    function toSequence(shortcut) {
        let value = String(shortcut || "").trim()
        if (value.endsWith("\u00BB"))
            value = value.replace(/\u00BB$/, /Shift\+/i.test(value) ? "+" : "=")
        return value.replace(/Equal$/i, "=").replace(/Plus$/i, "+")
    }

    function defaultBindings() {
        const bindings = {}
        for (let index = 0; index < inAppActions.length; ++index) {
            bindings[inAppActions[index].action] = inAppActions[index].defaultKey
        }
        return bindings
    }
}
