# TV Protocol Matrix

Research snapshot, not a support claim - the app supports none of these
in real form yet (Phase 0 ships only `FakeTvProvider`). "Confidence"
reflects how independently corroborated the entry is from public docs and
established community implementations, not certainty about future
Flutter integration effort.

| Platform | Discovery | Pairing | Transport | Remote commands | Keyboard | Voice | Launch apps | Casting | Mirroring | Power on | Power off | Wake support | Official API | Key limitations | Complexity | Confidence |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Android TV / Google TV | mDNS (`_androidtvremote2._tcp`) | Cert-based pairing, PIN shown on TV | TCP + protobuf (Android TV Remote protocol v2) | Yes (D-pad, media, volume on some) | Yes | Limited (Assistant-gated) | Deep-link only, not full launcher control | Via Cast (separate protocol) | No general API | Wake-on-LAN if enabled on TV | Yes | Yes (WoL) | Unofficial but stable, widely implemented (Home Assistant, python `androidtvremote2`) | No official Flutter/Dart SDK; must implement protobuf handshake ourselves | Medium | High |
| Chromecast / Google Cast | mDNS (`_googlecast._tcp`) | None (open protocol, no PIN) | Cast v2 protocol over TLS | N/A (media-session commands, not a TV remote) | No | No | N/A | Yes - this *is* the casting protocol | No | Via cast session start | Yes (stop casting) | No | Official (Cast SDK, Android/iOS native) | No first-party Flutter plugin; needs a native bridge | Medium-High | High |
| Samsung Tizen | SSDP + mDNS | Token pairing (on-TV prompt or PIN depending on model/year) | WebSocket (`wss://`) JSON API | Yes | Yes (some models) | No public API | Yes (`ms.channel.emit` app control) | Limited (SmartThings, not Cast) | No | Wake-on-LAN (model-dependent) | Yes | Model-dependent | Unofficial (reverse-engineered; SmartThings Cloud API is official but different scope) | Heavy model/year variance; older Orsay-based TVs use a different protocol entirely | High | Medium |
| LG webOS | SSDP | Pairing key exchange (on-TV prompt) | WebSocket (`ssap://`) JSON-RPC-like | Yes | Yes | No public API | Yes | No native Cast-equivalent | No | Limited (WoL on some models) | Yes | Model-dependent | Unofficial (well-documented via community libraries, e.g. `python-lgtv`, `lgwebos`) | Pairing key must be persisted per-TV or user re-pairs every session | Medium | Medium |
| Roku | SSDP | None required for ECP | HTTP (External Control Protocol) | Yes | Yes (text-entry endpoint) | No | Yes (`launch` by app ID) | Limited (screen mirroring via Miracast is separate) | Yes (Miracast, Windows/Android only, not iOS) | No documented API | Yes (`PowerOff` keypress on supported models) | No | Official (Roku publishes ECP docs) | No auth = simplest but weakest security; app ID needed for launch | Low | High |
| Fire TV | Not standardized publicly | N/A | N/A | No public general remote protocol | No | No | Deep-link only (Amazon requires MFi/partner program for more) | Via Fire TV's own Cast-like tech (not Google Cast) | No | No | No | No | No general public API for third-party remote apps | Amazon does not expose an open remote-control protocol comparable to Android TV's; ADB-over-network is the practical fallback, same caveats as Phase 8 | High | Medium |
| DLNA / UPnP | SSDP | None | HTTP (SOAP/UPnP AV) | Media transport only (play/pause/seek/volume on renderer) | No | No | No (not app-aware) | Yes (this is DLNA's actual purpose - media rendering) | No | No | No | No | Open standard (UPnP Forum) | Renderer discovery is inconsistent across TV brands; not a general remote protocol | Medium | High |

## How to read "complexity"

Low = HTTP/REST, no crypto handshake. Medium = WebSocket + a pairing
handshake. High = binary/protobuf protocol, per-model quirks, or heavy
security handling (TLS cert pinning, token rotation).

## Sources of truth for future phases

Public protocol documentation, established open-source client
implementations (used for behavior verification only - not for copying
proprietary code), and the platform's own developer portal where one
exists (Roku, Google Cast). Every real provider should link its specific
sources in its own module doc-comment when implemented.
