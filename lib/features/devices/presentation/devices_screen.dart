import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/section_header.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import '../../remote/presentation/widgets/connection_status_indicator.dart';
import '../application/paired_android_tv_controller.dart';
import '../../../tv/providers/android_tv/storage/android_tv_paired_device_store.dart';

/// Shows the currently connected device, plus any Android TVs paired in
/// a previous session, and lets the user disconnect, forget, or find
/// another TV. Connection history and per-TV renaming are a follow-up -
/// see docs/product/feature-roadmap.md.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  /// Reconnects using the saved identity/host - no rediscovery required -
  /// and only then decides where to go: straight to Remote when that
  /// identity is still trusted, or to Pairing only if the TV actually
  /// asks for a new code (e.g. it forgot this client).
  Future<void> _connectSaved(
    BuildContext context,
    WidgetRef ref,
    PairedAndroidTvMetadata device,
  ) async {
    final notifier = ref.read(tvSessionControllerProvider.notifier);
    await notifier.connect(
      TvDevice(
        id: device.deviceId,
        name: device.name,
        platform: TvPlatform.androidTv,
        host: device.lastKnownHost,
      ),
    );
    if (!context.mounted) return;
    final session = ref.read(tvSessionControllerProvider);
    if (session.isConnected) {
      context.go(AppRoutes.remote);
    } else if (session.pairingRequest != null) {
      unawaited(context.push(AppRoutes.pairing));
    } else if (session.lastError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(session.lastError!)));
    }
  }

  Future<void> _confirmForget(
    BuildContext context,
    WidgetRef ref,
    PairedAndroidTvMetadata device,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forget this TV?'),
        content: Text(
          "${device.name} will be removed from your saved TVs. You'll need "
          'to pair with it again to reconnect.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(forgetAndroidTvDeviceProvider)(device.deviceId);
    }
  }

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
            _DeviceCard(
              name: session.selectedDevice!.name,
              status: ConnectionStatusIndicator(state: session.connectionState),
              trailing: OutlinedButton(
                onPressed: notifier.disconnect,
                child: const Text('Disconnect'),
              ),
            )
          else
            _DeviceCard(
              name: 'No TV connected',
              icon: Icons.tv_off_rounded,
              status: Text(
                "You're not connected to a TV right now.",
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: FilledButton(
                onPressed: () => context.push(AppRoutes.discovery),
                child: const Text('Connect a TV'),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Paired Android TVs'),
          pairedDevices.when(
            data: (devices) => devices.isEmpty
                ? const _NoSavedDevicesState()
                : Column(
                    children: [
                      for (final device in devices)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _SavedDeviceCard(
                            device: device,
                            isLiveConnection:
                                session.selectedDevice?.id == device.deviceId &&
                                session.isConnected,
                            connectionState:
                                session.selectedDevice?.id == device.deviceId
                                ? session.connectionState
                                : null,
                            onConnect: () =>
                                _connectSaved(context, ref, device),
                            onForget: () =>
                                _confirmForget(context, ref, device),
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
          if (pairedDevices.valueOrNull?.isNotEmpty ?? false) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => context.push(AppRoutes.discovery),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add another TV'),
            ),
          ],
        ],
      ),
    );
  }
}

/// A single rounded, bordered surface - the same card language Welcome/
/// Discovery/Remote/Cast already use - instead of a plain Material
/// [Card]+[ListTile].
class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.name,
    required this.status,
    required this.trailing,
    this.icon = Icons.tv_rounded,
  });

  final String name;
  final IconData icon;
  final Widget status;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaces?.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                status,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          trailing,
        ],
      ),
    );
  }
}

/// A saved Android TV: Connect is the clear primary action, hidden
/// entirely (not just disabled) once this is the live connection - per
/// the design brief's preferred "Connected status + no Connect button"
/// treatment. Forget stays available but visually secondary/destructive,
/// and always confirms before removing anything.
class _SavedDeviceCard extends StatelessWidget {
  const _SavedDeviceCard({
    required this.device,
    required this.isLiveConnection,
    required this.connectionState,
    required this.onConnect,
    required this.onForget,
  });

  final PairedAndroidTvMetadata device;
  final bool isLiveConnection;

  /// Set only when this saved device is the one the session currently
  /// has selected (connected, reconnecting, connecting, ...) - null
  /// means "not this one," shown as its last-known host instead.
  final TvConnectionState? connectionState;
  final VoidCallback onConnect;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaces?.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isLiveConnection
              ? AppColors.connected.withValues(alpha: 0.4)
              : surfaces?.border ?? theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.tv_rounded, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      device.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (connectionState != null)
                      ConnectionStatusIndicator(state: connectionState!)
                    else
                      Text(
                        'Last seen at ${device.lastKnownHost}',
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (!isLiveConnection) ...[
                const SizedBox(width: AppSpacing.sm),
                FilledButton.tonal(
                  onPressed: onConnect,
                  child: const Text('Connect'),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForget,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: const Text('Forget'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium empty state for "no saved TVs" - the same icon-in-glow-circle
/// language Welcome/Discovery/Cast already use, instead of a bare line
/// of text.
class _NoSavedDevicesState extends StatelessWidget {
  const _NoSavedDevicesState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
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
              Icons.tv_outlined,
              size: 32,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No saved TVs', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Connect a TV to control it quickly next time.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => context.push(AppRoutes.discovery),
            child: const Text('Find a TV'),
          ),
        ],
      ),
    );
  }
}
