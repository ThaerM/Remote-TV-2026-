# Research: LG webOS

## Discovery

SSDP (UPnP-based). webOS TVs respond to an `M-SEARCH` broadcast with a
device description pointing to their local WebSocket endpoint.

## Transport & pairing

WebSocket (`ws://<tv-ip>:3000` or `wss://<tv-ip>:3001` on newer
firmware), JSON-RPC-like request/response framing (not strict JSON-RPC
2.0, but close enough that most community client libraries model it that
way). First connection triggers an on-screen pairing prompt on the TV;
once accepted, the TV returns a **client key** the app must persist and
resend on every future connection to skip re-pairing.

This client key is the pairing secret - store via `SecureCredentialStore`,
never in plain storage, matching the same pattern as Android TV's
certificate and Samsung's token.

## Commands

Rich command set via named "URIs" in the JSON-RPC-style payload
(`ssap://com.webos.applicationManager/launch`,
`ssap://audio/volumeUp`, `ssap://com.webos.service.ime/insertText`,
etc.). D-pad, volume, channel, numeric keypad, and app launch are all
supported this way. No documented color-key API - LG's remotes lean on
the "Magic Remote" pointer/gesture model more than colored buttons.

## Keyboard

Supported via a dedicated input-manager endpoint
(`com.webos.service.ime`), separate from key-press events - matches our
`TvCommand.text(...)`.

## Voice

No public API for third-party voice injection.

## App launching

Supported and reasonably reliable - `applicationManager/launch` accepts
an app ID; `applicationManager/listApps` (where available) can enumerate
installed apps, though availability varies by webOS version.

## Power

Power-off is a standard command. Power-on from a fully off state depends
on Wake-on-LAN, which is model/firmware-dependent (LG calls it "Mobile
TV On" in some menus) - same caveat as every other platform here.

## Official vs. reverse-engineered

Unofficial for third parties (no LG developer program covers this),
but extremely well documented by the community - `python-lgtv`, the
`lgwebos` component in Home Assistant, and multiple open client
implementations across languages corroborate the protocol shape
independently, which is why confidence in the matrix entry is
Medium-to-High despite being unofficial.

## Recommended Phase 4 scope

Discovery, pairing + client-key persistence, D-pad/volume/channel/
numeric commands, keyboard text input, app launch for a known app-ID
list. Defer: voice, guaranteed wake-on-LAN, and any Magic Remote
pointer/gyroscope-style pointing (a different interaction model from our
D-pad/touchpad, worth a dedicated design discussion if pursued later).
