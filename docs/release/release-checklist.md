# Release Checklist

Status as of this document. **Nothing here has been submitted to a
store**, and nothing should be until every blocking item is done.

## Blocking - owner action required

- [ ] **Real-device gates A-D pass** for Android TV
      (`docs/testing/real-device-test-plan.md`). Other providers ship only
      once their section of that plan passes, or are hidden behind a
      "beta" label.
- [ ] **Android release signing.** `android/app/build.gradle.kts` still
      signs release builds with the debug key (Flutter template default).
      Create an upload keystore, keep it out of git, and wire a
      `signingConfigs.release` from `key.properties`.
- [ ] **Apple multicast entitlement decision.** Roku, LG, Samsung and
      DLNA discovery use SSDP, which on iOS requires
      `com.apple.developer.networking.multicast` (request at
      developer.apple.com/contact/request/networking-multicast, with the
      justification "SSDP discovery of TVs on the local network"). Without
      it those brands work on iOS only via **Add TV by IP address** (and
      DLNA not at all). Android TV and Google Cast use system Bonjour and
      don't need it.
- [ ] **App icon and launch screen artwork.** The icons in
      `ios/Runner/Assets.xcassets` and `android/app/src/main/res/mipmap-*`
      are Flutter placeholders. Add final artwork (1024x1024 master, an
      Android adaptive icon foreground/background) - no manufacturer
      logos.
- [ ] **Privacy policy URL** for both stores (local-first, see
      `docs/architecture/privacy.md`).
- [ ] **Store listing copy** must match `docs/product/feature-matrix.md` -
      no claims of brands/features that aren't real-device verified, no
      "Google Cast" / "Designed for Google Cast" branding (ADR-004), no
      manufacturer logos.

## Done in the codebase

- [x] iOS `NSLocalNetworkUsageDescription` explains the local-network use.
- [x] iOS `NSBonjourServices`: `_androidtvremote2._tcp`, `_googlecast._tcp`
      (exactly the types the app browses - nothing extra).
- [x] Display name "Remote TV 2026" on iOS (`CFBundleDisplayName`) and
      Android (`android:label`).
- [x] Android permissions: `INTERNET`, `ACCESS_NETWORK_STATE`,
      `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE` (lock held only
      during scans). No location, contacts, storage, or phone permissions.
- [x] Secrets only in Keychain/Keystore (`SecureCredentialStore`); none in
      logs (`docs/architecture/security.md`).
- [x] No analytics or crash-reporting SDKs.
- [x] CI: format, analyze, tests, Android debug build, iOS no-codesign
      build on every PR.
- [x] Versioning: `pubspec.yaml` `version: 0.1.0+1` drives both platforms
      (bump the build number for each store upload).

## Before each release

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build appbundle --release      # after release signing is set up
flutter build ipa --release            # on a Mac with signing configured
```

- [ ] No `ENABLE_DEMO_TV_DEVICES` in release build commands (demo TVs
      must never ship).
- [ ] Review `TODO`/`FIXME` (currently none in `lib/`).
- [ ] Re-read `docs/product/feature-matrix.md` and the store listing
      together.
