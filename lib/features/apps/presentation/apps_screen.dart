import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import 'widgets/app_icon.dart';

/// Full-grid view of apps the connected TV actually reports via
/// `TvProvider.getApplications()`. Never shows an app the device didn't
/// return - a real TV with `launchApps == false` (or that returned no
/// apps) sees an honest empty state instead of a hardcoded catalog.
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(tvSessionControllerProvider);
    final notifier = ref.read(tvSessionControllerProvider.notifier);
    final canLaunch = session.capabilities.launchApps;
    final apps = session.applications;

    return Scaffold(
      appBar: AppBar(title: const Text('Apps')),
      body: !session.isConnected
          ? const _AppsEmptyState(message: 'Connect to a TV to see its apps.')
          : !canLaunch
          ? const _AppsEmptyState(
              message: 'This TV does not support launching apps.',
            )
          : apps.isEmpty
          ? const _AppsEmptyState(message: 'No apps reported by this TV yet.')
          : GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 110,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.85,
              ),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return _AppTile(
                  app: app,
                  onTap: () =>
                      notifier.sendCommand(TvCommand.launchApp(app.id)),
                );
              },
            ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app, required this.onTap});

  final TvApplication app;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Semantics(
        button: true,
        label: 'Open ${app.name}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(app: app, size: 64),
            const SizedBox(height: AppSpacing.xs),
            Text(
              app.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsEmptyState extends StatelessWidget {
  const _AppsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apps_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
