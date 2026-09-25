# App Store Connect — App Privacy answers (Remote TV 2026 v1.0.0)

Answers for **App Store Connect → App Privacy**, based on an audit of the
code at release/1.0.0-rc1. Re-audit if a dependency or feature is added.

## Result: "Data Not Collected"

Apple defines *collect* as transmitting data off the device in a way that
lets you or your third-party partners access it for longer than needed to
service the request in real time. Remote TV 2026 has no server, sends
nothing to the developer, and contains no third-party SDK that transmits
data. So the answer to "Do you or your third-party partners collect data
from this app?" is **No**.

## Audit, category by category

| Apple data type | In the app? | Collected (leaves the device to the developer/third party)? |
|---|---|---|
| Contact info (name, email, phone, address) | No | No |
| Health & fitness | No | No |
| Financial info | No | No |
| Location (precise/coarse) | No. No location permission; SSID/Wi-Fi info is not read | No |
| Sensitive info | No | No |
| Contacts | No | No |
| User content (photos, audio, messages, other) | Media **links** the user types on the Cast screen, and keyboard text, are sent only to the user's own TV on the local network | No |
| Browsing / search history | No | No |
| Identifiers (user ID, device ID, IDFA) | No advertising ID, no vendor ID read. TV-side identifiers (serial/UDN) are received from the user's own TVs and kept on the device | No |
| Purchases | No | No |
| Usage data (product interaction, advertising) | No analytics | No |
| Diagnostics (crash, performance, other) | Log lines go to the device's system log only. No crash reporter, nothing uploaded | No |
| Other data | Pairing credentials (see below) | No |

### Local-only data (not "collected")

Stored on the device only, never sent to the developer:

| Data | Storage | Purpose |
|---|---|---|
| Android TV client certificate + private key | Keychain (`flutter_secure_storage`) | Authenticate to the paired TV |
| LG client key, Samsung token | Keychain | Authenticate to the paired TV |
| Paired Android TV metadata (id, name, last IP, last connected time) | `UserDefaults` (`shared_preferences`) | Reconnect without re-pairing |
| Discovered device list, settings | Memory only | Current session |

Sending commands, text, or a media URL to the user's own TV at their
request is on-device functionality on the user's network, not collection
by the developer.

### Tracking

**No.** No data is linked to identity or used for tracking, the app does
not use the AdSupport/AppTrackingTransparency frameworks, and no
`NSUserTrackingUsageDescription` is needed.

## Third-party code in the binary

| Package | Purpose | Sends data off device? |
|---|---|---|
| Flutter engine/framework | UI runtime | No |
| flutter_riverpod, go_router | State, navigation | No |
| flutter_secure_storage | Keychain access | No |
| shared_preferences | Local preferences | No |
| url_launcher | Opens privacy/support/website links in the browser | No (the browser does) |
| package_info_plus | Reads app version for About | No |
| multicast_dns, protobuf, basic_utils, crypto, logging | Discovery, protocol encoding, key generation, local logs | No |

Each plugin that uses an Apple "required reason" API (e.g.
`shared_preferences` → `UserDefaults`, `package_info_plus`) ships its own
`PrivacyInfo.xcprivacy`, and Xcode merges them into the app's privacy
report. The app's own Swift code (`BonjourDiscoveryBridge.swift`) uses no
required-reason APIs.

## Other App Store Connect answers

| Question | Answer |
|---|---|
| Export compliance: uses encryption? | Yes, but exempt: only standard TLS and authentication (Android TV pairing). `ITSAppUsesNonExemptEncryption = false` is set in `Info.plist`. **Owner confirms.** |
| Content rights: third-party content? | No. The app does not display or provide third-party content; media links are the user's own |
| Advertising identifier (IDFA)? | No |
| Sign-in required? | No. App Review notes explain that a TV is needed (see `docs/store-metadata.md`) |
| Privacy policy URL | https://thaerm.github.io/remote-tv-2026/privacy-policy.html |
