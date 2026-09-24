import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import '../../settings/application/settings_controller.dart';
import 'widgets/connection_status_indicator.dart';
import 'widgets/device_switcher_sheet.dart';
import 'widgets/dpad_control.dart';
import 'widgets/remote_action_button.dart';
import 'widgets/remote_rocker.dart';
import 'widgets/secondary_controls_sheet.dart';
import 'widgets/touchpad_surface.dart';

/// The primary control surface. Entirely capability-driven: every control
/// group is shown only when the connected device reports support for it -
/// see docs/architecture/provider-system.md ("Capability-driven design").
class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final notifier = ref.read(tvSessionControllerProvider.notifier);
    final settings = ref.watch(settingsControllerProvider);

    if (session.selectedDevice == null) {
      return _NotConnectedState(
        onFindTv: () => context.push(AppRoutes.discovery),
      );
    }

    void send(TvCommandKey key) => notifier.sendCommand(TvCommand.key(key));
    final caps = session.capabilities;
    final isLive = session.isConnected;

    return Scaffold(
      backgroundColor: settings.theaterModeEnabled ? Colors.black : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _DeviceHeader(
              deviceName: session.selectedDevice!.name,
              connectionState: session.connectionState,
              powerEnabled: caps.power,
              onPower: () => send(TvCommandKey.power),
              onSwitchTv: () => DeviceSwitcherSheet.show(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (caps.launchApps && session.applications.isNotEmpty) ...[
              _QuickAppsRow(
                applications: session.applications,
                onLaunch: (app) =>
                    notifier.sendCommand(TvCommand.launchApp(app.id)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AbsorbPointer(
              absorbing: !isLive,
              child: Opacity(
                opacity: isLive ? 1 : 0.4,
                child: Column(
                  children: [
                    if (caps.dpad)
                      AnimatedSwitcher(
                        duration: AppMotion.panel,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        ),
                        child:
                            settings.navigationStyle ==
                                RemoteNavigationStyle.dpad
                            ? DpadControl(
                                key: const ValueKey('dpad'),
                                onCommand: send,
                              )
                            : SizedBox(
                                key: const ValueKey('touchpad'),
                                width: AppControlSize.dpadDiameter + 60,
                                child: TouchpadSurface(onCommand: send),
                              ),
                      ),
                    if (caps.dpad) const SizedBox(height: AppSpacing.sm),
                    if (caps.dpad)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(settingsControllerProvider.notifier)
                            .setNavigationStyle(
                              settings.navigationStyle ==
                                      RemoteNavigationStyle.dpad
                                  ? RemoteNavigationStyle.touchpad
                                  : RemoteNavigationStyle.dpad,
                            ),
                        icon: Icon(
                          settings.navigationStyle == RemoteNavigationStyle.dpad
                              ? Icons.touch_app_outlined
                              : Icons.gamepad_outlined,
                          size: 18,
                        ),
                        label: Text(
                          settings.navigationStyle == RemoteNavigationStyle.dpad
                              ? 'Switch to touchpad'
                              : 'Switch to D-pad',
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (caps.allows(TvCommandKey.home))
                          RemoteActionButton(
                            icon: Icons.home_rounded,
                            label: 'Home',
                            onPressed: () => send(TvCommandKey.home),
                          ),
                        if (caps.allows(TvCommandKey.back))
                          RemoteActionButton(
                            icon: Icons.arrow_back_rounded,
                            label: 'Back',
                            onPressed: () => send(TvCommandKey.back),
                          ),
                        if (caps.allows(TvCommandKey.menu))
                          RemoteActionButton(
                            icon: Icons.menu_rounded,
                            label: 'Menu',
                            onPressed: () => send(TvCommandKey.menu),
                          ),
                        if (caps.keyboard)
                          RemoteActionButton(
                            icon: Icons.keyboard_alt_outlined,
                            label: 'Keyboard',
                            onPressed: () =>
                                _showKeyboardSheet(context, ref, notifier),
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
                            RemoteRocker(
                              label: 'Volume',
                              increaseSemanticLabel: 'Volume Up',
                              decreaseSemanticLabel: 'Volume Down',
                              onIncrease: () => send(TvCommandKey.volumeUp),
                              onDecrease: () => send(TvCommandKey.volumeDown),
                              icon: caps.mute
                                  ? RemoteActionButton(
                                      icon: Icons.volume_off_rounded,
                                      label: '',
                                      size: 36,
                                      semanticLabel: 'Mute',
                                      onPressed: () => send(TvCommandKey.mute),
                                    )
                                  : null,
                            ),
                          if (caps.channel)
                            RemoteRocker(
                              label: 'Channel',
                              increaseSemanticLabel: 'Channel Up',
                              decreaseSemanticLabel: 'Channel Down',
                              onIncrease: () => send(TvCommandKey.channelUp),
                              onDecrease: () => send(TvCommandKey.channelDown),
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
                  ],
                ),
              ),
            ),
            if (!isLive) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                session.connectionState == TvConnectionState.reconnecting
                    ? 'Reconnecting to ${session.selectedDevice!.name}…'
                    : 'Not connected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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

  void _showKeyboardSheet(
    BuildContext context,
    WidgetRef ref,
    TvSessionController notifier,
  ) {
    final controller = TextEditingController();
    var sent = false;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom:
                MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                ref.read(tvSessionControllerProvider).selectedDevice?.name ??
                    'TV',
                style: Theme.of(sheetContext).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Type on your TV…',
                ),
                onSubmitted: (value) {
                  if (value.isEmpty) return;
                  notifier.sendCommand(TvCommand.text(value));
                  setSheetState(() => sent = true);
                },
              ),
              if (sent)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text('Sent'),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton(
                onPressed: () {
                  if (controller.text.isEmpty) return;
                  notifier.sendCommand(TvCommand.text(controller.text));
                  setSheetState(() => sent = true);
                },
                child: const Text('Send'),
              ),
            ],
          ),
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

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSwitchTv,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_display_rounded,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          deviceName,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                        ConnectionStatusIndicator(state: connectionState),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Apps', style: Theme.of(context).textTheme.bodySmall),
            InkWell(
              onTap: () => context.push(AppRoutes.apps),
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
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
        ),
      ],
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Connect a compatible TV when you're ready.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onFindTv,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Connect TV'),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You can explore the app before connecting a device.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
