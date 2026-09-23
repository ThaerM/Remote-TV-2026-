# Research: Android TV / Google TV

**Status: implemented in `lib/tv/providers/android_tv/` (Phase 1). Not yet
validated against a physical device** - see
`docs/testing/android-tv-real-device.md` before trusting this against
real hardware.

## Protocol status

**UNOFFICIAL.** Google does not publish this protocol or an SDK for
third-party remote-control apps; there is no Terms of Service covering
this use the way Roku documents its ECP for third parties. The protocol
is what Google's own "Android TV Remote Control" app and the Android TV
system's built-in remote-pairing flow use, observed and maintained by an
active open-source community. Confidence in the protocol *shape* is
high (see Sourcing below); confidence in long-term stability is
necessarily lower than an officially documented API, since Google could
change it without notice.

## Sourcing (exact provenance)

The Dart protobuf bindings in `lib/tv/providers/android_tv/protocol/generated/`
were generated with `protoc` from the `FileDescriptorProto` embedded in
the **`androidtvremote2`** Python package
(PyPI: `androidtvremote2`, source: `github.com/tronikos/androidtvremote2`,
Apache-2.0), which is the library behind Home Assistant's official
`androidtv_remote` integration - a widely-deployed, actively maintained
implementation. The pairing handshake and remote-session logic in
`pairing_handshake.dart` / `remote_session.dart` reproduce that package's
`pairing.py` / `remote.py` state machines message-for-message. See
`lib/tv/providers/android_tv/protocol/generated/NOTICE.md` for the
license/attribution details.

## Discovery

mDNS/Bonjour service type `_androidtvremote2._tcp.local.`, port 6467
(pairing) and 6466 (remote control, after pairing).

**Implemented**: `AndroidTvDiscovery` (`discovery/android_tv_discovery.dart`)
is an interface with two backends, chosen by `AndroidTvProvider`:

- **Android (and other non-iOS)**: `MdnsAndroidTvDiscovery`, raw mDNS via
  `package:multicast_dns` 0.3.3+1 (PTR -> SRV -> A).
- **iOS**: `NativeBonjourAndroidTvDiscovery`, a MethodChannel to
  `ios/Runner/AndroidTvBonjourDiscovery.swift` (`NWBrowser` browse +
  `NetService` resolve). On a real iPhone, `MDnsClient.start()` failed in
  `RawDatagramSocket.joinMulticast` with a bare `OSError` (not a
  `SocketException`), which escaped `discover()` and was silently turned
  into "no TVs" by `TvProviderRegistry.discoverAll`. Beyond that bug, iOS
  only allows raw multicast sockets (UDP 5353) for apps holding Apple's
  managed `com.apple.developer.networking.multicast` entitlement (see
  Apple TN3179, "Understanding local network privacy"); the system
  Bonjour APIs need only `NSLocalNetworkUsageDescription` +
  `NSBonjourServices` (`_androidtvremote2._tcp`), both in `Info.plist`.
  So the entitlement is deliberately **not** requested.

Both de-duplicate by the stable advertised hostname (not the DHCP IP),
are bounded by one scan timeout, never throw, release their sockets/
browser, and always log `started` ... `completed count=N`, with a
`resolve_failed stage=... reason=...` line for every failure
(`socket_bind_failed`, `permission_denied_or_restricted`,
`bonjour_service_missing`, `scan_timeout`, `ptr_empty`, `srv_failed`,
`ip_failed`, `start_failed`).

**Needs physical-TV validation**: whether real Android TV/Google TV
devices reliably advertise this service on typical home routers (some
routers block or rate-limit multicast).

## Pairing

Two-phase TLS handshake, both using self-signed certificates with no
certificate authority - trust is established by both sides hashing their
public keys together with a 6-hex-digit code the TV displays, not by
certificate chain validation. See `docs/architecture/security.md` for
why `onBadCertificate` accepting the peer is correct here, not a
shortcut.

**Pairing phase** (port 6467, `polo.proto` / `OuterMessage`):

```
client -> pairing_request           {client_name, service_name: "atvremote"}
server -> pairing_request_ack
client -> options                   {preferred_role: INPUT, encoding: HEX/6}
server -> options
client -> configuration             {client_role: INPUT, encoding: HEX/6}
server -> configuration_ack         <- TV now displays the code
[user reads the code, enters it]
client -> secret                    {secret: sha256(...)}
server -> secret_ack                <- paired
```

Secret computation (verified self-consistent in
`test/tv/providers/android_tv/android_tv_identity_test.dart` by
brute-forcing a code that actually validates, not just asserted):

```
SHA256(
  hex(client_modulus) + hex(client_exponent, min 2 bytes) +
  hex(server_modulus) + hex(server_exponent, min 2 bytes) +
  hex(pairing_code[2:])
)[0] == pairing_code[0:2] as a byte
```

**Implemented**: `PairingHandshake` (state machine, tested against a fake
transport), `AndroidTvIdentity` (RSA-2048 self-signed cert/key generation
via `package:basic_utils`, tested), `AndroidTvPairingSecret` (the hash
above, tested).

**Needs physical-TV validation**: the actual pairing UX on a real TV
(prompt wording, whether the code is always exactly 6 hex digits on
every OS version, timing).

## Remote-control protocol

TLS on port 6466, reusing the paired certificate (no re-pairing needed on
reconnect). `remotemessage.proto` / `RemoteMessage`, framed with a varint
length prefix (implemented in `transport/android_tv_message_transport.dart`,
unit-tested independent of the TLS layer).

Connection handshake:

```
server -> remote_configure   {code1: <feature bitmask>, device_info}
client -> remote_configure   {code1: <our supported subset>, our device_info}
server -> remote_set_active
client -> remote_set_active
server -> remote_start       {started: true}   <- ready to accept commands
```

The TV pings roughly every 5s; `RemoteSession` answers `remote_ping_request`
with `remote_ping_response` and additionally self-disconnects after 16s of
total silence (matching the reference client) rather than waiting to be
dropped.

**Implemented**: `RemoteSession` (tested against a fake transport for
configure/ping/key-inject/volume-update).

**Needs physical-TV validation**: real-world negotiated feature bitmask
per device/OS version (which features a given TV actually reports).

## Remote commands

D-pad, Home, Back, Menu, Guide, Info, TV-input, volume up/down/mute,
channel up/down, digits 0-9, and the standard media transport keys map
directly onto `RemoteKeyCode` - see
`lib/tv/providers/android_tv/protocol/command_mapper.dart`. **No color
keys and no "previous channel" key exist in this protocol** (that's a
cable-box/Samsung concept) - `AndroidTvCommandMapper.unsupportedByProtocol`
makes this explicit so the UI never offers a button that would silently
no-op.

## Keyboard

Supported via `remote_ime_batch_edit`, a distinct message type from key
events - implemented in `RemoteSession.sendText`.

## Voice

**Not implemented, by design.** The reference protocol does support a
voice session (`remote_voice_begin`/`remote_voice_payload`/`remote_voice_end`,
triggered by sending `KEYCODE_SEARCH`), but it requires streaming raw PCM
audio chunks from the phone's microphone to the TV - meaningfully more
work and more sensitive (live audio capture) than this phase's scope.
`TvCapabilities.voice` stays `false` for `AndroidTvProvider` until a
dedicated phase implements it deliberately, with its own privacy review.

## App launching

The protocol launches apps via `remote_app_link_launch_request` with an
Android **app-link URI** (e.g. `https://www.netflix.com/`), not a package
name - this is an Android intent deep-link, resolved by whichever app
registered a matching intent filter, not a general "launch any installed
app by ID" API. `AndroidTvAppLinks` in `command_mapper.dart` holds a
small, deliberately conservative set of verified app links (Netflix,
YouTube) rather than guessing URIs for apps we haven't confirmed.

## Power / wake

Power is a key event (`KEYCODE_POWER`) reported through the negotiated
feature bitmask (`Feature.POWER`), only offered when the TV reports
support. **Wake-on-LAN is not implemented** - `TvCapabilities.wakeOnLan`
is `false` for this provider; real support would need the TV's MAC
address (not returned by this protocol) and the user's TV to have WoL
enabled, which is inconsistent across OEMs.

## Fire TV note

Fire TV (Amazon's AOSP fork) does **not** run Google's Android TV Remote
service - `AndroidTvProvider` will not discover or connect to Fire TV
devices. Fire TV needs its own research track (Phase 9).

## Reconnect behavior

`AndroidTvProvider` reconnects with exponential backoff (1s, 2s, 4s, 8s,
16s, capped at 30s) when the remote-control connection drops
unexpectedly (network blip, TV standby, app backgrounded past the idle
watchdog), and stops attempting once the user explicitly disconnects or
forgets the device. See `docs/architecture/provider-system.md`.

## Tested vs. untested assumptions summary

| Area | Status |
|---|---|
| Discovery (mDNS on Android, native Bonjour on iOS) | Implemented and unit-tested (fake querier / mocked channel); iOS native bridge not yet run on a device |
| Certificate generation, PEM round-trip | Implemented and unit-tested |
| Pairing secret hash algorithm | Implemented and unit-tested (self-consistent) |
| Pairing handshake message sequence | Implemented and unit-tested (fake transport) |
| Remote-session handshake, ping, key inject | Implemented and unit-tested (fake transport) |
| TLS trust model (self-signed, no CA) | Implemented per reference client's approach, not device-tested |
| Real pairing UX on-device | **Needs physical-TV validation** |
| Real per-device capability accuracy | **Needs physical-TV validation** |
| Reconnect timing under real network conditions | **Needs physical-TV validation** |
| Cross-manufacturer/OS-version compatibility | **Needs physical-TV validation** |
| Voice, general app install/launch, screen mirroring | **Future work**, explicitly out of scope |

## Recommended Phase 2

Google Cast (separate protocol, separate provider - see
`docs/research/google-cast.md`). Do not start until this phase passes
the manual real-device test sequence in
`docs/testing/android-tv-real-device.md`.
