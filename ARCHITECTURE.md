# Architecture

CassetteCat Desktop is a C++20 and Qt 6 app with a QML interface. C++ owns playback, the library, network services and the operating system integrations; QML owns everything on screen. It runs on Windows and Linux, and a macOS version is in development.

There is no dependency-injection framework. `src/main.cpp` creates one object of each controller and hands them to QML as context properties: `library`, `player`, `streaming`, `services`, `appSettings`, `phoneRemote`, `smtc`, `mpris`, `discord`, `globalShortcuts`, `tray` and `windowFrame`.

## Starting up (`src/main.cpp`)

- **One instance.** A `QLocalServer` named `CassetteCat.Desktop.Instance` (`CassetteCat.Desktop.Dev.Instance` for Debug builds, so they run beside the installed app) lets a second launch, such as opening a song from the file manager, pass its file to the running app and exit.
- **Self-checks.** `--self-check` and the other flags in [Building and testing](docs/dev/building.md#testing) run each controller's `selfCheck()` without showing a window.
- **Library scans.** `--scan-library <folder>` scans one folder and prints its songs as JSON. `LibraryController` starts the app again with this flag for each folder, so a crash in a damaged file's tags can't take the app down.
- **Microsoft Store.** When installed from the Store, `installedFromStore` hides the update check, since the Store updates the app.

## Playback (`src/player_controller.*`, `src/audio_pipeline.*`)

- **`PlayerController`** holds the queue position, ReplayGain, the volume limit, crossfade and the equalizer settings. It plays through two `QMediaPlayer`s: while one track ends, the next one fades in on the other.
- **`AudioPipeline`** receives both players' decoded audio through `QAudioBufferOutput`, mixes it, applies the ten-band equalizer (biquad filters at the AutoEq bands) and the volume, and plays it on one `QAudioSink` fed from its own thread. Because the next song is decoded into its own queue while the last one's samples still play, there's no gap between tracks. An empty output device follows the system default.
- **Remote tracks** resolve to authenticated stream URLs in C++, so server passwords and tokens never reach QML.

## Library (`src/library_controller.*`, `src/library_scanner.*`, `src/audio_metadata.*`)

- **`library_scanner`** finds audio files (AAC, AIFF, ALAC, FLAC, M4A, MP3, Ogg, Opus, WAV and WMA) and reads their tags with TagLib 2.3, which CMake downloads and builds.
- **`LibraryController`** keeps the songs, folders, playlists, likes and the Listening Record, filters and sorts for the Library and Search pages, and watches the music folders with `QFileSystemWatcher`.
- **Tags and covers** are written to the files themselves: `updateTracksMetadata` and `updateEachTrackMetadata` for song details, `embedArtwork` for covers, both through `audio_metadata`. Removing duplicates moves files to the Recycle Bin or trash with `QFile::moveToTrash`.
- **`image_cache`** serves covers to QML as `image://cover/...`, decoding them off the GUI thread.

## Library Health (`qml/TagScan.qml`, `qml/LibraryTidy.js`, `src/services_tags.cpp`)

`ServicesController::findMusicBrainzTags` looks a song up on MusicBrainz, a request at least 1.1 seconds after the last, as MusicBrainz asks, and retries when it's busy. `TagScan` walks a list of songs through it and keeps what would change, saved in the settings so a check survives a restart. `LibraryTidy.js` decides which differences count as a change and groups duplicate songs; its tests are in `tests/tst_librarytidy.qml`.

## Streaming (`src/streaming*.cpp`, `src/remote_track_model.*`)

`StreamingController` signs in to Subsonic, Navidrome and Jellyfin servers, loads their libraries into `RemoteTrackModel`, and syncs likes with them. Subsonic requests use a salted token, never the password. A self-signed server certificate is trusted only when the user turns that on for that server.

## Online services (`src/services_*.cpp`)

`ServicesController` makes every request to an outside service, and none while Offline Blackout Mode is on or the service is turned off in **Settings > Network & Services**.

| File | Does |
| :--- | :--- |
| `services_lyrics.cpp` | Synced and plain lyrics from LRCLIB |
| `services_covers.cpp` | Cover search across iTunes, Deezer and MusicBrainz's Cover Art Archive |
| `services_artist.cpp` | Artist photos and descriptions from TheAudioDB and Wikipedia |
| `services_tags.cpp` | Song details from MusicBrainz |
| `services_scrobble.cpp` | ListenBrainz, Last.fm and Libre.fm scrobbling |
| `services_controller.cpp` | Radio Browser stations, the update check, and what the others share |

## Phone remote (`src/remote_control.*`, `src/remote_tls.*`)

`RemoteControlServer` is the HTTPS server the Android app talks to. It answers discovery broadcasts on UDP port 47800 and serves HTTPS on port 47800 too, or any free port when that one is taken, with a self-signed certificate made on first use (`remote_tls`) that phones pin when they pair. Phones pair by asking and being allowed on the computer, or with the six-character pairing code. Every request is listed in the [Desktop Remote protocol](https://github.com/samyyy2311/CassetteCat/blob/main/docs/dev/desktop-remote-protocol.md) in the Android repository.

## Operating system integrations

| File | Does |
| :--- | :--- |
| `credential_vault.cpp` | Server passwords and scrobbling tokens in Windows Credential Manager, the macOS Keychain or the Secret Service through `libsecret` on Linux. Never in the settings file. |
| `smtc_controller.cpp`, `macos_now_playing.*` | Media keys and the system's now-playing controls on Windows and macOS |
| `mpris_controller.*`, `mpris_adaptor.*` | MPRIS over D-Bus on Linux |
| `window_frame.cpp` | The frameless window's maximize button, so Windows 11 shows Snap Layouts on it |
| `global_shortcut_controller.cpp` | Shortcuts that work while the app is in the background |
| `tray_controller.cpp` | The tray icon and its menu |
| `discord_presence.cpp` | Discord status through Discord's local IPC socket |
| `app_settings.cpp` | Settings storage and the debug log |

## Interface (`qml/`)

`Main.qml` is the window: the sidebar, the page loaders, the player dock, Now Playing and the shared colour tokens. Each page and Settings section is its own file (`LibraryPage.qml`, `SettingsLibraryHealthSection.qml` and so on), built from shared controls such as `SettingButton`, `SettingRow`, `SettingSwitch`, `AppDialog` and `PressDepthIconButton`. `MiniPlayerWindow.qml` is the separate mini player window. Pure logic lives in `.js` files with tests in `tests/`. Colours, type and icons are in [DESIGN.md](DESIGN.md).
