# Research: CarPlay Feasibility

**Not planned for implementation.** This is a research-only feasibility
note, per the project's explicit instruction not to design core
architecture around CarPlay.

## Can Remote TV 2026 qualify for CarPlay?

Apple's CarPlay app categories (as of current public CarPlay developer
documentation) are a fixed, curated list: Audio, Communication (VoIP/
messaging), Navigation, Parking, EV Charging, Quick Food Ordering,
Fueling, and a few others added over time. **"TV remote control" is not
one of Apple's CarPlay app categories.** Apple requires a CarPlay
entitlement scoped to a specific category, granted case-by-case; a
general remote-control app does not map onto any existing category, so
qualifying would require Apple creating (or us successfully petitioning
for) a new category, which is outside our control and has no public
precedent for this app type.

## Which entitlements would be required?

If, hypothetically, a category existed, it would need the corresponding
`com.apple.developer.carplay-*` entitlement (e.g. audio apps need
`com.apple.developer.carplay-audio`), each requiring a formal request to
Apple with a business justification tied to that specific category. There
is no general-purpose "CarPlay app" entitlement.

## Could only limited actions be available?

Even within an existing category (say, if we squinted and pitched
something audio-adjacent), CarPlay's UI templates are fixed and
category-scoped (list templates, now-playing templates, map templates) -
we could not render a custom remote/D-pad UI on CarPlay's display even
with an entitlement. This further weakens the case: the app's core
interaction (D-pad, touchpad, numeric keypad) isn't expressible in any
CarPlay template regardless of category.

## Could widgets/Live Activities be useful instead?

More promising, and unrelated to CarPlay entitlements:

- **iOS Home Screen / Lock Screen widgets** - could show "currently
  connected TV" status and maybe a couple of quick actions (power,
  volume) via `WidgetKit` interactive widgets (iOS 17+), without any
  CarPlay involvement.
- **Live Activities** (Dynamic Island / Lock Screen) - could show "casting
  to Living Room TV" during an active cast session, similar to how music
  apps show playback state. This is a real, implementable, in-scope
  feature for a later phase and doesn't require special Apple approval
  beyond normal `ActivityKit` entitlements.

## Future parked-car media scenarios

If the product direction later leans toward "control your car's infotainment
casting session while parked," that's arguably closer to an *Audio* or
*Navigation-adjacent* CarPlay category than "TV remote," but would need
its own from-scratch entitlement conversation with Apple and is
speculative - not something to design for now.

## What Apple explicitly prohibits

General-purpose remote-control UI, freeform D-pad/gesture surfaces, and
any custom rendering outside CarPlay's provided templates are not
permitted within CarPlay regardless of category - this is a hard
constraint of the CarPlay platform, not a policy nuance that changes with
a strong pitch.

## Conclusion

Do not build for CarPlay. Revisit only if Apple introduces a fitting app
category. A Live Activity for "currently casting" status is the
realistic near-term alternative and can be scoped independently whenever
casting (Phase 2) is stable.

## Status

Re-checked: still no CarPlay category that a TV remote fits, and CarPlay
templates can't render a remote/D-pad. **Not built.** The realistic
alternative remains a Live Activity for an active cast session, now that
casting exists.
