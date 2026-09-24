import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/animated_connection_ring.dart';
import '../application/onboarding_state.dart';

/// First screen of the first-run journey: explains the local-network
/// requirement before asking for any permission or starting a scan.
/// See docs/product/screen-inventory.md for the full flow.
///
/// Reached only via [_leave]'s `go()` (never pushed on top of anything),
/// so it can never reappear behind a later screen's Back button.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  /// Either choice finishes onboarding; neither touches saved TVs.
  void _leave(String route) {
    unawaited(ref.read(onboardingStoreProvider).markCompleted());
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: Stack(
        children: [
          // Depth, not decoration: a soft top-to-background wash so the
          // screen doesn't read as a flat, single-tone Material page -
          // built entirely from this theme's own surface tokens, never a
          // one-off color.
          if (surfaces != null)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      surfaces.surface.withValues(alpha: 0.7),
                      surfaces.background,
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // Lets the hero take whatever vertical slack is left
                    // over on a tall screen (via the Expanded below)
                    // instead of leaving a dead gap under the buttons;
                    // on a short screen this whole column just scrolls.
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: _Hero(
                                pulse: _glow,
                                reducedMotion: reducedMotion,
                              ),
                            ),
                          ),
                          Text(
                            'Remote TV 2026',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displayLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'One elegant remote for the smart TVs and '
                            'streaming devices you already own.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const _RequirementsCard(),
                          const SizedBox(height: AppSpacing.xl),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _leave(AppRoutes.discovery),
                              icon: const Icon(Icons.search_rounded),
                              label: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text('Find my TV'),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () => _leave(AppRoutes.remote),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    surfaces?.textSecondary ??
                                    theme.colorScheme.onSurface,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSpacing.sm,
                                ),
                                child: Text('Explore app first'),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The app mark: a soft static glow behind an expanding ring (the same
/// [AnimatedConnectionRing] the pairing/connecting states use, so the
/// "remote" motif is consistent across the app, not reinvented here),
/// around a raised-surface badge holding the app icon. The ring already
/// renders a static outline under reduced motion; [pulse] only breathes
/// the outer glow's intensity, which reduced motion also holds still.
class _Hero extends StatelessWidget {
  const _Hero({required this.pulse, required this.reducedMotion});

  final Animation<double> pulse;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = reducedMotion ? 0.5 : pulse.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.glow.withValues(alpha: 0.12 + t * 0.10),
                    AppColors.glow.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: AnimatedConnectionRing(
        active: true,
        color: AppColors.glow,
        size: 156,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: surfaces?.surfaceRaised,
            border: Border.all(color: surfaces?.border ?? theme.dividerColor),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.settings_remote_rounded,
            size: 44,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// The two "before you start" facts, grouped into one bordered surface
/// instead of floating loose on the background - the card/surface
/// treatment the rest of the app already uses for grouped information.
class _RequirementsCard extends StatelessWidget {
  const _RequirementsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaces = theme.extension<AppSurfaceColors>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: surfaces?.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: surfaces?.border ?? theme.dividerColor),
      ),
      child: const Column(
        children: [
          _RequirementRow(
            icon: Icons.wifi_rounded,
            text:
                'Your phone and TV need to be on the same Wi-Fi network to '
                'be discovered.',
          ),
          SizedBox(height: AppSpacing.md),
          Divider(height: 1),
          SizedBox(height: AppSpacing.md),
          _RequirementRow(
            icon: Icons.privacy_tip_outlined,
            text:
                "We'll ask for local network permission next, used only to "
                'find your TVs.',
          ),
        ],
      ),
    );
  }
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
