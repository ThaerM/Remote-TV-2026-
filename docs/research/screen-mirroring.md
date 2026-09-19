# Research: Screen Mirroring vs. Casting

These get conflated constantly by users ("mirror my phone" often really
means "cast this video") - this doc exists to keep the app's language and
architecture honest about which one is actually happening.

## Definitions

1. **Screen mirroring** - the TV shows a live, real-time copy of the
   phone's screen (every app, every pixel), typically via a
   phone-to-TV direct video stream (Miracast/WFD) or a receiver-side
   mirroring mode.
2. **Media casting** - the phone tells the TV *what* to play (a URL, a
   media session), and the TV fetches/renders it independently. This is
   what Google Cast, DLNA, and AirPlay's media-casting mode all do. The
   phone can lock or leave the app after starting a cast.
3. **AirPlay** - Apple's protocol; supports both mirroring (2) and media
   casting depending on mode. iOS exposes AirPlay mirroring/casting as a
   system-level feature (Control Center), not something third-party apps
   can directly trigger for another device the same way Cast SDKs allow.
4. **DLNA** - media casting only (see `docs/research/dlna.md`).
5. **App-level streaming** - an app streams its own content directly
   (e.g. a video player app casting via its own logic) - not a distinct
   protocol, just usage of one of the above from within an app.

## Android phone -> TVs

- **Android -> Google TV/Chromecast-enabled TV**: Google Cast SDK,
  official, well-documented (see `docs/research/google-cast.md`).
- **Android -> generic Miracast-capable TV** (including many Roku, some
  Samsung/LG models): OS-level `MediaProjection`-based mirroring is
  possible for an app to *initiate* on Android, but requires
  `MediaProjection` permission (visible system prompt) and a WFD-capable
  receiver on the TV side. This is genuine screen mirroring, distinct
  from casting. Non-trivial to implement reliably across OEM Miracast
  stacks - flag as high-effort, defer past Phase 7's initial scope.

## iPhone -> TVs

- **iPhone -> AirPlay-capable device** (Apple TV, and AirPlay 2-certified
  smart TVs from Samsung/LG/Sony/Vizio): system-level only. A third-party
  app cannot programmatically start AirPlay mirroring to an arbitrary
  device the way Cast SDKs allow - the user must use Control Center or a
  system `AVRoutePickerView` (which shows *all* AirPlay-capable
  receivers, not just the one our app is currently paired with). We can
  surface an `AVRoutePickerView` as a "Mirror with AirPlay" button, but
  cannot script the destination choice.
- **iPhone -> non-AirPlay TVs** (most Roku, most Fire TV, non-AirPlay
  Samsung/LG models): **no general mirroring path exists** on iOS. Do
  not claim mirroring support for these; casting (Cast SDK where
  applicable, DLNA as fallback) is the only realistic option.

## Explicit non-claims

We do not claim universal screen mirroring. Concretely:

| Source | Target | Mirroring possible? |
|---|---|---|
| Android | Chromecast/Google TV | Casting yes; direct mirroring via Cast "screen share" mode is possible but degrades quality/battery - treat as last resort |
| Android | Miracast-capable non-Google TV | Mirroring possible (MediaProjection + WFD), high effort |
| iPhone | AirPlay-capable TV | Mirroring possible via system AirPlay only, not app-scripted |
| iPhone | Non-AirPlay TV (Roku, Fire TV, most non-AirPlay Samsung/LG) | Not possible |

## Recommendation

Ship casting (Phase 2 onward) well before attempting any mirroring.
Mirroring is higher-effort, platform-fragmented, and in iOS's case
partially outside third-party app control entirely.
