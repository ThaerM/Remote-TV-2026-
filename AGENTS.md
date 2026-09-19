# AGENTS.md

Read this before touching the codebase. It should let you understand the
project without scanning every file.

## Product goal

A universal, capability-aware smart TV remote and companion app. See
`docs/product/vision.md`. Critically: "universal" means one consistent
app experience across TV brands, achieved by isolating every vendor's
protocol inside its own provider - **not** one shared network protocol.

## Current phase

**Phase 1: Android TV / Google TV.** `AndroidTvProvider`
(`lib/tv/providers/android_tv/`) implements real mDNS discovery, real
TLS certificate pairing, and the real Android TV Remote v2 protocol,
registered alongside (not replacing) `FakeTvProvider`. Its protocol
logic is unit-tested against fake transports, but **it has not been
validated against a physical TV yet** - see
`docs/testing/android-tv-real-device.md` for the manual pass that must
happen before claiming it works, and
`docs/research/android-google-tv.md`'s "Tested vs. untested assumptions"
table for exactly what's proven versus what isn't. Do not claim
real-device-verified support in code comments, UI copy, or docs until
that manual pass has actually been run. Per the current task's stop
condition, no other real provider (Cast, Samsung, LG, Roku, Fire TV) has
been started - see `docs/product/feature-roadmap.md`.

## Architecture (read `docs/architecture/overview.md` for full detail)

```
lib/
  app/        Entry point, go_router routing, bottom-tab shell, theme
  core/       Design tokens, logging, storage abstractions (no TV/feature knowledge)
  features/   One directory per screen area (presentation/, application/ if stateful)
  tv/
    domain/       TvDevice, TvCapabilities, TvCommand, TvConnectionState,
                  TvPairingRequest, TvException hierarchy, TvProvider interface
    providers/    fake/ today; one directory per platform as phases land
    application/   TvSessionController (the only thing features talk to)
```

**Hard rule**: `features/*` never imports a concrete provider
(`tv/providers/<platform>/...`) directly. Only
`tv/providers/tv_provider_registry_provider.dart` does that wiring.

## Capability-driven design (the most important rule in this codebase)

The Remote UI renders from `TvCapabilities` (a connected device's actual
supported features), never from `TvPlatform`. Never write
`if (platform == TvPlatform.samsung) ...` anywhere outside a provider
implementation. If you need the UI to behave differently, add or check a
`TvCapabilities` flag - see `docs/architecture/provider-system.md`.

## State management

Riverpod (`flutter_riverpod`), `StateNotifier` for controllers. See
`docs/decisions/ADR-002-state-management.md` for why, over Bloc. Don't
introduce a second state-management pattern.

## Security requirements

- Pairing secrets (tokens, keys, certs) go through
  `SecureCredentialStore` (`lib/core/storage/`) - Keychain/Keystore-backed
  in release builds, in-memory only in tests. Never plain storage.
- Never log secrets. Use `AppLogger` with `[TV][CONCERN][Vendor]`-style
  tags. See `docs/architecture/security.md` and
  `docs/architecture/diagnostics.md`.
- Any future ADB/APK sideloading feature must stay off by default,
  behind Settings > Advanced > Developer Mode, with explicit per-action
  confirmation. See `docs/research/android-tv-apk-installation.md`.

## Coding conventions

- No comments explaining *what* code does; only *why*, when non-obvious
  (a protocol quirk, a deliberate scope limitation).
- Immutable state classes with `copyWith`, matching
  `TvSessionState`/`SettingsState`.
- Design tokens (`lib/core/design/`) instead of literal colors/spacing/
  radii in widget code.
- `dart format` + `flutter_lints` (`analysis_options.yaml`) - keep
  `flutter analyze` at zero issues.

## Testing expectations

Every new `TvProvider` needs unit tests exercising its full lifecycle
directly (not just through the UI) - see `test/tv/fake_tv_provider_test.dart`
as the pattern to follow (discover, connect/pairing success and failure,
capability-gated command rejection, disconnect). New capability-gated UI
needs a widget test proving it hides/shows correctly, following
`test/features/remote_screen_capability_test.dart`.

## Commands

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

All four run in CI (`.github/workflows/flutter-ci.yml`) on every PR to
`main`.

## What NOT to do

- Don't add manufacturer branching (`if (platform == ...)`) outside a
  provider implementation.
- Don't claim a real TV platform works before its provider is
  implemented and tested - update `docs/research/*` and the roadmap
  honestly instead.
- Don't add a second state-management library.
- Don't persist secrets outside `SecureCredentialStore`.
- Don't build ADB/sideloading, CarPlay, or general screen-mirroring
  features without re-reading the corresponding `docs/research/*.md` -
  each has explicit constraints (off-by-default, no CarPlay category
  exists, iOS mirroring is largely out of third-party reach).
- Don't implement multiple real vendor providers in one pass - one
  platform at a time, per the roadmap, with tests.

## Recommended next task

Run the manual real-device pass in
`docs/testing/android-tv-real-device.md` against an actual Android TV /
Google TV device and fix whatever it finds - this is the gating step
before Phase 1 can be considered done. Do not start Phase 2 (Google
Cast) or any other real provider before that validation happens and any
resulting bugs are fixed, per the current task's explicit stop
condition.
