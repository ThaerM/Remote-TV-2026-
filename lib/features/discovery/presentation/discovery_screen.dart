import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/discovery_radar.dart';
import '../../../core/design/widgets/section_header.dart';
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
    // Navigator (not GoRouter.canPop): go_router pushes onto the same
    // Navigator, and this must render correctly with no router in
    // context too (widget tests mount this screen standalone).
    final canPop = Navigator.of(context).canPop();

    return PopScope(
      // Reached from Welcome with nothing underneath: the system back
      // gesture/button must still leave into the app rather than trapping
      // (or exiting) from here, exactly like the visible Back button does.
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.remote);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find your TV'),
          leading: canPop
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
      ),
    );
  }
}

class _ScanningState extends StatelessWidget {
  const _ScanningState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Looking for TVs nearby',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Make sure your TV and phone are on the same Wi-Fi network.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          // The radar itself communicates "still scanning" continuously,
          // so it - not a spinner - carries the waiting state; this
          // section just frames it with real context above.
          const Expanded(child: Center(child: DiscoveryRadar())),
        ],
      ),
    );
  }
}

class _DeviceList extends ConsumerWidget {
  const _DeviceList({required this.devices});

  final List<TvDevice> devices;

  /// Only for an ungrouped device or a demo device - a grouped physical
  /// TV shows [_capabilityBadges] instead. Never invented: the plain
  /// platform name a lone Roku/Cast/Android TV card always showed.
  static String _statusLabel(PhysicalTvDevice physical) {
    if (physical.isDevelopmentFake) return 'Demo device · not a real TV';
    return physical.primary.platform.displayName;
  }

  /// "Remote", "Cast", or both - never invented, only what the grouped
  /// endpoints actually are, and never a raw protocol/service name.
  static List<String>? _capabilityBadges(PhysicalTvDevice physical) {
    if (!physical.isGrouped) return null;
    return [if (physical.hasRemote) 'Remote', if (physical.hasCast) 'Cast'];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grouped fresh from the flat list on every build: a pure function of
    // already-atomic discovery results (the registry only ever replaces
    // `discoveredDevices` all at once - see TvSessionController.discover),
    // so a rescan can't flicker a card between grouped and split.
    final physicalDevices = PhysicalTvDevice.group(devices);
    return Column(
      children: [
        SectionHeader(
          physicalDevices.length == 1
              ? '1 TV found nearby'
              : '${physicalDevices.length} TVs found nearby',
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            itemCount: physicalDevices.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index == physicalDevices.length) {
                return TextButton.icon(
                  onPressed: () => AddTvByAddressSheet.show(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Don't see your TV? Add it by IP address"),
                );
              }
              final physical = physicalDevices[index];
              return _StaggeredEntrance(
                index: index,
                child: TvDeviceCard(
                  device: physical.primary,
                  statusLabel: _statusLabel(physical),
                  capabilityBadges: _capabilityBadges(physical),
                  onTap: () async {
                    // Hides the protocol choice: connects with the remote
                    // endpoint when this physical TV has one (Android TV,
                    // Roku, ...), the cast endpoint otherwise. Providers stay
                    // untouched - this only picks which single TvDevice
                    // TvSessionController.connect gets, exactly as before
                    // grouping existed.
                    await ref
                        .read(tvSessionControllerProvider.notifier)
                        .connect(physical.primary);
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
          ),
        ),
      ],
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
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // A soft glow behind the icon, not a bare glyph on black -
            // this "found nothing yet" state should feel like a designed
            // resting state, not a broken/blank screen.
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glow.withValues(alpha: 0.16),
                    AppColors.glow.withValues(alpha: 0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                copy.icon,
                size: 40,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              copy.title,
              style: theme.textTheme.headlineMedium,
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
