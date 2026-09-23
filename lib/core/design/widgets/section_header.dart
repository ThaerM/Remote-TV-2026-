import 'package:flutter/material.dart';

/// A small uppercase-weight label used to introduce a group of settings
/// or a list section - shared so `SettingsScreen` and other grouped
/// lists don't each define their own.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
