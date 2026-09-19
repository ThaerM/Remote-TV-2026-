# ADR-002: State Management - Riverpod over Bloc

## Status

Accepted (Foundation phase)

## Context

The app needs to manage: async TV connection lifecycle (discovering ->
connecting -> pairing -> connected -> error, with a live stream from
whichever provider is active), provider selection/swapping for tests,
device-session state shared across four+ screens (Remote, Cast, Devices,
Diagnostics), and simpler local UI state (settings toggles). The two
realistic candidates evaluated were Riverpod (`flutter_riverpod`) and
Bloc (`flutter_bloc`).

## Decision

Riverpod, using `StateNotifierProvider` for controllers
(`TvSessionController`, `SettingsController`) and `Provider` for DI
(`TvProviderRegistry`, `FakeTvProvider`).

## Rationale

- **Testability**: Riverpod's `ProviderScope(overrides: [...])` makes it
  straightforward to substitute a fake controller or provider in widget
  tests without a DI framework or service locator - used directly in
  `test/features/remote_screen_capability_test.dart` to drive the Remote
  screen through different `TvCapabilities` without touching
  `FakeTvProvider`'s timing.
- **Async connection state**: `StateNotifier` + exposing a provider's
  `Stream<TvConnectionState>` fits the discover/connect/pair/connected
  lifecycle more directly than Bloc's event-to-state mapping would for
  what is fundamentally "reduce this stream into state," not a rich
  event taxonomy.
- **Provider switching**: `TvProviderRegistry` itself is just a
  Riverpod-managed object; swapping which `TvProvider` backs the active
  session at runtime (as new platforms are added) doesn't need a second
  state-management concept layered on top.
- **Less ceremony for the amount of state involved**: Bloc's explicit
  event classes are valuable for large, event-sourced-style domains;
  this app's state changes (discover, connect, submit pairing code, send
  command, disconnect) are naturally expressed as async methods on a
  controller, which is exactly Riverpod's `StateNotifier` model.
- **Maintainability for a project expected to grow one provider at a
  time**: fewer boilerplate classes per feature keeps the "add a
  provider, add its screen state" loop fast without sacrificing
  testability.

## Consequences

- Single state-management library across the app - no Bloc dependency,
  no mixed patterns.
- Every controller pattern in the codebase should follow the
  `TvSessionController`/`SettingsController` shape: a `StateNotifier`
  exposing an immutable state class with `copyWith`, backed by a
  top-level `StateNotifierProvider`.
