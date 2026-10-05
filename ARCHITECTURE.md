# Architecture & System Design

CassetteCat Desktop is a native desktop audio player built with C++20 and Qt 6.10+. This document describes the internal architecture, subsystem designs, data flow, and platform integration layers.

---

## 1. System Overview & Technology Stack

The application is structured as a native C++ engine managing business logic, audio decoding, local filesystem indexing, network protocols, and OS APIs, paired with a hardware-accelerated Qt Quick (QML) declarative interface.

* **Core Language**: C++20 (`std::span`, concepts, modern `<chrono>`, smart pointers)
* **Application Framework**: Qt 6.10+ (Quick, Quick Controls 2, Multimedia, Concurrent, Network, Widgets)
* **Metadata & Tagging**: [TagLib](https://taglib.org) 2.0.2 (built via CMake FetchContent or linked via system packages)
* **Build System**: CMake 3.24+ with Ninja build presets (`cmake --preset dev`)
* **Supported Platforms**:
  * **Windows**: Windows 10/11 (MSVC 2022 / MinGW-w64), Windows Media Transport Controls (C++/WinRT), Windows Credential Manager (`wincred.h`), DWM frameless windowing
  * **Linux**: GCC 13+ / Clang 17+, MPRIS 2 D-Bus interface, Secret Service API via `libsecret`, Flatpak, AppImage

---

## 2. Process Lifecycle & Single Instance Architecture

All entry logic resides in `src/main.cpp`:

```text
User Launch / File Click
          │
          ▼
   Check CLI Args
          │
   ┌──────┴──────┐
   │ --self-check│ ──► Runs deterministic tests for all controllers & exits
   └──────┬──────┘
          ▼
Single Instance Check:
   Windows: Named Mutex "CassetteCat.AudioEngine.Desktop.InstanceMutex"
   All: QLocalServer "CassetteCat.Desktop.Instance"
          │
    ┌─────┴────────────────────────┐
    ▼                              ▼
Already Running?             First Instance?
    │                              │
Send JSON IPC Handoff:        Start QLocalServer
{"action":"activate",         Initialize QGuiApplication
 "path":"/path/to/song"}      Instantiate Core Controllers
    │                         Register QML Context Properties
Exit Current Process          Load QML Engine (CassetteCat::Main)
```

1. **Single Instance Handoff**:
   * Uses a platform mutex on Windows (`CreateMutexW`) and a local IPC socket (`QLocalServer` / `QLocalSocket`) named `CassetteCat.Desktop.Instance`.
   * If a second instance launches (e.g., user double-clicks an audio file or an `.m3u` playlist in Windows Explorer / Linux file manager), it writes a JSON payload `{"action": "activate", "path": "<file>"}` to the running server.
   * The running instance receives the connection in `handleInstanceSocket`, invokes `openExternalPath()`, queues or plays the file, and brings the main window to the front via `activateWindow()`.
2. **Deterministic Self-Check**:
   * Invoked via `CassetteCat --self-check`.
   * Executes headless unit checks across `PlayerController::selfCheck()`, `LibraryController::selfCheck()`, `ServicesController::selfCheck()`, `MprisController::selfCheck()`, and `RemoteControlServer::selfCheck()` without starting a GUI event loop.
3. **Microsoft Store Detection**:
   * Calls Windows API `GetCurrentPackageFullName()`. When installed via MSIX from the Microsoft Store, automatic GitHub update checks are disabled and update settings are hidden, deferring lifecycle management to the Store.
4. **DWM Frameless Windowing (Windows)**:
   * `setupWindowsFrameless()` extends the DWM frame into the client area using `DwmExtendFrameIntoClientArea()`.
   * Subclasses the native window procedure to handle `WM_NCCALCSIZE` and `WM_NCHITTEST`, eliminating default Win32 window titlebars while preserving native snap layouts, aero glass shadows, resize borders, and window animations.

---

## 3. Subsystem Breakdown

### 3.1 Audio Playback Engine (`src/player_controller.*`)

The audio engine wraps Qt Multimedia components with custom state management and DSP attenuation:

* **Dual-Player Crossfading**:
  * Implemented using two `QMediaPlayer` and `QAudioOutput` instances (`m_player` and `m_crossfadePlayer`).
  * When crossfade is enabled (`crossfadeMs` = 3000, 6000, or 10000 ms), the controller monitors track progress. When `duration - position <= crossfadeMs`, the incoming track begins playing on the secondary output and fades in while the outgoing track fades out.
  * Skipping or seeking cuts immediately over to avoid audio collision.
* **ReplayGain Processing**:
  * TagLib extracts `REPLAYGAIN_TRACK_GAIN`, `REPLAYGAIN_TRACK_PEAK`, `REPLAYGAIN_ALBUM_GAIN`, and `REPLAYGAIN_ALBUM_PEAK`.
  * Computes linear gain multiplier:
    $$\text{factor} = 10^{\frac{\text{gain\_dB}}{20}}$$
  * Applies peak clipping protection: if $\text{factor} \times \text{peak} > 1.0$, the factor is clamped to $\frac{1.0}{\text{peak}}$.
  * Scales `QAudioOutput::setVolume()` transparently beneath the user's master volume slider.
* **Audio Level Metering**:
  * `QAudioBufferOutput` receives raw decoded PCM samples, calculates root-mean-square (RMS) amplitude levels, and exposes `audioLevel` to QML at 60 Hz for UI visualization.
* **Smart Autoplay**:
  * When the user's explicit queue finishes, `LibraryController::similarTracks()` seeds recommendations based on the last played song.
  * Uses weighted attribute matching (shared primary genre, matching artist, and release year within $\pm 5$ years), excluding tracks played earlier in the current session.

---

### 3.2 Library Scanner & Audio Metadata Engine (`src/library_scanner.*`, `src/library_controller.*`, `src/audio_metadata.*`)

* **Threaded Discovery**:
  * `LibraryScanner` runs off the main GUI thread using `QtConcurrent::run()`.
  * Recursively traverses configured root directories, filtering for supported audio extensions (`.mp3`, `.flac`, `.m4a`, `.aac`, `.ogg`, `.opus`, `.wav`).
  * Files smaller than 3 seconds or marked hidden can be excluded based on user settings.
  * Monitors live filesystem changes using `QFileSystemWatcher`.
* **TagLib Parsing Pipeline (`audio_metadata.cpp`)**:
  * Uses `TagLib::FileRef` with format-specific tag handlers:
    * ID3v2 (`TagLib::ID3v2::Tag`): Extracts `TIT2` (title), `TPE1` (artist), `TPE2` (album artist), `TALB` (album), `TCON` (genre), `TDRC`/`TYER` (year), `TRCK` (track index), `TPOS` (disc index), and `USLT` (unsynced lyrics).
    * FLAC / Vorbis Comments: Reads key-value metadata fields including `DISCNUMBER`, `TRACKNUMBER`, and `LYRICS`.
    * MP4 Atoms: Reads standard iTunes-style metadata (`\xa9nam`, `\xa9ART`, `aART`, `\xa9alb`, `\xa9day`, `trkn`, `disk`).
* **Batch Tag Editing (`LibraryController::updateTracksMetadata`)**:
  * Allows bulk editing of tracks directly on disk.
  * Only modified fields are written; untouched tag frames remain bit-identical.
  * TagLib writes changes to disk, updates internal in-memory models, and emits fine-grained change signals to QML without forcing full library rescans.
* **Content-Addressed Artwork Cache (`image_cache.cpp`)**:
  * Extracts raw cover art bytes (`APIC` frame in ID3v2, `METADATA_BLOCK_PICTURE` in FLAC, `covr` atom in MP4).
  * Hashes raw bytes with SHA-1 to deduplicate images across identical albums.
  * Writes full-size images to disk cache and exposes an in-memory thumbnail cache via `CoverImageProvider` (`image://cover/<path>`).

---

### 3.3 Streaming & Remote Media Protocol Adapters (`src/streaming.*`, `src/streaming_protocols.*`, `src/remote_track_model.*`)

Enables remote media consumption without local file downloads:

* **Subsonic / Navidrome Protocol**:
  * Implements the Subsonic REST API (v1.16.1+).
  * **Authentication**: Generates a random salt per session and computes $\text{token} = \text{MD5}(\text{password} + \text{salt})$. Plaintext passwords are never sent or cached.
  * **Endpoints**: `ping.view`, `getArtists.view`, `getArtist.view`, `getAlbum.view`, `getCoverArt.view`, `stream.view`, `search3.view`.
  * **Self-Signed Certificates**: Allows optional override to trust self-signed TLS certificates for private home servers.
* **Jellyfin Protocol**:
  * Connects via Jellyfin REST API.
  * Sends client authorization headers (`X-Emby-Authorization`) including client version, device name, and device UUID.
  * Supports QuickConnect flow: displays a 6-digit code on desktop and polls `/QuickConnect/Connect` until authorized by the user on their Jellyfin web dashboard.
* **Credential Isolation**:
  * Streaming credentials live exclusively in native OS vaults and transient C++ network request headers.
  * Stream URLs passed to QML are resolved in C++ (`resolveMediaSource`) so tokens and session keys are never exposed in QML property trees or debug inspectors.
* **RemoteTrackModel (`remote_track_model.cpp`)**:
  * A `QAbstractListModel` subclass providing fast, virtualized item delivery to QML views for remote libraries containing tens of thousands of tracks.

---

### 3.4 Phone Remote & Local Wi-Fi Sync (`src/remote_control.*`)

CassetteCat Desktop embeds an HTTP server and UDP broadcaster to interface with CassetteCat for Android on the local area network (LAN):

```text
    Desktop App                                    Android App
         │                                              │
         │ ─── UDP Broadcast (Port 58943) ────────────► │ Zero-conf discovery
         │     "CassetteCat:Desktop:<port>:<name>"      │
         │                                              │
         │ ◄── POST /api/pair {device, code} ────────── │ User enters 4-digit PIN
         │ ─── 200 OK (Bearer Token issued) ──────────► │ Device paired
         │                                              │
         │ ◄── GET /api/status (Poll) ───────────────── │ Long-poll status
         │ ─── 200 OK {track, position, queue, likes} ► │ Updates phone UI
         │                                              │
         │ ◄── POST /api/command {play, seek, ...} ──── │ User taps control
         │ ─── 200 OK ────────────────────────────────► │ Desktop executes
```

* **Service Discovery**: Broadcasts discovery datagrams on UDP port 58943. Android devices on the same subnet detect running desktop players automatically.
* **Authentication**: Generates a 4-digit PIN displayed in Desktop settings. Pairing requests require explicit confirmation on desktop. Failed attempts trigger exponential cooldowns to block local brute-force attempts.
* **Sync Capabilities**:
  * **Playback Handoff**: Moves songs, active queue, and seek positions between devices. Tracks are matched by normalized title and artist.
  * **Likes Synchronization**: Bi-directionally syncs favorite track lists.
  * **Playlist Sync**: Imports and exports user playlists over HTTP JSON payloads.
  * **Backups**: Android app sends encrypted daily backup archives to desktop for safe keeping.
  * **Cover Art Stream**: Serves extracted album covers directly to the phone at up to 1440 px resolution.

---

### 3.5 Operating System & Native Integrations

* **Credential Storage (`src/credential_vault.cpp`)**:
  * **Windows**: Uses Windows Credential Manager (`wincred.h`) via `CredWriteW`, `CredReadW`, and `CredDeleteW`. Secrets are stored under the target prefix `CassetteCat/<key>`.
  * **Linux**: Uses the FreeDesktop Secret Service API via `libsecret` (`secret_password_store_sync`, `secret_password_lookup_sync`).
* **Media Transport Controls**:
  * **Windows SMTC (`src/smtc_controller.cpp`)**: Integrates with `Windows.Media.Playback.MediaPlayer` and `SystemMediaTransportControls` via C++/WinRT. Binds hardware play/pause/skip media keys, taskbar controls, and Windows 10/11 volume flyouts.
  * **Linux MPRIS 2 (`src/mpris_controller.cpp`, `src/mpris_adaptor.cpp`)**: Implements `org.mpris.MediaPlayer2` and `org.mpris.MediaPlayer2.Player` over D-Bus, supporting desktop media widgets and lock-screen controls.
* **Discord Rich Presence (`src/discord_presence.cpp`)**:
  * Connects directly to local Discord client IPC sockets (`\\.\pipe\discord-ipc-0` through `9` on Windows; `$XDG_RUNTIME_DIR/discord-ipc-*` on Linux).
  * Transmits JSON RPC handshake and activity frames with timestamps, track title, artist, album, and artwork keys.
* **Global Keyboard Shortcuts (`src/global_shortcut_controller.cpp`)**:
  * Low-level Windows keyboard hook (`SetWindowsHookExW` with `WH_KEYBOARD_LL`) allowing global background shortcuts even when the application is minimized or unfocused.
* **System Tray (`src/tray_controller.cpp`)**:
  * Uses `QSystemTrayIcon` to support minimize-to-tray, background playback, and a quick tray menu.

---

### 3.6 Online Services & Scrobbling (`src/services_controller.*`)

* **Lyrics Engine (`src/services_lyrics.cpp`)**:
  * Queries [LRCLIB](https://lrclib.net) (`/api/get` and `/api/search`) using track title, artist, album, and duration.
  * Supports synchronized timestamped lyrics (`[mm:ss.xx]`) and plain text fallback.
  * Cached locally in SQLite/settings.
* **Scrobbling (`src/services_scrobble.cpp`)**:
  * **ListenBrainz**: Submits JSON payloads to `https://api.listenbrainz.org/1/submit-listens` with user token validation.
  * **Libre.fm**: Submits GNU FM 2.0 handshake and scrobble calls via authenticated session keys.
* **Radio Browser (`src/services_controller.cpp`)**:
  * Queries `https://de1.api.radio-browser.info/json/stations/search` for live internet radio stations.
* **Cover Art Search (`src/services_covers.cpp`)**:
  * Queries iTunes Search API, MusicBrainz, Cover Art Archive, TheAudioDB, and Deezer for online album art retrieval.
* **Offline Blackout Mode**:
  * When enabled, a global filter intercepts and cancels all outbound `QNetworkRequest` calls originating from service controllers.

---

## 4. UI Architecture & QML Integration (`qml/`)

The user interface is entirely declarative, using Qt Quick and Quick Controls 2 with a custom design system:

* **Design Tokens (`qml/UiConstants.qml`)**:
  * Exposes colors, spacing metrics, corner radii, and font bindings as a QML singleton.
  * Supports dynamic theme switching (Dark and Light modes) with smooth color animations.
* **Navigation Architecture**:
  * `Main.qml` acts as the root window. It hosts the collapsible sidebar navigation, page router, mini player overlay, and Now Playing deck.
  * Navigation occurs via stack and tab transitions through `EnterAnimation.qml`.
* **Mini Player (`qml/MiniPlayerWindow.qml`)**:
  * A separate `QQuickWindow` instance that can detach into a compact, always-on-top floating desk player.
* **Performance & Virtualization**:
  * Uses `AppListView` and `AppGridView` wrappers around Qt Quick `ListView` and `GridView` with `reuseItems: true` to support smooth 60/120 Hz scrolling on libraries exceeding 100,000 files.
  * Queue rows in `QueueModel.qml` are mutated in-place rather than rebuilt on track changes, eliminating UI stuttering.
