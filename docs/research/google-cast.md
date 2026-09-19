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
