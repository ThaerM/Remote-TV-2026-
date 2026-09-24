# Remote TV 2026

A universal, capability-aware smart TV remote and companion app built
with Flutter.

## Project status

**v1.0.0 RC1** (`release/1.0.0-rc1`), feature-frozen. What's left before
store submission: [`docs/release/release-checklist.md`](docs/release/release-checklist.md).
Public pages: [privacy policy](docs/privacy-policy.md) ·
[support](docs/support.md). Developer: Thaer Mosa
(<https://thaerm.github.io/>).

Six real providers are implemented - **none has passed its real-device
test yet**, so treat every one as "implemented and unit-tested, not
proven on hardware". The honest, row-by-row picture is in
[`docs/product/feature-matrix.md`](docs/product/feature-matrix.md); the
script to prove them is
[`docs/testing/real-device-test-plan.md`](docs/testing/real-device-test-plan.md).

| Provider | What it does | Notes |
|---|---|---|
| Android TV / Google TV | Full remote (Android TV Remote v2, TLS pairing) | Gates A-D pending |
| Google Cast | Cast media links, playback, volume | Dart CASTV2 sender - see ADR-004 |
| Roku | Full remote (official ECP), apps | iOS: add by IP unless the multicast entitlement is granted |
| LG webOS | Full remote (SSAP), apps, keyboard | Confirm-on-TV pairing |
| Samsung Tizen (2016+) | Full remote, apps, keyboard | Allow-on-TV pairing |
| DLNA / UPnP renderers | Cast target only | Android discovery only |

Not implemented (and not claimed): Fire TV, screen mirroring, APK
install, voice, power-on/Wake-on-LAN, casting files stored on the phone,
CarPlay (not viable). `FakeTvProvider` demo devices exist for UI work
only (`--dart-define=ENABLE_DEMO_TV_DEVICES=true`).

## What's implemented

- Flutter app (Android + iOS), premium dark-first design system with a
  centralized motion system, reduced-motion support and accessibility
  semantics - see [`docs/design/design-system.md`](docs/design/design-system.md)
- `TvProvider` interface + provider registry + capability-driven UI: every
  control renders only when the connected device supports it
  (`TvCapabilities`, including per-key `unsupportedKeys`) - see
  [`docs/architecture/provider-system.md`](docs/architecture/provider-system.md)
- Discovery that always finishes and says why it missed TVs (local
  network denied, not on Wi-Fi, multicast restricted, timeout), plus
  **Add TV by IP address**
- Flow: Welcome -> Find my TV -> Pairing (PIN or confirm-on-TV) ->
  Connected -> Remote; Cast tab (media links, now playing); Devices;
  Settings (layout, behavior, theater mode, diagnostics)
- Secrets only in Keychain/Keystore; local-first, no analytics - see
  [`docs/architecture/security.md`](docs/architecture/security.md) and
  [`docs/architecture/privacy.md`](docs/architecture/privacy.md)
- Unit + widget tests (no real network in CI) and CI that also builds the
  Android and iOS apps

## Architecture

Feature-first (`lib/features/`) plus a dedicated `lib/tv/` layer for the
TV domain and provider system, so every TV ecosystem's quirks stay inside
its own provider and never leak into shared UI. State management is
Riverpod. Full details:

- [`docs/architecture/overview.md`](docs/architecture/overview.md)
- [`docs/architecture/provider-system.md`](docs/architecture/provider-system.md)
- [`docs/architecture/security.md`](docs/architecture/security.md)
- [`docs/architecture/diagnostics.md`](docs/architecture/diagnostics.md)
- [`docs/decisions/`](docs/decisions) - ADRs

## Getting started

```bash
flutter pub get
flutter run
```

`flutter run` alone uses **real providers only** - no demo devices, so
it's safe to run on a real phone against a real TV. To also see the
three fake demo devices (UI development, screenshots, demos):

```bash
flutter run --dart-define=ENABLE_DEMO_TV_DEVICES=true
```

## Commands

```bash
flutter pub get                          # install dependencies
dart format .                            # format
dart format --set-exit-if-changed .      # format check (CI)
flutter analyze                          # static analysis
flutter test                             # unit + widget tests
flutter build apk --debug                # Android debug build (also run in CI)
flutter build ios --debug --no-codesign  # iOS build on a Mac (also run in CI)
```

## Testing

`flutter test` runs every provider's protocol against scripted fakes of
the real device (Android TV transports, a fake Cast receiver, a fake LG
SSAP endpoint, a fake Samsung channel, a fake UPnP renderer, fake SSDP and
mDNS) plus widget tests for capability-driven UI - no real network or TV
in CI. Real hardware is covered by
[`docs/testing/real-device-test-plan.md`](docs/testing/real-device-test-plan.md).
Release readiness: [`docs/release/release-checklist.md`](docs/release/release-checklist.md).

## For AI agents / future contributors

Read [`AGENTS.md`](AGENTS.md) first.
