# Store Screenshot Plan — Remote TV 2026 v1.0.0

Capture every screenshot from the **release build running against a real
TV**. Never use demo mode (`ENABLE_DEMO_TV_DEVICES`): demo devices are
labelled "Demo device · not a real TV" and are not real states. Don't edit
screenshots to add controls, brands, or states the app didn't show.

## Required sizes

| Store | Device class | Size (portrait, px) | Count |
|---|---|---|---|
| App Store | iPhone 6.9" (e.g. iPhone 16/17 Pro Max) | 1320 × 2868 (or 1290 × 2796) | 3–10 |
| App Store | iPad 13" (only because the app supports iPad: `TARGETED_DEVICE_FAMILY = 1,2`) | 2064 × 2752 | 3–10 |
| Google Play | Phone | 1080 × 1920 or larger, 9:16 | 2–8 |

Owner decision: if you don't want to produce iPad screenshots, make the
app iPhone-only (`TARGETED_DEVICE_FAMILY = 1`) before the first
submission. Removing iPad support later is not allowed for an app that has
already shipped on iPad.

## Shot list (order = store order)

| # | Screen | How to reach it | State to show | Caption idea |
|---|---|---|---|---|
| 1 | Remote — D-pad | Connect to your Android TV → Remote tab | Connected, D-pad visible, device name in header | "The controls your TV supports" |
| 2 | Discovery — TV found | Find your TV, after a scan on your Wi-Fi | Your real TV(s) listed with platform label | "Finds TVs on your Wi-Fi" |
| 3 | Pairing | Select an unpaired Android TV | 6-character hex code entry ("Numbers 0-9 and letters A-F"), a few characters typed, e.g. `A4F` | "Secure one-time pairing" |
| 4 | Remote — Touchpad | Settings → Remote layout → Touchpad | Connected, touchpad surface | "Swipe to navigate" |
| 5 | Cast | Connect to a Google Cast device → Cast tab | Link form, or Now Playing after casting a real link you're allowed to use | "Cast a media link" |
| 6 | Devices | Devices tab | Your paired TV | "Your TVs, remembered" |
| 7 | Welcome | Fresh install, first launch | As shipped | "No account. Stays on your network." |
| 8 | Settings | Settings tab | As shipped | (optional) |
| 9 | Connected | Right after pairing succeeds | Success screen | (optional) |

Notes:

- Rename your TV to something neutral (e.g. "Living Room TV") before
  capturing. Don't show the Wi-Fi name or IP addresses of your home
  network.
- Only use media links you have the rights to. The Cast screenshot
  must not show copyrighted artwork or titles.
- Brand logos must not appear, including a TV's own logo in the app list.
  The app shows app names in text only.
- Use dark mode (the default). Optionally add one light-mode Remote shot.
- Captions may be overlaid with a plain background. No device frames
  showing another manufacturer's hardware.

## Capturing

```bash
# iPhone (release build on a real device, from a Mac)
flutter run --release -d <iphone-id>
# Screenshot: side button + volume up. AirDrop to the Mac.

# Android
flutter run --release -d <android-id>
adb exec-out screencap -p > shot.png
```

The golden images in `test/goldens/goldens/` render text as boxes (the
Ahem test font), so they are **not** usable as store screenshots. They
are only regression references.
