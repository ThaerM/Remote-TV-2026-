/// Spacing scale in logical pixels. Use these instead of literal numbers
/// so remote-control layouts stay consistent and easy to retune.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radius scale.
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 14;
  static const double lg = 20;
  static const double pill = 999;
}

/// Standard control (button) dimensions for the remote, sized for reliable
/// thumb targets rather than generic Material defaults.
class AppControlSize {
  const AppControlSize._();

  static const double primaryButton = 64;
  static const double secondaryButton = 52;
  static const double dpadDiameter = 220;
  static const double minTouchTarget = 48;
}

/// Motion durations, kept short so button presses feel instant.
class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);
}
