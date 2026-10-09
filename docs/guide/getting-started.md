# Getting started

CassetteCat plays the music on your computer, music on your own Subsonic or Jellyfin server, and internet radio. It runs on Windows 10 and 11, macOS 13 and later, and Linux on x86_64 and ARM64.

## Install

### Windows

Pick one:

- **Microsoft Store**: [CassetteCat on the Microsoft Store](https://apps.microsoft.com/detail/9NXNRR95X3K0). The Store keeps it up to date.
- **Windows Package Manager**: run `winget install CassetteCat`, and `winget upgrade CassetteCat` later for new versions.
- **Installer**: download `CassetteCat-vX.Y.Z-windows-x64-setup.exe` from the [latest release](https://github.com/samyyy2311/CassetteCat-Desktop/releases/latest). The installer can add "Open with CassetteCat" for audio files and start CassetteCat when you sign in. Uninstalling asks before it deletes your settings and Listening Record.
- **Portable**: download the `windows-x64.zip`, unzip it anywhere and run `CassetteCat\bin\CassetteCat.exe`. Nothing is installed.

### macOS

Download `CassetteCat-vX.Y.Z-macos-universal.dmg`, open it and drag CassetteCat to Applications. One app runs on both Apple silicon and Intel Macs.

The app isn't notarized by Apple yet, so macOS blocks the first launch. Right-click CassetteCat in Applications and choose **Open**, or allow it under **System Settings > Privacy & Security**. You only need to do this once.

### Linux

Every package comes for x86_64 and ARM64 (aarch64). Pick the one that suits your system:

| Package | Use it on | Install |
| :--- | :--- | :--- |
| `.AppImage` | Most distributions | Make it executable (`chmod +x`) and run it |
| `.deb` | Debian, Ubuntu, Linux Mint, Pop!_OS | `sudo apt install ./CassetteCat-*.deb` |
| `.rpm` | Fedora, openSUSE, RHEL | `sudo dnf install ./CassetteCat-*.rpm` |
| `.flatpak` | Any distribution with Flatpak | `flatpak install --user CassetteCat-*.flatpak` |
| `.tar.gz` | Anywhere, without installing | Unpack it and run `CassetteCat/bin/CassetteCat` |

Each release has a `SHA256SUMS.txt` if you want to check your download.

## First launch

A short setup runs the first time. Everything in it can be changed later in **Settings**.

1. **Welcome**: an introduction to what CassetteCat does.
2. **Choose your music**: add the folders that hold your music. CassetteCat builds your library from them and picks up new files as you add them. You can add more folders, or exclude some, in **Settings > Music Library** later.
3. **Make it yours**: pick an accent colour and how the app looks.

Your library appears on **Home** once the first scan finishes. If songs are missing, see [Troubleshooting](troubleshooting.md#my-songs-dont-show-up).

## Finding your way around

The sidebar on the left holds the main pages:

- **Home**: picks from your library that change with the time of day, a shuffle card for everything, and sections such as Heavy Rotation and Recently Played.
- **Library**: Songs, Artists, Albums, Genres, Folders and Playlists. See [Library and playlists](library-and-playlists.md).
- **Jellyfin** and **Subsonic**: your own music servers. See [Streaming, radio and online services](streaming-and-radio.md).
- **Radio**: internet radio stations.
- **Search**: songs, artists, albums and genres, with your recent searches.
- **Listening Record**: your listening history and stats.
- **Settings**: everything else.

**Ctrl+B** (**Cmd+B** on a Mac) hides or shows the sidebar.

The **player bar** at the bottom shows what's playing. Click the cover to open **Now Playing**. The buttons on the right open the phone remote, lyrics, the queue, the mini player and Now Playing.

## Next steps

- [Library and playlists](library-and-playlists.md)
- [Playback and sound](playback-and-sound.md)
- [Using CassetteCat with your phone](phone-remote.md)
