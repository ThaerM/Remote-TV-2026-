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

Because the registry is keyed by `TvPlatform`, there is no ambiguity
between providers: `FakeTvProvider` owns `TvPlatform.fake` and
`AndroidTvProvider` owns `TvPlatform.androidTv` - two distinct keys, so
`forPlatform()` can never resolve a real device to the fake provider or
vice versa. A `TvDevice`'s `isDevelopmentFake` flag is a UI-facing label
on top of that, not the mechanism that keeps them apart.

**Demo devices are opt-in, not always-on.** `tv_provider_registry_provider.dart`
only registers `FakeTvProvider` into the registry when
`kEnableDemoTvDevices` (`lib/core/config/app_config.dart`,
`--dart-define=ENABLE_DEMO_TV_DEVICES=true`) is set - a normal `flutter
run` against a real TV must never show demo devices mixed into real
discovery results. This is deliberately not gated on `kDebugMode`: debug
builds are also used for real-device testing (e.g. on a physical phone
against a real TV), so debug-vs-release must not be conflated with
real-vs-demo. The actual on/off decision lives in the plain function
`selectRegisteredProviders`, kept separate from the `Provider` wiring
specifically so it's unit-testable without a `--dart-define` recompile -
see `test/tv/providers/tv_provider_registry_provider_test.dart`.

## Worked example: `AndroidTvProvider`

`lib/tv/providers/android_tv/` is the first real (non-fake) provider and
a template for the structure a new one should follow:

```
android_tv/
  android_tv_provider.dart        TvProvider implementation, orchestrates
                                  the pieces below; owns the connection
                                  state machine and reconnect policy
  android_tv_constants.dart        Ports, timeouts, mDNS service type
  discovery/                       mDNS discovery -> TvDevice
  security/                        Self-signed cert/key identity +
                                   pairing-secret hash computation
  transport/                       AndroidTvMessageTransport interface
                                   (varint framing) + the real TLS socket
                                   implementation
  protocol/
    generated/                     Vendored protobuf bindings (see its
                                   NOTICE.md for provenance/licensing)
    pairing_handshake.dart         State machine for the pairing protocol
    remote_session.dart            State machine for the remote-control
                                   protocol
    command_mapper.dart            TvCommandKey -> protocol-specific enum
  storage/                         Non-sensitive metadata (shared_preferences)
                                   + pairing identity (SecureCredentialStore)
```

The key pattern worth copying: `AndroidTvMessageTransport` is an
interface, not a concrete socket type, specifically so
`PairingHandshake` and `RemoteSession` can be unit-tested against a fake
transport instead of a real network connection - see
`test/tv/providers/android_tv/`. A provider whose protocol logic can't be
exercised without a real device is much harder to keep correct; design
for the fake-transport seam from the start.
