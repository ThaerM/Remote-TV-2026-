import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/application/settings_controller.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class RemoteTvApp extends ConsumerWidget {
  const RemoteTvApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      settingsControllerProvider.select((state) => state.themeMode),
    );

    return MaterialApp.router(
      title: 'Remote TV 2026',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
