# Manual Test Guide: Android TV / Google TV (Real Device)

`AndroidTvProvider` has never been run against physical hardware. Its
protocol logic is proven correct in isolation (see "What's already
verified" below), but the end-to-end flow against a real TV needs this
manual pass before it can be trusted. Do this before relying on the
feature, and repeat it after any change to
`lib/tv/providers/android_tv/`.

## What's already verified (no TV needed)

- The pairing-secret SHA-256 hash matches the protocol's algorithm
  (`test/tv/providers/android_tv/android_tv_identity_test.dart` brute-forces
  a real matching code and confirms it validates).
- The pairing handshake and remote-session message exchanges are correct
  against a scripted fake transport
  (`pairing_handshake_test.dart`, `remote_session_test.dart`,
  `android_tv_provider_test.dart`).
- `flutter analyze` confirms every generated-protobuf field/enum name
  used compiles - this catches typos in message construction that unit
  tests alone might miss.

## What still needs a real device

- Whether discovery actually finds a real Android TV / Google TV on the
  LAN - the protocol logic is unit-tested against fakes, but only a real
  responder proves it. On iOS this goes through the native Bonjour bridge
  (look for `started backend=native_bonjour` in the logs); on Android
  through raw mDNS (`started backend=mdns`). Every scan must end with
  `completed count=N`; if it's 0, the preceding `resolve_failed ...
  reason=...` line says why.
- Whether the TLS handshake against a *real* Android TV Remote service
  succeeds (self-signed cert acceptance, `onBadCertificate` behavior).
- Whether the pairing PIN shown on a real TV is genuinely 6 hex digits
  and behaves as `docs/research/android-google-tv.md` describes.
- Whether reconnect-after-idle-disconnect and reconnect-after-Wi-Fi-drop
  behave as designed on real hardware/OS timing.
- Cross-manufacturer/cross-OS-version compatibility (Sony, TCL, Chromecast
  with Google TV, NVIDIA Shield, different Android TV OS versions).

## Prerequisites

- An Android TV or Google TV device, powered on, with Developer options
  not required (this is the normal remote-control protocol, not ADB).
- The device and the phone running Remote TV 2026 on the **same Wi-Fi
  network** (not guest/isolated Wi-Fi - client isolation blocks mDNS and
  the TLS connection).
- The TV's Android TV Remote Service should be enabled (it is by default
  on most Android TV/Google TV devices - Settings > Apps > see all system
  apps > "Android TV Remote Service" should be present and enabled).

## Test sequence

1. **Discover**: open Remote TV 2026 > Find my TV. Expect the real
   device to appear in the list within ~5 seconds, alongside no fake
   devices (the fake catalog is unaffected). If nothing appears, see
   Troubleshooting.
2. **Pair**: tap the device. Expect the TV to show a pairing prompt with
   a **6-digit** code within a few seconds. Enter it in the app.
   - Expected success: the app navigates to the Remote screen.
   - Expected failure paths to also test: cancel pairing on the TV,
     enter a wrong code (app should show an error, not crash or hang).
3. **D-pad**: from the Remote screen, press each direction and Select.
   Expect the TV's on-screen focus to move accordingly.
4. **Home / Back**: press both. Expect standard Android TV navigation
   behavior.
5. **Volume**: press Volume Up/Down/Mute. If the TV has no separate
   volume control (some Google TV streaming boxes rely on the TV's own
   remote for volume via HDMI-CEC), note whether the app still reports
   `TvCapabilities.volume == true` incorrectly - if so, file this as a
   capability-mapping bug, since currently `getCapabilities()` assumes
   volume support whenever the TV's negotiated feature bitmask includes
   it, and that bitmask's real-world accuracy per device is exactly what
   this manual pass is meant to confirm.
6. **Keyboard**: tap the keyboard button, type some text, submit. Expect
   it to appear in whatever text field is focused on the TV.
7. **Media keys**: from the "More controls" sheet, test
   play/pause/rewind/forward/next/previous against a video paused on the
   TV.
8. **Launch app**: use the Netflix/YouTube quick-app shortcut. Expect the
   TV to open (or attempt to open) that app.
9. **Disconnect / reconnect**: use Devices > Disconnect, then reconnect
   without re-entering the pairing code (should skip straight to
   connected, reusing the stored certificate).
10. **Forget**: use Devices > Forget on the paired entry, then repeat
    step 2 - it should require pairing again from scratch (proves
    credentials were actually deleted, not just hidden).
11. **Backgrounding**: background the app for ~20 seconds (longer than
    the 16s idle-disconnect watchdog), then foreground it. Expect a
    reconnect attempt rather than a stuck "connecting" spinner.
12. **Wi-Fi drop**: briefly toggle phone Wi-Fi off/on while connected.
    Expect the connection state to show `reconnecting` and then recover
    without needing to re-pair.

## Collecting safe logs

`AppLogger` prints to the debug console with `[TV][...]` tags (see
`docs/architecture/diagnostics.md`). When reporting an issue, copy the
console output around the failure - it never contains PINs, certificates,
or tokens, so it's safe to paste into an issue or PR comment as-is. Do
not additionally paste PEM certificate contents, pairing codes, or
`AndroidTvIdentity` field values manually.

## Troubleshooting

- **No devices found**: confirm the TV and phone are on the same Wi-Fi
  network (not a guest network with client isolation), and that the
  TV's screen is on (some devices suppress mDNS advertisement in deep
  sleep).
- **Pairing times out**: the TV may require confirming a prompt on-screen
  before showing the code - check the TV display, not just the phone.
- **"AuthenticationFailedException" on reconnect**: this is the "stored
  identity was rejected, re-pairing" path in `AndroidTvProvider.connect` -
  expected if the TV's pairing list was cleared (factory reset, "forget
  all remotes"). The app should transparently re-pair; if it doesn't,
  that's a bug.
