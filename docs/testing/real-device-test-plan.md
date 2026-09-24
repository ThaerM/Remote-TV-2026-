# Real-Device Test Plan

Everything below is **unit-tested against fakes** (no real sockets in CI)
but **none of it has been run against real hardware yet**. This is the
script to do that. Record results in the table at the end of each section
and file issues for anything that fails.

Setup for every run:

```bash
git fetch origin && git switch main && git pull --ff-only
flutter pub get
(cd ios && pod install)          # iOS only
flutter run -d <device-id>        # iPhone: 00008150-001E61083C6A401C
```

Keep the console visible - every step names the log line that proves it.
Phone and TVs on the **same Wi-Fi**; iPhone Settings > Privacy & Security
> Local Network > Remote TV 2026 **on**.

## Gate A - Android TV discovery (blocking)

1. Open the app -> **Find my TV**.
2. Expect, within ~6 s on iPhone:
   ```
   [TV][DISCOVERY][ANDROID_TV] started backend=native_bonjour
   [TV][DISCOVERY][ANDROID_TV] ptr instance=Family room TV
   [TV][DISCOVERY][ANDROID_TV] srv host=Android_9ca7000de06743959d7010b65da4d5c7.local port=6466
   [TV][DISCOVERY][ANDROID_TV] resolved host=Android_...local ip=<ip>
   [TV][DISCOVERY][ANDROID_TV] found device=Family room TV
   [TV][DISCOVERY][ANDROID_TV] completed count=1 durationMs=...
   ```
   (on Android the first line says `backend=mdns`).
3. The list shows **Family room TV** with subtitle **Android TV / Google
   TV** (and, if the TV has Chromecast built-in, a second entry labelled
   **Google Cast**).
4. If `completed count=0`: note the `resolve_failed stage=... reason=...`
   line and the on-screen message, then try **Add TV by IP address** with
   the TV's IP (TV: Settings > Network > About).

Pass = the TV is listed by scanning (not only by IP).

## Gate B - Android TV pairing (blocking)

1. Tap **Family room TV**. The TV shows a 6-character **hex** code (0-9,
   A-F). The app's keyboard must allow letters (fixed in RC1: the field
   used to accept digits only).
2. Enter it. Expect `[TV][PAIRING]...` success, the Connected screen, then
   the Remote.
3. Wrong code: enter a wrong one first - the digits shake, an error shows,
   the TV keeps its code; then enter the right one.
3b. Cancel: on the code screen press **Cancel** (or Back) - the app returns
   to Find your TV and the TV's code dialog closes; selecting the TV again
   shows a new code.
4. Kill the app, reopen, connect again - **no code** should be asked
   (identity is in the Keychain/Keystore).
5. Devices > Forget -> connect again -> the TV asks for a code again.
6. Confirm no log line contains the code, a certificate or a key.

## Gate C - Android TV commands (blocking)

D-pad (up/down/left/right/OK), Back, Home, Menu, volume up/down/mute,
channel up/down (on a tuner input), play/pause, rewind/forward,
previous/next, digits (More controls), keyboard (type in YouTube search),
Netflix/YouTube quick apps, touchpad swipe = one D-pad step per swipe and
tap = OK, press-and-hold volume repeats and stops on release.

| Command | Works? | Notes |
|---|---|---|
| ... | | |

## Gate D - Android TV reconnect (blocking)

1. Connected, lock the phone 30 s, unlock -> still usable.
2. Turn the phone's Wi-Fi off 10 s, on -> `reconnecting` then `connected`
   within ~30 s, no duplicate sessions in the logs.
3. Power-cycle the TV -> the app shows reconnecting, then connected (or a
   clear error) - no endless retry loop: at most 5 `reconnect_attempt=`
   lines (1+2+4+8+16 s), then `reconnect_gave_up`.
3b. Switch to another TV (e.g. the Google Cast entry) and back - the old
   connection is closed, no duplicate sessions.
4. Force-quit the app, reopen -> the remembered TV reconnects.

**Android TV is production-ready only when Gates A-D pass.**

## Google Cast (Chromecast / Google TV / Cast TVs)

1. Find my TV -> pick the **Google Cast** entry (named from the device,
   e.g. "Living Room TV") -> no pairing -> Connected.
2. Cast tab -> paste a direct MP4 link, e.g. a public sample video URL ->
   **Cast**. Expect `[TV][CAST][GOOGLE_CAST] load contentType=video/mp4`,
   playback on the TV, "Now playing" in the app.
3. Pause/play, seek bar, -10 s/+30 s, stop; volume rocker on the Remote
   (hidden if the device fixes volume).
4. An HLS `.m3u8` link; a web page URL (expect the "direct media file"
   error, not a hang).
5. Wi-Fi off/on while casting -> reconnect (max 3 attempts).

## Roku

1. Find my TV -> Roku listed by its name (iOS: likely **not** listed
   without the multicast entitlement - use Add TV by IP).
2. Connect (no pairing). D-pad, Home, Back, Menu (= Roku `*`), play/pause,
   rewind/forward, keyboard in a search field, apps list and launch.
3. Roku TV only: volume, mute, channel, power (off).
4. Roku: Settings > System > Advanced system settings > Control by mobile
   apps > **Disabled** -> connect shows the "Control by mobile apps"
   message.

## LG webOS

1. Discovery by name (Android) / Add by IP (iOS without entitlement).
2. First connect: the TV asks to allow the app; the app shows "confirm on
   your TV". Allow -> Connected. Reconnect later -> no prompt.
3. Buttons (D-pad, OK, Back, Home, Menu, Guide, Info, color keys, digits,
   volume, channel, media), keyboard, apps, power off.
4. Deny on first connect -> clear error, no stored key.

## Samsung Tizen (2016+)

1. Discovery / Add by IP (REST `:8001/api/v2/`).
2. First connect: Allow/Deny on the TV. Allow -> Connected; reconnect ->
   no prompt (token reused).
3. Keys incl. Source (input), keyboard (focus a text field first), apps
   (may be empty on 2022+ firmware - the quick-apps row should just hide).
4. Deny -> clear error.

## DLNA / UPnP renderers

1. Android: Find my TV lists the renderer as **DLNA / UPnP**. (iOS without
   the multicast entitlement: not discoverable - expected.)
2. Connect -> Cast tab -> cast an MP4/MP3 link -> plays; pause, seek,
   stop; volume if the renderer supports RenderingControl.
3. An unsupported format -> "The TV cannot play this media".
