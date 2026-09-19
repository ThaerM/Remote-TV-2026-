# ADR-003: The TvProvider Abstraction and Capability-Driven UI

## Status

Accepted (Foundation phase)

## Context

The product brief is explicit that "universal TV remote" must not become
one universal protocol, and that the UI must never branch on manufacturer.
We needed an interface abstract enough to represent Android TV's
protobuf/TLS handshake, Roku's unauthenticated HTTP, Samsung/LG's
WebSocket + token pairing, and Google Cast's session model, without
leaking any of those differences into shared code - while still letting
the UI render meaningfully different remotes for devices with different
real-world capabilities.

## Decision

1. Define `TvProvider` as a small interface: `discover`, `connect`,
   `submitPairingCode`, `disconnect`, `connectionState` (stream),
   `getCapabilities`, `sendCommand`, `getApplications`. Every vendor
   integration implements this and nothing else is exposed to shared code.
2. Define `TvCapabilities` as a flat set of booleans describing what the
   *currently connected device* supports, queried after connection - not
   assumed from `TvPlatform`.
3. The Remote UI (and Cast screen, and any future screen) reads
   `TvCapabilities`, never `TvPlatform`, to decide what to render.
4. Pairing is modeled as a sealed `TvPairingRequest` (`none`,
   `TvPinPairingRequest`, `TvConfirmOnDevicePairingRequest`) so the
   Pairing screen handles every provider's pairing UX with one switch,
   not one branch per vendor.
5. Provider-specific failures are translated to a shared `TvException`
   hierarchy (`UnsupportedTvCommandException`, `TvNotConnectedException`,
   `TvConnectionException`) so UI error handling is uniform.

## Rationale

Capability flags let two devices on the *same* platform (e.g. an older
vs. newer Samsung model) render different remotes correctly, which a
platform-keyed `switch` never could. `FakeTvProvider`'s three demo
profiles exist specifically to force this: Living Room Google TV
(voice + keyboard + casting), Bedroom Samsung TV (numeric keypad + color
keys, no voice/keyboard/casting), Office LG TV (keyboard, no voice/
casting) - verified by
`test/features/remote_screen_capability_test.dart`.

## Consequences

- A new provider is an additive change (new directory + registry line),
  never a UI change - see `docs/architecture/provider-system.md`.
- `TvCapabilities` will grow over time as new command types are added
  (e.g. `screenMirroring`, `appInstall` are already present but unused by
  any real provider yet) - each new capability flag needs to be
  considered for every existing provider's accuracy, not just the one
  that motivated adding it.
- The interface deliberately does not expose provider-specific
  configuration or extra methods; a provider needing something the
  interface doesn't support should either propose extending
  `TvCommand`/`TvCapabilities` (if broadly applicable) or handle it as an
  internal implementation detail invisible to the UI (if truly
  vendor-specific, e.g. a SmartThings OAuth flow for Samsung).
