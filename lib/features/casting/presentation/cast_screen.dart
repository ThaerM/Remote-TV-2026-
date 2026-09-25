import 'dart:async';

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
import '../../remote/presentation/widgets/connection_status_indicator.dart';

/// Casts a media link to the connected device and controls playback.
/// Everything is gated on `TvCapabilities.casting` - which provider backs
/// it (Google Cast or DLNA) is invisible here, and nothing on screen ever
/// exposes protocol/transport details (service names, ports, CASTV2
/// internals).
class CastScreen extends ConsumerWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final device = session.selectedDevice;

    return Scaffold(
      appBar: AppBar(title: const Text('Cast')),
      body: switch (device) {
        null => _EmptyState(
          icon: Icons.cast_rounded,
          title: 'No cast device connected',
          body: 'Connect a compatible TV or streaming device to cast media.',
          action: FilledButton(
            onPressed: () => context.push(AppRoutes.discovery),
            child: const Text('Connect TV'),
          ),
        ),
        final device when !session.isConnected => _ConnectionState(
          device: device,
          session: session,
        ),
        final device when !session.capabilities.casting => _EmptyState(
          icon: Icons.cast_connected_rounded,
          title: "Casting isn't available for this connection",
          body:
              '${device.name} supports the remote, but not casting. Casting '
              'works with Google Cast and DLNA media devices - if this TV '
              'has Chromecast built-in, pick its "Google Cast" entry in '
              'Find your TV.',
        ),
        final device => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _CastDeviceHeader(
              name: device.name,
              connectionState: session.connectionState,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (session.mediaStatus case final media? when media.isActive) ...[
              _NowPlayingCard(
                status: media,
                capabilities: session.capabilities,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _CastLinkForm(deviceName: device.name),
          ],
        ),
      },
    );
  }
}

/// A device is selected but the session isn't live: still connecting/
/// pairing (handled elsewhere - Remote/Pairing own that flow, this is
/// just a non-blocking status), reconnecting, or genuinely dropped. Only
/// the last of those offers Retry/Find another device - the app must
/// never trap the user behind an indefinite spinner.
class _ConnectionState extends ConsumerWidget {
  const _ConnectionState({required this.device, required this.session});

  final TvDevice device;
  final TvSessionState session;

  bool get _isTransitional =>
      session.connectionState == TvConnectionState.connecting ||
      session.connectionState == TvConnectionState.pairingRequired ||
      session.connectionState == TvConnectionState.reconnecting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isTransitional) {
      return _EmptyState(
        icon: Icons.cast_rounded,
        title: device.name,
        body: session.connectionState == TvConnectionState.reconnecting
            ? 'Reconnecting…'
            : 'Connecting…',
        statusIndicator: session.connectionState,
      );
    }
    return _EmptyState(
      icon: Icons.cast_rounded,
      title: 'Connection lost',
      body: "${device.name} isn't reachable right now.",
      statusIndicator: session.connectionState,
      action: FilledButton.icon(
        onPressed: () =>
            ref.read(tvSessionControllerProvider.notifier).connect(device),
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
      secondaryAction: TextButton(
        onPressed: () => context.push(AppRoutes.discovery),
        child: const Text('Find another device'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.secondaryAction,
    this.statusIndicator,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final Widget? secondaryAction;

  /// Shown under the title instead of plain text, reusing the same
  /// dot+label the device header uses - so "reconnecting" here reads
  /// exactly the same as it does everywhere else in the app.
  final TvConnectionState? statusIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              child: Icon(icon, size: 40, color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (statusIndicator != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ConnectionStatusIndicator(state: statusIndicator!),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.xs),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact "which TV am I casting to" header - name and live connection
/// state only, never a protocol/service/port detail.
class _CastDeviceHeader extends StatelessWidget {
  const _CastDeviceHeader({required this.name, required this.connectionState});

  final String name;
  final TvConnectionState connectionState;

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
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cast_connected_rounded,
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ConnectionStatusIndicator(state: connectionState),
        ],
      ),
    );
  }
}

/// A single rounded, bordered surface - the same card language Welcome/
/// Discovery/Remote already use - instead of a plain Material [Card] or
/// loose widgets on the scaffold background.
class _SurfacePanel extends StatelessWidget {
  const _SurfacePanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaces?.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: child,
    );
  }
}

const _contentTypes = {
  'video/mp4': 'Video (MP4)',
  'video/webm': 'Video (WebM)',
  'application/x-mpegURL': 'Stream (HLS)',
  'audio/mpeg': 'Audio (MP3)',
  'image/jpeg': 'Photo (JPEG)',
  'image/png': 'Photo (PNG)',
};

class _CastLinkForm extends ConsumerStatefulWidget {
  const _CastLinkForm({required this.deviceName});

  final String deviceName;

  @override
  ConsumerState<_CastLinkForm> createState() => _CastLinkFormState();
}

class _CastLinkFormState extends ConsumerState<_CastLinkForm> {
  final _url = TextEditingController();
  final _title = TextEditingController();
  String? _chosenType;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _url.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _url.dispose();
    _title.dispose();
    super.dispose();
  }

  Uri? get _parsedUrl {
    final uri = Uri.tryParse(_url.text.trim());
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    return uri.host.isEmpty ? null : uri;
  }

  Future<void> _cast() async {
    final url = _parsedUrl;
    if (url == null) {
      setState(() => _error = 'Enter a link starting with http:// or https://');
      return;
    }
    final contentType = TvMediaItem.guessContentType(url) ?? _chosenType;
    if (contentType == null) {
      setState(() => _error = 'Choose what kind of media this link is.');
      return;
    }
    setState(() {
      _error = null;
      _sending = true;
    });
    final title = _title.text.trim();
    final error = await ref
        .read(tvSessionControllerProvider.notifier)
        .castMedia(
          TvMediaItem(
            url: url,
            contentType: contentType,
            title: title.isEmpty ? null : title,
          ),
        );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = _parsedUrl;
    final guessed = url == null ? null : TvMediaItem.guessContentType(url);

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Cast a link'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              // The TV fetches the URL itself - never implies this phone
              // streams or uploads anything, or that local files work.
              '${widget.deviceName} downloads the link itself, so it must '
              'be a direct media file (not a web page) that the TV can '
              'reach.',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _url,
            enabled: !_sending,
            keyboardType: TextInputType.url,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Media link',
              hintText: 'https://example.com/video.mp4',
              prefixIcon: Icon(Icons.link_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _title,
            enabled: !_sending,
            decoration: const InputDecoration(labelText: 'Title (optional)'),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (url != null && guessed == null)
            DropdownButtonFormField<String>(
              initialValue: _chosenType,
              decoration: const InputDecoration(labelText: 'Media type'),
              items: [
                for (final entry in _contentTypes.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _chosenType = value),
            )
          else if (guessed != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Detected: ${_contentTypes[guessed] ?? guessed}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: theme.colorScheme.error.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _sending ? null : _cast,
            icon: _sending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cast_rounded),
            label: Text(_sending ? 'Starting…' : 'Cast'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              "Casting photos and videos stored on this phone isn't "
              'supported yet.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NowPlayingCard extends ConsumerStatefulWidget {
  const _NowPlayingCard({required this.status, required this.capabilities});

  final TvMediaStatus status;
  final TvCapabilities capabilities;

  @override
  ConsumerState<_NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends ConsumerState<_NowPlayingCard> {
  // The receiver only reports position on state changes, so the displayed
  // position advances locally between reports while playing.
  Timer? _ticker;
  late Duration _position = widget.status.position;
  double? _dragging;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (widget.status.playerState == TvPlayerState.playing &&
          _dragging == null) {
        setState(() => _position += const Duration(seconds: 1));
      }
    });
  }

  @override
  void didUpdateWidget(covariant _NowPlayingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _position = widget.status.position;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    final error = await action();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.read(tvSessionControllerProvider.notifier);
    final status = widget.status;
    final caps = widget.capabilities;
    final duration = status.duration;
    final playing = status.playerState == TvPlayerState.playing;
    final position = duration == null || _position <= duration
        ? _position
        : duration;

    return _SurfacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.movie_creation_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Now playing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      status.title ?? 'Untitled media',
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (status.playerState == TvPlayerState.buffering) ...[
            const SizedBox(height: AppSpacing.xs),
            Text('Loading…', style: theme.textTheme.bodySmall),
          ],
          if (duration != null) ...[
            const SizedBox(height: AppSpacing.xs),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                overlayShape: SliderComponentShape.noOverlay,
              ),
              child: Slider(
                value: (_dragging ?? position.inMilliseconds.toDouble()).clamp(
                  0,
                  duration.inMilliseconds.toDouble(),
                ),
                max: duration.inMilliseconds.toDouble(),
                onChanged: (value) => setState(() => _dragging = value),
                onChangeEnd: (value) {
                  setState(() {
                    _dragging = null;
                    _position = Duration(milliseconds: value.round());
                  });
                  _run(
                    () => controller.seekMedia(
                      Duration(milliseconds: value.round()),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position), style: theme.textTheme.bodySmall),
                  Text(_format(duration), style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CastControlButton(
                icon: Icons.replay_10_rounded,
                semanticLabel: 'Back 10 seconds',
                onTap: () => _run(
                  () => controller.seekMedia(
                    position - const Duration(seconds: 10),
                  ),
                ),
              ),
              _CastControlButton(
                icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                semanticLabel: playing ? 'Pause' : 'Play',
                emphasized: true,
                onTap: () => _run(controller.togglePlayback),
              ),
              _CastControlButton(
                icon: Icons.forward_30_rounded,
                semanticLabel: 'Forward 30 seconds',
                onTap: () => _run(
                  () => controller.seekMedia(
                    position + const Duration(seconds: 30),
                  ),
                ),
              ),
              _CastControlButton(
                icon: Icons.stop_rounded,
                semanticLabel: 'Stop casting',
                onTap: () => _run(controller.stopMedia),
              ),
            ],
          ),
          if (caps.volume || caps.mute) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: theme.dividerColor, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (caps.mute)
                  _CastControlButton(
                    icon: Icons.volume_off_rounded,
                    semanticLabel: 'Mute',
                    size: 40,
                    onTap: () => controller.sendCommand(
                      const TvCommand.key(TvCommandKey.mute),
                    ),
                  ),
                if (caps.volume) ...[
                  _CastControlButton(
                    icon: Icons.volume_down_rounded,
                    semanticLabel: 'Volume Down',
                    size: 40,
                    onTap: () => controller.sendCommand(
                      const TvCommand.key(TvCommandKey.volumeDown),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _CastControlButton(
                    icon: Icons.volume_up_rounded,
                    semanticLabel: 'Volume Up',
                    size: 40,
                    onTap: () => controller.sendCommand(
                      const TvCommand.key(TvCommandKey.volumeUp),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

/// A small circular control button in this screen's own premium
/// language - [PressableScale] press feedback, no ripple - kept local to
/// Cast rather than reused from Remote's widgets so this screen doesn't
/// couple to Remote's implementation.
class _CastControlButton extends StatelessWidget {
  const _CastControlButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.size = AppControlSize.minTouchTarget,
    this.emphasized = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final double size;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PressableScale(
      // Playback controls aren't the remote-command haptic surface -
      // kept silent to match this screen's other taps.
      hapticsEnabled: false,
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: emphasized ? theme.colorScheme.primary : theme.cardTheme.color,
          shape: BoxShape.circle,
          border: emphasized ? null : Border.all(color: theme.dividerColor),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: emphasized ? 26 : 20,
          color: emphasized
              ? theme.colorScheme.onPrimary
              : theme.iconTheme.color,
        ),
      ),
    );
  }
}
