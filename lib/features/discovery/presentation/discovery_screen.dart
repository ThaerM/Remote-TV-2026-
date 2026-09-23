import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/discovery_radar.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import 'widgets/tv_device_card.dart';

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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DiscoveryRadar(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Scanning your network for TVs…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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
        return _StaggeredEntrance(
          index: index,
          child: TvDeviceCard(
            device: device,
            statusLabel: device.isDevelopmentFake
                ? 'Demo device · not a real TV'
                : 'Ready to pair',
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

/// Fades and slides each card in with a small per-item delay, so the
/// list feels alive without a heavyweight animation framework.
class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.connection,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 6));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: AppMotion.enter);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 16),
            child: child,
          ),
        );
      },
      child: widget.child,
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
