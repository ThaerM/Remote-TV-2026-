import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:remote_tv_2026/features/about/presentation/about_screen.dart';

void main() {
  testWidgets('shows the developer, links, and the installed version', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
      appName: 'Remote TV 2026',
      packageName: 'com.thaerm.remotetv2026',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AboutScreen())),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Remote TV 2026'), findsOneWidget);
    expect(find.text('Version 1.0.0 (7)'), findsOneWidget);
    expect(find.text('Thaer Mosa'), findsOneWidget);
    expect(find.text('https://thaerm.github.io/'), findsOneWidget);
    expect(find.text('https://github.com/ThaerM'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Open Source Licenses'), findsOneWidget);
  });
}
