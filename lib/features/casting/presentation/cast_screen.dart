import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';

/// Foundation-phase Cast screen. Real Google Cast session support is a
/// dedicated phase - see docs/research/google-cast.md. For now this shows
/// capability-gated casting affordances against the connected device.
class CastScreen extends ConsumerWidget {
  const CastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final castingSupported = session.capabilities.casting;

    return Scaffold(
      appBar: AppBar(title: const Text('Cast')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: !session.isConnected
              ? const Text('Connect to a TV to cast media to it.')
              : !castingSupported
              ? const Text('This TV does not support casting yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cast_connected_rounded,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Cast a video, photo, or web link to '
                      '${session.selectedDevice?.name ?? 'your TV'}.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Cast a URL (coming soon)'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
