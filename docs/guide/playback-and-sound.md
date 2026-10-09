# Playback and sound

## Now Playing

Click the cover in the player bar to open **Now Playing**: large artwork, the song, its album and the progress bar. The badge under the artist names the audio quality, such as Hi-Res Lossless, Lossless or the codec. Click it for the format, sample rate, bit depth, bitrate and encoding.

The buttons at the top add the song to your favourites, open the song menu and the mini player, and switch between the lyrics and the queue. **Escape** closes Now Playing, and the **Left** and **Right** arrow keys change songs while it's open.

## The queue

The queue shows what's playing next. Drag a song by its handle to move it, or remove it with its button. **Play Next** and **Add to Queue** in any song's menu add to it.

- **Resume Queue on Launch** (**Settings > Playback & Audio**) brings back the song, queue and position when you open CassetteCat.
- **Autoplay** keeps playing songs similar to the last one when the queue runs out.
- **Save Queue**, on the Library page, turns the queue into a playlist.

## How songs play

- **Gapless playback**: songs play back to back with no gap, so live albums and DJ mixes run on as recorded.
- **Song changes**: skipping fades briefly instead of cutting.
- **Crossfade**: fades each song into the next as it ends, for up to 10 seconds.
- **Volume Normalization (ReplayGain)**: evens out loudness between songs (**Track**) or keeps the levels of an album as mastered (**Album**), using the ReplayGain tags in your files.
- **Volume Limit**: caps the volume slider at 50 to 90 percent to protect your hearing.
- **Playback Device**: picks the speakers or headphones CassetteCat plays through, apart from the system default.

## Equalizer

**Settings > Playback & Audio > Equalizer** has ten bands from 31 Hz to 16 kHz and a preamp.

- **Preset** gives starting points such as Bass Boost, Treble Boost, Vocal and Loudness that you can adjust band by band.
- **Headphone Correction** applies a measured curve from the [AutoEq](https://github.com/jaakkopasanen/AutoEq) project that evens out the sound of your headphones. Pick your model from the list.
- **Reset** sets every band and the preamp back to 0 dB.

## Sleep timer

**Settings > Playback & Audio > Sleep Timer** stops playback after 15, 30, 45 or 60 minutes, or at the end of the current song. **Gentle Fade-Out** lowers the volume slowly before it stops.

## Lyrics

Open lyrics with the quotation-mark button in the player bar or in Now Playing. Synced lyrics scroll with the song and highlight the current line; click a line to jump to it. Instrumental songs are marked as such instead of showing nothing.

CassetteCat looks for lyrics in this order:

1. A `.lrc` file next to the song with the same name.
2. Lyrics embedded in the file's tags. Turn off **Prefer Local .lrc Files** in **Settings > Lyrics** to try these before the `.lrc` file.
3. Your Jellyfin server, for songs streamed from it.
4. [LRCLIB](https://lrclib.net), if **LrcLib Lyrics** is on in **Settings > Network & Services**.

**Choose lyrics** picks a different version from LRCLIB when the first match is wrong. If synced lyrics run early or late, the **-** and **+** buttons in Now Playing shift them in steps of 0.1 seconds, and CassetteCat remembers it for that song.

**Timing plain lyrics.** If a song only has unsynced lyrics, click **Tap to Sync** in Now Playing and press **Space** as each line starts. The undo button takes back the last tap. When you finish, the timings are saved into the song, so the lyrics scroll from then on.

**Settings > Lyrics** sets the text size, alignment, and whether the current line is highlighted in your accent colour or white.

## Mini player

**Ctrl+M** (**Cmd+M** on a Mac), or the mini player button in the player bar, swaps the main window for a small player. It can show the artwork, the lyrics or the queue, and **Keep Mini Player on Top** (**Settings > General & System**) floats it above other windows. Restore the full player from its button.

## System media controls

CassetteCat works with each system's own controls:

- **Windows**: the media overlay and keyboard media keys, and play, pause and skip buttons in the taskbar thumbnail.
- **macOS**: the media keys, and Now Playing in Control Center.
- **Linux**: MPRIS, so your desktop's media controls, media keys and tools such as `playerctl` work.

When **Close to System Tray** is on, the tray icon's menu also plays, pauses and skips.

## Keyboard shortcuts

On a Mac, use **Cmd** where this table says **Ctrl**.

| Action | Default |
| :--- | :--- |
| Play or pause | Space |
| Volume up / down | Ctrl+Up / Ctrl+Down |
| Mute | M |
| Seek forward / back 5 seconds | Ctrl+Right / Ctrl+Left |
| Next / previous song (in Now Playing) | Right / Left |
| Close Now Playing | Escape |
| Open search | Ctrl+K |
| Search this page | Ctrl+F |
| Toggle the mini player | Ctrl+M |
| Toggle the sidebar | Ctrl+B |

Change any of them in **Settings > Keyboard Shortcuts**: click a shortcut and press the new keys.
