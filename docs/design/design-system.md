# Design System

Original design system for Remote TV 2026. Dark is the default and
primary mode; light and system are fully supported. The goal is a
premium, near-black surface - not Material's default dark grey - and a
remote that feels like a physical controller rather than a settings form:
"the phone becomes the remote," not a generic Flutter app.

## Tokens (`lib/core/design/`)

- `AppColors` - brand (`brandPrimary` signal green, `brandSecondary`
  control blue), dark/light surface scales, semantic colors
  (success/warning/danger, connection-state colors including
  `reconnecting`), and `glow` - a cyan-blue accent used only for ambient/
  ring effects (Welcome, discovery radar, connection rings, the active
  pairing-code box), always at low alpha, never a solid fill.
- `AppTypography` - a compact type scale (display, headline, title, body,
  bodyStrong, caption, buttonLabel), platform default font family for
  this foundation (no bundled/licensed font dependency yet).
- `AppSpacing` - 4/8/16/24/32/48 scale.
- `AppRadius` - sm/md/lg/pill corner radii.
- `AppControlSize` - `primaryButton` (64), `secondaryButton` (52),
  `dpadDiameter` (220), `minTouchTarget` (48) - sized for reliable thumb
  targets on a remote, not generic Material defaults.

## Motion system (`AppMotion`)

Every duration/curve used anywhere in the app comes from `AppMotion` -
no widget hardcodes its own timing:

| Token | Value | Used for |
|---|---|---|
| `fast` | 120ms | Button/D-pad press feedback - must stay short; the command dispatches immediately regardless of this animation |
| `normal` | 220ms | Small state changes (icon swaps, digit box fill) |
| `panel` | 260ms | Bottom sheets, the D-pad/touchpad morph transition |
| `connection` | 350ms | Connection-state transitions, list-item entrance |
| `standard` / `enter` / `exit` | `Curves.easeOutCubic` / `easeOutCubic` / `easeInCubic` | All of the above - deliberately no bounce/overshoot curves |

**Reduced motion**: any looping/ambient animation (`DiscoveryRadar`,
`AnimatedConnectionRing`, the Welcome glow) checks
`MediaQuery.disableAnimations` and renders a static equivalent instead of
animating when the platform's reduced-motion setting is on.

**Haptics** are never fired unconditionally by a component - every
control that vibrates takes the caller's `hapticsEnabled` (read from
`SettingsState.hapticFeedbackEnabled`), so the existing Remote Behavior
toggle actually governs all of them, including the ones added in this
pass (D-pad, rocker, pairing-code shake, touchpad steps).

## Theme (`lib/app/theme/app_theme.dart`)

Builds Material 3 `ThemeData` from the tokens above for both brightness
modes, plus an `AppSurfaceColors` `ThemeExtension` exposing the raw
surface/border/text tokens that don't map cleanly onto `ColorScheme`.

**Theater mode** (`SettingsState.theaterModeEnabled`, Settings >
Remote): forces the Remote screen's `Scaffold` to pure black and is the
seam for further "reduce decorative intensity" work later. Never touches
system brightness.

## Remote control hierarchy

The Remote screen (`RemoteScreen`) is deliberately not "every button on
one screen":

```
Top       Device name + ConnectionStatusIndicator + power (tap name for
          the device switcher bottom sheet)
Quick     Horizontal app shortcut row + "See all" -> Apps screen
          (capability-gated: launchApps && applications.isNotEmpty)
Primary   D-pad or TouchpadSurface (user's Remote Layout preference),
          cross-faded via AnimatedSwitcher; a text button switches
          between them on the fly
Actions   Home / Back / Menu / Keyboard / Voice (each capability-gated)
Volume/   RemoteRocker pill controls with press-and-hold repeat
Channel
More      Bottom sheet: media transport, numeric keypad, color keys
```

Every group is conditionally rendered from `TvCapabilities` - see
`docs/architecture/provider-system.md#capability-driven-design`. While
the connection is not live (`connecting`/`reconnecting`/`pairingRequired`),
the whole control area is dimmed and input-absorbed rather than replaced
by a full-screen spinner, so the layout doesn't jump during a brief
hiccup.

## Components (`lib/core/design/widgets/` and per-feature `widgets/`)

Shared, cross-feature (`core/design/widgets/`):

- `PressableScale` - the shared press feedback (1.0 -> 0.96 scale,
  spring back, gated haptic) every remote control button now uses.
- `AnimatedConnectionRing` - expanding/fading ring behind a TV icon
  during connecting/pairing.
- `DiscoveryRadar` - three staggered fading rings around a TV icon while
  scanning; cheap (no shaders/particles), stops entirely once discovery
  finishes.
- `SectionHeader` - shared uppercase-weight list section label (used by
  Settings and Devices).

Feature-scoped:

- `DpadControl` / `TouchpadSurface` - the two Remote Layout options.
  `TouchpadSurface` translates swipe gestures into discrete `dpad*`
  commands (there is no raw pointer command in any `TvCommandKey`
  vocabulary - see its doc comment) with a touch-position glow.
- `RemoteActionButton` - circular icon(+label) button, press-and-hold
  repeat, now built on `PressableScale` with a real accessibility label.
- `RemoteRocker` - physical-rocker-style pill for volume/channel
  (separate increase/decrease halves, hairline divider, optional slotted
  icon e.g. mute).
- `ConnectionStatusIndicator` - dot + label for `TvConnectionState`,
  pulses only while a state is actually in flux (`connecting`/
  `reconnecting`/`pairingRequired`).
- `TvDeviceCard` - device row for Discovery and the device switcher.
- `PairingCodeInput` - segmented PIN boxes wrapping a single hidden
  `TextField` (keeps native keyboard/autofill); exposes `shake()` for a
  rejected code, triggered by the pairing screen, not itself.
- `DeviceSwitcherSheet` - bottom sheet opened from the Remote header:
  current TV, other paired TVs, "Find another TV."
- `SecondaryControlsSheet` - the "More controls" bottom sheet for media,
  numeric keypad, and color keys.

## Accessibility

- Every remote control has a real `Semantics` label independent of its
  visible text (e.g. the mute button inside a rocker, D-pad directions:
  "Navigate Up/Down/Left/Right", "Select").
- Touch targets stay at or above `AppControlSize.minTouchTarget` (48px).
- Reduced-motion and haptics are both real, wired settings, not
  decorative toggles - see "Motion system" above.

## Golden tests

Not added in this pass. Recommended strategy when picked up: pin
`Welcome` (dark), `Remote` (dark, connected + full capabilities), and
`Settings` (dark) as goldens, generated on the same CI runner image that
will compare them (font rendering varies by platform/font availability,
which is the usual source of golden flakiness) - do not add goldens
generated locally and compared in a different CI environment.

## Not yet built

A bundled display typeface (still platform default). Google Cast,
Samsung, LG, Roku, Fire TV screens - out of scope until their providers
exist, per the roadmap.
