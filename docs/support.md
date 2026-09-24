# Remote TV 2026 — Support

Remote TV 2026 controls compatible smart TVs and streaming devices over
your home Wi-Fi network, and can send media links to devices that accept
casting. This page covers setup and the most common problems.

## Before you start

1. **Same Wi-Fi network.** Your phone and your TV must be on the same
   network. Guest networks, "AP/client isolation", and some mesh or
   business networks block devices from seeing each other.
2. **TV switched on.** Most TVs don't answer on the network while they are
   off or in deep standby, and the app cannot switch a TV on.
3. **Local Network permission (iPhone and iPad).** The first time you
   search for TVs, iOS asks to let Remote TV 2026 find devices on your
   local network. Choose **Allow**. If you chose "Don't Allow", turn it on
   in **Settings → Privacy & Security → Local Network → Remote TV 2026**.

## Supported devices

| Device family | Remote control | Casting links | How it's found |
|---|---|---|---|
| Android TV / Google TV | Yes (pairing code on the TV) | Via its Google Cast entry | Automatically |
| Chromecast and TVs with Chromecast built-in | Volume and playback | Yes | Automatically |
| Roku TV and Roku players | Yes | No | Android: automatically. iPhone/iPad: **Add TV by IP address** |
| LG webOS TVs | Yes (accept the prompt on the TV) | No | Android: automatically. iPhone/iPad: **Add TV by IP address** |
| Samsung Tizen TVs (2016 and newer) | Yes (allow the connection on the TV) | No | Android: automatically. iPhone/iPad: **Add TV by IP address** |
| DLNA / UPnP media renderers | Playback and volume | Yes | Android only |

Which buttons appear depends on what your TV reports it supports. The app
hides controls a TV can't use. Features vary by model and firmware.

**Not supported:** Fire TV, Apple TV, screen mirroring, voice control,
switching a TV on, and casting photos or videos stored on your phone.

## My TV isn't found

- Check that the phone and TV are on the **same Wi-Fi** and that the TV is
  on.
- On iPhone/iPad, check the **Local Network** permission (see above).
- Tap **Scan again**. A scan takes a few seconds and stops by itself.
- Restart the TV, and turn the phone's Wi-Fi off and on.
- A Google TV can appear twice: once as **Android TV / Google TV** (the
  remote) and once as **Google Cast** (for casting links). Both entries
  are the same TV.
- Still nothing? Use **Add TV by IP address**.

## Add a TV by IP address

1. Find the TV's IP address in its network settings (usually **Settings →
   Network → Status / About**). It looks like `192.168.1.20`.
2. In the app, open **Find your TV → Add TV by IP address** and enter it.
3. The app checks which kind of TV answers at that address and adds it to
   the list.

On iPhone and iPad this is how Roku, LG, and Samsung TVs are added. iOS
restricts the network discovery method (SSDP) those TVs use, so the app
cannot find them automatically there. DLNA devices can't be added by
address because they only publish their details through that same
discovery method.

## Pairing problems

- **Android TV / Google TV:** after you pick the TV, it shows a
  6-character pairing code made of numbers **0–9** and letters **A–F**
  (for example `A4F29C`). Type it in the app (lower case is fine), or
  copy it and tap **Paste code**. It is not a numeric PIN, so letters
  are expected. If the code is rejected, check it carefully and try
  again. If the code disappears from the TV, go back and select
  the TV again to get a new one.
- **LG:** accept the "Remote TV 2026" prompt on the TV with its own
  remote.
- **Samsung:** choose **Allow** when the TV asks about the new device. If
  you picked **Deny**, allow it again in the TV's device connection
  settings (the menu name varies by model).
- **Roku and Google Cast** don't need pairing.
- If a TV was reset or "forgot" your phone, remove it in **Devices →
  Forget** (Android TV) and pair again.

## Reconnecting

- The app reconnects automatically after short network drops, for about
  30 seconds. After that it stops trying and shows that the TV is
  disconnected. Select the TV again to reconnect.
- If the TV was switched off or restarted, wait until it has fully started
  and then select it again.
- If reconnecting keeps failing for an Android TV, **Forget** it in
  **Devices** and pair again.

## Casting a link

Open **Cast** while connected to a casting-capable device (Google Cast or
DLNA) and paste a direct link to a media file, for example one ending in
`.mp4`. The TV downloads the file itself, so the link must be reachable
from the TV. Web pages and links that need a login usually won't play.

## Privacy

The app works entirely on your local network. It has no account, no
analytics, and no tracking, and it sends nothing to the developer. Pairing
credentials stay in your phone's secure storage. Read the full
[Privacy Policy](privacy-policy.html).

## Contact

Remote TV 2026 is developed by **Thaer Mosa**.

- Website: <https://thaerm.github.io/>
- GitHub: <https://github.com/ThaerM>

When reporting a problem, include your phone model and OS version, the TV
brand and model, and what you tried.

---

Remote TV 2026 is not affiliated with or endorsed by Google, Roku, LG,
Samsung, or any other manufacturer. Product names are trademarks of their
respective owners.
