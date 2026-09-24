# ADR-004: Google Cast via a Dart CASTV2 sender, not the native Cast SDKs

## Status

Proposed - implemented in the Google Cast PR. Reversible: the choice is
confined to `lib/tv/providers/google_cast/` behind `TvProvider` +
`TvMediaCaster`.

## Context

`docs/research/google-cast.md` recommended wrapping Google's native Cast
Sender SDKs (Android `play-services-cast-framework`, iOS
`google-cast-sdk`) behind our own platform channel, and noted the SDK is
the only integration Google sanctions. The owner's brief also said to
prefer the native SDKs.

What the app actually needs from Cast is small: find receivers, launch
Google's Default Media Receiver (`CC1AD845`), load a URL, play/pause/
seek/stop, volume/mute, and reconnect. All of that is the CASTV2 wire
protocol (TLS on 8009, length-prefixed protobuf `CastMessage`, JSON
payloads on four namespaces) that every open-source sender speaks -
pychromecast (Home Assistant), node-castv2, and VLC, which ships its own
Chromecast sender on both app stores.

## Decision

Implement Cast as a pure-Dart CASTV2 sender (`GoogleCastProvider`),
discovering receivers through the shared DNS-SD layer
(`_googlecast._tcp`, friendly name from TXT `fn`).

Why, over wrapping the native SDKs:

1. **Testable where it matters.** The session/heartbeat/request
   correlation/reconnect logic runs in CI against a scripted fake
   receiver (`test/tv/providers/google_cast/`). Two native wrappers would
   only be *compile*-checked in CI (this environment has no Xcode or
   Android SDK), with their state machines untested.
2. **One implementation, identical on iOS and Android**, instead of two
   native bridges plus a channel protocol that must stay in sync.
3. **Same shape as the rest of the app.** The Android TV provider already
   speaks an unofficial protocol in Dart; Cast discovery reuses the same
   bounded iOS-Bonjour/Android-mDNS code (#12) instead of the SDKs' own
   discovery, and follows the same `TvProvider` lifecycle.
4. **No Google Play Services dependency** on Android (Fire tablets, de-
   Googled phones), and no SDK-imposed UI (MediaRouter dialogs, Cast
   button) that conflicts with the app's own design system.

## Consequences / accepted risks

- **Not Google-sanctioned.** The app must not use the "Google Cast"
  logo/icon or "Designed for Google Cast" branding (that program requires
  the SDK). UI copy says "Cast" and "Google Cast devices" descriptively.
- **No sender device authentication.** Cast certificates chain to
  Google's private device CA, so `TlsCastTransport` accepts them without
  CA validation (as all open-source senders do) and skips the optional
  `deviceauth` challenge. Local network only; no user credentials cross
  the connection. Documented in `docs/architecture/security.md`.
- **Protocol drift.** Google could change receiver behavior; given how
  many third-party senders depend on CASTV2 this is low-probability, and
  a break would show up in the real-device test pass.
- **Default Media Receiver only.** No custom receiver app, no queueing
  (so no previous/next), no casting of files stored on the phone (that
  needs a local HTTP server - a later phase).

If store review or Google policy ever requires the SDK, the replacement
is contained: a native-SDK-backed `CastTransport`/session behind the same
provider, with the UI untouched.
