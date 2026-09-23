import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation control style for the primary remote surface.
enum RemoteNavigationStyle { dpad, touchpad }

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.dark,
    this.navigationStyle = RemoteNavigationStyle.dpad,
    this.hapticFeedbackEnabled = true,
    this.keepScreenAwake = true,
    this.commandRepeatEnabled = true,
    this.developerModeEnabled = false,
    this.theaterModeEnabled = false,
  });

  final ThemeMode themeMode;
  final RemoteNavigationStyle navigationStyle;
  final bool hapticFeedbackEnabled;
  final bool keepScreenAwake;
  final bool commandRepeatEnabled;
  final bool developerModeEnabled;

  /// Reduces the Remote screen's decorative glow/ring effects and
  /// deepens surfaces for low-light use - see docs/design/design-system.md
  /// ("Theater mode"). Does not touch system brightness.
  final bool theaterModeEnabled;

  SettingsState copyWith({
    ThemeMode? themeMode,
    RemoteNavigationStyle? navigationStyle,
    bool? hapticFeedbackEnabled,
    bool? keepScreenAwake,
    bool? commandRepeatEnabled,
    bool? developerModeEnabled,
    bool? theaterModeEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      navigationStyle: navigationStyle ?? this.navigationStyle,
      hapticFeedbackEnabled:
          hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      commandRepeatEnabled: commandRepeatEnabled ?? this.commandRepeatEnabled,
      developerModeEnabled: developerModeEnabled ?? this.developerModeEnabled,
      theaterModeEnabled: theaterModeEnabled ?? this.theaterModeEnabled,
    );
  }
}

/// Holds app preferences for this foundation phase.
///
/// Persistence beyond process lifetime (e.g. SharedPreferences) is a
/// follow-up task - see docs/product/feature-roadmap.md. Pairing secrets
/// never belong here; those go through `SecureCredentialStore`.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState());

  void setThemeMode(ThemeMode mode) => state = state.copyWith(themeMode: mode);

  void setNavigationStyle(RemoteNavigationStyle style) =>
      state = state.copyWith(navigationStyle: style);

  void setHapticFeedbackEnabled(bool enabled) =>
      state = state.copyWith(hapticFeedbackEnabled: enabled);

  void setKeepScreenAwake(bool enabled) =>
      state = state.copyWith(keepScreenAwake: enabled);

  void setCommandRepeatEnabled(bool enabled) =>
      state = state.copyWith(commandRepeatEnabled: enabled);

  void setDeveloperModeEnabled(bool enabled) =>
      state = state.copyWith(developerModeEnabled: enabled);

  void setTheaterModeEnabled(bool enabled) =>
      state = state.copyWith(theaterModeEnabled: enabled);
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
      return SettingsController();
    });
