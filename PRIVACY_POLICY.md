# Privacy Policy for CassetteCat Desktop

CassetteCat Desktop is a free and open-source audio player developed with a strict **privacy-first, local-first** architecture. Your listening habits and personal data belong solely to you.

---

## 1. Information We Collect

### A. Personal Information
**We do not collect, store, transmit, or sell any personally identifiable information (PII).**

There are no account registrations with CassetteCat, no user tracking, no profiling, and no advertising networks.

### B. Local Filesystem & Audio Access
CassetteCat Desktop accesses your local filesystem strictly to scan, organize, and play your music files.
* Audio indexing, embedded artwork extraction, and metadata parsing happen 100% locally on your computer.
* Your music files are never uploaded to any external server.

### C. Self-Hosted Server Credentials
If you connect CassetteCat Desktop to a self-hosted media server (such as Subsonic, Navidrome, Gonic, Airsonic, or Jellyfin):
* Your server URLs, usernames, and authentication tokens/passwords are stored **locally on your device**.
* Sensitive credentials are protected using platform-native secure storage:
  * **Windows:** Windows Credential Manager (`wincred.h`).
  * **Linux:** FreeDesktop Secret Service API via `libsecret`.
* Credentials are sent exclusively to your specified server endpoint to facilitate direct media streaming.

### D. Phone Remote & Local Wi-Fi Sync
When connecting with [CassetteCat for Android](https://github.com/samyyy2311/CassetteCat) for remote playback or queue handoff:
* Communication occurs strictly over your **local area network (LAN)**.
* No data traverses third-party servers or relays.

---

## 2. Third-Party Services & Network Requests

CassetteCat Desktop only makes network requests to external services when directly necessary for the features you use:

1. **Lyrics (LRCLIB):**
   * When fetching synchronized or plain lyrics, track titles and artist names are queried against the public [LRCLIB](https://lrclib.net) API.
2. **Metadata & Artwork (MusicBrainz / Cover Art Archive / TheAudioDB / Deezer / iTunes):**
   * Public metadata APIs are queried using artist and album names to fetch album covers and artist biographies.
3. **Optional Scrobbling (ListenBrainz / Libre.fm):**
   * If you explicitly configure scrobbling, playback logs (track title, artist, time played) are submitted to your chosen scrobbling service using the token you provide.
4. **Internet Radio (Radio Browser):**
   * Station directories and search queries are fetched from the community-run [Radio Browser](https://www.radio-browser.info) API.
5. **Discord Rich Presence (Optional):**
   * When enabled, current playing status is communicated locally to your running Discord desktop client via local IPC.
6. **Release Update Checks:**
   * Checks GitHub Releases for new desktop version availability.
7. **Offline Blackout Mode:**
   * You can enable "Offline Blackout Mode" in Settings at any time to instantly cut all outbound network requests across the entire application.

---

## 3. Analytics, Tracking & Advertising

* **No Ads:** CassetteCat Desktop contains zero advertisements.
* **No Analytics:** We do not include telemetry, telemetry SDKs, or background usage tracking.
* **No Trackers:** There are no behavioral trackers embedded in the app.

---

## 4. Data Retention & Deletion

All data generated within the app (playlists, playback history, local listening stats, and server logins) is stored locally on your machine in standard platform application directories.

You can delete your data at any time by:
* Using the **"Clear Credentials"** or **"Reset Listening Record"** options in App Settings.
* Deleting the local configuration and database directory.
* Uninstalling the application.

---

## 5. Open Source Transparency

CassetteCat Desktop is free and open-source software licensed under the **GNU General Public License v3.0 or later (GPL-3.0-or-later)**. The complete source code is publicly auditable at:
[https://github.com/samyyy2311/CassetteCat-Desktop](https://github.com/samyyy2311/CassetteCat-Desktop)

---

## 6. Contact

If you have questions or feedback regarding this Privacy Policy, please open an issue on GitHub:
* GitHub: [https://github.com/samyyy2311/CassetteCat-Desktop/issues](https://github.com/samyyy2311/CassetteCat-Desktop/issues)
