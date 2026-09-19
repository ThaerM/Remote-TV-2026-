import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';

/// Scans every registered [TvProvider] and lists what was found. Handles
/// the empty-result state with actionable troubleshooting per
/// docs/product/screen-inventory.md.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(tvSessionControllerProvider.notifier).discover(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tvSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find your TV')),
      body: session.isDiscovering
          ? const _ScanningState()
          : session.discoveredDevices.isEmpty
          ? _EmptyState(
              onRescan: () =>
                  ref.read(tvSessionControllerProvider.notifier).discover(),
            )
          : _DeviceList(devices: session.discoveredDevices),
    );
  }
}

class _ScanningState extends StatelessWidget {
  const _ScanningState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSpacing.md),
          Text('Scanning your network for TVs…'),
        ],
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<TvDevice> devices;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: devices.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final device = devices[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.tv_rounded),
            title: Text(device.name),
            subtitle: device.isDevelopmentFake
                ? const Text('Demo device · not a real TV')
                : Text(device.platform.displayName),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              await ref
                  .read(tvSessionControllerProvider.notifier)
                  .connect(device);
              if (context.mounted) context.go(AppRoutes.pairing);
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRescan});

  final VoidCallback onRescan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_find_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No TVs found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Make sure your TV is powered on and your phone and TV are on the '
              'same Wi-Fi network.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Rescan'),
            ),
          ],
        ),
      ),
    );
  }
}
