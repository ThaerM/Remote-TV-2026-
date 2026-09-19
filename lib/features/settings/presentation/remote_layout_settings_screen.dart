import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';

class RemoteLayoutSettingsScreen extends ConsumerWidget {
  const RemoteLayoutSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Remote layout')),
      body: RadioGroup<RemoteNavigationStyle>(
        groupValue: settings.navigationStyle,
        onChanged: (style) => notifier.setNavigationStyle(style!),
        child: ListView(
          children: [
            RadioListTile<RemoteNavigationStyle>(
              title: Text('D-pad'),
              subtitle: Text('Discrete directional buttons'),
              value: RemoteNavigationStyle.dpad,
            ),
            RadioListTile<RemoteNavigationStyle>(
              title: Text('Touchpad'),
              subtitle: Text('Swipe to move the on-screen cursor'),
              value: RemoteNavigationStyle.touchpad,
            ),
          ],
        ),
      ),
    );
  }
}
