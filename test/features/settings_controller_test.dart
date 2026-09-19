import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/features/settings/application/settings_controller.dart';

void main() {
  group('SettingsController', () {
    test('defaults to dark theme and D-pad navigation', () {
      final controller = SettingsController();

      expect(controller.state.themeMode, ThemeMode.dark);
      expect(controller.state.navigationStyle, RemoteNavigationStyle.dpad);
    });

    test('setThemeMode updates state', () {
      final controller = SettingsController();

      controller.setThemeMode(ThemeMode.light);

      expect(controller.state.themeMode, ThemeMode.light);
    });

    test('setNavigationStyle updates state', () {
      final controller = SettingsController();

      controller.setNavigationStyle(RemoteNavigationStyle.touchpad);

      expect(controller.state.navigationStyle, RemoteNavigationStyle.touchpad);
    });

    test('developer mode is off by default', () {
      final controller = SettingsController();

      expect(controller.state.developerModeEnabled, isFalse);

      controller.setDeveloperModeEnabled(true);

      expect(controller.state.developerModeEnabled, isTrue);
    });
  });
}
