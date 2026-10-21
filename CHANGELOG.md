# Changelog

All notable changes to CassetteCat Desktop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

## [1.0.1] - 2026-10-22

### Added
* Search finds songs by a line from their lyrics. Turn on Find Songs by Their Lyrics in Settings > Lyrics to download lyrics for your library in the background, so search has them to look through.
* Smart playlists that fill themselves from rules you pick, the same rules as on the phone.
* Choose which pages the sidebar shows and in what order, in Settings > General & System > Sidebar.
* Pick the app's language in Settings > General & System. It switches at once, without a restart.
* An A to Z bar beside long lists in the Library jumps to a letter.
* Full screen Now Playing, also on F11, and a Moving backdrop that slowly drifts the cover's colours.
* Choose the app font, and a font and weight for lyrics.
* Hold or tap Alt to show the letter that opens each page.

### Changed
* Synced lyrics light up word by word and follow the song more smoothly.
* Settings is grouped more clearly: Appearance is now Look & Feel, and Playback & Audio is split into Sound and Playback. Each setting has an icon that matches what it does.
* Pages are rebuilt each time you open them, and covers use less memory, so the app uses noticeably less RAM.
* A thin loading bar shows while a page or its covers load, instead of empty covers flashing up.
* Previous restarts the song after its first 3 seconds, as on the phone.
* The volume limit turns all playback down instead of capping the slider.

### Fixed
* Bold text across the app now looks bold.
* Some songs never got lyrics from LRCLIB; they now do.
* A Jellyfin or Subsonic search is kept when you come back to its page.
* The list of Settings pages scrolls when the window is short, so the last pages are no longer cut off.

---

## [1.0.0] - 2026-10-15

### Added
* Library Health in Settings. Fix Tags checks every song, or the ones you select, with MusicBrainz in the background, and lists the song details and album covers it would fix. Nothing changes until you review the lists and click Apply.
* Library Health also finds duplicate songs, keeps the best copy, and moves the copies you pick to the Recycle Bin.
* Fill from MusicBrainz in the tag editor, and Edit Metadata in every song's right-click menu.
* Covers you pick are also saved into the music files, so File Explorer and other players show them. A switch under the cover search turns this off.
* Search in Settings, in the title bar or with Ctrl+F.
* Disconnect in the Phone Remote window, so the phone and the computer each play their own music. They stay paired.

### Changed
* Liking a Subsonic or Jellyfin song likes it on the server too.
* System Default follows Windows' default output, and a chosen output that's unplugged plays on the default until it's back.
* Network & Services calls the Cover Art Archive switch MusicBrainz, since it also looks up song details.
* Scrobbling settings say why ListenBrainz refused your listens, such as an email address that isn't verified yet.
* The macOS app is in development, so this release doesn't include it.

### Fixed
* Previous goes back to the song you heard after turning shuffle off, Play Next keeps its place, and Autoplay no longer turns shuffle off.
* No more silence after resuming when the audio output dropped while paused, such as after moving music to the phone.
* Maximizing works with the mini player open, the window corners are square while maximized, and hovered covers aren't cut off on artist pages and in search.

---

## [0.9.0] - 2026-10-09

### Added
* Your phone can browse this computer's music and play it, on the computer or streamed to the phone.
* The player bar shows what your phone is playing and controls it. Play Here moves the song to the computer, and music plays on one device at a time.
* Phone Remote has its own page in Settings, with the pairing code and a list of paired phones you can remove.
* One Listening Record with your phone: plays count the same way on both, songs you skip still add listening time, and a Sync button brings them together.
* A ten-band equalizer with AutoEq correction for your headphones.
* Last.fm scrobbling, alongside ListenBrainz and Libre.fm.
* Search shows matching artists and albums, remembers your recent searches, and can play or shuffle every result.
* A short setup when you first open the app, to choose your music folder and colours.
* Windows: Snap Layouts on the maximize button, rounded window corners, and play controls in the taskbar preview.
* macOS: media keys and Now Playing in Control Center.
* The Windows installer can start CassetteCat when you sign in, and asks before deleting your settings and Listening Record on uninstall.

### Changed
* Songs play back to back with no gap, and changing songs fades briefly instead of cutting.
* Buttons and choices look the same throughout the app, and the player bar is calmer.
* The Listening Record names months Jan, Feb, Mar instead of single letters.
* Lossless audio is called Lossless rather than Lossless Uncompressed.

### Fixed
* The app no longer uses CPU while idle because of hidden loading bars.

---

## [0.8.1] - 2026-10-08

### Added
* **macOS**: A universal app for Apple silicon and Intel Macs, shipped as a disk image. Passwords are kept in the Keychain. The app is not notarized yet.
* **Linux ARM64**: `.AppImage`, `.deb`, `.rpm` and `.tar.gz` packages for ARM64 alongside x86_64.
* **Audio quality badge**: Now Playing shows Hi-Res Lossless, Lossless or the codec under the artist. Click it for the format, sample rate, bit depth, bitrate and encoding, matching the Android app.
* **Publisher details**: The Windows executable, macOS bundle and Linux listing name CaffeineLabs as the publisher. Settings, Credits & Legal shows the version, website and privacy policy.
* The Microsoft Store package is attached to each GitHub release.

### Changed
* Uses less memory: about 500 MB instead of 720 MB on Home, and about 10-20 MB while hidden in the tray instead of about 500 MB (as shown in Task Manager).
* Downloaded covers are stored at up to 1536 px instead of full size, and covers already cached are shrunk in the background. The covers folder takes well under half the space, with no visible change.
* The mini player's controls match the main player bar, with tooltips and keyboard focus.
* Home shows a loading bar while it builds, like the other pages.
* Grey and accent-colored text meets WCAG AA contrast on every surface.

### Fixed
* Clicking the mini player's taskbar button minimizes it.
* The playing song's cover is shown at full resolution instead of a stretched 512 px copy, and the phone remote shows covers for queued songs again.
* The README and installer no longer mention gapless playback, which the app does not have.

---

## [0.8.0] - 2026-10-05

### Added
* **Phone Remote & Wi-Fi Sync**: Pair with CassetteCat for Android on your local network. Handoff playback with queue and position, send songs to play next between devices, keep likes and playlists in sync, and receive daily backups from the phone.
* **Batch Tag Editing**: Select multiple tracks in the library to edit artist, album, genre, year, disc number, and comment simultaneously. Only modified fields are written to files.
* **Track Crossfade**: Configurable 3, 6, or 10-second crossfades between tracks using dual playback engines while preserving ReplayGain levels.
* **Tap-to-Sync Lyrics**: Interactive timing tool in the lyrics view. Tap Space or click lines along with playback to stamp timestamps and save synced lyrics directly to audio tags.
* **Smart Autoplay**: Continues playback when the queue ends by queuing tracks with shared genre, artist, or era rather than purely random library shuffling.
* **Startup Update Check**: Checks GitHub Releases once daily on launch for new versions with a dismissible prompt.
* **Microsoft Store Packaging**: Build pipeline support for generating unsigned MSIX packages for Windows Partner Center distribution.

### Changed
* Sent cover art to paired phones at up to 1440 px for high-density phone displays.
* Restricted phone pairing to the local route address to avoid advertising virtual machine or hotspot adapters.
* Autoplay skips tracks that were recently queued or played.
* Outgoing track volume follows master slider changes during crossfades.

### Fixed
* Addressed potential queue index staleness during phone remote reorder commands.
* Fixed seek requests dropped while audio files were still opening.

---

## [0.7.5] - 2026-09-26

### Added
* **Rewind Overhaul**: Redesigned listening recap with interactive monthly charts, top artists, top albums with artwork, and total listening time breakdown.
* **Track Action Sheet**: Access artist details, album view, cover search, and queue actions directly by clicking the artist name in Now Playing.
* **Smooth View Transitions**: Added directional slide and fade animations when navigating between pages, albums, artists, and detail sheets.

### Changed
* **Queue Performance**: Reworked queue model to perform in-place insertions, removals, and moves instead of rebuilding the list on every track change.
* Unified artist credit splitting rules across local library, Jellyfin, and Subsonic so counts match across views.
* Large album covers are extracted from files at full resolution instead of scaling up from 512 px thumbnails.

### Fixed
* Prevented volume adjustments when scrolling on areas of Now Playing outside the volume slider.
* Fixed issue where Discord Rich Presence kept displaying the previous track after quick track skips.
* Cached failed server artwork downloads are now retried on a cooldown instead of permanently falling back to the vinyl placeholder.
* Fixed numeric settings losing fractional values on restore.
* Prevented maximized window state from being lost on launch on Windows.

---

## [0.7.0] - 2026-09-26

### Changed
* Unified version declarations across CMake, application settings, Linux metainfo, and installer scripts.
* Updated store listing screenshots and documentation.

---

## [0.6.0] - 2026-09-24

### Added
* **Discord Rich Presence**: Broadcasts current track, artist, album, and playback state via local Discord IPC socket.
* **ReplayGain Normalization**: Automatic gain adjustment from embedded track and album peak/gain tags.
* **Linux MPRIS 2**: Native D-Bus interface for system media control and lock-screen integration on Linux desktops.
* **Listening Record Recaps**: Added yearly summary cards and play count milestones.

### Changed
* Optimized smooth scrolling and thumbnail rendering across large library collections.

---

## [0.5.1] - 2026-08-20

### Added
* **Secure Linux Credential Storage**: Migrated server login storage to FreeDesktop Secret Service via `libsecret`.
* Windows Inno Setup installer automation.
* Flatpak manifest validation in continuous integration.

---

## [0.5.0] - 2026-08-10

### Added
* Initial public desktop release of CassetteCat.
* Local library scanning with embedded ID3, FLAC, and MP4 tag extraction via TagLib.
* Subsonic and Jellyfin server streaming support.
* Internet radio tuning via Radio Browser.
* Synchronized lyrics integration via LRCLIB.
* Scrobbling support for ListenBrainz and Libre.fm.
* Compact mini player mode.
* Offline Blackout Mode to disable external network access.
