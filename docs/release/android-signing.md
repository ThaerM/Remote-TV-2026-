# Android Release Signing

`android/app/build.gradle.kts` signs release builds with the key described
in `android/key.properties`. That file and the keystore are **never
committed** (`.gitignore` covers `key.properties`, `*.jks`, `*.keystore`).
Without `key.properties`, release builds fall back to the debug key and
Gradle prints a warning. Those builds are fine for CI but **cannot be
uploaded to Google Play**.

## 1. Create the upload key (once)

Run this on your Mac. It needs a JDK (Android Studio bundles one):

```bash
keytool -genkeypair -v \
  -keystore ~/keys/remote-tv-2026-upload.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Choose a strong password, store it in your password manager, and **back
up the .jks file**. Losing it means asking Google to reset the upload key.

## 2. Point the build at it

Create `android/key.properties` (not committed):

```properties
storePassword=<the keystore password>
keyPassword=<the key password>
keyAlias=upload
storeFile=/Users/<you>/keys/remote-tv-2026-upload.jks
```

## 3. Build and verify

```bash
flutter build appbundle --release
# build/app/outputs/bundle/release/app-release.aab

keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
# The certificate owner must be your upload key, NOT "CN=Android Debug".
```

## 4. Play App Signing

When you create the app in Play Console, enroll in **Play App Signing**
(the default). Google holds the app signing key and you upload with the
upload key above. Record the SHA-1/SHA-256 of both keys from Play Console
→ Setup → App signing.

## Identifiers

- `applicationId` / `namespace`: `com.thaerm.remotetv2026`. This can
  never change once the app is published on Play.
- Version: `pubspec.yaml` `version: 1.0.0+1` → `versionName 1.0.0`,
  `versionCode 1`. Increase the `+N` build number for every upload.
