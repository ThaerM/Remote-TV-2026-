# Research: DLNA / UPnP

## What this actually is

DLNA (Digital Living Network Alliance) is a certification built on top of
UPnP AV (Audio/Video) profiles. It is a **media rendering** standard, not
a general remote-control protocol - do not implement it expecting D-pad/
Home/Back-style commands to exist. A DLNA "Digital Media Renderer" (DMR)
exposes play/pause/stop/seek/volume for content pushed to it, and that's
effectively the whole surface.

## Discovery

SSDP, same underlying mechanism as Roku and LG webOS discovery
(`M-SEARCH` multicast to `239.255.255.250:1900`), searching for
`urn:schemas-upnp-org:device:MediaRenderer:1` or similar service types.

## Transport / control

HTTP SOAP requests against the renderer's `AVTransport` and
`RenderingControl` UPnP services - `SetAVTransportURI`, `Play`, `Pause`,
`Stop`, `Seek`, `SetVolume`, etc. XML-heavy, verbose, but a well-
established open standard (UPnP Forum specs are public).

## What it's useful for in this app

A generic fallback for "cast a video/photo URL" to smart TVs and media
boxes that expose DLNA rendering but don't have (or we haven't yet built)
a dedicated provider - a reasonable complement to Google Cast for
non-Chromecast, non-major-brand devices. Feeds `TvCapabilities.casting`,
not the general remote-control capability set.

## Known inconsistency

DLNA renderer implementations vary significantly in quality across TV
brands and firmware versions - some renderers silently ignore `Seek`,
others have unreliable `SetVolume`. Treat every DLNA capability as
"probably works" rather than "guaranteed works," and prefer real
platform-specific providers (Cast, Tizen, webOS) over DLNA whenever one
is available for the discovered device.

## Recommended Phase 6 scope

SSDP discovery, `AVTransport` play/pause/stop/seek, `RenderingControl`
volume where present. No remote-control key events (not part of the
standard) - `TvCapabilities` for a DLNA-only device should have `dpad`,
`home`, `back` etc. all false, and rely on the UI's capability gating to
show a casting-only surface instead of an empty remote screen.

## Implementation status (`lib/tv/providers/dlna/`)

**Implemented and unit-tested against a fake MediaRenderer; not yet run
against real hardware.**

- **A media target, not a remote**: DLNA/UPnP has no remote-control keys,
  so `DlnaProvider` only reports `casting`, `mediaControls` and (when the
  renderer has RenderingControl) volume/mute - never D-pad/keyboard/apps.
- **Discovery**: SSDP `urn:schemas-upnp-org:device:MediaRenderer:1`, then
  the device description for `friendlyName`, UDN and the AVTransport /
  RenderingControl control URLs (resolved against `URLBase`/location).
  Renderers without AVTransport aren't listed. Renderers have no fixed
  port, so **Add TV by IP address can't find them** (`probeHost` returns
  null), and a DLNA device can only be controlled after it's been
  discovered in the current session. On iOS, SSDP needs the multicast
  entitlement - without it DLNA isn't discoverable at all.
- **Casting**: `SetAVTransportURI` with a DIDL-Lite item (`protocolInfo`
  `http-get:*:<mime>:*`, title, class by MIME type) then `Play`;
  `Pause`/`Play` toggle, `Seek REL_TIME H:MM:SS`, `Stop`; rewind/forward
  seek -10 s/+30 s. UPnP faults 714-716 are reported as "can't play this
  media".
- **Status**: polled (`GetTransportInfo` + `GetPositionInfo`, every 2 s)
  rather than GENA eventing, which would need an inbound HTTP server.
- **Volume**: RenderingControl `GetVolume`/`SetVolume` (steps of 5,
  clamped 0-100) and `GetMute`/`SetMute` on the Master channel.

**Needs a real renderer**: DIDL/protocolInfo acceptance per brand, seek
support, polling accuracy, renderers that need `SetNextAVTransportURI`
or special headers.
