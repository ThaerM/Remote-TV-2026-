import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
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
              onTap: () => context.go(AppRoutes.discovery),
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
          SwitchListTile(
            secondary: const Icon(Icons.developer_mode_rounded),
            title: const Text('Developer / power user mode'),
            subtitle: const Text(
              'Off by default. Enables ADB/APK tools in a later phase.',
            ),
            value: settings.developerModeEnabled,
            onChanged: notifier.setDeveloperModeEnabled,
          ),
          const Divider(),
          const SectionHeader('Application'),
          const ListTile(
            leading: Icon(Icons.help_outline_rounded),
            title: Text('Help & Support'),
          ),
          const ListTile(
            leading: Icon(Icons.feedback_outlined),
            title: Text('Feedback'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('About'),
            subtitle: Text('Remote TV 2026 · Phase 1 build'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
          ),
          const ListTile(
            leading: Icon(Icons.gavel_outlined),
            title: Text('Legal'),
          ),
        ],
      ),
    );
  }
}
