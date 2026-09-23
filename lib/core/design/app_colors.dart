import 'package:flutter/widgets.dart';

/// Design tokens for color. Dark is the app's primary, default mode: a
/// premium near-black surface rather than Material's default dark grey.
class AppColors {
  const AppColors._();

  // Brand
  static const Color brandPrimary = Color(0xFF3DDC97); // signal green
  static const Color brandSecondary = Color(0xFF5B8CFF); // control blue

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0A0B0D);
  static const Color darkSurface = Color(0xFF16181C);
  static const Color darkSurfaceRaised = Color(0xFF1F2227);
  static const Color darkBorder = Color(0xFF2A2D33);
  static const Color darkTextPrimary = Color(0xFFF4F5F7);
  static const Color darkTextSecondary = Color(0xFFA3A8B2);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF5F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceRaised = Color(0xFFF0F1F4);
  static const Color lightBorder = Color(0xFFE0E2E7);
  static const Color lightTextPrimary = Color(0xFF14161A);
  static const Color lightTextSecondary = Color(0xFF5B6068);

  // Semantic
  static const Color success = Color(0xFF3DDC97);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFE5484D);
  static const Color connected = Color(0xFF3DDC97);
  static const Color connecting = Color(0xFFF5A623);
  static const Color reconnecting = Color(0xFF5B8CFF);
  static const Color disconnected = Color(0xFF6B7078);

  /// Ambient/ring-glow accent used behind the Welcome mark, the
  /// discovery radar, and connection rings - a soft cyan-blue rather
  /// than the brand green, so "searching" and "connected" read as
  /// visually distinct states. Always used at low alpha (see
  /// `AppMotion` callers) - never a solid fill.
  static const Color glow = Color(0xFF4FD1FF);
}
