# Settings, backups and privacy

## Appearance

**Settings > Appearance** sets:

- **Accent Colour**: Red, Amber, Cyan, Green, Pink, Mono, or a **Custom** colour you pick. It colours the selected page, controls, the seek bar and volume.
- **Album Art Corners**: Square, Soft or Rounded.
- **Now Playing Backdrop**: **Tinted** takes its colour from the album art; **Clean** keeps it plain.
- **Time Display**: the time left in the song, or its total length.

## The window and the tray

**Settings > General & System**:

- **Default Launch Page**: the page CassetteCat opens on, or the last one you visited.
- **Close to System Tray**: closing the window keeps CassetteCat playing in the tray. Quit from the tray icon's menu.
- **Start Minimized**: opens straight into the tray.
- **Now-Playing Notifications**: a system notification when the song changes, always or only while the window is minimized.
- **Keep Mini Player on Top**: floats the mini player above other windows.

On Windows, the installer can also start CassetteCat when you sign in. Run the installer again to change that choice.

## Updates

- **Microsoft Store**: the Store updates CassetteCat for you.
- **winget**: `winget upgrade CassetteCat`.
- **Everything else**: CassetteCat checks GitHub for a new version once a day when it starts, and tells you when there is one. **Settings > General & System > Check for Updates** checks straight away, and **Download Update** opens the download.

## Backups

**Settings > Backup & Diagnostics > Configuration Backup**:

- **Export** saves your settings, favourites, saved queues and filters to a JSON file.
- **Import** applies a backup straight away, for example on a new computer.

Passwords, tokens and other secrets are never written to a backup, so you sign in to your servers and scrobbling services again after importing. Your Listening Record isn't part of the backup.

## Logs

**Settings > Backup & Diagnostics > Application Logs** can **Open** the log folder, **Copy** the log so you can paste it into a bug report, or **Clear** it. The log records what the app was doing, not what you listened to.

## Where CassetteCat keeps its data

| | Settings (`settings.ini`) | Library cache, Listening Record and logs |
| :--- | :--- | :--- |
| Windows | `%LOCALAPPDATA%\CassetteCat\CassetteCat` | `%LOCALAPPDATA%\CassetteCat\CassetteCat` |
| macOS | `~/Library/Preferences/CassetteCat/CassetteCat` | `~/Library/Application Support/CassetteCat/CassetteCat` |
| Linux | `~/.config/CassetteCat/CassetteCat` | `~/.local/share/CassetteCat/CassetteCat` |

The Flatpak keeps the same folders inside `~/.var/app/io.github.samyyy2311.CassetteCat`. Passwords and scrobbling sessions are in the system's credential store instead, not in these folders.

Uninstalling with the Windows installer asks whether to delete these folders too. Other packages leave them in place.

## Privacy

- There's no account, no analytics and no tracking.
- Your library, Listening Record and settings stay on your computer.
- Lookups for lyrics, artwork and artist information send only the names being looked up, and each one can be turned off. **Offline Blackout Mode** turns them all off at once. See [Streaming, radio and online services](streaming-and-radio.md#online-services).
- The phone remote only talks to phones on your own network, over an encrypted connection.

The full details are in the [privacy policy](../../PRIVACY_POLICY.md).
