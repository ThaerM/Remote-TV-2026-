# Architecture Overview

Remote TV 2026 uses a feature-first structure with a separate `tv/` layer
for the TV domain and provider system, since that layer is shared by
almost every feature.

```
lib/
  app/            Entry point, routing (go_router), shell, theme
  core/            Design tokens, logging, storage abstractions
  features/        One directory per user-facing feature (presentation +
                   application/state where a feature needs its own)
  tv/
    domain/        Platform-agnostic models: TvDevice, TvCapabilities,
                   TvCommand, TvConnectionState, TvPairingRequest,
                   TvException hierarchy, the TvProvider interface
    providers/     One implementation per TvPlatform (fake/ today;
                   android_tv/, google_cast/, samsung/, lg_webos/, roku/,
                   dlna/ as later phases add them) plus the registry
    application/    TvSessionController: orchestrates discover -> connect
                   -> pair -> command against the registry
```

## Layering rule

`features/*` depends on `tv/domain` and `tv/application`, never directly
on a concrete provider (`tv/providers/fake/FakeTvProvider`, a future
`tv/providers/android_tv/...`, etc). The only place that imports a
concrete provider is the DI wiring in
`tv/providers/tv_provider_registry_provider.dart`. This is what makes
"add a new TV platform" a one-directory change instead of a UI change.

## State management

Riverpod (`flutter_riverpod` + `StateNotifier`). See
`docs/decisions/ADR-002-state-management.md` for why, over Bloc.

## Data flow for a remote button press

```
RemoteScreen (UI)
  -> ref.read(tvSessionControllerProvider.notifier).sendCommand(cmd)
    -> TvSessionController holds the active TvProvider
      -> provider.sendCommand(cmd)
        -> throws UnsupportedTvCommandException if the connected
           device's TvCapabilities don't support it
        -> otherwise talks to the vendor transport (network socket,
           SDK call, HTTP request - provider-specific)
    -> on TvException, state.lastError is set and the UI shows it
```

UI code never catches vendor-specific exceptions; every provider maps its
own failures onto the `TvException` hierarchy in `tv/domain/tv_errors.dart`.

## Routing

`go_router` with a `ShellRoute` for the four bottom-tab destinations
(Remote, Cast, Devices, Settings) and top-level routes for the onboarding
flow and settings sub-screens that shouldn't show the tab bar.

## Related documents

- `docs/architecture/provider-system.md` - the `TvProvider` contract in
  detail and how to add a new platform
- `docs/architecture/security.md` - credential handling
- `docs/architecture/diagnostics.md` - logging conventions
- `docs/decisions/` - ADRs for the choices above
