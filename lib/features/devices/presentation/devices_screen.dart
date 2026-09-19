import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';

/// Shows the currently connected device and lets the user disconnect or
/// find another TV. "Saved TVs" and connection history are a follow-up -
/// see docs/product/feature-roadmap.md.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final notifier = ref.read(tvSessionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Connected', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (session.isConnected && session.selectedDevice != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tv_rounded),
                  title: Text(session.selectedDevice!.name),
                  subtitle: Text(session.selectedDevice!.platform.displayName),
                  trailing: TextButton(
                    onPressed: notifier.disconnect,
                    child: const Text('Disconnect'),
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tv_off_rounded),
                  title: const Text('No TV connected'),
                  trailing: TextButton(
                    onPressed: () => context.go(AppRoutes.discovery),
                    child: const Text('Find a TV'),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.discovery),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add another TV'),
            ),
          ],
        ),
      ),
    );
  }
}
