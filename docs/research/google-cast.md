# Research: Google Cast

## Official SDKs

Google publishes first-party native Cast Sender SDKs for both platforms:

- **Android**: `com.google.android.gms:play-services-cast-framework`
- **iOS**: `google-cast-sdk` (CocoaPods) - Objective-C/Swift

Both are actively maintained by Google and are the only sanctioned way to
integrate Cast sending. There is no public, documented raw-protocol path
Google endorses for third parties (unlike Roku's ECP) - the SDK is the
contract.

## Flutter integration options

**A. Existing maintained Flutter plugin.** As of this research pass, the
Flutter Cast plugin ecosystem is fragmented: several `cast`/`chromecast`
packages on pub.dev have low maintenance activity, incomplete iOS
support, or predate current Cast SDK major versions. None found during
this pass wraps the *current* native SDKs on both platforms with active
maintenance and no major open crash/reconnect issues. This assessment
should be re-verified against pub.dev at Phase 2 kickoff, since plugin
health changes over time - do not treat this file as a permanent verdict.

**B. Our own platform channel / plugin.** Wrap the native Cast Sender SDK
on each platform behind a small Flutter platform channel exposing only
what the app needs: discovery (device list), session start/stop, media
load, basic transport controls (play/pause/seek/volume), and
reconnection. This is more upfront work but avoids depending on a
plugin's maintenance cadence for something as failure-sensitive as
casting, and keeps `TvCapabilities.casting` behavior fully in our control.

## Recommendation (non-binding until Phase 2 starts)

Lean toward **B** unless a Phase-2 recheck of pub.dev turns up a plugin
that's clearly current, dual-platform, and actively maintained - casting
is user-facing and failure-visible enough (skipped tracks, dead
reconnects) that depending on an unmaintained wrapper is a worse
trade-off than the extra native-bridge work. Final choice must be
recorded as a dedicated ADR when Phase 2 begins, evaluating whatever the
plugin landscape looks like at that time against: maintenance activity,
current-SDK compatibility on both platforms, license, open bug count
around sessions/reconnection, and iOS parity (a common gap in these
plugins).

## Capability mapping

`TvCapabilities.casting = true` only once a Cast session can actually be
established and a media load command succeeds - not merely because a
Cast-capable device was discovered via mDNS (`_googlecast._tcp`).

## Scope for Phase 2

Device discovery (mDNS), session start against a chosen receiver, load a
media URL, transport controls (play/pause/stop/seek), session
reconnection after app backgrounding. Out of scope: custom Cast receiver
app development (using Google's default receiver only).

## Decision (Phase 2)

Implemented as a pure-Dart CASTV2 sender instead of option B - see
`docs/decisions/ADR-004-google-cast-castv2.md` for the reasoning and the
accepted risks (not Google-sanctioned, so no official Cast branding).

**Implemented and unit-tested, not yet run against a real receiver**
(`lib/tv/providers/google_cast/`):

- Discovery: `_googlecast._tcp` via the shared DNS-SD layer (native
  Bonjour on iOS - `_googlecast._tcp` is in `NSBonjourServices` - raw mDNS
  on Android), name from TXT `fn`, id from TXT `id`, Cast groups keep
  their own SRV port. A Google TV with Chromecast built-in appears twice
  in Find your TV: once as "Android TV / Google TV" (remote) and once as
  "Google Cast" (media target); the device card shows which.
- Add by IP: TLS + `GET_STATUS` on 8009.
- Session: CONNECT, 5 s heartbeat (and PONG replies), 15 s idle watchdog,
  8 s request timeouts (20 s for LAUNCH/LOAD), bounded 3-attempt
  exponential-backoff reconnect, CLOSE on disconnect.
- Media: launch or reuse the Default Media Receiver, LOAD a URL
  (`contentId`/`contentUrl`, BUFFERED/LIVE, title metadata),
  PLAY/PAUSE/SEEK/STOP, receiver SET_VOLUME level/muted (hidden when the
  device reports `controlType: fixed`). Rewind/forward = seek -10 s/+30 s.
- Cast screen: cast a direct media link (type detected from the
  extension, or chosen), now-playing card with seek bar and controls.

`TvCapabilities.casting` is true once the receiver answers `GET_STATUS`
on a live session - a LOAD can still fail per-URL, and that failure is
shown inline rather than hiding the capability.

**Needs a real device**: Chromecast/Google TV/Cast-TV discovery naming,
LOAD with real media URLs (HLS, MP4), receiver behavior when another
sender takes over, volume on TV-integrated receivers, reconnect after
Wi-Fi drops, Cast groups.
