# Changelog

All notable changes to CassetteCat Desktop are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
