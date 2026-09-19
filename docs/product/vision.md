# Product Vision

Remote TV 2026 is a universal, capability-aware remote and companion app
for smart TVs. "Universal" describes the product promise to the user, not
the engineering approach: under the hood every TV ecosystem gets its own
provider, discovery method, pairing flow, and command set, and the app
adapts its UI to whatever the connected device can actually do.

## Who it's for

Households with more than one kind of TV (a Google TV in the living room,
an older Samsung in the bedroom, a hotel Roku on a trip) who are tired of
juggling manufacturer apps that each look and behave differently.

## What "universal" means here

- One app, one design language, one navigation model - regardless of which
  TV is connected.
- The remote UI is generated from the connected device's declared
  capabilities (`TvCapabilities`), not hardcoded per brand. A TV that can't
  do voice input simply doesn't show a voice button - it isn't disabled or
  greyed out, it's absent.
- Vendor differences (protocol, auth, transport) are isolated inside a
  `TvProvider` implementation and never leak into shared UI or domain code.

## What "universal" does not mean

- It does not mean one network protocol works everywhere - Chromecast,
  Tizen, webOS, Roku's ECP, and DLNA are unrelated protocols with
  different security models.
- It does not mean every TV supports every feature. Some capabilities
  (app install, wake-on-LAN, screen mirroring) are only available on a
  subset of platforms and models.
- It does not mean the app pretends to support a platform before that
  platform's provider is implemented and tested against real research -
  see `docs/research/tv-protocol-matrix.md`.

## Longer-term product surface

Beyond remote control: media casting, screen mirroring, TV app shortcuts
and launching, saved multi-TV profiles, macros/scenes, and (behind an
explicit, off-by-default developer flag) Android TV APK sideloading tools.
See `docs/product/feature-roadmap.md` for sequencing.
