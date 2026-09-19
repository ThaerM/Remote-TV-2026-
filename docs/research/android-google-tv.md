# Research: Android TV / Google TV

## Discovery

Android TV Remote-capable devices advertise mDNS/Bonjour service type
`_androidtvremote2._tcp.local.` on port 6467 (pairing) and 6466 (remote
control after pairing). This is the same mechanism Google's own official
"Android TV Remote Control" app and Home Assistant's `androidtv` /
`androidtvremote2` integration use.

## Pairing

Two-phase TLS handshake:

1. **Pairing phase** (port 6467): client and TV exchange self-signed TLS
   certificates, TV displays a 6-digit code, client sends it back over
   the encrypted channel to prove it saw the code (protects against a
   different device on the network claiming to be the pairing client).
2. **Remote phase** (port 6466): subsequent connections reuse the
   certificate pair established during pairing - no code re-entry needed
   on reconnect, as long as the client persists its cert/key.

This maps directly onto `TvPinPairingRequest` in our domain model,
and the certificate becomes the "pairing secret" that must go through
`SecureCredentialStore` rather than plain storage.

## Protocol

Protobuf messages over the TLS socket (`RemoteMessage` proto, tagged with
a 2-byte length prefix). Google does not publish this proto publicly, but
it has been reverse-engineered and is stable across Android TV/Google TV
OS versions - see the `androidtvremote2` Python package and the
`androidtv` Home Assistant integration as reference implementations.

## Remote commands

Full key-event set (equivalent to a physical remote): D-pad, Home, Back,
volume up/down/mute, media play/pause, power. No manufacturer-specific
color keys (that's a cable-box/Samsung concept, not Android TV's).

## Keyboard

Supported - the protocol has a text-input message distinct from
individual key events, matching our `TvCommand.text(...)`.

## Voice

Not exposed through this protocol. Assistant voice input on Android TV
goes through Google Assistant's own (not publicly documented for
third-party apps) channel. Treat `TvCapabilities.voice = false` for this
provider until proven otherwise.

## App launching

The protocol does not expose a general "launch any installed app" API.
Deep-linking via Android intents (`android-app://` URIs) works for apps
that register the right intent filters, which is how Google's own remote
app implements "recently used apps." Full launcher control (arbitrary
app by package name, guaranteed) is not available without ADB.

## Power / wake

Power-toggle is a key event within the protocol (works while the TV is
awake or in a low-power state that still has network + mDNS up).
True "wake from fully off" needs Wake-on-LAN, which requires
Android TV's WoL setting enabled by the user and is inconsistent across
OEMs (varies by chipset/firmware, not purely Google's software stack).

## Official vs. reverse-engineered

Not an official third-party API. Google does not publish an SDK or
Terms of Service for third-party remote-control apps using this
protocol; the protocol is what Google's own Android TV Remote Control
app uses, observed and documented by the community. This is a
meaningfully different risk profile than Roku's ECP (which Roku
explicitly documents for third parties) - flag this to the user before
Phase 1 implementation begins.

## Fire TV note

Fire TV (Amazon's AOSP fork) does **not** run Google's Android TV Remote
service - this protocol will not work against Fire TV devices. Fire TV
needs its own research track (Phase 9).

## Recommended Phase 1 scope

Discovery, pairing (cert exchange + PIN), D-pad/Home/Back/volume/media
key events, keyboard text input, reconnect using persisted certs. Explicit
non-goals for Phase 1: voice, general app launching by package name,
guaranteed wake-on-LAN (expose it as best-effort, capability-gated).
