import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routing/app_router.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../tv/application/tv_session_controller.dart';
import '../../../devices/application/paired_android_tv_controller.dart';
import '../../../discovery/presentation/widgets/tv_device_card.dart';

/// Bottom sheet opened by tapping the device name in the Remote header:
/// shows the currently connected TV, other previously-paired TVs (no
/// credentials shown, just name/host), and a way to find another one.
class DeviceSwitcherSheet extends ConsumerWidget {
  const DeviceSwitcherSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => const DeviceSwitcherSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final pairedDevices = ref.watch(pairedAndroidTvDevicesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current TV', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (session.selectedDevice != null)
              TvDeviceCard(
                device: session.selectedDevice!,
                statusLabel: session.isConnected ? 'Connected' : 'Available',
                onTap: () => Navigator.of(context).pop(),
              ),
            const SizedBox(height: AppSpacing.lg),
            pairedDevices.maybeWhen(
              data: (devices) {
                final others = devices
                    .where((d) => d.deviceId != session.selectedDevice?.id)
                    .toList();
                if (others.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Other paired TVs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final device in others)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.tv_rounded),
                            title: Text(device.name),
                            subtitle: const Text('Offline'),
                            onTap: () {
                              Navigator.of(context).pop();
                              // Pushed, not go(): this is a child flow off
                              // Remote, so Back returns here instead of
                              // relying on Discovery's no-caller fallback.
                              context.push(AppRoutes.discovery);
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(AppRoutes.discovery);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Find another TV'),
            ),
          ],
        ),
      ),
    );
  }
}
