import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';

/// Read-only view of the current session state, useful when debugging a
/// provider without leaving the app. See docs/architecture/diagnostics.md.
class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Row('Connection state', session.connectionState.name),
          _Row('Selected device', session.selectedDevice?.name ?? '-'),
          _Row('Platform', session.selectedDevice?.platform.displayName ?? '-'),
          _Row('Discovered devices', '${session.discoveredDevices.length}'),
          _Row('Applications', '${session.applications.length}'),
          _Row('Last error', session.lastError ?? '-'),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Structured logs use tags like [TV][DISCOVERY], [TV][PAIRING], '
            '[TV][COMMAND] and are printed to the debug console. Pairing '
            'codes and tokens are never logged.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
