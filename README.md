# Remote TV 2026

A universal, capability-aware smart TV remote and companion app built
with Flutter.

## Project status: Foundation

This is the Foundation phase. **The app currently ships with only a demo
TV provider (`FakeTvProvider`)** - no real television integration exists
yet. Discovery, pairing, connecting, and sending remote commands all work
end-to-end, but against three simulated demo devices, not real hardware.
Real vendor support is planned platform-by-platform - see
[`docs/product/feature-roadmap.md`](docs/product/feature-roadmap.md).

## What's implemented

- Flutter app (Android + iOS) with a dark-first Material 3 theme
  (dark / light / system)
- TV domain model + `TvProvider` interface + provider registry
  (`lib/tv/`) - see
  [`docs/architecture/provider-system.md`](docs/architecture/provider-system.md)
- `FakeTvProvider`: three demo devices with different capability sets, so
  the remote UI can be proven to adapt per device without real hardware
- Capability-driven Remote screen: every control group (D-pad, volume,
  channel, keyboard, voice, media transport, numeric keypad, color keys,
  quick app shortcuts) renders only when the connected device reports
  support for it
- Full first-run flow: Welcome -> Discovery -> Pairing (PIN) -> Remote
- Cast, Devices, and Settings screens (Remote Layout, Remote Behavior,
  Diagnostics)
- Secure credential storage abstraction (Keychain/Keystore via
  `flutter_secure_storage`), not yet used by a real provider
- Structured logging convention (`AppLogger`, `[TV][...]` tags)
- Unit + widget tests, GitHub Actions CI

## Planned platforms (not yet implemented)

Android TV / Google TV, Google Cast, Samsung (Tizen), LG webOS, Roku,
Fire TV, DLNA/UPnP - research for each is in
[`docs/research/`](docs/research). See the roadmap for sequencing.

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

## Commands

```bash
flutter pub get                          # install dependencies
dart format .                            # format
dart format --set-exit-if-changed .      # format check (CI)
flutter analyze                          # static analysis
flutter test                             # unit + widget tests
flutter build apk --debug                # Android debug build (requires Android SDK)
```

## Testing

`flutter test` covers: `TvCapabilities` equality/copyWith, the provider
registry, `FakeTvProvider`'s full discover -> pair -> command lifecycle
(including unsupported-command and wrong-PIN failure paths), the
in-memory credential store, the settings controller, and a widget test
proving the Remote screen renders different controls for different
`TvCapabilities`.

## For AI agents / future contributors

Read [`AGENTS.md`](AGENTS.md) first.
