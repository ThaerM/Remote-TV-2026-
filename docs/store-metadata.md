# Store Metadata — Remote TV 2026 v1.0.0

Copy for App Store Connect and Google Play Console. Character counts are
checked against each store's limits.

**Before submitting, trim the compatibility list to what has passed its
real-device section in `docs/testing/real-device-test-plan.md`.** The copy
below lists every platform the app implements. None has been verified on
hardware yet (see `docs/product/feature-matrix.md`). Don't ship a brand
claim that hasn't been tested on a real device.

Rules for all listing text and artwork:

- Say "compatible smart TVs and streaming devices". Never say "works with
  every TV", "universal", or "all brands".
- Use brand names only to describe compatibility ("works with compatible
  Roku devices"). No manufacturer logos, no "Designed for Google Cast" or
  "Works with Chromecast" badges (ADR-004: CASTV2 is used without Google's
  sender SDK), and no brand names in the app name or subtitle.
- Mention the iOS limitation: Roku, LG, and Samsung are added by IP address
  on iPhone/iPad.
- Include the trademark disclaimer.

## Shared URLs

| | URL |
|---|---|
| Privacy policy | https://thaerm.github.io/remote-tv-2026/privacy-policy.html |
| Support | https://thaerm.github.io/remote-tv-2026/support.html |
| Marketing / website | https://thaerm.github.io/ |

These pages come from `docs/privacy-policy.html` and `docs/support.html`.
Publish them at exactly these paths before submitting. The app links to
them from Settings and About (`lib/core/config/app_links.dart`).

---

## Apple App Store

| Field | Value | Limit |
|---|---|---|
| App name | Remote TV 2026 | 14 / 30 |
| Subtitle | Smart TV remote & link casting | 30 / 30 |
| Primary category | Utilities | |
| Secondary category | Entertainment | |
| Age rating | 4+ (no objectionable content; the app doesn't browse the web) | |
| Copyright | © 2026 Thaer Mosa | |
| Price | Free (owner decision) | |

**Promotional text** (144 / 170):

> Control compatible smart TVs and streaming devices from your iPhone over
> Wi-Fi: D-pad, volume, keyboard, apps and more. No account, no tracking.

**Keywords** (99 / 100, comma-separated, no spaces after commas):

```
tv remote,remote control,smart tv,wifi remote,cast,media,streaming,dpad,keyboard,television,casting
```

Brand names are deliberately left out of keywords. Apple may reject
third-party trademarks there (Guideline 2.3.7). The description is where
compatibility is described.

**Description** (under 4,000):

```
Remote TV 2026 turns your iPhone into a remote for compatible smart TVs and streaming devices on your home Wi-Fi.

ONE APP, THE CONTROLS YOUR TV ACTUALLY SUPPORTS
Remote TV 2026 asks each device what it can do and shows only those controls — no dead buttons.

• D-pad, OK, Back, Home and Menu
• Volume and mute
• Play, pause, rewind and fast-forward
• Keyboard text entry, where the TV supports it
• Quick app launch, where the TV supports it
• Swipe touchpad mode

WORKS WITH
• Android TV and Google TV devices (secure pairing with the code shown on your TV)
• Chromecast and TVs with Chromecast built-in: cast a media link, control playback and volume
• Roku TVs and players, LG webOS TVs and Samsung Tizen TVs (2016 and newer): add them by IP address on iPhone
Compatibility and available controls vary by model and firmware.

CAST A LINK
Send a direct link to a video, audio file or photo to a compatible device and control playback from your phone.

PRIVATE BY DESIGN
• No account and no sign-up
• No analytics, ads or tracking
• Everything stays on your local network; nothing is sent to the developer
• Pairing credentials are kept in your iPhone's secure Keychain

GOOD TO KNOW
• Your iPhone and TV must be on the same Wi-Fi network.
• The app can't switch a TV on, mirror your screen, or cast files stored on your phone.
• Fire TV and Apple TV are not supported.

Remote TV 2026 is not affiliated with or endorsed by Google, Roku, LG, Samsung or any other manufacturer. Product names are trademarks of their respective owners.
```

**What's New (1.0.0):**

```
First release.
```

**App Review notes** (the reviewer has no TV on their network):

```
Remote TV 2026 controls TVs on the local Wi-Fi network, so it needs a compatible TV (Android TV/Google TV, Chromecast, Roku, LG webOS or Samsung Tizen) on the same network to show devices. Without one, "Find your TV" correctly reports that no TVs were found, and "Add TV by IP address" is available.
The app has no account and no server. Local Network permission is requested only to discover TVs.
A demo video of the app controlling a real TV is attached / available at: <owner to add link>
```

Recommended: record a short screen video of real pairing and control and
attach it, because the reviewer cannot pair with your TV.

---

## Google Play

| Field | Value | Limit |
|---|---|---|
| App name | Remote TV 2026 | 14 / 30 |
| Category | Tools (alternative: Video Players & Editors) | |
| Tags | Remote control, Smart home | |
| Contains ads | No | |
| Content rating | IARC questionnaire: no violence, no user-generated content, no data sharing → expected "Everyone / PEGI 3" | |
| Target audience | 18+ (not designed for children; avoids the Families policy scope) | |
| Contact email | **Owner must provide** (required by Play) | |
| Privacy policy | https://thaerm.github.io/remote-tv-2026/privacy-policy.html | |
| Website | https://thaerm.github.io/ | |

**Short description** (75 / 80):

```
Wi-Fi remote & link casting for compatible smart TVs and streaming devices.
```

**Full description** (under 4,000):

```
Remote TV 2026 turns your phone into a remote for compatible smart TVs and streaming devices on your home Wi-Fi.

THE CONTROLS YOUR TV ACTUALLY SUPPORTS
Each device is asked what it can do, and only those controls are shown — no dead buttons.

• D-pad, OK, Back, Home and Menu
• Volume and mute
• Play, pause, rewind and fast-forward
• Keyboard text entry, where the TV supports it
• Quick app launch, where the TV supports it
• Swipe touchpad mode

WORKS WITH
• Android TV and Google TV devices (secure pairing with the code shown on your TV)
• Chromecast and TVs with Chromecast built-in: cast a media link, control playback and volume
• Roku TVs and players
• LG webOS TVs
• Samsung Tizen TVs (2016 and newer)
• DLNA / UPnP media renderers: cast a media link, control playback and volume
TVs are found automatically on your Wi-Fi, or you can add one by IP address. Compatibility and available controls vary by model and firmware.

PRIVATE BY DESIGN
• No account and no sign-up
• No analytics, ads or tracking
• Everything stays on your local network; nothing is sent to the developer
• Pairing credentials are kept in Android's secure Keystore-backed storage

GOOD TO KNOW
• Your phone and TV must be on the same Wi-Fi network.
• The app can't switch a TV on, mirror your screen, or cast files stored on your phone.
• Fire TV is not supported.

Remote TV 2026 is not affiliated with or endorsed by Google, Roku, LG, Samsung or any other manufacturer. Product names are trademarks of their respective owners.
```

**Release notes (1.0.0):** `First release.`

**Graphics** (from `tool/generate_brand_assets.py`):

| Asset | File |
|---|---|
| App icon 512×512 | `assets/branding/play_store_icon_512.png` |
| Feature graphic 1024×500 | `assets/branding/play_feature_graphic_1024x500.png` |
| Phone screenshots (2–8) | see `docs/store-screenshots.md` |
