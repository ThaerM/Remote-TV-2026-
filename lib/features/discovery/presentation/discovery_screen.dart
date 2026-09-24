import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/discovery_radar.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import 'discovery_issue_copy.dart';
import 'widgets/add_tv_by_address_sheet.dart';
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
      appBar: AppBar(
        title: const Text('Find your TV'),
        // Reached from Welcome with nothing underneath: Back still leads
        // into the app rather than trapping the user here.
        // Navigator (not GoRouter.canPop): go_router pushes onto the same
        // Navigator, and this must render correctly with no router in
        // context too (widget tests mount this screen standalone).
        leading: Navigator.of(context).canPop()
            ? null
            : BackButton(onPressed: () => context.go(AppRoutes.remote)),
      ),
      body: session.isDiscovering
          ? const _ScanningState()
          : session.discoveredDevices.isEmpty
          ? _EmptyState(
              copy: DiscoveryIssueCopy.forIssue(session.discoveryIssue),
              onRescan: () =>
                  ref.read(tvSessionControllerProvider.notifier).discover(),
              onAddByAddress: () => AddTvByAddressSheet.show(context),
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
      itemCount: devices.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == devices.length) {
          return TextButton.icon(
            onPressed: () => AddTvByAddressSheet.show(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Don't see your TV? Add it by IP address"),
          );
        }
        final device = devices[index];
        return _StaggeredEntrance(
          index: index,
          child: TvDeviceCard(
            device: device,
            // The platform name matters: a Google TV can appear twice, once
            // as a remote (Android TV) and once as a Cast target.
            statusLabel: device.isDevelopmentFake
                ? 'Demo device · not a real TV'
                : device.platform.displayName,
            onTap: () async {
              await ref
                  .read(tvSessionControllerProvider.notifier)
                  .connect(device);
              if (!context.mounted) return;
              final session = ref.read(tvSessionControllerProvider);
              final error = session.lastError;
              if (error != null && session.pairingRequest == null) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              // Devices without a pairing step (Roku, Google Cast) are
              // already connected here; the pairing screen only reacts to
              // changes, so it would never move on for them.
              if (session.isConnected) {
                context.go(AppRoutes.connectedSuccess);
              } else {
                // Pushed, so Back returns here and cancels the pairing.
                unawaited(context.push(AppRoutes.pairing));
              }
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

  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Reduced motion: cards appear in place, no fade/slide.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
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
  const _EmptyState({
    required this.copy,
    required this.onRescan,
    required this.onAddByAddress,
  });

  final DiscoveryIssueCopy copy;
  final VoidCallback onRescan;
  final VoidCallback onAddByAddress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              copy.icon,
              size: 56,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              copy.title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(copy.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan again'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: onAddByAddress,
              child: const Text('Add TV by IP address'),
            ),
          ],
        ),
      ),
    );
  }
}
