import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/settings_controller.dart';

class RemoteBehaviorSettingsScreen extends ConsumerWidget {
  const RemoteBehaviorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Remote behavior')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Haptic feedback'),
            subtitle: const Text('Vibrate on button press'),
            value: settings.hapticFeedbackEnabled,
            onChanged: notifier.setHapticFeedbackEnabled,
          ),
          SwitchListTile(
            title: const Text('Keep screen awake'),
            subtitle: const Text(
              'Prevent the phone from sleeping while remote is open',
            ),
            value: settings.keepScreenAwake,
            onChanged: notifier.setKeepScreenAwake,
          ),
          SwitchListTile(
            title: const Text('Press-and-hold repeat'),
            subtitle: const Text('Repeat volume/channel while held'),
            value: settings.commandRepeatEnabled,
            onChanged: notifier.setCommandRepeatEnabled,
          ),
        ],
      ),
    );
  }
}
