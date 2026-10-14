<p align="center">
  <img src="assets/cassettecat_icon.png" width="112" height="112" alt="CassetteCat icon" />
</p>

<h1 align="center">CassetteCat</h1>

<p align="center">
  <strong>A desktop music player for the music you own: your own files, your Subsonic or Jellyfin server, and internet radio.</strong>
</p>

<p align="center">
  Android app: <a href="https://github.com/samyyy2311/CassetteCat">CassetteCat for Android</a>, which pairs with this one so your phone becomes a remote
</p>

<p align="center">
  Website: <a href="https://cassettecat.caffeinelabs.in/desktop">cassettecat.caffeinelabs.in</a> · User guide: <a href="https://cassettecat.caffeinelabs.in/docs">cassettecat.caffeinelabs.in/docs</a>
</p>

<p align="center">
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest"><img src="https://img.shields.io/github/v/release/samyyy2311/CassetteCat-Desktop?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=&logo=git&logoColor=E55B3C" alt="Latest release" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/GPL--3.0--or--later-2A2A2A?style=flat-square&logo=gnu&logoColor=white" alt="GPL-3.0-or-later" /></a>
  <img src="https://img.shields.io/badge/Windows_%C2%B7_Linux-2A2A2A?style=flat-square" alt="Windows and Linux" />
  <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt_6-2A2A2A?style=flat-square&logo=qt&logoColor=41CD52" alt="Qt 6" /></a>
  <a href="https://isocpp.org"><img src="https://img.shields.io/badge/C%2B%2B20-2A2A2A?style=flat-square&logo=cplusplus&logoColor=659AD2" alt="C++20" /></a>
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases"><img src="https://img.shields.io/github/downloads/samyyy2311/CassetteCat-Desktop/total?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=downloads&logo=github&logoColor=white" alt="GitHub downloads" /></a>
  <br />
  <a href="https://alternativeto.net/software/cassettecat/about/"><img src="https://img.shields.io/badge/AlternativeTo-2A2A2A?style=flat-square&logo=alternativeto&logoColor=white" alt="AlternativeTo" /></a>
  <a href="https://coderabbit.ai"><img src="https://img.shields.io/coderabbit/prs/github/samyyy2311/CassetteCat-Desktop?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=CodeRabbit&logo=coderabbit&logoColor=FF570A" alt="CodeRabbit pull request reviews" /></a>
  <a href="https://app.codacy.com/gh/samyyy2311/CassetteCat-Desktop/dashboard"><img src="https://img.shields.io/codacy/grade/775f07dda4494cb98d88f1c91cd179f0?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=Codacy&logo=codacy&logoColor=white" alt="Codacy code quality" /></a>
  <a href="https://www.codefactor.io/repository/github/samyyy2311/cassettecat-desktop"><img src="https://img.shields.io/codefactor/grade/github/samyyy2311/CassetteCat-Desktop?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=CodeFactor&logo=codefactor&logoColor=F44A6A" alt="CodeFactor grade" /></a>
  <a href="https://www.bestpractices.dev/projects/15328"><img src="https://img.shields.io/cii/level/15328?style=flat-square&color=2A2A2A&labelColor=2A2A2A&label=OpenSSF&logo=linuxfoundation&logoColor=white" alt="OpenSSF Best Practices" /></a>
</p>

<p align="center">
  <img src="assets/screenshots/framed/now-playing.png" width="88%" alt="CassetteCat's Now Playing screen with large album art" />
</p>

---

## Install

<p align="center">
  <a href="https://apps.microsoft.com/detail/9NXNRR95X3K0"><img src="https://get.microsoft.com/images/en-us%20dark.svg" alt="Get it from the Microsoft Store" height="52" /></a>
</p>

On Windows 10 and 11, the Microsoft Store version updates itself.

Everything else is on the [latest release](https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest) page:

| System | Download | Notes |
| :--- | :--- | :--- |
| Windows | `setup.exe` | Installer, with optional "Open with" entries for audio files |
| Windows | `.zip` | Portable. Run `CassetteCat\bin\CassetteCat.exe` |
| Linux | `.AppImage` | Runs on most distributions. Make it executable and run it |
| Linux | `.flatpak` | `flatpak install --user <file>` |
| Linux | `.deb` | Debian, Ubuntu, Linux Mint, Pop!_OS |
| Linux | `.rpm` | Fedora, openSUSE, RHEL |
| Linux | `.tar.gz` | Portable. Run `CassetteCat/bin/CassetteCat` |

Linux packages come for x86_64 and ARM64; pick the one for your machine. Every release lists `SHA256SUMS.txt` for checking your download.

A macOS app is in development. It isn't ready to use yet, so releases don't include it for now.

---

## Screenshots

<p align="center">
  <img src="assets/screenshots/framed/home.png" width="48%" alt="Home" />
  <img src="assets/screenshots/framed/library-albums.png" width="48%" alt="Album library" />
</p>
<p align="center">
  <img src="assets/screenshots/framed/listening-record.png" width="48%" alt="Listening Record" />
  <img src="assets/screenshots/framed/radio.png" width="48%" alt="Internet radio" />
</p>

---

## Features

### Your music

- **Your own files**: point it at your music folders and it sorts everything by song, album, artist, genre and folder, and picks up new files as you add them. FLAC, MP3, AAC, M4A, ALAC, OGG, Opus and WAV all play.
- **Your server**: stream from Subsonic-compatible servers (Navidrome, Gonic, Airsonic) or Jellyfin, with Quick Connect, alongside your local library.
- **Internet radio**: live stations from [Radio Browser](https://www.radio-browser.info), plus stations you add yourself.
- **Tag editor**: fix the artist, album, genre, year, lyrics and cover art of many songs at once, written back to the files with [TagLib](https://taglib.org).
- **Playlists**: make them from a selection or the queue, and import or export M3U.
- **Search**: songs, artists and albums as you type, from anywhere with Ctrl+K.

### Listening

- **Gapless playback**, a short fade when you change songs, and crossfade up to 10 seconds.
- **Ten-band equalizer** with [AutoEq](https://github.com/jaakkopasanen/AutoEq) correction curves for your headphones.
- **ReplayGain** by track or album, a volume limit, and a sleep timer with a gentle fade-out.
- **Synced lyrics** from `.lrc` files, tags, Jellyfin or [LRCLIB](https://lrclib.net). For songs with plain lyrics, press Space along with the song once and CassetteCat saves the timings.
- **Audio details**: Hi-Res Lossless, Lossless or the codec at a glance, with the sample rate, bit depth and bitrate a click away.
- **Autoplay** keeps going with similar songs when the queue ends.

### On your desktop

- A floating **mini player** with artwork, lyrics or the queue, kept on top if you like.
- **System media controls**: the media overlay and taskbar buttons on Windows, Now Playing in Control Center on macOS, and MPRIS on Linux.
- **Keyboard shortcuts** for playback, volume, seeking, search and the mini player, all changeable.
- **Close to the system tray**, start minimized, and notifications when the song changes.
- **Listening Record**: top songs, artists and albums, your full history, and monthly and yearly Rewind.
- **Scrobbling** to Last.fm, [ListenBrainz](https://listenbrainz.org) and [Libre.fm](https://libre.fm), and an optional Discord status.

### With your phone

Pair with the Android app over your home Wi-Fi by clicking **Allow** when the phone asks. Then:

- your phone controls the computer, also from its notification and volume keys;
- the song, queue and position move between the two, and music plays on one device at a time;
- your phone can browse this computer's music and play it here or stream it;
- likes and playlists stay in sync, both apps keep one Listening Record, and the phone keeps a daily backup here.

The connection stays on your network and is encrypted. See [Phone and computer](https://cassettecat.caffeinelabs.in/docs/phone-and-computer) in the user guide.

### Private by default

No account, no telemetry, no analytics. Your library, history and settings stay on your computer, and passwords are kept in the system's credential store. **Offline Blackout Mode** turns off every internet request with one switch. The details are in [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

---

## Building from source

CassetteCat is written in C++20 with Qt 6. You need Qt 6.10 or newer, CMake 3.24 or newer, Ninja and OpenSSL 3; on Linux also `libsecret-1-dev`, and on macOS the Xcode command line tools.

```bash
cmake -S . -B build/dev -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_PREFIX_PATH=/path/to/Qt/6.x/<platform>
cmake --build build/dev
ctest --test-dir build/dev --output-on-failure
```

See [Building and testing](docs/dev/building.md) for each system's details.

---

## Documentation

- [User guide](https://cassettecat.caffeinelabs.in/docs): installing, every feature, the phone remote and troubleshooting
- [Developer guide](docs/README.md#working-on-the-code): building, architecture, design and releasing
- [Changelog](CHANGELOG.md)
- [Privacy policy](PRIVACY_POLICY.md)
- [Third-party notices](THIRD_PARTY_NOTICES.md)

---

## Contributing

Bug reports, ideas and pull requests are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull
request, and [AI_DISCLOSURE.md](AI_DISCLOSURE.md) for how AI assistance is used here. Report security issues
privately, as described in [SECURITY.md](.github/SECURITY.md).

### Translations

CassetteCat Desktop is English only for now. Making it translatable, so it can join the Android app on
[Weblate](https://hosted.weblate.org/engage/cassettecat/), is tracked in
[#56](https://github.com/samyyy2311/CassetteCat-Desktop/issues/56).

---

## Support

CassetteCat is free, with no ads and no tracking. If it's useful to you, you can support its development:

<p align="center">
  <a href="https://ko-fi.com/samyyy2311"><img src="https://img.shields.io/badge/Ko--fi-2A2A2A?style=flat-square&logo=kofi&logoColor=FF5E5B" alt="Support on Ko-fi" /></a>
  <a href="https://buymeacoffee.com/samyyy2311"><img src="https://img.shields.io/badge/Buy_Me_a_Coffee-2A2A2A?style=flat-square&logo=buymeacoffee&logoColor=FFDD00" alt="Buy Me a Coffee" /></a>
</p>

Starring the repository, reporting bugs and translating help too.

---

## Credits

### Services & Data

| Project | Used for |
| :--- | :--- |
| [LRCLIB](https://lrclib.net) | Synced and plain lyrics |
| [Cover Art Archive](https://coverartarchive.org) and [MusicBrainz](https://musicbrainz.org) | Album artwork and metadata |
| [Radio Browser](https://www.radio-browser.info) | Internet radio stations |
| [Last.fm](https://www.last.fm), [ListenBrainz](https://listenbrainz.org) and [Libre.fm](https://libre.fm) | Scrobbling |
| [Wikipedia](https://wikipedia.org) | Artist biographies (CC BY-SA 4.0) |
| [Deezer](https://deezer.com) and [TheAudioDB](https://theaudiodb.com) | Artist images |
| [GitHub](https://github.com) | Update checks |

### Libraries & Design

| Project | Used for |
| :--- | :--- |
| [Qt 6](https://www.qt.io) | Interface and playback |
| [TagLib](https://taglib.org) | Reading and writing tags and artwork |
| [OpenSSL](https://www.openssl.org) | Encryption for the phone remote |
| [AutoEq](https://github.com/jaakkopasanen/AutoEq) | Headphone EQ profiles by Jaakko Pasanen |
| [Lucide](https://lucide.dev) and [Simple Icons](https://simpleicons.org) | Icons |
| [IBM Plex](https://github.com/IBM/plex) and [Space Grotesk](https://github.com/floriankarsten/space-grotesk) | Typefaces (OFL 1.1) |

---

## Acknowledgements

<p align="center">
  <a href="https://coderabbit.ai"><img src="assets/coderabbit_logo.svg" width="56" height="56" alt="CodeRabbit" /></a>
  <a href="https://www.codacy.com"><img src="assets/codacy_logo.svg" width="56" height="56" alt="Codacy" /></a>
  <a href="https://www.codefactor.io"><img src="assets/codefactor_logo.svg" width="56" height="56" alt="CodeFactor" /></a>
  <a href="https://www.mintlify.com"><img src="assets/mintlify_logo.svg" width="56" height="56" alt="Mintlify" /></a>
</p>

<p align="center">
  Thanks to <a href="https://coderabbit.ai">CodeRabbit</a> for free code reviews on open-source projects like this one, and to <a href="https://www.codacy.com">Codacy</a>, <a href="https://www.codefactor.io">CodeFactor</a> and <a href="https://www.mintlify.com">Mintlify</a> for their free plans for open source.
</p>

---

## License

CassetteCat is licensed under the [GNU General Public License v3.0 or later](LICENSE). Third-party libraries, fonts and assets keep their own licenses.
