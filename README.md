# Remote TV 2026

A universal, capability-aware smart TV remote and companion app built
with Flutter.

## Project status: Phase 1 (Android TV / Google TV)

The Foundation phase shipped a fake-device-only remote experience.
**Phase 1 adds a real provider: `AndroidTvProvider`**, implementing real
mDNS discovery, real TLS certificate pairing, and the real Android TV
Remote v2 protocol - see
[`docs/research/android-google-tv.md`](docs/research/android-google-tv.md).
**This has not yet been validated against a physical TV** - its protocol
logic is unit-tested in isolation (including a self-consistency check of
the pairing-secret cryptography), but the real-device pass in
[`docs/testing/android-tv-real-device.md`](docs/testing/android-tv-real-device.md)
still needs to happen before it should be trusted or advertised as
working. `FakeTvProvider` remains available alongside it for UI
development, tests, and demos.

## What's implemented

- Flutter app (Android + iOS) with a dark-first Material 3 theme
  (dark / light / system)
- TV domain model + `TvProvider` interface + provider registry
  (`lib/tv/`) - see
  [`docs/architecture/provider-system.md`](docs/architecture/provider-system.md)
- `FakeTvProvider`: three demo devices with different capability sets, so
  the remote UI can be proven to adapt per device without real hardware
- `AndroidTvProvider`: real mDNS discovery, real TLS pairing handshake,
  real authenticated remote-control protocol, capability-gated commands,
  reconnect with backoff, secure pairing-identity persistence - **pending
  physical-device validation**, see
  [`docs/research/android-google-tv.md`](docs/research/android-google-tv.md)
- Capability-driven Remote screen: every control group (D-pad, volume,
  channel, keyboard, voice, media transport, numeric keypad, color keys,
  quick app shortcuts) renders only when the connected device reports
  support for it
- Full first-run flow: Welcome -> Discovery -> Pairing (PIN) -> Remote
- Cast, Devices (including paired Android TVs, with Forget), and Settings
  screens (Remote Layout, Remote Behavior, Diagnostics)
- Secure credential storage (Keychain/Keystore via
  `flutter_secure_storage`), used by `AndroidTvProvider` to persist its
  pairing identity
- Structured logging convention (`AppLogger`, `[TV][...]` tags)
- Unit + widget tests, GitHub Actions CI

## Planned platforms

Android TV / Google TV is implemented (Phase 1, pending device
validation - see above). Google Cast, Samsung (Tizen), LG webOS, Roku,
Fire TV, and DLNA/UPnP are not yet implemented - research for each is in
[`docs/research/`](docs/research). See the roadmap for sequencing. **Do
not treat "implemented" as "verified working on every device"** - see
each provider's own research doc for what's been validated versus what
still needs real-device testing.

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
in-memory credential store, the settings controller, a widget test
proving the Remote screen renders different controls for different
`TvCapabilities`, and `AndroidTvProvider`'s protocol layer (certificate
generation, the pairing-secret hash, message framing, the pairing and
remote-session state machines, command mapping, paired-device
persistence, and a full discover-pair-connect-forget integration test)
against fake transports - no physical TV required. See
[`docs/testing/android-tv-real-device.md`](docs/testing/android-tv-real-device.md)
for the manual pass that still needs a real device.

## For AI agents / future contributors

Read [`AGENTS.md`](AGENTS.md) first.
