# Using CassetteCat with your phone

Pair CassetteCat Desktop with [CassetteCat for Android](https://github.com/samyyy2311/CassetteCat) on the same Wi-Fi, and the two work as one: your phone controls the computer, music moves between them, and your likes, playlists and Listening Record stay in sync.

Each app works fine on its own. Pairing is optional.

You need CassetteCat for Android 1.8.0 or later. Earlier versions can't connect to CassetteCat Desktop 0.9.0 and later, because the connection is now encrypted.

## Pairing

1. Make sure **Settings > Phone Remote > Control From Your Phone** is on. It's on by default.
2. On your phone, open **Settings > Desktop Remote** in CassetteCat. Your computer appears in the list after a moment.
3. Tap your computer. The computer asks **Connect *your phone*?**
4. Click **Allow**.

The phone shows up under **Paired Phones**. Pairing is remembered, also when your computer gets a new address on your network.

The first time you turn on the phone remote, Windows may ask whether CassetteCat can use your network. Allow it on private networks, or your phone won't find the computer.

### If your phone can't find the computer

Pair by address instead. **Settings > Phone Remote > Pair Manually** shows an address such as `192.168.1.100:47800#4LECFB`. Click **Copy**, and enter it on the phone under **Settings > Desktop Remote**.

The part after `#` is the pairing code. **New Code** makes a new one, which unpairs phones that were paired by address. Phones you approved with **Allow** stay paired.

See also [Troubleshooting](troubleshooting.md#my-phone-cant-find-the-computer).

## Controlling the computer from your phone

Once paired, pick your computer from the devices button in the phone's player. The phone then:

- shows what the computer is playing, with the cover, progress and queue;
- plays, pauses, skips, seeks and changes the computer's volume, also from the phone's notification, lock screen and volume keys;
- plays songs you pick on the phone on the computer.

## Moving music between devices

Music plays on one device at a time, and the song, queue and position move with it.

- **From the phone to the computer**: pick the computer from the phone's devices button.
- **From the computer to the phone**: open the phone remote from the phone button in the player bar and click **Continue on** *your phone*.
- **Taking over what the phone plays**: when your phone is playing and the computer isn't, the player bar shows the phone's song and controls it. **Play Here** moves it to this computer.

**Play Next on Phone**, in any song's menu, adds a song to play next on your phone.

## Your computer's library on your phone

The phone can browse this computer's music and play it on the computer, or stream it to the phone over Wi-Fi.

## What stays in sync

- **Likes** sync both ways.
- **Playlists** can be sent from the phone to the computer and copied back.
- **Listening Record**: plays on either device count in one history, ranked the same way. The **Sync** button on the Listening Record page brings them together straight away.
- **Backups**: the phone keeps a daily backup on this computer, which it can restore from.

## Privacy and security

Everything stays on your network. The connection is encrypted: the computer makes its own certificate the first time, and the phone remembers it when you pair. If the computer's certificate ever changes, for example after a reinstall that removed its data, the phone asks you to pair again.

To unpair a phone, click **Remove** next to it under **Paired Phones**. To stop phones connecting at all, turn off **Control From Your Phone**.
