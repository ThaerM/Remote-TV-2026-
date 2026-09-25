# Privacy

User-facing policy: `docs/privacy-policy.md` (published as
`privacy-policy.html`). Store answers: `docs/app-store-privacy.md`,
`docs/google-play-data-safety.md`. Keep all four consistent with this file.

Remote TV 2026 is **local-first**: it talks directly to TVs on the user's
own network and has no backend.

## What leaves the phone

- **Only traffic to devices on the local network**: discovery
  (mDNS/Bonjour, SSDP), and the control/cast connections to the TV the
  user picks. Nothing is sent to a server operated by this app.
- **Cast links**: when the user casts a URL, the *TV* fetches that URL
  itself. The app sends the URL to the TV and nothing else.
- **No analytics, no advertising SDKs, no crash reporting.** If crash
  reporting is ever added, it must be opt-in, documented here, and strip
  hostnames/device names.

## What's stored on the phone

| Data | Where | Why |
|---|---|---|
| Android TV pairing identity (client cert + private key) | Keychain / Keystore (`SecureCredentialStore`) | Reconnect without re-pairing |
| LG webOS client key, Samsung token | Keychain / Keystore | Same |
| Paired Android TV name, last host, last connected time | App preferences | Device list |
| Settings (theme, remote layout, haptics) | Memory only (not persisted in 1.0) | Preferences |

"Forget device" (Android TV, Devices screen) removes both the metadata
and the secret. LG/Samsung credentials have no in-app Forget in 1.0.
Uninstalling removes them on Android. On iOS, Keychain items can outlive
the app until the device is erased. Nothing is
synced to iCloud/Google backup beyond the platform's normal app-data
backup of preferences (secrets use Keychain/Keystore, which are not
exported in plain form).

## Permissions

- **iOS Local Network** - required to find and talk to TVs. The prompt
  text (`NSLocalNetworkUsageDescription`) says so and that nothing leaves
  the local network.
- **Android** - network state, Wi-Fi state, and a Wi-Fi multicast lock
  held only while scanning. No location, contacts, microphone, camera, or
  storage permissions.

## Logs

Diagnostic logs (`[TV][...]` lines, Settings > Diagnostics) contain device
names, IP addresses and protocol states - never PINs, pairing codes,
tokens, client keys, certificates or private keys. They stay on the
device unless the user chooses to share them.
