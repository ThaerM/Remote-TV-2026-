# RC1 Real-Device Checklist — Android TV Gates A–D

A compact version of `real-device-test-plan.md` for **v1.0.0-rc1** on your
iPhone (`00008150-001E61083C6A401C`) against **Family room TV**
(`_androidtvremote2._tcp`, port 6466). Tick each box only after you've
seen it happen. **None of these is passed until you run them.**

## Setup (Mac)

```bash
cd ~/Desktop/Projects/remote_2026
git fetch origin
git switch release/1.0.0-rc1 && git pull --ff-only
flutter clean && flutter pub get
# Release-mode build on the phone (what users will run), console attached:
flutter run --release -d 00008150-001E61083C6A401C
```

- The bundle ID changed to `com.thaerm.remotetv2026`, so this installs as a
  **new app** next to the old dev build. Delete the old "Remote TV 2026"
  icon first so you don't test the wrong one. The new app has no pairings
  yet, so expect to pair again.
- If Xcode asks for signing: open `ios/Runner.xcworkspace` → Runner →
  Signing & Capabilities → Team **KE2TDZEG3K**, Automatic signing.
- Phone and TV on the same Wi-Fi, TV on.
- `--release` hides nothing: `[TV]...` logs still print to the console.

## Gate A — Discovery

- [ ] First launch shows the new icon and a dark launch screen with the mark
      (no Flutter logo).
- [ ] **Find my TV** → iOS asks for Local Network → Allow.
- [ ] Within ~6 s: `[TV][DISCOVERY][ANDROID_TV] started backend=native_bonjour`
      … `found device=Family room TV` … `completed count=1`.
- [ ] List shows **Family room TV · Android TV / Google TV**. If the TV has
      Chromecast built-in, a second **Family room TV · Google Cast** entry is
      expected. Both are the same TV, not a duplicate bug.
- [ ] No demo/fake TVs ("Demo device") anywhere.
- [ ] **Scan again** twice quickly → one scan, it stops by itself, no
      duplicate cards.
- [ ] Wi-Fi off → Scan → clear "no network" style message (no spinner forever).
- [ ] Settings → Privacy & Security → Local Network → turn Remote TV 2026 off →
      Scan → the "needs permission" message. Turn it back on.

## Gate B — Pairing

- [ ] Tap **Family room TV** → TV shows a 6-character **hex** code (0-9, A-F,
      e.g. `A4F29C`). App: "Enter the 6-character pairing code shown on your
      TV", six boxes, hint "Numbers 0-9 and letters A-F", **Paste code**.
- [ ] Keyboard has letters (not a number pad). `G`, `-`, `!` can't be typed;
      a 7th character is refused.
- [ ] Enter a **wrong** valid-looking code → boxes shake, "Incorrect pairing
      code.", TV keeps showing its code.
- [ ] Enter the **correct** code in lower case → shown upper case →
      Connected screen → Remote.
- [ ] Paste: type the TV's code in Notes, copy it, next pairing tap
      **Paste code** → fills and pairs. Copy `G12345` → Paste → refused with
      a message.
- [ ] VoiceOver on: the field is read as "Pairing code", not "PIN".
- [ ] Cancel: start pairing again on a fresh app install (or after Forget),
      press **Back** on the code screen → the code disappears from the TV
      within a few seconds; selecting the TV again shows a new code.
- [ ] Retry after cancel works.
- [ ] Stored identity: force-quit, reopen, select the TV → connects **without**
      a code.
- [ ] Console: no line contains the code, "BEGIN CERTIFICATE", "PRIVATE KEY",
      or a token.

## Gate C — Commands

| Command | Works | Notes |
|---|---|---|
| D-pad up/down/left/right | [ ] | |
| Select / OK | [ ] | |
| Back | [ ] | |
| Home | [ ] | |
| Menu | [ ] | |
| Volume up / down | [ ] | hold = repeats, stops on release |
| Mute | [ ] | |
| Play/pause, rewind, forward | [ ] | in a video app |
| Keyboard (type in YouTube search) | [ ] | |
| Quick app: YouTube | [ ] | |
| Quick app: Netflix | [ ] | only if installed on the TV |
| Touchpad: swipe = one step, tap = OK | [ ] | Settings → Remote layout |
| No button shown that does nothing | [ ] | |

## Gate D — Reconnect

- [ ] Lock phone 30 s → unlock → next button press works (it may show
      "reconnecting" briefly).
- [ ] App to background 2 min → resume → works.
- [ ] Force-kill → reopen → select the TV → connects without a code.
- [ ] Wi-Fi off 10 s → on → `reconnecting` → `connected` within ~30 s.
- [ ] TV restart (unplug 10 s) → app shows reconnecting. After the TV is back,
      either reconnects or, after about 30 s of failures, stops with
      "disconnected/error". Select the TV again → connects.
- [ ] Log shows at most 5 `reconnect_attempt=` lines per drop, then
      `reconnect_gave_up`. **No endless loop.**
- [ ] Switch to the **Google Cast** entry and back → no errors, and only one
      `reconnect`/connection sequence per switch (no duplicate sockets).
- [ ] Devices → **Forget** → select the TV → asks for a new code.

## Report back

For any unticked box, send the exact on-screen text and the 20 console
lines around it. Gates A–D all ticked = Android TV passes the RC1 gate.
Until then the app is **not** production-ready.
