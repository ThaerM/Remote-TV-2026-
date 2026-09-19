# Security

## Pairing secrets

Pairing tokens, keys, and certificates issued by a TV during pairing must
never be stored in plain text - not in `SharedPreferences`, not in a
plain file, not in app state that gets serialized to disk.

Use `SecureCredentialStore` (`lib/core/storage/secure_credential_store.dart`):

- **iOS**: Keychain, via `flutter_secure_storage`.
- **Android**: Keystore-backed `EncryptedSharedPreferences`
  (`AndroidOptions(encryptedSharedPreferences: true)`), via
  `flutter_secure_storage`.
- **Tests / Linux dev host**: `InMemoryCredentialStore` - explicitly not
  used in release builds on iOS/Android.

No provider in this foundation persists a real secret yet (`FakeTvProvider`
has nothing to persist). The abstraction exists now so the first real
provider (Phase 1, Android TV) has a secure place to put its pairing key
from day one instead of it being retrofitted later.

## What must never happen

- No secret (token, PIN, certificate, pairing key) in git, in a committed
  `.env` file, in logs, in diagnostics output, or in crash reports.
- No plain-text credential storage anywhere in the app.
- `AppLogger` callers must not pass secret values as log messages - see
  `docs/architecture/diagnostics.md`.

## Local network trust model

The app talks to devices on the user's local network, which it treats as
semi-trusted: reachable, but not necessarily the device the user thinks
it is (spoofing, DNS rebinding-style local attacks are a known class of
risk for TV-remote-style apps). Real providers should validate
device identity as part of pairing rather than trusting an IP alone,
per each platform's own pairing protocol.

## Developer / power-user features

Sideloading (Phase 8, ADB/APK tools) carries real security and legal
risk if done casually. Requirements once implemented:

- Off by default; gated behind Settings > Advanced > Developer Mode
  (`SettingsState.developerModeEnabled`, already false by default in this
  foundation).
- Never installs software without an explicit, per-action user
  confirmation - no silent installs.
- Clearly labelled as a developer/power-user feature in the UI, not
  presented as a normal consumer flow.

## Dependency hygiene

Prefer actively maintained packages with compatible licenses. Flag any
proprietary SDK dependency (e.g. a vendor's native Cast/Tizen/webOS SDK)
in the relevant `docs/research/*.md` file before adding it, per the
project's authorization terms.
