import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// Builds the app's Material 3 [ThemeData] from the design tokens in
/// `core/design`. Dark is the default/primary theme - see
/// docs/design/design-system.md.
class AppTheme {
  const AppTheme._();

  static ThemeData dark() => _build(brightness: Brightness.dark);

  static ThemeData light() => _build(brightness: Brightness.light);

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;

    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surfaceRaised = isDark
        ? AppColors.darkSurfaceRaised
        : AppColors.lightSurfaceRaised;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brandPrimary,
      onPrimary: Colors.black,
      secondary: AppColors.brandSecondary,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      fontFamily: AppTypography.fontFamily,
      dividerColor: border,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headline.copyWith(color: textPrimary),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: textPrimary),
        headlineMedium: AppTypography.headline.copyWith(color: textPrimary),
        titleMedium: AppTypography.title.copyWith(color: textPrimary),
        bodyLarge: AppTypography.body.copyWith(color: textPrimary),
        bodyMedium: AppTypography.body.copyWith(color: textSecondary),
        labelLarge: AppTypography.buttonLabel.copyWith(color: textPrimary),
        bodySmall: AppTypography.caption.copyWith(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: surfaceRaised,
          foregroundColor: textPrimary,
          minimumSize: const Size.square(AppControlSize.minTouchTarget),
          shape: const CircleBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      extensions: [
        AppSurfaceColors(
          background: background,
          surface: surface,
          surfaceRaised: surfaceRaised,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ],
    );
  }
}

/// Theme extension exposing the raw surface tokens that don't map cleanly
/// onto [ColorScheme], so widgets can use `Theme.of(context).extension<...>`
/// instead of hardcoding [AppColors] directly.
class AppSurfaceColors extends ThemeExtension<AppSurfaceColors> {
  const AppSurfaceColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  @override
  AppSurfaceColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
  }) {
    return AppSurfaceColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
    );
  }

  @override
  AppSurfaceColors lerp(ThemeExtension<AppSurfaceColors>? other, double t) {
    if (other is! AppSurfaceColors) return this;
    return AppSurfaceColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
    );
  }
}
