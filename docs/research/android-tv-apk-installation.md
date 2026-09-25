# Research: Android TV / Google TV APK Installation

## Two entirely different flows - must not be blurred in the UI

### Normal consumer flow

- Google Play Store on the TV itself, or Play Store deep links
  (`market://details?id=...`) that open the *TV's* Play Store app if the
  app targets that context, or more commonly just point the user to
  search for the app on the TV.
- We can surface "Open in Play Store" deep links for known streaming
  apps from the phone, but we cannot install an app onto the TV through
  the Play Store on the user's behalf from a companion app - Play Store
  installs are device-local, not remotely triggerable by a third party
  app without Google's own remote-install APIs (which are Google-account-
  scoped and not something a third-party remote app has access to).

### Power-user / developer flow (ADB)

- **Wireless debugging / ADB over network**: Android TV/Google TV
  devices with Developer Options enabled and "Network debugging" or
  "Wireless debugging" (Android 11+ pairing-code flow) turned on expose
  an ADB endpoint on the LAN.
- **ADB pairing**: Android 11+ devices support the same wireless-adb
  pairing-code flow as phones (`adb pair <ip>:<port>`) - a 6-digit code
  shown on the TV, roughly analogous to our existing
  `TvPinPairingRequest` pattern.
- **APK transfer + install**: once paired, `adb install <path.apk>` (or
  the equivalent raw ADB protocol implementation, since shelling out to
  the `adb` binary isn't available on a mobile OS - a Dart/Flutter
  implementation would need to speak the ADB wire protocol directly, or
  bridge through a native Android service using `android.debug` APIs).
- **Update/uninstall**: `adb install -r` (replace) / `adb uninstall`
  follow the same pattern.
- **Android TV restrictions**: Google TV/Android TV devices restrict
  "Install unknown apps" per source app on Android 8+, generally
  defaulted off; sideloading is technically fully possible once
  Developer Options + wireless debugging are enabled by the user on the
  TV, but is inherently a device-owner action, not something enabled
  from the outside.

## Security risks - real, not hypothetical

- Installing arbitrary APKs bypasses Play Protect's install-time
  scanning on unknown sources.
- A compromised or malicious APK sideloaded via this flow has the same
  access as any other installed app - no additional sandboxing from the
  sideload path itself.
- ADB access, once paired, is a fairly powerful channel (shell access,
  not just install) - our app should scope any implementation to install/
  uninstall/update operations only, not expose a general shell.

## Requirements for any future implementation

- **Off by default.** Gated behind Settings > Advanced > Developer Mode
  (already scaffolded as `SettingsState.developerModeEnabled = false` by
  default in this foundation).
- **Explicit per-action confirmation.** Never install/update/uninstall
  without the user confirming that specific action - no "auto-update"
  silently in the background.
- **Clear developer/power-user labelling** in the UI wherever this
  surface appears - never presented as part of the normal consumer flow.
- **No default UI entry point** until implemented - the Settings screen
  in this foundation shows the Developer Mode toggle with a "later
  phase" description, no functional ADB tooling yet.

## Recommended phase

Phase 8, after at least one and ideally two real remote providers are
stable, since this feature is higher-risk and lower-priority than basic
remote control.

## Status

**Not implemented.** Nothing in the app talks ADB; Developer Mode remains
an off-by-default setting with no functional tooling behind it. When
built, it needs a Dart ADB implementation (legacy `:5555` RSA-key auth
with the on-TV prompt, and Android 11+ wireless-debugging pairing, which
is TLS + a SPAKE2 pairing code) plus the requirements above. The same
transport would back a power-user Fire TV provider
(`docs/research/fire-tv.md`).
