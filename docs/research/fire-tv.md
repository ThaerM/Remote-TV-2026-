# Research: Amazon Fire TV

## Not the Android TV Remote protocol

Fire TV runs Fire OS (an Android fork) but **does not run Google's
Android TV Remote service** (`_androidtvremote2._tcp`) - that service
ships with Google TV / Android TV's Google Play Services, which Fire TV
doesn't have. `AndroidTvProvider` therefore can't control a Fire TV, and
the app must not suggest otherwise.

## What exists

| Option | Official for third parties? | What it gives | Verdict |
|---|---|---|---|
| Amazon's own "Fire TV" phone app protocol | No - private, undocumented, keyed to Amazon's app | Full remote | **Not usable.** Reverse-engineering Amazon's app credentials would be both fragile and a terms/store-policy problem. |
| DIAL (`urn:dial-multiscreen-org:service:dial:1`) | Yes (open spec, used by YouTube/Netflix) | Launch a *DIAL-registered* app (e.g. YouTube) with a parameter | Launch-only, per-app registration on the TV side; not a remote. Possible future "open YouTube on Fire TV" nicety, nothing more. |
| ADB over network (Developer Options -> ADB debugging) | Yes, as a developer feature | Key events (`input keyevent`), text, app launch/list, APK install | **The only real remote path.** Power-user only: the user must enable Developer Options and ADB debugging on the TV and accept an RSA-key prompt. Shares all the requirements of `android-tv-apk-installation.md`. |
| Fire TV "Matter" / Alexa | Cloud + account linking | Voice-assistant level control | Out of scope (cloud, account-bound). |

## Decision

Fire TV is **not implemented**. When the ADB power-user feature is built
(see `android-tv-apk-installation.md`), a `FireTvProvider` can sit on the
same ADB transport - but it must:

- be off by default, behind Settings > Advanced > Developer Mode;
- explain the on-TV steps (Settings > My Fire TV > Developer Options >
  ADB debugging) and that an RSA prompt will appear on the TV;
- expose only key events, text, app launch/list and install - never a
  general shell;
- report capabilities honestly (no volume on models where `input keyevent
  KEYCODE_VOLUME_*` is swallowed by HDMI-CEC, no power-on).

Until then Fire TV devices simply don't appear in discovery, rather than
appearing and failing.
