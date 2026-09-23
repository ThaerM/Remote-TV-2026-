import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/section_header.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../application/paired_android_tv_controller.dart';

/// Shows the currently connected device, plus any Android TVs paired in
/// a previous session, and lets the user disconnect, forget, or find
/// another TV. Connection history and per-TV renaming are a follow-up -
/// see docs/product/feature-roadmap.md.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final notifier = ref.read(tvSessionControllerProvider.notifier);
    final pairedDevices = ref.watch(pairedAndroidTvDevicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader('Connected'),
          if (session.isConnected && session.selectedDevice != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.tv_rounded),
                title: Text(session.selectedDevice!.name),
                subtitle: Text(session.selectedDevice!.platform.displayName),
                trailing: TextButton(
                  onPressed: notifier.disconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.tv_off_rounded),
                title: const Text('No TV connected'),
                trailing: TextButton(
                  onPressed: () => context.go(AppRoutes.discovery),
                  child: const Text('Find a TV'),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Paired Android TVs'),
          pairedDevices.when(
            data: (devices) => devices.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text('No Android TVs paired yet.'),
                  )
                : Column(
                    children: [
                      for (final device in devices)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.tv_rounded),
                            title: Text(device.name),
                            subtitle: Text(
                              'Last seen at ${device.lastKnownHost}',
                            ),
                            trailing: TextButton(
                              onPressed: () => ref.read(
                                forgetAndroidTvDeviceProvider,
                              )(device.deviceId),
                              child: const Text('Forget'),
                            ),
                          ),
                        ),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),
            error: (error, stackTrace) =>
                Text('Could not load paired TVs: $error'),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.discovery),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add another TV'),
          ),
        ],
      ),
    );
  }
}
