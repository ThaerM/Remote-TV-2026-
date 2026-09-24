# AGENTS.md

Read this before touching the codebase. It should let you understand the
project without scanning every file.

## Product goal

A universal, capability-aware smart TV remote and companion app. See
`docs/product/vision.md`. Critically: "universal" means one consistent
app experience across TV brands, achieved by isolating every vendor's
protocol inside its own provider - **not** one shared network protocol.

## Current phase

Six real providers exist - Android TV/Google TV, Google Cast (Dart CASTV2,
see ADR-004), Roku (ECP), LG webOS (SSAP), Samsung Tizen, DLNA - plus
`FakeTvProvider`. **None has passed its real-device pass yet**
(`docs/testing/real-device-test-plan.md`); Android TV's Gates A-D are the
blocking ones. `docs/product/feature-matrix.md` is the source of truth for
what's implemented vs verified. Do not claim real-device-verified support
in code comments, UI copy, or docs until that pass has actually been run.
Not implemented (don't claim): Fire TV, screen mirroring, APK install,
voice, power-on, casting phone-stored files, CarPlay.

Shared pieces providers build on: `lib/tv/providers/shared/service_discovery/`
(DNS-SD: native Bonjour on iOS, raw mDNS on Android), `lib/core/network/`
(SSDP, UPnP descriptions, text WebSocket, multicast lock). iOS raw
multicast (SSDP) needs Apple's multicast entitlement, which the app does
not have - SSDP providers fall back to **Add TV by IP address** there.

## Architecture (read `docs/architecture/overview.md` for full detail)

```
lib/
  app/        Entry point, go_router routing, bottom-tab shell, theme
  core/       Design tokens, logging, storage abstractions (no TV/feature knowledge)
  features/   One directory per screen area (presentation/, application/ if stateful)
  tv/
    domain/       TvDevice, TvCapabilities, TvCommand, TvConnectionState,
                  TvPairingRequest, TvException hierarchy, TvProvider interface
    providers/    one directory per platform (android_tv, google_cast, roku,
                  lg_webos, samsung, dlna, fake) + shared/
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
  radii in widget code. All motion durations/curves come from
  `AppMotion` - no widget hardcodes its own timing. See
  `docs/design/design-system.md`.
- Press feedback goes through `PressableScale`; haptics are always
  caller-controlled via `SettingsState.hapticFeedbackEnabled`, never
  fired unconditionally by a component.
- Looping/ambient animations (radar, connection rings, glows) must check
  `MediaQuery.disableAnimations` and render a static equivalent - and
  must never be the thing a widget test calls `pumpAndSettle()` against
  (it hangs on a deliberately-repeating animation); pump a fixed
  duration instead.
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

All four run in CI (`.github/workflows/flutter-ci.yml`) on every PR, which
then also runs `flutter build apk --debug` (Ubuntu) and
`flutter build ios --debug --no-codesign` (macOS). Those two jobs are the
only thing that compiles the native Kotlin/Swift platform channels
(`ios/Runner/*.swift`, `android/app/src/main/kotlin/...`) - a change to
native code isn't verified until they're green.

`flutter run` alone registers real providers only (no demo devices).
For UI development/demos, use
`flutter run --dart-define=ENABLE_DEMO_TV_DEVICES=true` - see
`lib/core/config/app_config.dart` and "Registry" in
`docs/architecture/provider-system.md`.

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

Run `docs/testing/real-device-test-plan.md` on real hardware, starting
with Android TV Gates A-D, and fix whatever it finds. Then the blocking
owner items in `docs/release/release-checklist.md` (release signing, the
multicast-entitlement decision, final icons).
