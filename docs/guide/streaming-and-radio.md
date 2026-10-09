# Streaming, radio and online services

## Your own music server

CassetteCat streams from your own server alongside the music on your computer. Songs from a server appear on its own page in the sidebar.

- **Subsonic**: Navidrome, Gonic, Airsonic and other servers that speak the Subsonic API.
- **Jellyfin**: your Jellyfin music libraries.

### Connecting

1. Open **Subsonic** or **Jellyfin** in the sidebar.
2. Enter the **Server Address**, for example `music.example.com` or `192.168.1.20:4533`, with your username and password.
3. Click **Connect**.

For Jellyfin you can use **Quick Connect** instead of a password: CassetteCat shows a code, and you approve it in another Jellyfin app where you're already signed in.

If your server uses a certificate it made itself, or one from your own certificate authority, turn on **Trust self-signed certificate** before connecting.

Your password is kept in the system's credential store: Windows Credential Locker, the macOS Keychain, or your Linux keyring through the Secret Service.

### Browsing a server

A server's page has **Songs**, **Artists**, **Albums**, **Genres** and **Playlists**, with search, **Refine & Sort**, **Play All** and **Shuffle**. Click **Refresh** to pull in songs you've added to the server since.

**Disconnect** removes your saved login, and the server's songs leave your library until you connect again. Nothing is deleted from the server.

## Internet radio

**Radio** in the sidebar plays live stations from the [Radio Browser](https://www.radio-browser.info) directory.

- **All Stations** lists popular stations, with genre chips such as Pop, Rock, Jazz, Lofi and Classical.
- **Search** finds stations by name, genre or country.
- **Refine & Sort** sorts by popularity, trending, bitrate or country.
- The heart on a station adds it to **Favorites**. **Recents** lists what you played lately.
- **Custom** holds stations you add yourself: click **Add Station** and enter a name and an HTTP or HTTPS stream URL, with a logo URL and genre if you like.

## Scrobbling

**Settings > Scrobbling** sends what you play to your listening profile.

- **Last.fm** and **Libre.fm**: click **Connect** and sign in with your username and password. CassetteCat keeps the session the service gives back, not your password.
- **ListenBrainz**: click **Connect** and paste your user token from your [ListenBrainz settings](https://listenbrainz.org/settings/).

A song is scrobbled once you've listened to most of it. Scrobbles are sent as you listen, so songs played while you're offline aren't sent later.

## Discord status

**Settings > Network & Services > Discord Status** shows the song you're playing on your Discord profile while the Discord app is running on this computer.

## Online services

CassetteCat can look things up online to fill in what your files don't have. Each service has its own switch in **Settings > Network & Services**:

| Service | What it's used for |
| :--- | :--- |
| LRCLIB | Synced lyrics when a song has none |
| Radio Browser | Internet radio stations |
| Deezer | Artist photos |
| TheAudioDB | Artist photos and biographies when Deezer has none |
| Wikipedia | Artist biographies |
| Cover Art Archive | Album covers from MusicBrainz |

CassetteCat also asks GitHub for a new version once a day when it starts, unless it came from the Microsoft Store, which updates it for you. **Settings > General & System > Check for Updates** checks straight away.

Lyrics lookups send the song's title and artist, and artwork and biography lookups send the artist and album names. See [Settings, backups and privacy](settings-and-privacy.md#privacy).

## Offline Blackout Mode

**Offline Blackout Mode**, at the top of **Settings > Network & Services**, turns off every internet request with one switch: lookups, radio, streaming servers, scrobbling and update checks. It also pauses the phone remote. Your own files keep playing.
