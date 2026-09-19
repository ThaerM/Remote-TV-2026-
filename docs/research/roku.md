# Research: Roku

## Official and simplest platform in this matrix

Roku publishes the **External Control Protocol (ECP)** officially, with
public docs at developer.roku.com. This is the only platform here with a
first-party, documented, no-pairing-required remote protocol - a strong
candidate to resequence earlier if the team wants a quick real-device win
(see `docs/product/feature-roadmap.md`).

## Discovery

SSDP - Roku devices respond to `M-SEARCH` with `roku:ecp` in the search
target, returning a base ECP URL (`http://<roku-ip>:8060`).

## Pairing

**None.** ECP has no authentication by default. This is a security
trade-off Roku itself accepts (LAN-only, no internet exposure by
default) - our app should surface this plainly rather than pretending
Roku pairing behaves like every other platform (no `TvPinPairingRequest`
needed; `TvPairingRequest.none` fits directly).

## Commands

Simple HTTP POST to keypress endpoints:
`POST /keypress/{key}` where `{key}` is one of Roku's documented key
names (`Home`, `Back`, `Select`, `Up`/`Down`/`Left`/`Right`,
`VolumeUp`/`VolumeDown`/`VolumeMute`, `Play`, `InstantReplay`,
`Info`, `Rev`/`Fwd`, `PowerOff` on supported models, digits via
`Lit_<char>` for literal character entry).

## Keyboard

Supported - each character is sent as a separate `Lit_<char>` keypress
request, which our `TvCommand.text(...)` can iterate over character by
character.

## App launching

`POST /launch/{appId}` - Roku assigns numeric channel/app IDs; a small
static map of popular streaming app IDs (Netflix, YouTube, etc.) is
enough for a useful quick-apps row; full "list installed apps" is also
available via `GET /query/apps` (returns an XML app list).

## Media controls

`Play`/`Rev`/`Fwd`/`InstantReplay` keypresses cover the common cases;
Roku does not expose fine-grained seek-to-timestamp over ECP.

## Screen mirroring

Roku supports Miracast-based mirroring from Windows and some Android
devices, but this is OS-level mirroring, not something ECP exposes or
our app can trigger - not applicable to iOS at all. Distinguish from
casting, which Roku also supports via its own protocol (separate from
Google Cast) - out of scope for this research pass.

## Power

`PowerOff` keypress works on supported models. No documented programmatic
power-on (Roku remotes wake the device via IR/RF from the physical
remote's own pairing, not ECP) - treat as unsupported unless proven
otherwise on a specific model.

## Recommended Phase 5 scope (or earlier, per roadmap note above)

Discovery, no pairing UI needed, full key command set, keyboard via
per-character `Lit_` requests, app launch from a known ID list plus
`/query/apps` where available. Lowest implementation risk in the roadmap.
