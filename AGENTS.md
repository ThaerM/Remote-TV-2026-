# AGENTS.md

Read this before touching the codebase. It should let you understand the
project without scanning every file.

## Product goal

A universal, capability-aware smart TV remote and companion app. See
`docs/product/vision.md`. Critically: "universal" means one consistent
app experience across TV brands, achieved by isolating every vendor's
protocol inside its own provider - **not** one shared network protocol.

## Current phase

**Foundation.** Only `FakeTvProvider` (three simulated demo devices)
exists. No real TV integration. Do not claim real-device support in code
comments, UI copy, or docs. See `docs/product/feature-roadmap.md` for
what's next and why Android TV/Google TV is the recommended Phase 1.

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

Phase 1: real Android TV / Google TV support. Start from
`docs/research/android-google-tv.md` (mDNS discovery, TLS cert-pairing
handshake, protobuf remote protocol) and
`docs/architecture/provider-system.md` ("Adding a new provider"). Create
`lib/tv/providers/android_tv/`, implement `TvProvider` against the real
protocol, persist the pairing certificate via `SecureCredentialStore`,
register it in `tv_provider_registry_provider.dart` alongside (not
replacing) `FakeTvProvider`, and add provider-level tests.
