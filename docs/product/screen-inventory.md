# Screen Inventory

## First-run journey

1. **Welcome** (`WelcomeScreen`) - product intro, explains the local-network
   requirement before asking for anything.
2. **Discovery** (`DiscoveryScreen`) - scans every registered provider;
   shows a scanning state, a device list, or an empty state with
   rescan/troubleshooting guidance.
3. **Pairing** (`PairingScreen`) - handles both `TvPinPairingRequest` (user
   types a code) and `TvConfirmOnDevicePairingRequest` (user confirms on
   the TV) via the shared `TvPairingRequest` sealed type.
4. **Remote** - on successful pairing, the user lands directly on the main
   Remote screen.

## Main navigation (bottom tabs, `AppShell`)

- **Remote** (`RemoteScreen`) - the primary control surface. See
  `docs/design/design-system.md` for the control hierarchy.
- **Cast** (`CastScreen`) - casting entry point, capability-gated on
  `TvCapabilities.casting`. Full Cast session UI lands in Phase 2.
- **Devices** (`DevicesScreen`) - the current session's connected device,
  plus a path back to Discovery. Saved/recent TVs are a follow-up
  (requires persistence beyond process lifetime).
- **Settings** (`SettingsScreen`) - appearance, remote sub-settings,
  developer mode toggle, about.

## Settings sub-screens

- **Remote Layout** (`RemoteLayoutSettingsScreen`) - D-pad vs. touchpad
  navigation style.
- **Remote Behavior** (`RemoteBehaviorSettingsScreen`) - haptics, keep
  screen awake, press-and-hold repeat.
- **Diagnostics** (`DiagnosticsScreen`) - read-only session state dump for
  debugging a provider without a separate tool.

## Deferred to later phases

Saved TVs list, connection history, app favorites/reordering, manual IP
entry, Wake-on-LAN toggle, macros/scenes editor, About/FAQ/Privacy/Terms
content screens (currently a single line in Settings). None of these were
skipped by oversight - they either need persistence work Phase 0
intentionally doesn't include, or depend on a real provider existing
first.
