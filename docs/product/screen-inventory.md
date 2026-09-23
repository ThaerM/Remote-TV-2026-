# Screen Inventory

## First-run journey

1. **Welcome** (`WelcomeScreen`) - product intro, explains the local-network
   requirement before asking for anything.
2. **Discovery** (`DiscoveryScreen`) - scans every registered provider;
   shows a radar scanning state (`DiscoveryRadar`), a device list with
   staggered card entrance, or an empty state whose wording comes from the
   scan's `TvDiscoveryIssue` (local network denied, not on Wi-Fi, search
   restricted, timed out, failed, or simply none found). Both the list and
   the empty state offer **Add TV by IP address** (`AddTvByAddressSheet`),
   which asks every provider to probe the address.
3. **Pairing** (`PairingScreen`) - handles both `TvPinPairingRequest`
   (segmented `PairingCodeInput`, shakes on a rejected code) and
   `TvConfirmOnDevicePairingRequest` (user confirms on the TV) via the
   shared `TvPairingRequest` sealed type.
4. **Connected Success** (`ConnectedSuccessScreen`) - brief success state
   (animated check) shown once pairing completes, with "Go to Remote"
   and "Manage Device" (-> Devices).
5. **Remote** - reached from Connected Success, or directly on reconnect.

## Main navigation (bottom tabs, `AppShell`)

- **Remote** (`RemoteScreen`) - the primary control surface. See
  `docs/design/design-system.md` for the control hierarchy.
- **Cast** (`CastScreen`) - casting entry point, capability-gated on
  `TvCapabilities.casting`. Deliberately shown as a disabled/coming-soon
  state, not a production-ready surface, until Phase 2 implements Cast.
- **Devices** (`DevicesScreen`) - the current session's connected device,
  paired Android TVs (with Forget), and a path back to Discovery.
- **Settings** (`SettingsScreen`) - grouped: Current TV, Appearance,
  Remote (layout/behavior/theater mode), Devices, Advanced (diagnostics,
  developer mode), Application (Help/Feedback/About/Privacy/Legal -
  static informational tiles, no real backend behind them yet).

Not a bottom-nav tab: **Apps** (`AppsScreen`, pushed from the Remote
screen's quick-apps row via "See all") - a full grid of whatever
`TvProvider.getApplications()` actually returned. Considered for the
bottom nav per the design brief, but adding a 5th tab would touch
`AppShell`'s destination list and every test that asserts against it for
comparatively little benefit while the app only has 4 primary
destinations worth persistent nav real estate - revisit once
Cast/Devices/Settings have enough of their own depth that Apps
competing for a tab slot is clearly justified.

## Settings sub-screens

- **Remote Layout** (`RemoteLayoutSettingsScreen`) - D-pad vs. touchpad
  navigation style; both are real, implemented surfaces (see
  `DpadControl` / `TouchpadSurface`), switchable from Settings or
  directly from the Remote screen.
- **Remote Behavior** (`RemoteBehaviorSettingsScreen`) - haptics, keep
  screen awake, press-and-hold repeat.
- **Diagnostics** (`DiagnosticsScreen`) - read-only session state dump for
  debugging a provider without a separate tool.

## Remote screen sub-surfaces

- **Device switcher** (`DeviceSwitcherSheet`) - bottom sheet opened by
  tapping the device name in the Remote header: current TV, other
  paired TVs (name/host only, no credentials), "Find another TV."
- **Keyboard** (bottom sheet in `RemoteScreen`) - native text field,
  Send button, "Sent" confirmation. Not a dedicated route or a
  hand-rolled keyboard - the platform keyboard handles actual input.
- **More controls** (`SecondaryControlsSheet`) - media transport,
  numeric keypad, color keys.

## Deferred to later phases

Saved TVs' per-device layout/shortcut preferences, connection history,
app favorites/reordering, Wake-on-LAN toggle,
macros/scenes editor, and real backing content for the Application
section's Help/Feedback/Privacy/Legal tiles. None of these were skipped
by oversight - they either need persistence work beyond this phase's
scope, or depend on a real provider/content source existing first.
