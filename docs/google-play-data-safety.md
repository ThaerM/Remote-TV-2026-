# Google Play — Data safety answers (Remote TV 2026 v1.0.0)

Answers for **Play Console → App content → Data safety**, based on an
audit of the code at release/1.0.0-rc1. Re-audit if a dependency or
feature is added.

## Data collection and security

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **No** | No server, no analytics/crash/ads SDKs; nothing is sent to the developer or to third parties |
| Is all of the user data collected by your app encrypted in transit? | Not applicable (no data collected) | — |
| Do you provide a way for users to request that their data is deleted? | Not applicable (no data collected). In-app: **Devices → Forget** deletes a paired Android TV's stored data; uninstalling removes everything | — |

Play defines *collection* as transmitting data off the device, and
*sharing* as transferring it to a third party. The exemptions that apply
here:

- **Processed on device only:** pairing credentials, paired-TV metadata,
  and settings never leave the phone.
- **User-initiated transfer the user expects:** sending commands, typed
  text, or a media link to the user's own TV on their local network is the
  purpose of the app, is started by the user, and doesn't go to the
  developer.

## Data type audit

| Play data type | Present? | Collected / shared |
|---|---|---|
| Location (approximate/precise) | No (no location permission, SSID not read) | No |
| Personal info (name, email, IDs, address, phone) | No | No |
| Financial info | No | No |
| Health and fitness | No | No |
| Messages | No | No |
| Photos and videos | No (the app doesn't read media on the phone) | No |
| Audio files | No | No |
| Files and docs | No | No |
| Calendar / contacts | No | No |
| App activity (interactions, search, installed apps, other actions) | No | No |
| Web browsing | No | No |
| App info and performance (crash logs, diagnostics) | Local logcat lines only, never uploaded | No |
| Device or other IDs | No advertising ID, no Android ID read. TV identifiers from the user's own TVs are kept on the device | No |

## Permissions declared (AndroidManifest.xml)

| Permission | Why |
|---|---|
| `INTERNET` | TCP/TLS/WebSocket/HTTP connections to TVs on the local network |
| `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE` | Normal (install-time) network/Wi-Fi state permissions kept alongside the multicast lock. The app reads no Wi-Fi name, BSSID, or location from them |
| `CHANGE_WIFI_MULTICAST_STATE` | Hold a multicast lock during a scan so mDNS/SSDP replies arrive |

No location, nearby-devices, storage, camera, microphone, contacts,
phone, or advertising-ID permission. `com.google.android.gms.permission.AD_ID`
is not declared and no dependency adds it. **Owner: check the merged
manifest of the first release AAB in Play Console** (App bundle explorer →
Permissions) to confirm.

## Other Play Console declarations

| Declaration | Answer |
|---|---|
| Ads | No ads |
| App access | All functionality is available without special access. A compatible TV on the same network is required. Explain this in the review notes |
| Target audience | 18+ (not designed for children) |
| News app | No |
| Government app | No |
| Financial features | None |
| Health | None |
| Privacy policy | https://thaerm.github.io/remote-tv-2026/privacy-policy.html |
