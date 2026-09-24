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

## Implementation status (`lib/tv/providers/lg_webos/`)

**Implemented and unit-tested against a scripted fake TV; not yet run
against a real LG TV.** Protocol facts (unsigned registration manifest,
endpoints, button names) come from `aiowebostv` 0.10.0 (Apache-2.0, the
library behind Home Assistant's webOS integration) - see
`lib/tv/providers/lg_webos/NOTICE.md`. Current aiowebostv registers with
an **unsigned** manifest, so no LG signature blob is embedded.

- **Discovery**: SSDP `urn:lge-com:service:webos-second-screen:1`, name
  from the UPnP description's `friendlyName`, id `lg:<UDN>`. On iOS the
  SSDP send needs the multicast entitlement (see Roku notes), so **Add TV
  by IP address** (`hello` on the SSAP socket, no registration) is the
  fallback.
- **Transport**: `ws://<tv>:3000`, falling back to `wss://<tv>:3001` with
  the TV's self-signed certificate accepted for that host only (newer
  firmware requires the secure port).
- **Pairing**: `register` with `pairingType: PROMPT`. First time, the TV
  shows "allow this device?" and the app shows
  `TvConfirmOnDevicePairingRequest`; the returned client-key is stored in
  `SecureCredentialStore` (`lg_webos.client_key.<deviceId>`) and reused
  silently afterwards. Declining ends in `error` with nothing stored.
- **Buttons** go over the separate pointer-input socket
  (`getPointerInputSocket` -> `type:button\nname:<BUTTON>\n\n`): D-pad,
  ENTER, BACK, HOME, MENU, GUIDE, INFO, volume/mute, channel, color keys,
  digits, PLAY/PAUSE/STOP/REWIND/FASTFORWARD. **Text** via
  `com.webos.service.ime/insertText`, **apps** via
  `listLaunchPoints` + `system.launcher/launch`, **power off** via
  `system/turnOff` (sent without waiting - the TV often never answers).
- **Not supported**: power *on* (needs Wake-on-LAN), input switching (no
  public SSAP button), previous/next.
- **Reconnect**: 3-attempt backoff re-registering with the stored key; if
  the TV asks for the prompt again (key revoked) it stops immediately in
  `error` instead of prompting repeatedly.

**Needs a real LG TV**: ws vs wss per firmware year, prompt UX, key
reuse across TV reboots, button coverage, text entry in real apps, power
off behavior with "Quick Start+".
