import QtQml

QtObject {
    readonly property var inAppActions: [
        { action: "toggleMiniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+M", icon: "pip", iconColor: "#A5B4FC" },
        { action: "toggleSidebar", label: "Toggle Sidebar", defaultKey: "Ctrl+B", icon: "panel-left", iconColor: "#96918A" },
        { action: "search", label: "Open Search", defaultKey: "Ctrl+F", icon: "search", iconColor: "#F59E0B" },
        { action: "quickSwitcher", label: "Quick Switcher", defaultKey: "Ctrl+K", icon: "key-round", iconColor: "#38BDF8" },
        { action: "closePlayerView", label: "Close Player View", defaultKey: "Escape", icon: "x", iconColor: "#C4C4C0" },
        { action: "playPause", label: "Play / Pause", defaultKey: "Space", icon: "play", iconColor: "#10B981" },
        { action: "volumeUp", label: "Volume Up", defaultKey: "Ctrl+Up", icon: "volume-2", iconColor: "#F59E0B" },
        { action: "volumeDown", label: "Volume Down", defaultKey: "Ctrl+Down", icon: "volume-1", iconColor: "#F59E0B" },
        { action: "seekForward", label: "Seek Forward", defaultKey: "Ctrl+Right", icon: "skip-forward", iconColor: "#38BDF8" },
        { action: "seekBackward", label: "Seek Backward", defaultKey: "Ctrl+Left", icon: "skip-back", iconColor: "#38BDF8" },
        { action: "nowPlayingNext", label: "Seek Forward (5s)", defaultKey: "Right", icon: "skip-forward", iconColor: "#38BDF8" },
        { action: "nowPlayingPrevious", label: "Seek Backward (5s)", defaultKey: "Left", icon: "skip-back", iconColor: "#38BDF8" },
        { action: "mute", label: "Mute", defaultKey: "M", icon: "volume-x", iconColor: "#C23B30" }
    ]

    function defaultKey(action) {
        for (let index = 0; index < inAppActions.length; ++index) {
            if (inAppActions[index].action === action) return inAppActions[index].defaultKey
        }
        return ""
    }
}
