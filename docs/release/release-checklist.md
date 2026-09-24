# Release Checklist — Remote TV 2026 v1.0.0 (RC1)

Branch `release/1.0.0-rc1`. Status key: **DONE** (in the codebase and
verified here) · **MANUAL** (owner action, can't be done from the repo) ·
**BLOCKED** (waiting on something outside the repo) · **NOT REQUIRED**.

**The app is not production-ready until the Android TV real-device gates
A–D pass** (`docs/testing/rc1-device-checklist.md`). Nothing has been
submitted to either store.

| Area | Status | Details |
|---|---|---|
| **Branding** | DONE | "Remote TV 2026" on iOS (`CFBundleDisplayName`, `CFBundleName`), Android (`android:label`), app title, launch screens. Developer: Thaer Mosa. No old/snake_case name in customer-facing text. Welcome tagline no longer claims "every TV" |
| **Identifiers** | DONE (owner registers) | `com.thaerm.remotetv2026` on both platforms. **MANUAL:** register this bundle ID in the Apple Developer account / create the App Store Connect record, and create the Play Console app with this package name. It can't change after the first upload |
| **Version** | DONE | `pubspec.yaml` `1.0.0+1` → iOS `CFBundleShortVersionString 1.0.0` / `CFBundleVersion 1`, Android `versionName 1.0.0` / `versionCode 1`. Bump `+N` for every upload |
| **Icon** | DONE | Generated from `tool/generate_brand_assets.py`: `assets/branding/app_icon_master_1024.png` (no alpha), full iOS AppIcon set, Android adaptive (foreground/background/monochrome) + legacy mipmaps, Play 512 icon, feature graphic. No Flutter default icon remains |
| **Splash / launch** | DONE (device check MANUAL) | Dark `#0A0B0D` + app mark. iOS `LaunchScreen.storyboard`; Android pre-12 `launch_background.xml`; Android 12+ `windowSplashScreen*` (`values-v31`). Check on devices during Gate A |
| **About** | DONE | Settings → About: name, developer, website, GitHub, version and build from the bundle (`package_info_plus`, not hardcoded), Privacy Policy, Support, Open Source Licenses |
| **Privacy policy** | DONE (publish MANUAL) | `docs/privacy-policy.md` → `docs/privacy-policy.html` (`tool/build_pages.py`). **MANUAL:** publish at `https://thaerm.github.io/remote-tv-2026/privacy-policy.html` (the URL the app and stores use) |
| **Support page** | DONE (publish MANUAL) | `docs/support.md` → `docs/support.html`. **MANUAL:** publish at `https://thaerm.github.io/remote-tv-2026/support.html` |
| **Contact email** | MANUAL | Google Play requires a developer contact email. Add one to Play Console (and optionally to both pages) |
| **Store metadata** | DONE (trim MANUAL) | `docs/store-metadata.md`. **MANUAL:** remove any brand from the listing that hasn't passed its real-device section |
| **Apple App Privacy** | DONE (enter MANUAL) | `docs/app-store-privacy.md`: "Data Not Collected", no tracking |
| **Google Data Safety** | DONE (enter MANUAL) | `docs/google-play-data-safety.md`: no data collected or shared |
| **Export compliance (iOS)** | DONE (owner confirms) | `ITSAppUsesNonExemptEncryption = false`: only standard TLS and authentication |
| **Android signing** | BLOCKED on owner | Gradle reads `android/key.properties` (not committed). Without it, release builds are **debug-signed and not uploadable**. Steps: `docs/release/android-signing.md` |
| **iOS signing** | MANUAL | Team `KE2TDZEG3K`, automatic signing, set for Debug/Release/Profile. Needs an Apple Distribution certificate + App Store profile on the Mac: Xcode → Product → Archive → Distribute |
| **Multicast entitlement (iOS)** | NOT REQUIRED for 1.0 (owner decision) | Not requested and not added. Android TV and Google Cast use system Bonjour. Roku/LG/Samsung are added by IP on iOS, and DLNA is Android-only. Request it later if automatic SSDP discovery on iOS is wanted |
| **iPad** | MANUAL decision | The app supports iPad (`TARGETED_DEVICE_FAMILY 1,2`), so iPad screenshots are required. Or make it iPhone-only before the *first* submission |
| **Tests** | DONE | `flutter test`: 252 passing (was 232). New: session switching and duplicate identity, bounded Android TV reconnect, hex pairing codes, pairing cancel, About |
| **Goldens** | DONE | 14 goldens (13 + About), rendered with Flutter 3.47.5, as pinned in CI |
| **Format / analyze** | DONE | `dart format --set-exit-if-changed .` clean; `flutter analyze` 0 issues |
| **Android build** | DONE in CI | CI `flutter build apk --debug` on the RC branch. `flutter build apk --release` / `appbundle --release` need the Android SDK. Run them locally after signing is set up |
| **iOS build** | DONE in CI | CI `flutter build ios --debug --no-codesign` on macOS. `flutter build ios --release --no-codesign` / `flutter build ipa` on your Mac |
| **Real-device Gate A (discovery)** | MANUAL, not run | `docs/testing/rc1-device-checklist.md` |
| **Real-device Gate B (pairing)** | MANUAL, not run | Two blockers found and fixed in RC1: hex codes could not be typed, and pairing could not be cancelled |
| **Real-device Gate C (commands)** | MANUAL, not run | |
| **Real-device Gate D (reconnect)** | MANUAL, not run | Reconnect now capped at 5 attempts (~31 s) |
| **Other providers on hardware** | MANUAL, not run | Google Cast, Roku, LG, Samsung, DLNA sections of `real-device-test-plan.md` |
| **Screenshots** | MANUAL | `docs/store-screenshots.md`. Real device and real TV only; demo mode is not allowed |
| **App Review demo video** | MANUAL (recommended) | The reviewer has no TV. Attach a short screen recording |
| **Store submission** | BLOCKED | On Gates A–D, signing, published privacy/support pages, and screenshots |

## Known limitations shipped in 1.0 (documented, not bugs)

- LG and Samsung pairing credentials have no in-app **Forget** (only
  Android TV does). They are removed on uninstall (Android), or stay
  in the iOS Keychain, readable only by this app. The privacy policy
  says so.
- On iOS, Roku/LG/Samsung need **Add TV by IP address**. DLNA isn't
  available on iOS.
- A TV added by IP address has a different identity than when found by
  scanning, so an Android TV paired via one way asks for a code again
  when reached the other way.
- `features/devices` imports the Android TV paired-device store directly
  (a pre-existing exception to the "features never import providers"
  rule). Generalizing saved devices is post-1.0 work.

## Build commands (owner's Mac)

```bash
git switch release/1.0.0-rc1 && git pull --ff-only
flutter clean && flutter pub get
dart format --set-exit-if-changed . && flutter analyze && flutter test

# Android (after android/key.properties exists)
flutter build apk --release
flutter build appbundle --release          # upload this to Play

# iOS
flutter build ios --release --no-codesign  # compile check
flutter build ipa --release                # signed archive for App Store Connect
```

Never pass `--dart-define=ENABLE_DEMO_TV_DEVICES=true` to a release build.

## Regenerating assets and pages

```bash
pip install pillow markdown
python3 tool/generate_brand_assets.py   # icons, launch images, store graphics
python3 tool/build_pages.py             # privacy-policy.html, support.html
flutter test --update-goldens test/goldens   # only with Flutter 3.47.5
```
