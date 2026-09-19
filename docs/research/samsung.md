# Research: Samsung Smart TV (Tizen)

## Two different Samsung surfaces - don't conflate them

1. **SmartThings API** (official, cloud-based) - controls SmartThings-
   registered devices, including some Samsung TVs, through Samsung's
   cloud. Requires a SmartThings developer account, OAuth, and the TV
   being registered to a Samsung account. Good for basic power/volume/
   input on supported models; not a full remote-control replacement.
2. **Tizen local WebSocket API** (unofficial for third parties, though
   it's the same API Samsung's own SmartThings/Samsung Remote apps use
   locally) - `wss://<tv-ip>:8002/api/v2/channels/samsung.remote.control`.
   Local, low-latency, no cloud dependency, no SmartThings account
   needed. This is the more practical path for a general "remote control"
   feature and is what community libraries (e.g. `samsungtvws` for
   Python) implement.

## Pairing

Local WebSocket flow: TV shows a permission prompt (or a PIN, depending
on model and firmware) the first time an unrecognized client connects.
Once approved, the TV issues a token the client must send on every
reconnect - **this token is the pairing secret** and must be stored via
`SecureCredentialStore`.

## Model/year variance - the biggest real risk

- Pre-2016 Samsung "Smart Hub" TVs run **Orsay**, not Tizen, and use an
  entirely different (older, less documented) protocol. Out of scope
  unless explicitly requested later.
- 2016+ Tizen models generally support the WebSocket API described above,
  but exact command availability, encryption requirements, and pairing
  UX (PIN vs. on-screen Allow/Deny) vary by year and firmware.
- Do not assume a Samsung TV found on the network supports the same
  command set as another Samsung TV - this is exactly why
  `TvCapabilities` is per-device, not per-platform.

## Commands

Volume, mute, channel, D-pad, numeric keypad, color keys (Tizen TVs
commonly expose these, unlike Android TV), power (works while TV is on
standby-with-network, not fully unplugged), input switching, app launch
via `ms.channel.emit` with an app-specific payload.

## Keyboard / voice

No public voice API. Text input is supported through a different
WebSocket message type than key presses (`ms.remote.control` with a
`Unicode` payload), separate research needed at implementation time to
confirm reliability across firmware versions.

## Power limitations

"Power on" over the local API generally does not work from a fully
powered-off state without Wake-on-LAN being enabled in the TV's network
settings (model-dependent naming: "Power On with Mobile," etc.) - the
same caveat as most platforms in this matrix.

## Recommended Phase 3 scope

Local WebSocket provider only (not SmartThings cloud, to avoid an
external account dependency for a core feature). Pairing + token
persistence, D-pad/volume/channel/numeric/color-key commands, app launch
for a small known app-ID list, capability flags conservative by default
(assume less, not more, until verified against a real test device).
