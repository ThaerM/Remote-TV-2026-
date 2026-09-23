import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';

/// Short-lived success state shown right after pairing completes, before
/// handing off to the Remote screen. Deliberately brief - no artificial
/// delay beyond the entrance animation itself.
class ConnectedSuccessScreen extends ConsumerStatefulWidget {
  const ConnectedSuccessScreen({super.key});

  @override
  ConsumerState<ConnectedSuccessScreen> createState() =>
      _ConnectedSuccessScreenState();
}

class _ConnectedSuccessScreenState extends ConsumerState<ConnectedSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = ref.watch(
      tvSessionControllerProvider.select((s) => s.selectedDevice?.name),
    );

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeOutBack,
                ),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Connected!',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                deviceName ?? 'Your TV',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(AppRoutes.remote),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text('Go to Remote'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.go(AppRoutes.devices),
                child: const Text('Manage Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
