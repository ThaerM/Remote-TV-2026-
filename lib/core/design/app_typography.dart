import 'package:flutter/widgets.dart';

/// Type scale for the app. Uses the platform default font family so the
/// app never depends on a licensed/bundled font for this foundation.
class AppTypography {
  const AppTypography._();

  static const String? fontFamily = null;

  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.1,
    letterSpacing: 0.1,
  );
}
