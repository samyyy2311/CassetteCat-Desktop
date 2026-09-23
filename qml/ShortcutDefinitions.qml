import QtQml

QtObject {
    readonly property var inAppActions: [
        { action: "toggleMiniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+M", icon: "pip" },
        { action: "toggleSidebar", label: "Toggle Sidebar", defaultKey: "Ctrl+B", icon: "panel-left" },
        { action: "search", label: "Open Search", defaultKey: "Ctrl+F", icon: "search" },
        { action: "quickSwitcher", label: "Quick Switcher", defaultKey: "Ctrl+K", icon: "key-round" },
        { action: "closePlayerView", label: "Close Player View", defaultKey: "Escape", icon: "x" },
        { action: "playPause", label: "Play / Pause", defaultKey: "Space", icon: "play" },
        { action: "volumeUp", label: "Volume Up", defaultKey: "Ctrl+Up", icon: "volume-2" },
        { action: "volumeDown", label: "Volume Down", defaultKey: "Ctrl+Down", icon: "volume-1" },
        { action: "seekForward", label: "Seek Forward", defaultKey: "Ctrl+Right", icon: "skip-forward" },
        { action: "seekBackward", label: "Seek Backward", defaultKey: "Ctrl+Left", icon: "skip-back" },
        { action: "nowPlayingNext", label: "Next Track in Player", defaultKey: "Right", icon: "skip-forward" },
        { action: "nowPlayingPrevious", label: "Previous Track in Player", defaultKey: "Left", icon: "skip-back" },
        { action: "mute", label: "Mute", defaultKey: "M", icon: "volume-x" }
    ]

    function defaultKey(action) {
        for (let index = 0; index < inAppActions.length; ++index) {
            if (inAppActions[index].action === action) return inAppActions[index].defaultKey
        }
        return ""
    }
}
