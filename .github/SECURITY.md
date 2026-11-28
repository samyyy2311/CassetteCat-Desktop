# Security Policy

CassetteCat for desktop keeps your server and scrobbling passwords in the system's credential store (Windows Credential Manager, or the Secret Service keyring on Linux) and runs a small server on your local network so the Android app can pair with it. Problems in either of those, or anywhere else in the app, are worth reporting.

## How to report

Use [private vulnerability reporting](https://github.com/samyyy2311/CassetteCat-Desktop/security/advisories/new) on this repository. Only the maintainer can see these reports, so please don't use public issues or discussions for security problems.

Tell us:

1. Which release you're on, which operating system, and whether you installed it with the installer, AppImage, a .deb or .rpm package, or the archive.
2. What goes wrong, and what someone could gain from it.
3. How to make it happen. A short script, a sample file or a captured request helps most.

Please use test accounts and made-up files rather than your own passwords or music library.

## Fixes and disclosure

Only the latest release gets security fixes. A confirmed problem is fixed in the next release, and the advisory goes public once that release is available. You're welcome to be named in the advisory and the release notes, or to stay anonymous.

We ask that you don't share the details until then.

## What counts

Worth reporting:

- passwords, session keys or tokens stored or sent in a way others could read
- the pairing server answering devices outside your local network, or accepting requests it shouldn't
- audio files, playlists, tags or covers that crash the app or make it read or write files it shouldn't
- the update check sending you to a download that isn't an official release

Not a CassetteCat problem:

- bugs in Jellyfin, Navidrome, Last.fm, ListenBrainz or other services, which belong with those projects
- bugs in Qt or other libraries, unless CassetteCat uses them unsafely
- anything that needs administrator rights or someone already sitting at your unlocked computer
- flooding the network to slow the app down
