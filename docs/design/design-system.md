# Design System

Original design system for Remote TV 2026. Dark is the default and
primary mode; light and system are fully supported. The goal is a
premium, near-black surface - not Material's default dark grey - and a
remote that feels like a physical controller rather than a settings form.

## Tokens (`lib/core/design/`)

- `AppColors` - brand (`brandPrimary` signal green, `brandSecondary`
  control blue), dark/light surface scales, semantic colors
  (success/warning/danger, connection-state colors).
- `AppTypography` - a compact type scale (display, headline, title, body,
  bodyStrong, caption, buttonLabel), platform default font family for
  this foundation (no bundled/licensed font dependency yet).
- `AppSpacing` - 4/8/16/24/32/48 scale.
- `AppRadius` - sm/md/lg/pill corner radii.
- `AppControlSize` - `primaryButton` (64), `secondaryButton` (52),
  `dpadDiameter` (220), `minTouchTarget` (48) - sized for reliable thumb
  targets on a remote, not generic Material defaults.
- `AppMotion` - fast/normal/slow durations, kept short so button presses
  feel instant.

## Theme (`lib/app/theme/app_theme.dart`)

Builds Material 3 `ThemeData` from the tokens above for both brightness
modes, plus an `AppSurfaceColors` `ThemeExtension` exposing the raw
surface/border/text tokens that don't map cleanly onto `ColorScheme`, so
widgets read `Theme.of(context).extension<AppSurfaceColors>()` instead of
importing `AppColors` directly wherever possible.

## Remote control hierarchy

The Remote screen (`RemoteScreen`) is deliberately not "every button on
one screen":

```
Top       Device selector, connection status dot, power (if supported)
Quick     Horizontal app shortcut row (if the device reports apps)
Primary   D-pad (capability-gated)
Actions   Home / Back / Menu / Keyboard / Voice (each capability-gated)
Volume/   Vertical +/- clusters with press-and-hold repeat
Channel
More      Bottom sheet: media transport, numeric keypad, color keys
```

Every group in this hierarchy is conditionally rendered from
`TvCapabilities` - see `docs/architecture/provider-system.md#capability-driven-design`.

## Components

- `DpadControl` - circular five-button cluster (`lib/features/remote/presentation/widgets/dpad_control.dart`).
- `RemoteActionButton` - circular icon+label button with optional
  press-and-hold repeat, used for Home/Back/Menu/Volume/Channel.
- `SecondaryControlsSheet` - the "More controls" bottom sheet for media,
  numeric keypad, and color keys.

## Not yet built

A dedicated touchpad navigation surface (Settings > Remote Layout already
exposes the *preference*, but the D-pad is the only implemented control
today - touchpad rendering is a follow-up), and a bundled display
typeface. Both are foundation-appropriate gaps, not oversights.
