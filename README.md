<p align="center">
  <img src="assets/cassettecat_icon.png" width="128" height="128" alt="CassetteCat logo" />
</p>

<h1 align="center">CassetteCat Desktop</h1>

<p align="center">
  <strong>A local-first desktop music player for the music you already own.</strong>
</p>

<p align="center">
  Looking for the Android app? <a href="https://github.com/samyyy2311/CassetteCat">CassetteCat for Android</a>
</p>

<p align="center">
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest"><img src="https://img.shields.io/github/v/release/samyyy2311/CassetteCat-Desktop?style=flat-square&label=Release&color=E55B3C" alt="Latest release" /></a>
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases"><img src="https://img.shields.io/github/downloads/samyyy2311/CassetteCat-Desktop/total?style=flat-square&label=Downloads&color=E55B3C" alt="Downloads" /></a>
  <img src="https://img.shields.io/badge/Windows%20%7C%20Linux-1C1917?style=flat-square" alt="Windows and Linux" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0--or--later-A42E2B?style=flat-square" alt="GPL-3.0-or-later" /></a>
</p>

<p align="center">
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest"><img src="https://img.shields.io/badge/Download-E55B3C?style=for-the-badge&logo=github&logoColor=white" alt="Download" /></a>
</p>

<p align="center">
  <img src="assets/screenshots/home.png" alt="CassetteCat Home screen" />
</p>

## Features

- **Library.** Browse your music folder by songs, artists, albums, genres and folders, with search, favourites and playlists.
- **Playback.** A queue that survives restarts, ReplayGain, a sleep timer and a floating mini player.
- **Controls.** Media keys, global shortcuts, the tray, and the Windows and Linux media controls. Every screen works from the keyboard.
- **Lyrics and artwork.** Synced lyrics from your files or LRCLIB, covers from your files or the Cover Art Archive, and artist pictures and bios.
- **Listening Record.** Plays, listening time, top songs, artists and albums, full history, and a yearly Recap.
- **Online extras.** Internet radio, Jellyfin and Subsonic, scrobbling to Libre.fm and ListenBrainz, and a Discord status.
- **Privacy.** No account needed. Offline Blackout Mode turns every online lookup off.

## Screenshots

<table>
  <tr>
    <td><img src="assets/screenshots/library-albums.png" alt="Albums" /></td>
    <td><img src="assets/screenshots/now-playing.png" alt="Player" /></td>
  </tr>
  <tr>
    <td><img src="assets/screenshots/library-songs.png" alt="Songs" /></td>
    <td><img src="assets/screenshots/radio.png" alt="Radio" /></td>
  </tr>
</table>

## Install

Download from the [latest release](https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest).

| Platform | File | Notes |
| --- | --- | --- |
| Windows | `setup.exe` | Installer, with optional file associations |
| Windows | `.zip` | Portable. Run `CassetteCat\bin\CassetteCat.exe` |
| Linux | `.AppImage` | Runs on most distributions. Make it executable and run it |
| Linux | `.flatpak` | Install with `flatpak install --user` and the file name |
| Linux | `.deb` | Debian, Ubuntu and derivatives |
| Linux | `.rpm` | Fedora, openSUSE and derivatives |
| Linux | `.tar.gz` | Portable. Run `CassetteCat/bin/CassetteCat` |

Linux builds are x86_64. Each release includes `SHA256SUMS.txt` to verify downloads.

## Build from source

Requires Qt 6.10 or newer (Quick, Quick Controls 2, Multimedia, Network), CMake 3.24 or newer, and Ninja. On Linux, also install the libsecret headers (`libsecret-1-dev` on Debian and Ubuntu).

```bash
cmake --preset dev
cmake --build --preset dev
```

The app is built to `build/dev/`. Run the checks with:

```bash
build/dev/CassetteCat --self-check
ctest --test-dir build/dev --output-on-failure
```

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request. For security issues, read
[SECURITY.md](.github/SECURITY.md).

## Support

<p align="center">
  <a href="https://ko-fi.com/samyyy2311"><img src="https://img.shields.io/badge/Ko--fi-FF5E5B?style=flat-square&logo=kofi&logoColor=white" alt="Ko-fi" /></a>
  <a href="https://buymeacoffee.com/samyyy2311"><img src="https://img.shields.io/badge/Buy%20Me%20a%20Coffee-FFDD00?style=flat-square&logo=buymeacoffee&logoColor=black" alt="Buy Me a Coffee" /></a>
</p>

<p align="center">If CassetteCat is useful to you, support helps keep it improving.</p>

## Credits

### Music and information

- <a href="https://lrclib.net"><img src="https://img.shields.io/badge/LRCLIB-38BDF8?style=flat-square" alt="LRCLIB" /></a> Lyrics when a track has none locally.
- <a href="https://www.radio-browser.info"><img src="https://img.shields.io/badge/Radio%20Browser-1C1917?style=flat-square" alt="Radio Browser" /></a> Internet radio stations.
- <a href="https://wikipedia.org"><img src="https://img.shields.io/badge/Wikipedia-000000?style=flat-square&logo=wikipedia&logoColor=white" alt="Wikipedia" /></a> Artist information.
- <a href="https://coverartarchive.org"><img src="https://img.shields.io/badge/Cover%20Art%20Archive-BA478F?style=flat-square&logo=musicbrainz&logoColor=white" alt="Cover Art Archive" /></a> Album covers.
- <a href="https://deezer.com"><img src="https://img.shields.io/badge/Deezer-FEAA2D?style=flat-square&logo=deezer&logoColor=white" alt="Deezer" /></a> and <a href="https://theaudiodb.com"><img src="https://img.shields.io/badge/TheAudioDB-6599CD?style=flat-square" alt="TheAudioDB" /></a> Artist images and details.

### Built with

- <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt%206-41CD52?style=flat-square&logo=qt&logoColor=white" alt="Qt 6" /></a> Desktop interface and playback.
- <a href="https://taglib.org"><img src="https://img.shields.io/badge/TagLib-1C1917?style=flat-square" alt="TagLib" /></a> Music metadata, artwork, and lyrics.
- <a href="https://lucide.dev"><img src="https://img.shields.io/badge/Lucide-F56565?style=flat-square&logo=lucide&logoColor=white" alt="Lucide" /></a> Interface icons.
- <a href="https://github.com/IBM/plex"><img src="https://img.shields.io/badge/IBM%20Plex-0F62FE?style=flat-square&logo=ibm&logoColor=white" alt="IBM Plex" /></a> and <a href="https://github.com/floriankarsten/space-grotesk"><img src="https://img.shields.io/badge/Space%20Grotesk-242424?style=flat-square" alt="Space Grotesk" /></a> Typefaces.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for all included notices.

## License

CassetteCat Desktop is licensed under the
[GNU General Public License v3.0 or later](LICENSE). Third-party code, fonts,
and artwork keep their own licenses.
