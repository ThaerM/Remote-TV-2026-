# Feature Matrix

"Unit-tested" = exercised in CI against scripted fakes of the device
protocol. "Real device" = run against actual hardware. **As of this
writing no provider has passed its real-device pass**
(`docs/testing/real-device-test-plan.md`), so every row below is
"implemented, not yet proven on hardware".

| Feature | Platform(s) | Implemented | Unit-tested | Real device | Remaining risk |
|---|---|---|---|---|---|
| Android TV discovery | iOS (system Bonjour), Android (mDNS + multicast lock) | Yes | Yes | **No - Gate A** | iOS bridge only compile-verified in CI |
| Android TV pairing (TLS, 6-char code) | Both | Yes | Yes | **No - Gate B** | Real TV cert/handshake behavior |
| Android TV remote commands | Both | Yes | Yes | **No - Gate C** | Key coverage per TV model |
| Android TV reconnect | Both | Yes (bounded backoff) | Yes | **No - Gate D** | Real network timing |
| Google Cast (discover, URL cast, playback, volume) | Both | Yes (CASTV2, ADR-004) | Yes | No | Not Google-sanctioned; real receivers |
| Roku (ECP) | Android: SSDP; iOS: Add by IP | Yes | Yes | No | iOS SSDP needs multicast entitlement |
| LG webOS (SSAP) | Android: SSDP; iOS: Add by IP | Yes | Yes | No | ws vs wss per firmware |
| Samsung Tizen 2016+ | Android: SSDP; iOS: Add by IP | Yes | Yes | No | Apps list on new firmware |
| DLNA / UPnP renderers (cast target) | Android only (SSDP) | Yes | Yes | No | iOS needs multicast entitlement; per-brand DIDL |
| Add TV by IP address | Both | Yes (all providers except DLNA) | Yes | No | - |
| Actionable discovery errors | Both | Yes | Yes | No | - |
| Fire TV | - | **No** | - | - | Only viable path is power-user ADB (`docs/research/fire-tv.md`) |
| Screen mirroring | - | **No** | - | - | Not app-controllable on iOS; see `screen-mirroring.md` |
| APK install (ADB) | - | **No** | - | - | Power-user, off by default when built |
| Voice | - | **No** | - | - | No public voice API on these protocols |
| Power on (Wake-on-LAN) | - | **No** | - | - | Power **off** only where supported |
| Cast files stored on the phone | - | **No** | - | - | Needs a local HTTP server |
| CarPlay | - | **Not viable** | - | - | No CarPlay category fits (`carplay-feasibility.md`) |
