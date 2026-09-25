import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/pressable_scale.dart';
import '../../../core/design/widgets/section_header.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import '../../apps/presentation/widgets/app_icon.dart';
import '../../settings/application/settings_controller.dart';
import 'widgets/connection_status_indicator.dart';
import 'widgets/device_switcher_sheet.dart';
import 'widgets/dpad_control.dart';
import 'widgets/remote_action_button.dart';
import 'widgets/remote_rocker.dart';
import 'widgets/secondary_controls_sheet.dart';
import 'widgets/touchpad_surface.dart';

const _mediaButtons = [
  (
    key: TvCommandKey.mediaPrevious,
    icon: Icons.skip_previous_rounded,
    label: 'Prev',
  ),
  (
    key: TvCommandKey.mediaRewind,
    icon: Icons.fast_rewind_rounded,
    label: 'Rewind',
  ),
  (key: TvCommandKey.mediaPlay, icon: Icons.play_arrow_rounded, label: 'Play'),
  (
    key: TvCommandKey.mediaForward,
    icon: Icons.fast_forward_rounded,
    label: 'Forward',
  ),
  (key: TvCommandKey.mediaNext, icon: Icons.skip_next_rounded, label: 'Next'),
];

/// The primary control surface. Entirely capability-driven: every control
/// group is shown only when the connected device reports support for it -
/// see docs/architecture/provider-system.md ("Capability-driven design").
///
/// Deliberately compact: the goal is for the core controls (D-pad, Home/
/// Back/Menu, Volume/Mute/Channel, and media transport) to fit in one view
/// on a standard phone without scrolling. Only genuinely secondary
/// controls (number pad, color keys, keyboard, voice) live behind
/// "More controls".
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

    final theaterMode = settings.theaterModeEnabled;
    final hasSecondaryControls =
        caps.numericKeypad || caps.colorKeys || caps.keyboard || caps.voice;

    return Scaffold(
      backgroundColor: theaterMode ? Colors.black : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              _DeviceHeader(
                deviceName: session.selectedDevice!.name,
                platform: session.selectedDevice!.platform,
                connectionState: session.connectionState,
                powerEnabled: caps.power,
                onPower: () => send(TvCommandKey.power),
                onSwitchTv: () => DeviceSwitcherSheet.show(context),
              ),
              if (caps.launchApps && session.applications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _QuickAppsRow(
                  applications: session.applications,
                  onLaunch: (app) =>
                      notifier.sendCommand(TvCommand.launchApp(app.id)),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // One housing for the whole control surface - a physical
              // remote is a single object, not a stack of separate cards.
              _RemoteControlPanel(
                isLive: isLive,
                theaterModeEnabled: theaterMode,
                child: Column(
                  children: [
                    if (caps.dpad) ...[
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
                                theaterModeEnabled: theaterMode,
                                onCommand: send,
                              )
                            : SizedBox(
                                key: const ValueKey('touchpad'),
                                width: AppControlSize.dpadDiameter + 40,
                                child: TouchpadSurface(
                                  theaterModeEnabled: theaterMode,
                                  onCommand: send,
                                ),
                              ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _NavStyleToggle(
                        style: settings.navigationStyle,
                        onSelect: (style) => ref
                            .read(settingsControllerProvider.notifier)
                            .setNavigationStyle(style),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (caps.allows(TvCommandKey.home) ||
                        caps.allows(TvCommandKey.back) ||
                        caps.allows(TvCommandKey.menu))
                      Row(
                        children: [
                          if (caps.allows(TvCommandKey.home))
                            Expanded(
                              child: _HardwareButton(
                                icon: Icons.home_rounded,
                                label: 'HOME',
                                dimmed: theaterMode,
                                onPressed: () => send(TvCommandKey.home),
                              ),
                            ),
                          if (caps.allows(TvCommandKey.back)) ...[
                            if (caps.allows(TvCommandKey.home))
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _HardwareButton(
                                icon: Icons.arrow_back_rounded,
                                label: 'BACK',
                                dimmed: theaterMode,
                                onPressed: () => send(TvCommandKey.back),
                              ),
                            ),
                          ],
                          if (caps.allows(TvCommandKey.menu)) ...[
                            if (caps.allows(TvCommandKey.home) ||
                                caps.allows(TvCommandKey.back))
                              const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _HardwareButton(
                                icon: Icons.menu_rounded,
                                label: 'MENU',
                                dimmed: theaterMode,
                                onPressed: () => send(TvCommandKey.menu),
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (caps.volume || caps.channel) ...[
                      const SizedBox(height: AppSpacing.md),
                      Divider(color: Theme.of(context).dividerColor, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      _VolumeChannelRow(
                        volumeEnabled: caps.volume,
                        muteEnabled: caps.mute,
                        channelEnabled: caps.channel,
                        dimmed: theaterMode,
                        onVolumeUp: () => send(TvCommandKey.volumeUp),
                        onVolumeDown: () => send(TvCommandKey.volumeDown),
                        onMute: () => send(TvCommandKey.mute),
                        onChannelUp: () => send(TvCommandKey.channelUp),
                        onChannelDown: () => send(TvCommandKey.channelDown),
                      ),
                    ],
                    if (caps.mediaControls) ...[
                      const SizedBox(height: AppSpacing.md),
                      Divider(color: Theme.of(context).dividerColor, height: 1),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final button in _mediaButtons)
                            if (caps.allows(button.key))
                              RemoteActionButton(
                                icon: button.icon,
                                label: '',
                                size: 44,
                                semanticLabel: button.label,
                                emphasized:
                                    button.key == TvCommandKey.mediaPlay,
                                onPressed: () => notifier.sendCommand(
                                  TvCommand.key(button.key),
                                ),
                              ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (hasSecondaryControls)
                _MoreControlsEntry(
                  onTap: () => SecondaryControlsSheet.show(
                    context,
                    capabilities: caps,
                    onCommand: notifier.sendCommand,
                    onOpenKeyboard: () =>
                        _showKeyboardSheet(context, ref, notifier),
                  ),
                ),
              if (!isLive) ...[
                const SizedBox(height: AppSpacing.md),
                _ConnectionBanner(state: session.connectionState),
              ],
              if (session.lastError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  session.lastError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
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

/// The single housing for the whole control surface - D-pad/touchpad,
/// Home/Back/Menu, Volume/Mute/Channel, and media transport all sit on
/// one raised surface instead of reading as separate unrelated cards, the
/// way a real remote is one physical object. Dimmed (never hidden) while
/// the session isn't live, so the layout never jumps during a brief
/// reconnect.
class _RemoteControlPanel extends StatelessWidget {
  const _RemoteControlPanel({
    required this.isLive,
    required this.theaterModeEnabled,
    required this.child,
  });

  final bool isLive;
  final bool theaterModeEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return AbsorbPointer(
      absorbing: !isLive,
      child: AnimatedOpacity(
        duration: AppMotion.connection,
        opacity: isLive ? 1 : 0.4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            // Theater Mode keeps the housing dark and unobtrusive rather
            // than a lit panel floating on pure black.
            color: theaterModeEnabled ? Colors.black : surfaces?.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: surfaces?.border ?? theme.dividerColor),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A compact segmented pill between D-pad and touchpad navigation -
/// both options visible with the active one highlighted, replacing a
/// full-width "Switch to touchpad" text row.
class _NavStyleToggle extends StatelessWidget {
  const _NavStyleToggle({required this.style, required this.onSelect});

  final RemoteNavigationStyle style;
  final void Function(RemoteNavigationStyle style) onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NavStyleSegment(
            icon: Icons.gamepad_outlined,
            label: 'D-pad',
            selected: style == RemoteNavigationStyle.dpad,
            onTap: () => onSelect(RemoteNavigationStyle.dpad),
          ),
          _NavStyleSegment(
            icon: Icons.touch_app_outlined,
            label: 'Touchpad',
            selected: style == RemoteNavigationStyle.touchpad,
            onTap: () => onSelect(RemoteNavigationStyle.touchpad),
          ),
        ],
      ),
    );
  }
}

class _NavStyleSegment extends StatelessWidget {
  const _NavStyleSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected ? AppColors.glow : theme.colorScheme.secondary;

    return PressableScale(
      hapticsEnabled: false,
      semanticLabel: 'Switch to $label',
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.glow.withValues(alpha: 0.14) : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Volume, Mute, and Channel matching a physical remote's layout: a
/// vertical Volume rocker on the left, a circular Mute button in the
/// center, and a vertical Channel rocker (labelled "CH") on the right.
class _VolumeChannelRow extends StatelessWidget {
  const _VolumeChannelRow({
    required this.volumeEnabled,
    required this.muteEnabled,
    required this.channelEnabled,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onMute,
    required this.onChannelUp,
    required this.onChannelDown,
    this.dimmed = false,
  });

  final bool volumeEnabled;
  final bool muteEnabled;
  final bool channelEnabled;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final VoidCallback onMute;
  final VoidCallback onChannelUp;
  final VoidCallback onChannelDown;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (volumeEnabled)
          RemoteRocker(
            increaseSemanticLabel: 'Volume Up',
            decreaseSemanticLabel: 'Volume Down',
            dimmed: dimmed,
            onIncrease: onVolumeUp,
            onDecrease: onVolumeDown,
          ),
        if (muteEnabled)
          RemoteActionButton(
            icon: Icons.volume_off_rounded,
            label: '',
            size: 44,
            semanticLabel: 'Mute',
            onPressed: onMute,
          ),
        if (channelEnabled)
          RemoteRocker(
            increaseSemanticLabel: 'Channel Up',
            decreaseSemanticLabel: 'Channel Down',
            dimmed: dimmed,
            onIncrease: onChannelUp,
            onDecrease: onChannelDown,
            icon: Text(
              'CH',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }
}

/// Three equal-width hardware-style buttons (Home/Back/Menu): a rounded
/// rectangle with an icon and a small uppercase label, not a circular
/// Material button with a loose caption underneath.
class _HardwareButton extends ConsumerStatefulWidget {
  const _HardwareButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.dimmed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool dimmed;

  @override
  ConsumerState<_HardwareButton> createState() => _HardwareButtonState();
}

class _HardwareButtonState extends ConsumerState<_HardwareButton> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );
    final borderColor = theme.dividerColor.withValues(
      alpha: widget.dimmed ? 0.35 : 0.7,
    );

    return PressableScale(
      hapticsEnabled: hapticsEnabled,
      semanticLabel: widget.label,
      onTap: widget.onPressed,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xs,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.glow.withValues(alpha: 0.1)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 20, color: theme.iconTheme.color),
            const SizedBox(height: 2),
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The subtle entry point into "More Controls": a thin divider, a small
/// icon, the label, and a chevron - not a large outlined CTA button.
class _MoreControlsEntry extends StatelessWidget {
  const _MoreControlsEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Divider(color: theme.dividerColor, height: 1),
        PressableScale(
          hapticsEnabled: false,
          semanticLabel: 'More controls',
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.apps_rounded,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('More Controls', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Replaces a hand-rolled "Reconnecting…"/"Not connected" caption with
/// the same dot-and-label component the header already uses, so the
/// wording and color for every [TvConnectionState] is defined in exactly
/// one place.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});

  final TvConnectionState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: surfaces?.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: ConnectionStatusIndicator(state: state),
    );
  }
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({
    required this.deviceName,
    required this.platform,
    required this.connectionState,
    required this.powerEnabled,
    required this.onPower,
    required this.onSwitchTv,
  });

  final String deviceName;
  final TvPlatform platform;
  final TvConnectionState connectionState;
  final bool powerEnabled;
  final VoidCallback onPower;
  final VoidCallback onSwitchTv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Integrated into the remote, not a settings-tile card: a plain row,
    // not a bordered/backgrounded container.
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.6),
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.smart_display_rounded,
            size: 18,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: PressableScale(
            hapticsEnabled: false,
            semanticLabel: 'Switch TV, currently $deviceName',
            onTap: onSwitchTv,
            child: Row(
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        deviceName,
                        style: theme.textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConnectionStatusIndicator(state: connectionState),
                          Flexible(
                            child: Text(
                              ' · ${platform.displayName}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
        if (powerEnabled) ...[
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton.filledTonal(
              padding: EdgeInsets.zero,
              onPressed: onPower,
              icon: const Icon(Icons.power_settings_new_rounded, size: 18),
            ),
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: AppSpacing.xs),
              child: SectionHeader('Apps'),
            ),
            InkWell(
              onTap: () => context.push(AppRoutes.apps),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                child: Text(
                  'See all',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 72,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
    final theme = Theme.of(context);

    return PressableScale(
      hapticsEnabled: false,
      scaleFactor: 0.96,
      semanticLabel: 'Open ${app.name}',
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: theme.dividerColor),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(app: app, size: 24, bordered: false),
            const SizedBox(height: 4),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
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
