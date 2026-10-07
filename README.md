# CassetteCat

<p align="center">
  <img src="assets/cassettecat_icon.png" width="128" height="128" alt="CassetteCat Logo" style="border-radius: 28px;" />
</p>

<p align="center">
  <strong>A local-first desktop music player for the music you already own, with support for local files, Subsonic, and Jellyfin.</strong>
</p>

<p align="center">
  Android app: <a href="https://github.com/samyyy2311/CassetteCat">CassetteCat for Android</a>
</p>

<p align="center">
  Website: <a href="https://cassettecat.caffeinelabs.in">cassettecat.caffeinelabs.in</a>
</p>

<p align="center">
  <a href="CHANGELOG.md"><img src="https://img.shields.io/badge/v0.8.0-E55B3C?style=flat-square&logo=git&logoColor=white" alt="v0.8.0" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/GPL--3.0-A42E2B?style=flat-square&logo=gnu&logoColor=white" alt="GPL-3.0" /></a>
  <img src="https://img.shields.io/badge/Windows%2010%2F11-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Linux%20x86__64-FCC624?style=flat-square&logo=linux&logoColor=black" alt="Linux" />
  <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt%206-41CD52?style=flat-square&logo=qt&logoColor=white" alt="Qt 6" /></a>
  <img src="https://img.shields.io/badge/C++20-00599C?style=flat-square&logo=c%2B%2B&logoColor=white" alt="C++20" />
  <a href="https://alternativeto.net/software/cassettecat/about/"><img src="https://img.shields.io/badge/AlternativeTo-0289D5?style=flat-square&logo=alternativeto&logoColor=white" alt="AlternativeTo" /></a>
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases"><img src="https://img.shields.io/github/downloads/samyyy2311/CassetteCat-Desktop/total?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=Downloads&logo=github&logoColor=white" alt="GitHub downloads" /></a>
  <a href="https://coderabbit.ai"><img src="https://img.shields.io/coderabbit/prs/github/samyyy2311/CassetteCat-Desktop?utm_source=oss&utm_medium=github&utm_campaign=samyyy2311%2FCassetteCat-Desktop&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews" alt="CodeRabbit Pull Request Reviews" /></a>
</p>

---

## Install

<p align="center">
  <a href="https://apps.microsoft.com/detail/9NXNRR95X3K0">
    <img src="https://get.microsoft.com/images/en-us%20dark.svg" alt="Get it on Microsoft Store" height="52" />
  </a>
</p>

<p align="center">
  <strong>Windows 10/11, macOS 13+ & Linux (x86_64 and ARM64)</strong><br />
  Install through the Microsoft Store for background updates, via <code>winget</code>, or download standalone binaries below.
</p>

### Windows Package Manager (winget)

```powershell
winget install CassetteCat
```

### Standalone Packages

Download from the [latest release](https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest).

| Platform | Format | Package | Notes |
| :--- | :--- | :--- | :--- |
| **Windows** | Installer | `setup.exe` | Recommended installer with optional file associations |
| **Windows** | Portable | `.zip` | Standalone archive. Run `CassetteCat\bin\CassetteCat.exe` |
| **macOS** | Disk image | `.dmg` | One app for Apple silicon and Intel. Drag it to Applications |
| **Linux** | Universal | `.AppImage` | Runs on most Linux distributions. Make executable and run |
| **Linux** | Flatpak | `.flatpak` | Install with `flatpak install --user <file>` |
| **Linux** | Debian | `.deb` | Debian, Ubuntu, Linux Mint, and Pop!_OS |
| **Linux** | RPM | `.rpm` | Fedora, openSUSE, and RHEL |
| **Linux** | Tarball | `.tar.gz` | Portable archive. Run `CassetteCat/bin/CassetteCat` |

Linux packages are built for both x86_64 and ARM64; pick the one matching your machine.

The macOS app is not notarized by Apple yet, so the first time, right-click CassetteCat in Applications and choose **Open**, or allow it under **System Settings > Privacy & Security**.

> Each release includes `SHA256SUMS.txt` for integrity verification.

---

## Screenshots

<p align="center">
  <img src="assets/screenshots/home.png" width="48%" alt="Home Screen" />
  <img src="assets/screenshots/now-playing.png" width="48%" alt="Now Playing" />
</p>
<p align="center">
  <img src="assets/screenshots/library-albums.png" width="48%" alt="Albums Library" />
  <img src="assets/screenshots/library-songs.png" width="48%" alt="Songs Library" />
</p>
<p align="center">
  <img src="assets/screenshots/radio.png" width="48%" alt="Internet Radio" />
  <img src="assets/screenshots/settings.png" width="48%" alt="Settings" />
</p>

---

## Features

### Playback

- **Gapless & Crossfade**: Seamless track transitions, ReplayGain volume normalization, a sleep timer, and a floating mini player.
- **Persistent Queue**: Your current queue and playback position survive app restarts. Autoplay keeps the music going with similar tracks when your queue ends.
- **Synchronized Lyrics**: Karaoke-style lyrics from local `.lrc` files, embedded ID3 tags, or LRCLIB, plus a built-in tap-to-sync tool for unsynced tracks.
- **System Controls**: Native Windows Media Transport Controls (SMTC), Linux MPRIS, system tray controls, and global keyboard shortcuts. Every screen can be navigated entirely from the keyboard.

### Library & Organization

- **Local Collection**: Fast indexing for your local music folder with full support for FLAC, MP3, AAC, M4A, OGG, Opus, WAV, and ALAC.
- **Batch Tag Editor**: Edit metadata, track numbers, genres, and cover art across multiple files at once using [TagLib](https://taglib.org).
- **Listening Record**: Tracks your play counts, total listening time, top artists, and full history, with monthly and yearly Rewind summaries.

### Streaming & Radios

- **Subsonic & Navidrome**: Native streaming client for Subsonic-compatible servers including Navidrome, Gonic, and Airsonic.
- **Jellyfin**: Stream your personal music library directly from a Jellyfin server.
- **Internet Radio**: Tune into thousands of live radio stations worldwide through [Radio Browser](https://www.radio-browser.info).
- **Scrobbling & Presence**: Scrobble to [ListenBrainz](https://listenbrainz.org) and [Libre.fm](https://libre.fm), with Discord Rich Presence status support.

### Phone Remote

- **Wi-Fi Sync**: Pair with [CassetteCat for Android](https://github.com/samyyy2311/CassetteCat) on your local network. Handoff your current song, queue, and playback progress between phone and computer, keep favorites in sync, and mirror backups.

### Privacy

- **No Accounts or Tracking**: Everything stays on your machine. No telemetry, no analytics, and no accounts required. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md) for full details.
- **Offline Blackout Mode**: A single switch turns off every external network call for completely offline listening.
- **GPL-3.0**: Fully open-source software.

---

## Building

Requires Qt 6.10 or newer (Quick, Quick Controls 2, Multimedia, Network), CMake 3.24 or newer, and Ninja. On Linux, also install `libsecret-1-dev`.

```bash
cmake --preset dev
cmake --build --preset dev
```

The app is built to `build/dev/`. Run the test suite:

```bash
build/dev/CassetteCat --self-check
ctest --test-dir build/dev --output-on-failure
```

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request, and [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for how AI assistance is used in this project. For security reports, see [SECURITY.md](.github/SECURITY.md).

---

## Support

<p align="center">
  <a href="https://ko-fi.com/samyyy2311"><img src="https://img.shields.io/badge/Ko--fi-FF5E5B?style=flat-square&logo=kofi&logoColor=white" alt="Ko-fi" /></a>
  <a href="https://buymeacoffee.com/samyyy2311"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee" /></a>
</p>

<p align="center">If CassetteCat is useful to you, support helps keep development going.</p>

---

## Credits

### Services & Data

- <a href="https://lrclib.net"><img src="https://img.shields.io/badge/LRCLIB-38BDF8?style=flat-square" alt="LRCLIB" /></a> Synchronized and plain lyrics.
- <a href="https://coverartarchive.org"><img src="https://img.shields.io/badge/Cover%20Art%20Archive-BA478F?style=flat-square&logo=musicbrainz&logoColor=white" alt="Cover Art Archive" /></a> Album artwork from MetaBrainz and the Internet Archive.
- <a href="https://musicbrainz.org"><img src="https://img.shields.io/badge/MusicBrainz-EB743B?style=flat-square&logo=musicbrainz&logoColor=white" alt="MusicBrainz" /></a> Music encyclopedia and metadata.
- <a href="https://listenbrainz.org"><img src="https://img.shields.io/badge/ListenBrainz-EB743B?style=flat-square&logo=listenbrainz&logoColor=white" alt="ListenBrainz" /></a> Open scrobbling.
- <a href="https://www.radio-browser.info"><img src="https://img.shields.io/badge/Radio%20Browser-1C1917?style=flat-square" alt="Radio Browser" /></a> Internet radio directory.
- <a href="https://libre.fm"><img src="https://img.shields.io/badge/Libre.fm-990000?style=flat-square&logo=gnu&logoColor=white" alt="Libre.fm" /></a> Free software scrobbling.
- <a href="https://wikipedia.org"><img src="https://img.shields.io/badge/Wikipedia-000000?style=flat-square&logo=wikipedia&logoColor=white" alt="Wikipedia" /></a> Artist biographies (CC BY-SA 4.0).
- <a href="https://deezer.com"><img src="https://img.shields.io/badge/Deezer-FEAA2D?style=flat-square&logo=deezer&logoColor=white" alt="Deezer" /></a> and <a href="https://theaudiodb.com"><img src="https://img.shields.io/badge/TheAudioDB-6599CD?style=flat-square&logo=theaudiodb&logoColor=white" alt="TheAudioDB" /></a> Artist imagery and details.
- <a href="https://github.com"><img src="https://img.shields.io/badge/GitHub-181717?style=flat-square&logo=github&logoColor=white" alt="GitHub" /></a> Release update checks.

### Libraries & Design

- <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt%206-41CD52?style=flat-square&logo=qt&logoColor=white" alt="Qt 6" /></a> Desktop interface and multimedia engine.
- <a href="https://taglib.org"><img src="https://img.shields.io/badge/TagLib-1C1917?style=flat-square" alt="TagLib" /></a> Audio metadata, artwork extraction, and tag writing.
- <a href="https://lucide.dev"><img src="https://img.shields.io/badge/Lucide-F56565?style=flat-square&logo=lucide&logoColor=white" alt="Lucide" /></a> Interface icons.
- <a href="https://simpleicons.org"><img src="https://img.shields.io/badge/Simple%20Icons-111111?style=flat-square&logo=simpleicons&logoColor=white" alt="Simple Icons" /></a> Brand icons.
- <a href="https://github.com/IBM/plex"><img src="https://img.shields.io/badge/IBM%20Plex-0F62FE?style=flat-square&logo=ibm&logoColor=white" alt="IBM Plex" /></a> and <a href="https://github.com/floriankarsten/space-grotesk"><img src="https://img.shields.io/badge/Space%20Grotesk-242424?style=flat-square" alt="Space Grotesk" /></a> Typefaces.

---

## Acknowledgements

<p align="center">
  <a href="https://coderabbit.ai">
    <img src="assets/coderabbit_logo.svg" width="60" height="60" alt="CodeRabbit Logo" />
  </a>
</p>

<p align="center">
  Special thanks to <a href="https://coderabbit.ai">CodeRabbit</a> for supporting open-source development with automated AI code reviews.
</p>

---

## License

CassetteCat Desktop is licensed under the [GNU General Public License v3.0 or later](LICENSE). Third-party libraries, fonts, and assets retain their respective licenses.
