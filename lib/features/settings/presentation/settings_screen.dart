import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/config/app_links.dart';
import '../../../core/platform/external_links.dart';
import '../../../core/design/widgets/section_header.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
    final session = ref.watch(tvSessionControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SectionHeader('Current TV'),
          if (session.selectedDevice != null)
            ListTile(
              leading: const Icon(Icons.tv_rounded),
              title: Text(session.selectedDevice!.name),
              subtitle: Text(
                session.isConnected ? 'Connected' : 'Not connected',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.devices),
            )
          else
            ListTile(
              leading: const Icon(Icons.tv_off_rounded),
              title: const Text('No TV connected'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(AppRoutes.discovery),
            ),
          const Divider(),
          const SectionHeader('Appearance'),
          RadioGroup<ThemeMode>(
            groupValue: settings.themeMode,
            onChanged: (mode) => notifier.setThemeMode(mode!),
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Dark'),
                  value: ThemeMode.dark,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('Light'),
                  value: ThemeMode.light,
                ),
                RadioListTile<ThemeMode>(
                  title: Text('System'),
                  value: ThemeMode.system,
                ),
              ],
            ),
          ),
          const Divider(),
          const SectionHeader('Remote'),
          ListTile(
            leading: const Icon(Icons.gamepad_outlined),
            title: const Text('Remote layout'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.remoteLayoutSettings),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Remote behavior'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.remoteBehaviorSettings),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.nightlight_round),
            title: const Text('Theater mode'),
            subtitle: const Text(
              'Dims decorative effects on the Remote screen',
            ),
            value: settings.theaterModeEnabled,
            onChanged: notifier.setTheaterModeEnabled,
          ),
          const Divider(),
          const SectionHeader('Devices'),
          ListTile(
            leading: const Icon(Icons.devices_other_rounded),
            title: const Text('Connected & saved devices'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.devices),
          ),
          const Divider(),
          const SectionHeader('Advanced'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Diagnostics'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.diagnostics),
          ),
          const Divider(),
          const SectionHeader('Application'),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.support),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            subtitle: const Text(AppLinks.appName),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(AppRoutes.about),
          ),
        ],
      ),
    );
  }
}
