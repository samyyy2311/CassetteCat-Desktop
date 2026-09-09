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
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases"><img src="https://img.shields.io/badge/Releases-E55B3C?style=flat-square&logo=git&logoColor=white" alt="Releases" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/GPL--3.0--or--later-A42E2B?style=flat-square&logo=gnu&logoColor=white" alt="GPL-3.0-or-later" /></a>
  <img src="https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black" alt="Linux" />
  <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt%206-41CD52?style=flat-square&logo=qt&logoColor=white" alt="Qt 6" /></a>
  <img src="https://img.shields.io/badge/C%2B%2B20-00599C?style=flat-square&logo=cplusplus&logoColor=white" alt="C++20" />
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases"><img src="https://img.shields.io/github/downloads/samyyy2311/CassetteCat-Desktop/total?style=flat-square&label=Downloads&logo=github&logoColor=white" alt="GitHub downloads" /></a>
</p>

<p align="center">
  <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest"><img src="https://img.shields.io/badge/Download%20latest%20release-E55B3C?style=for-the-badge&logo=github&logoColor=white" alt="Download latest release" /></a>
</p>

---

## What it does

### Your music, in one place

- Choose a music folder and CassetteCat organises it by songs, artists, albums, and folders.
- Search, sort, filter, keep favourites, and revisit recent plays.
- Discover recently added music and your most-played tracks from Home.

### Playback

- Play, queue, shuffle, repeat, and control your music without losing your place.
- Use the floating MiniPlayer when you want simple controls on top of other windows.
- Resume your queue after restarting, set a sleep timer, limit volume, or let playback continue automatically.

### Lyrics, artwork, and radio

- Read local, embedded, or online synced lyrics, with search and timing adjustment when needed.
- Show cover art from your files and artist information when available.
- Browse internet radio without leaving the app.

### Yours to control

- Connect a Jellyfin or Subsonic server if you use one.
- Choose an accent colour, layout density, artwork style, and lyric appearance.
- Back up or restore your settings, and use Offline Blackout Mode to stop every online lookup.
- No account is required for your local library.

---

## Download

<p align="center">
  Windows and Linux builds are available from the <a href="https://github.com/samyyy2311/CassetteCat-Desktop/releases">Releases page</a>.
</p>

### Linux

```bash
gh release download --repo samyyy2311/CassetteCat-Desktop --pattern '*linux-x64.tar.gz'
tar -xzf CassetteCat-*-linux-x64.tar.gz
./CassetteCat/bin/CassetteCat
```

### Windows

The installer adds a Start menu entry and can optionally associate common audio files with CassetteCat. The ZIP remains portable:

```powershell
gh release download --repo samyyy2311/CassetteCat-Desktop --pattern '*windows-x64.zip'
$archive = Get-ChildItem 'CassetteCat-*-windows-x64.zip' | Select-Object -First 1
Expand-Archive $archive.FullName .\CassetteCat
.\CassetteCat\CassetteCat\bin\CassetteCat.exe
```

## Build from source

You need Qt 6.10 or newer with Qt Quick and Qt Quick Controls 2, CMake 3.24 or newer, and Ninja.

```powershell
cmake --preset dev
cmake --build --preset dev
.\build\dev\CassetteCat.exe
```

Run the built-in library scan check with:

```powershell
.\build\dev\CassetteCat.exe --self-check
```

---

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request. For security issues, read
[SECURITY.md](.github/SECURITY.md).

---

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
- <a href="https://deezer.com"><img src="https://img.shields.io/badge/Deezer-FEAA2D?style=flat-square&logo=deezer&logoColor=white" alt="Deezer" /></a> and <a href="https://theaudiodb.com"><img src="https://img.shields.io/badge/TheAudioDB-6599CD?style=flat-square" alt="TheAudioDB" /></a> Artist images and details.

### Built with

- <a href="https://www.qt.io"><img src="https://img.shields.io/badge/Qt%206-41CD52?style=flat-square&logo=qt&logoColor=white" alt="Qt 6" /></a> Desktop interface and playback.
- <a href="https://taglib.org"><img src="https://img.shields.io/badge/TagLib-1C1917?style=flat-square" alt="TagLib" /></a> Music metadata, artwork, and lyrics.
- <a href="https://lucide.dev"><img src="https://img.shields.io/badge/Lucide-F56565?style=flat-square&logo=lucide&logoColor=white" alt="Lucide" /></a> Interface icons.
- <a href="https://github.com/IBM/plex"><img src="https://img.shields.io/badge/IBM%20Plex-0F62FE?style=flat-square&logo=ibm&logoColor=white" alt="IBM Plex" /></a> and <a href="https://github.com/floriankarsten/space-grotesk"><img src="https://img.shields.io/badge/Space%20Grotesk-242424?style=flat-square" alt="Space Grotesk" /></a> Typefaces.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for all included notices.

---

## License

CassetteCat Desktop is licensed under the
[GNU General Public License v3.0 or later](LICENSE). Third-party code, fonts,
and artwork keep their own licenses.
