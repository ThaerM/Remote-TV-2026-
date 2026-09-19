import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import 'widgets/dpad_control.dart';
import 'widgets/remote_action_button.dart';
import 'widgets/secondary_controls_sheet.dart';

/// The primary control surface. Entirely capability-driven: every control
/// group is shown only when the connected device reports support for it -
/// see docs/architecture/provider-system.md ("Capability-driven design").
class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final notifier = ref.read(tvSessionControllerProvider.notifier);

    if (!session.isConnected) {
      return _NotConnectedState(
        onFindTv: () => context.go(AppRoutes.discovery),
      );
    }

    void send(TvCommandKey key) => notifier.sendCommand(TvCommand.key(key));
    final caps = session.capabilities;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _DeviceHeader(
              deviceName: session.selectedDevice?.name ?? 'TV',
              connectionState: session.connectionState,
              powerEnabled: caps.power,
              onPower: () => send(TvCommandKey.power),
              onSwitchTv: () => context.go(AppRoutes.discovery),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session.applications.isNotEmpty) ...[
              _QuickAppsRow(
                applications: session.applications,
                onLaunch: (app) =>
                    notifier.sendCommand(TvCommand.launchApp(app.id)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (caps.dpad) ...[
              DpadControl(onCommand: send),
              const SizedBox(height: AppSpacing.lg),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RemoteActionButton(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  onPressed: () => send(TvCommandKey.home),
                ),
                RemoteActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  onPressed: () => send(TvCommandKey.back),
                ),
                RemoteActionButton(
                  icon: Icons.menu_rounded,
                  label: 'Menu',
                  onPressed: () => send(TvCommandKey.menu),
                ),
                if (caps.keyboard)
                  RemoteActionButton(
                    icon: Icons.keyboard_alt_outlined,
                    label: 'Keyboard',
                    onPressed: () => _showKeyboardSheet(context, notifier),
                  ),
                if (caps.voice)
                  RemoteActionButton(
                    icon: Icons.mic_rounded,
                    label: 'Voice',
                    onPressed: () => send(TvCommandKey.voiceStart),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (caps.volume || caps.channel)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (caps.volume)
                    _VerticalCluster(
                      label: 'Volume',
                      onUp: () => send(TvCommandKey.volumeUp),
                      onDown: () => send(TvCommandKey.volumeDown),
                      middle: caps.mute
                          ? RemoteActionButton(
                              icon: Icons.volume_off_rounded,
                              label: 'Mute',
                              onPressed: () => send(TvCommandKey.mute),
                            )
                          : null,
                    ),
                  if (caps.channel)
                    _VerticalCluster(
                      label: 'Channel',
                      onUp: () => send(TvCommandKey.channelUp),
                      onDown: () => send(TvCommandKey.channelDown),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => SecondaryControlsSheet.show(
                context,
                capabilities: caps,
                onCommand: notifier.sendCommand,
              ),
              icon: const Icon(Icons.apps_rounded),
              label: const Text('More controls'),
            ),
            if (session.lastError != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                session.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showKeyboardSheet(BuildContext context, TvSessionController notifier) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Type on TV'),
          onSubmitted: (value) {
            notifier.sendCommand(TvCommand.text(value));
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({
    required this.deviceName,
    required this.connectionState,
    required this.powerEnabled,
    required this.onPower,
    required this.onSwitchTv,
  });

  final String deviceName;
  final TvConnectionState connectionState;
  final bool powerEnabled;
  final VoidCallback onPower;
  final VoidCallback onSwitchTv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = connectionState == TvConnectionState.connected
        ? theme.colorScheme.primary
        : theme.colorScheme.error;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSwitchTv,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    deviceName,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.expand_more_rounded),
              ],
            ),
          ),
        ),
        if (powerEnabled)
          IconButton.filledTonal(
            onPressed: onPower,
            icon: const Icon(Icons.power_settings_new_rounded),
          ),
      ],
    );
  }
}

class _QuickAppsRow extends StatelessWidget {
  const _QuickAppsRow({required this.applications, required this.onLaunch});

  final List<TvApplication> applications;
  final void Function(TvApplication app) onLaunch;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: applications.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final app = applications[index];
          return _QuickAppTile(app: app, onTap: () => onLaunch(app));
        },
      ),
    );
  }
}

class _QuickAppTile extends StatelessWidget {
  const _QuickAppTile({required this.app, required this.onTap});

  final TvApplication app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 88,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text(
          app.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _VerticalCluster extends StatelessWidget {
  const _VerticalCluster({
    required this.label,
    required this.onUp,
    required this.onDown,
    this.middle,
  });

  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final Widget? middle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        RemoteActionButton(
          icon: Icons.add_rounded,
          label: '',
          repeatWhileHeld: true,
          onPressed: onUp,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (middle != null) ...[middle!, const SizedBox(height: AppSpacing.sm)],
        RemoteActionButton(
          icon: Icons.remove_rounded,
          label: '',
          repeatWhileHeld: true,
          onPressed: onDown,
        ),
      ],
    );
  }
}

class _NotConnectedState extends StatelessWidget {
  const _NotConnectedState({required this.onFindTv});

  final VoidCallback onFindTv;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tv_off_rounded,
                size: 56,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No TV connected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onFindTv,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Find a TV'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
