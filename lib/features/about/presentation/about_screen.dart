import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_links.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/section_header.dart';
import '../../../core/platform/external_links.dart';

/// Version and build come from the installed bundle (pubspec `version`),
/// never a literal - so the About screen can't drift from the release.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glow.withValues(alpha: 0.18),
                    AppColors.glow.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Icon(
                Icons.settings_remote_rounded,
                size: 52,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLinks.appName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            version.when(
              data: (v) => 'Version $v',
              loading: () => ' ',
              error: (_, _) => 'Version unavailable',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Developer'),
          const ListTile(
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Developed by'),
            subtitle: Text(AppLinks.developerName),
          ),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('Website'),
            subtitle: Text(AppLinks.website.toString()),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.website),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: const Text('GitHub'),
            subtitle: Text(AppLinks.github.toString()),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.github),
          ),
          const Divider(),
          const SectionHeader('Legal & help'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.privacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Support'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => openExternalLink(context, AppLinks.support),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppLinks.appName,
              applicationVersion: version.value,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Not affiliated with or endorsed by any TV or streaming device '
              'manufacturer. Product names are trademarks of their owners.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
