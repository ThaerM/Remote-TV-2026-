import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remote_tv_2026/app/theme/app_theme.dart';
import 'package:remote_tv_2026/features/casting/presentation/cast_screen.dart';
import 'package:remote_tv_2026/features/devices/application/paired_android_tv_controller.dart';
import 'package:remote_tv_2026/features/devices/presentation/devices_screen.dart';
import 'package:remote_tv_2026/features/discovery/presentation/discovery_screen.dart';
import 'package:remote_tv_2026/features/onboarding/presentation/welcome_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/connected_success_screen.dart';
import 'package:remote_tv_2026/features/pairing/presentation/pairing_screen.dart';
import 'package:remote_tv_2026/features/remote/presentation/remote_screen.dart';
import 'package:remote_tv_2026/features/settings/application/settings_controller.dart';
import 'package:remote_tv_2026/features/settings/presentation/settings_screen.dart';
import 'package:remote_tv_2026/tv/application/tv_session_controller.dart';
import 'package:remote_tv_2026/tv/domain/tv_domain.dart';
import 'package:remote_tv_2026/tv/providers/registry/tv_provider_registry.dart';
import 'package:remote_tv_2026/tv/providers/tv_provider_registry_provider.dart';

import '../tv/stub_tv_provider.dart';

// Regenerate with: flutter test --update-goldens test/goldens
//
// Deterministic by construction: text renders in flutter_test's Ahem font
// (no system fonts), reduced motion is on (ambient animations render
// their static form), and the device size/pixel ratio is fixed.

const _familyRoomTv = TvDevice(
  id: 'android_tv:Android_9ca7.local',
  name: 'Family room TV',
  platform: TvPlatform.androidTv,
  host: '192.168.1.42',
);

const _allCaps = TvCapabilities(
  power: true,
  volume: true,
  mute: true,
  channel: true,
  dpad: true,
  keyboard: true,
  mediaControls: true,
  numericKeypad: true,
  launchApps: true,
);

final _connected = TvSessionState(
  selectedDevice: _familyRoomTv,
  connectionState: TvConnectionState.connected,
  capabilities: _allCaps,
  applications: const [
    TvApplication(id: 'netflix', name: 'Netflix'),
    TvApplication(id: 'youtube', name: 'YouTube'),
  ],
);

class _Session extends TvSessionController {
  _Session(super.ref, TvSessionState initial) {
    state = initial;
  }
}

class _Settings extends SettingsController {
  _Settings(SettingsState initial) {
    state = initial;
  }
}

Future<void> _golden(
  WidgetTester tester,
  String name,
  Widget screen, {
  TvSessionState? session,
  SettingsState settings = const SettingsState(),
  TvProviderRegistry? registry,
  Brightness brightness = Brightness.dark,
}) async {
  tester.view
    ..physicalSize = const Size(393, 852)
    ..devicePixelRatio = 1;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (session != null)
          tvSessionControllerProvider.overrideWith(
            (ref) => _Session(ref, session),
          ),
        settingsControllerProvider.overrideWith((ref) => _Settings(settings)),
        tvProviderRegistryProvider.overrideWithValue(
          registry ?? TvProviderRegistry(const []),
        ),
        pairedAndroidTvDevicesProvider.overrideWith((ref) async => const []),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: screen,
      ),
    ),
  );
  // Fixed pumps, never pumpAndSettle: some indicators repeat by design.
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }

  await expectLater(
    find.byWidget(screen),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('welcome', (tester) async {
    await _golden(tester, 'welcome_dark', const WelcomeScreen());
  });

  testWidgets('discovery - no TVs, local network denied', (tester) async {
    await _golden(
      tester,
      'discovery_denied_dark',
      const DiscoveryScreen(),
      registry: TvProviderRegistry([
        StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: TvDiscoveryOutcome.issue(
            TvDiscoveryIssue.localNetworkDenied,
          ),
        ),
      ]),
    );
  });

  testWidgets('discovery - found', (tester) async {
    await _golden(
      tester,
      'discovery_found_dark',
      const DiscoveryScreen(),
      registry: TvProviderRegistry([
        StubTvProvider(
          platform: TvPlatform.androidTv,
          outcome: const TvDiscoveryOutcome(
            devices: [
              _familyRoomTv,
              TvDevice(
                id: 'cast:1',
                name: 'Family room TV',
                platform: TvPlatform.googleCast,
                host: '192.168.1.42',
              ),
              TvDevice(
                id: 'roku:1',
                name: 'Bedroom Roku',
                platform: TvPlatform.roku,
                host: '192.168.1.50',
              ),
            ],
          ),
        ),
      ]),
    );
  });

  testWidgets('discovery - scanning', (tester) async {
    await _golden(
      tester,
      'discovery_scanning_dark',
      const DiscoveryScreen(),
      registry: TvProviderRegistry([_NeverFinishes()]),
    );
  });

  testWidgets('pairing - PIN', (tester) async {
    await _golden(
      tester,
      'pairing_pin_dark',
      const PairingScreen(),
      session: const TvSessionState(
        selectedDevice: _familyRoomTv,
        connectionState: TvConnectionState.pairingRequired,
        pairingRequest: TvPinPairingRequest(expectedLength: 6),
      ),
    );
  });

  testWidgets('connected success', (tester) async {
    await _golden(
      tester,
      'connected_success_dark',
      const ConnectedSuccessScreen(),
      session: _connected,
    );
  });

  testWidgets('remote - D-pad, dark', (tester) async {
    await _golden(
      tester,
      'remote_dpad_dark',
      const RemoteScreen(),
      session: _connected,
    );
  });

  testWidgets('remote - D-pad, light', (tester) async {
    await _golden(
      tester,
      'remote_dpad_light',
      const RemoteScreen(),
      session: _connected,
      brightness: Brightness.light,
    );
  });

  testWidgets('remote - touchpad', (tester) async {
    await _golden(
      tester,
      'remote_touchpad_dark',
      const RemoteScreen(),
      session: _connected,
      settings: const SettingsState(
        navigationStyle: RemoteNavigationStyle.touchpad,
      ),
    );
  });

  testWidgets('devices', (tester) async {
    await _golden(
      tester,
      'devices_dark',
      const DevicesScreen(),
      session: _connected,
    );
  });

  testWidgets('settings - dark', (tester) async {
    await _golden(
      tester,
      'settings_dark',
      const SettingsScreen(),
      session: _connected,
    );
  });

  testWidgets('settings - light', (tester) async {
    await _golden(
      tester,
      'settings_light',
      const SettingsScreen(),
      session: _connected,
      brightness: Brightness.light,
    );
  });

  testWidgets('cast - ready to cast', (tester) async {
    await _golden(
      tester,
      'cast_dark',
      const CastScreen(),
      session: TvSessionState(
        selectedDevice: _familyRoomTv.copyWith(platform: TvPlatform.googleCast),
        connectionState: TvConnectionState.connected,
        capabilities: const TvCapabilities(casting: true, volume: true),
        mediaStatus: const TvMediaStatus(
          playerState: TvPlayerState.paused,
          position: Duration(minutes: 3, seconds: 12),
          duration: Duration(minutes: 9, seconds: 56),
          title: 'Big Buck Bunny',
        ),
      ),
    );
  });
}

/// A scan that stays in progress, for the scanning-state golden.
class _NeverFinishes extends StubTvProvider {
  _NeverFinishes() : super(platform: TvPlatform.androidTv);

  @override
  Future<TvDiscoveryOutcome> discover() =>
      Completer<TvDiscoveryOutcome>().future;
}
