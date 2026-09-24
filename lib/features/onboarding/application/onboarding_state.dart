import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the user has been through Welcome once. Only this flag is
/// persisted - never "must connect a TV" - so later launches open the app
/// directly, with or without a TV.
class OnboardingStore {
  OnboardingStore({Future<SharedPreferences>? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance();

  static const _completedKey = 'onboarding.completed';

  final Future<SharedPreferences> _preferences;

  Future<bool> isCompleted() async =>
      (await _preferences).getBool(_completedKey) ?? false;

  Future<void> markCompleted() async =>
      (await _preferences).setBool(_completedKey, true);
}

final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => OnboardingStore(),
);

/// Read once at startup (see `bootstrap`) to choose the first screen.
final onboardingCompletedAtLaunchProvider = Provider<bool>((ref) => false);
