import QtQml

QtObject {
    readonly property var inAppActions: [
        { action: "toggleMiniPlayer", label: "Toggle Mini Player", defaultKey: "Ctrl+M" },
        { action: "toggleSidebar", label: "Toggle Sidebar", defaultKey: "Ctrl+B" },
        { action: "search", label: "Open Search", defaultKey: "Ctrl+F" },
        { action: "closePlayerView", label: "Close Player View", defaultKey: "Escape" },
        { action: "playPause", label: "Play / Pause", defaultKey: "Space" },
        { action: "volumeUp", label: "Volume Up", defaultKey: "Ctrl+Up" },
        { action: "volumeDown", label: "Volume Down", defaultKey: "Ctrl+Down" },
        { action: "seekForward", label: "Seek Forward", defaultKey: "Ctrl+Right" },
        { action: "seekBackward", label: "Seek Backward", defaultKey: "Ctrl+Left" },
        { action: "nowPlayingNext", label: "Seek Forward in Player View", defaultKey: "Right" },
        { action: "nowPlayingPrevious", label: "Seek Backward in Player View", defaultKey: "Left" },
        { action: "mute", label: "Mute", defaultKey: "M" }
    ]

    function defaultKey(action) {
        for (let index = 0; index < inAppActions.length; ++index) {
            if (inAppActions[index].action === action) return inAppActions[index].defaultKey
        }
        return ""
    }
}
