import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';

/// Casts a media link to the connected device and controls playback.
/// Everything is gated on `TvCapabilities.casting` - which provider backs
/// it (Google Cast or DLNA) is invisible here.
class CastScreen extends ConsumerWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cast')),
      body: !session.isConnected
          ? _Unavailable(
              icon: Icons.cast_rounded,
              title: 'Nothing to cast to yet',
              body:
                  'Connect to a Chromecast, a Google TV or another Cast-enabled '
                  'device. They appear as "Google Cast" in Find your TV.',
              action: FilledButton(
                onPressed: () => context.push(AppRoutes.discovery),
                child: const Text('Find a device'),
              ),
            )
          : !session.capabilities.casting
          ? _Unavailable(
              icon: Icons.cast_rounded,
              title:
                  "${session.selectedDevice?.name ?? 'This TV'} can't "
                  'receive casts',
              body:
                  'Casting works with Google Cast and DLNA media devices. If '
                  'this TV has Chromecast built-in, pick its "Google Cast" '
                  'entry in Find your TV.',
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (session.mediaStatus case final media?
                    when media.isActive) ...[
                  _NowPlaying(status: media),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _CastLinkForm(
                  deviceName: session.selectedDevice?.name ?? 'your TV',
                ),
              ],
            ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.secondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(body, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Cast a link', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${widget.deviceName} downloads the link itself, so it must be a '
          'direct media file (not a web page) that the TV can reach.',
          style: theme.textTheme.bodySmall,
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
          Text(
            'Detected: ${_contentTypes[guessed] ?? guessed}',
            style: theme.textTheme.bodySmall,
          ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
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
        const SizedBox(height: AppSpacing.md),
        Text(
          "Casting photos and videos stored on this phone isn't supported "
          'yet.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NowPlaying extends ConsumerStatefulWidget {
  const _NowPlaying({required this.status});

  final TvMediaStatus status;

  @override
  ConsumerState<_NowPlaying> createState() => _NowPlayingState();
}

class _NowPlayingState extends ConsumerState<_NowPlaying> {
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
  void didUpdateWidget(covariant _NowPlaying oldWidget) {
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
    final duration = status.duration;
    final playing = status.playerState == TvPlayerState.playing;
    final position = duration == null || _position <= duration
        ? _position
        : duration;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Now playing', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              status.title ?? 'Untitled media',
              style: theme.textTheme.titleMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (status.playerState == TvPlayerState.buffering)
              Text('Loading…', style: theme.textTheme.bodySmall),
            if (duration != null) ...[
              Slider(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_format(position), style: theme.textTheme.bodySmall),
                  Text(_format(duration), style: theme.textTheme.bodySmall),
                ],
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Back 10 seconds',
                  icon: const Icon(Icons.replay_10_rounded),
                  onPressed: () => _run(
                    () => controller.seekMedia(
                      position - const Duration(seconds: 10),
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: playing ? 'Pause' : 'Play',
                  iconSize: 32,
                  icon: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  onPressed: () => _run(controller.togglePlayback),
                ),
                IconButton(
                  tooltip: 'Forward 30 seconds',
                  icon: const Icon(Icons.forward_30_rounded),
                  onPressed: () => _run(
                    () => controller.seekMedia(
                      position + const Duration(seconds: 30),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Stop casting',
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: () => _run(controller.stopMedia),
                ),
              ],
            ),
          ],
        ),
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
