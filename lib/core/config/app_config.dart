/// Compile-time app configuration, set via `--dart-define` at build/run
/// time. Kept separate from `core/design` and `core/storage` since this
/// is build configuration, not a design token or a storage abstraction.
library;

/// Whether `FakeTvProvider`'s demo devices ("Living Room Google TV",
/// "Bedroom Samsung TV", "Office LG TV") are registered and discoverable.
///
/// Defaults to `false` so a normal `flutter run` against a real TV never
/// shows demo devices mixed in with real discovery results - see
/// `docs/architecture/provider-system.md`. Deliberately not gated on
/// `kDebugMode`: debug builds are used for real-device testing too (e.g.
/// running on a physical iPhone against a real TV), so debug-vs-release
/// must not be conflated with real-vs-demo devices.
///
/// Enable for UI development, screenshots, and demos:
///
/// ```
/// flutter run --dart-define=ENABLE_DEMO_TV_DEVICES=true
/// ```
const bool kEnableDemoTvDevices = bool.fromEnvironment(
  'ENABLE_DEMO_TV_DEVICES',
);
