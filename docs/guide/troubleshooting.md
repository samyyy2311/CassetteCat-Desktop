# Troubleshooting

## Installing and starting

### macOS says CassetteCat can't be opened

The Mac app isn't notarized by Apple yet. Right-click CassetteCat in Applications and choose **Open**, then **Open** again. Or go to **System Settings > Privacy & Security** and click **Open Anyway** next to the message about CassetteCat. macOS remembers the choice.

### The AppImage doesn't start

AppImages need FUSE 2. Install it (`sudo apt install libfuse2` on Debian and Ubuntu, `sudo dnf install fuse-libs` on Fedora), or use the `.deb`, `.rpm`, Flatpak or `.tar.gz` instead. Also check the file is executable: `chmod +x CassetteCat-*.AppImage`.

### Windows SmartScreen warns about the installer

New releases can show **Windows protected your PC** until enough people have downloaded them. Click **More info**, then **Run anyway**, or install from the Microsoft Store or with `winget install CassetteCat`.

## Library

### My songs don't show up

- Check the folder is listed under **Settings > Music Library > Audio Folders**, and isn't inside one of the **Excluded Folders**.
- **Ignore Short Clips** hides anything under 30 seconds.
- CassetteCat plays FLAC, MP3, AAC, M4A, ALAC, OGG, Opus and WAV. Other formats are skipped.
- To scan a folder from scratch, remove it under **Audio Folders** and add it again.

### Songs show the wrong artist, album or cover

CassetteCat uses the tags in your files. Fix them with **Edit Tags**, and covers with **Search Cover Art** in the song menu. **Library health** on the Library page lists songs with missing tags. See [Library and playlists](library-and-playlists.md#editing-tags-and-covers).

## Playback

### There's no sound

- Check **Settings > Playback & Audio > Playback Device**. Pick your speakers or headphones, or the system default.
- Check **Volume Limit** isn't set very low, and the volume slider and your system volume are up.
- If you connected headphones while CassetteCat was playing, choose them under **Playback Device**.

### Lyrics are missing or out of time

- Check **LrcLib Lyrics** is on in **Settings > Network & Services**, and **Offline Blackout Mode** is off.
- **Choose lyrics** in the lyrics view picks a different version.
- The **-** and **+** buttons in Now Playing move the lyrics earlier or later in steps of 0.1 seconds, and remember it for that song.
- For a song with plain lyrics, **Tap to Sync** lets you time them yourself. See [Playback and sound](playback-and-sound.md#lyrics).

## Servers and online services

### My server won't connect

- Include the port if your server uses one, such as `192.168.1.20:4533`. Without `http://` or `https://`, CassetteCat uses `http://` for addresses on your home network and `https://` for everything else, so type the one your server needs if that guess is wrong.
- For a self-signed certificate, turn on **Trust self-signed certificate** before connecting.
- Check **Offline Blackout Mode** is off.

### Scrobbles don't appear

Check the service shows your username in **Settings > Scrobbling**. If it doesn't, connect again. A song only scrobbles once you've played most of it, and songs played while offline aren't sent later.

## Phone remote

### My phone can't find the computer

- The phone and the computer must be on the same Wi-Fi network. Guest networks and some routers stop devices on the network from seeing each other; use your main network.
- **Settings > Phone Remote > Control From Your Phone** must be on, and **Offline Blackout Mode** off.
- On Windows, allow CassetteCat through the firewall on private networks. If you said no to the prompt earlier, allow it in **Windows Security > Firewall & network protection > Allow an app through firewall**.
- The phone needs CassetteCat for Android 1.8.0 or later.
- Pair by address instead: copy it from **Settings > Phone Remote > Pair Manually** and enter it on the phone. See [Using CassetteCat with your phone](phone-remote.md#if-your-phone-cant-find-the-computer).

CassetteCat uses port 47800 for the connection (TCP) and for being found (UDP). If you run your own firewall, allow both on your local network.

### The phone asks to pair again

That happens when the computer's pairing code changes (**New Code**), when the phone was removed under **Paired Phones**, or when the computer's certificate changed, for example after its data was deleted. Pair again as described in [Pairing](phone-remote.md#pairing).

## Reporting a bug

1. Check you're on the latest version: **Settings > General & System > Check for Updates**.
2. Copy the log: **Settings > Backup & Diagnostics > Application Logs > Copy**.
3. [Open an issue](https://github.com/samyyy2311/CassetteCat-Desktop/issues/new/choose) with what you did, what happened, your system (Windows, macOS or Linux, and its version) and the log.

For security problems, follow [SECURITY.md](../../.github/SECURITY.md) instead of opening a public issue.
