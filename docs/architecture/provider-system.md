# TV Provider System

## The contract

Every TV ecosystem implements `TvProvider` (`lib/tv/domain/tv_provider.dart`):

```dart
abstract interface class TvProvider {
  TvPlatform get platform;
  Future<List<TvDevice>> discover();
  Future<TvPairingRequest> connect(TvDevice device);
  Future<void> submitPairingCode(String code);
  Future<void> disconnect();
  Stream<TvConnectionState> get connectionState;
  Future<TvCapabilities> getCapabilities();
  Future<void> sendCommand(TvCommand command);
  Future<List<TvApplication>> getApplications();
}
```

A provider is a private implementation detail: it owns whatever transport
it needs (mDNS client, websocket, vendor SDK bridge, HTTP client) and
translates that transport's errors into the `TvException` hierarchy.

## Capability-driven design

`TvCapabilities` is a flat set of booleans (`power`, `volume`, `dpad`,
`voice`, `launchApps`, `casting`, ...). The Remote screen builds its
layout entirely from this object:

```
Samsung TV -> Samsung Provider -> TvCapabilities -> Remote UI
LG TV      -> LG Provider      -> TvCapabilities -> Remote UI   (same code)
Android TV -> Android Provider -> TvCapabilities -> Remote UI   (same code)
```

**Never** write `if (platform == TvPlatform.samsung) ...` in UI or shared
domain code. If a distinction matters to the UI, it belongs in
`TvCapabilities`, even if today only one provider sets that flag.

`FakeTvProvider`'s three demo profiles (Google TV, Samsung, LG) exist
specifically to prove this: they report different capability sets so the
Remote screen visibly renders differently for each, without any
platform-specific UI code - see `test/features/remote_screen_capability_test.dart`.

## Adding a new provider

1. Create `lib/tv/providers/<platform>/`.
2. Implement `TvProvider`, mapping the platform's real behavior onto
   `TvCapabilities` as accurately as research supports (never overclaim).
3. Register it in `tv_provider_registry_provider.dart`.
4. Persist any pairing secret through `SecureCredentialStore` - never in
   plain storage or logs.
5. Add unit tests against the provider directly (not just through the UI).

## Pairing

`TvPairingRequest` is a sealed type: `none`, `TvPinPairingRequest` (user
types a code shown on the TV), `TvConfirmOnDevicePairingRequest` (user
confirms on the TV, app just watches `connectionState`). `PairingScreen`
switches on this type once, generically - a new provider that reuses PIN
pairing needs zero UI changes.

## Registry

`TvProviderRegistry` (`lib/tv/providers/registry/`) holds every
registered provider keyed by `TvPlatform` and can `discoverAll()` across
all of them in parallel, tolerating individual provider failures.
`TvSessionController` is the only consumer that should read from it.
