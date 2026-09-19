# Feature Roadmap

## Phase 0 - Foundation (this delivery)

- Flutter project (Android + iOS), Riverpod, go_router
- Design system tokens + dark/light/system theme
- TV domain model, `TvProvider` interface, provider registry
- `FakeTvProvider` with three demo devices covering different capability
  sets
- Onboarding -> Discovery -> Pairing -> Remote flow, fully usable against
  fake devices
- Remote, Cast, Devices, Settings screens; Remote Layout and Remote
  Behavior settings; read-only Diagnostics screen
- Secure credential store abstraction (not yet used by a real provider)
- Unit + widget tests, CI

## Phase 1 - Google TV / Android TV (recommended next)

Real local discovery (mDNS), real pairing (Android TV Remote protocol v2,
Kotlin/Dart implementation research needed), secure pairing key
persistence via `SecureCredentialStore`, D-pad/Home/Back/media commands,
volume where supported, keyboard input, reconnect on app resume. See
`docs/research/android-google-tv.md`.

## Phase 2 - Google Cast

Official native Cast Sender SDK on both platforms via a platform channel
or a well-maintained plugin (decision documented once made - see
`docs/research/google-cast.md`). Session lifecycle, media controls,
device discovery, reconnection.

## Phase 3 - Samsung (Tizen)

Websocket remote protocol, token-based pairing, app launch. See
`docs/research/samsung.md` for the caveats around model/year variance.

## Phase 4 - LG webOS

Websocket pairing key exchange, command set, app launch. See
`docs/research/lg-webos.md`.

## Phase 5 - Roku

External Control Protocol (ECP) - HTTP-based, no pairing required. The
most straightforward integration; could be resequenced earlier if the
team wants a quick real-device win. See `docs/research/roku.md`.

## Phase 6 - DLNA / UPnP

SSDP discovery + media renderer control for generic smart TVs and media
boxes. Media playback only, not full remote control. See
`docs/research/dlna.md`.

## Phase 7 - Advanced screen mirroring

Investigate native Android (`MediaProjection` + a receiver, or
Cast-based mirroring) and iOS (AirPlay only - no general mirroring API is
public). See `docs/research/screen-mirroring.md`.

## Phase 8 - Android TV power-user tools

ADB-based APK install/uninstall, wireless debugging pairing. Off by
default behind Settings > Advanced > Developer Mode. See
`docs/research/android-tv-apk-installation.md`.

## Phase 9 - Fire TV

Separate research and likely separate provider from Android TV - Fire TV
forks AOSP but does not ship Google's Android TV Remote service. See
`docs/research/android-google-tv.md` (limitations section).

## Not sequenced yet (explicitly deferred)

- Macros/scenes ("Movie Night", "Gaming") - depends on at least 2 stable
  real providers to be worth building.
- CarPlay - research only, see `docs/research/carplay-feasibility.md`;
  current Apple entitlement categories do not include "TV remote."
- Remote profiles per TV (saved layout/shortcuts per device) - a Devices
  feature enhancement once saved TVs (not just the active session) exist.
