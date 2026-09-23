import 'package:flutter/animation.dart';

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

/// Motion durations and curves, centralized so no widget hardcodes its
/// own timing - see docs/design/design-system.md ("Motion system").
class AppMotion {
  const AppMotion._();

  /// Button/D-pad press feedback. Must stay short: remote responsiveness
  /// (dispatching the command) is never gated on this finishing.
  static const Duration fast = Duration(milliseconds: 120);

  /// Small state changes (icon swaps, list item highlight).
  static const Duration normal = Duration(milliseconds: 220);

  /// Bottom sheets and panel open/close.
  static const Duration panel = Duration(milliseconds: 260);

  /// Connection-state transitions (pairing -> connected, screen
  /// transitions between onboarding steps).
  static const Duration connection = Duration(milliseconds: 350);

  static const Duration slow = Duration(milliseconds: 360);

  /// Standard easing for most UI motion - decelerates into place,
  /// avoids the bouncy/overshoot curves the design direction explicitly
  /// asked to avoid.
  static const Curve standard = Curves.easeOutCubic;

  /// For elements entering the screen (device cards, panels).
  static const Curve enter = Curves.easeOutCubic;

  /// For elements leaving/collapsing.
  static const Curve exit = Curves.easeInCubic;
}
