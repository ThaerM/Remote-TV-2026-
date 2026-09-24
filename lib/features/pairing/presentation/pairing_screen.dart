import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/widgets/animated_connection_ring.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';
import '../../settings/application/settings_controller.dart';
import 'widgets/pairing_code_input.dart';

/// Handles both pairing flows exposed by [TvPairingRequest]: a PIN the user
/// types in, or a prompt they must confirm on the TV itself.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();
  final _codeInputKey = GlobalKey<PairingCodeInputState>();
  String? _lastShownError;
  late final TvSessionController _session;

  @override
  void initState() {
    super.initState();
    _session = ref.read(tvSessionControllerProvider.notifier);
  }

  @override
  void dispose() {
    _codeController.dispose();
    // Leaving before pairing finished (Back, or switching tabs) cancels it;
    // a no-op once connected.
    Future.microtask(_session.cancelPairing);
    super.dispose();
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.discovery);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tvSessionControllerProvider);
    final hapticsEnabled = ref.watch(
      settingsControllerProvider.select((s) => s.hapticFeedbackEnabled),
    );

    ref.listen(tvSessionControllerProvider, (previous, next) {
      if (next.isConnected) {
        context.go(AppRoutes.connectedSuccess);
        return;
      }
      // A fresh, non-empty error while still awaiting a PIN means the
      // code we just submitted was rejected - play the error feedback
      // once per distinct error, not on every rebuild.
      if (next.lastError == null) _lastShownError = null;
      if (next.pairingRequest is TvPinPairingRequest &&
          next.lastError != null &&
          next.lastError != _lastShownError) {
        _lastShownError = next.lastError;
        _codeController.clear();
        _codeInputKey.currentState?.shake();
        if (hapticsEnabled) HapticFeedback.mediumImpact();
      }
    });

    final device = session.selectedDevice;
    final pairingRequest = session.pairingRequest;

    return Scaffold(
      appBar: AppBar(title: Text('Pair with ${device?.name ?? 'TV'}')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (pairingRequest is TvPinPairingRequest) ...[
              const AnimatedConnectionRing(
                active: false,
                color: AppColors.glow,
                child: Icon(Icons.pin_rounded, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Enter the code shown on your television.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (pairingRequest.alphabet == TvPinAlphabet.hex) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'It can contain the letters A-F as well as numbers.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PairingCodeInput(
                key: _codeInputKey,
                length: pairingRequest.expectedLength,
                alphabet: pairingRequest.alphabet,
                controller: _codeController,
                onSubmitted: (code) => ref
                    .read(tvSessionControllerProvider.notifier)
                    .submitPairingCode(code),
              ),
              const SizedBox(height: AppSpacing.md),
              if (session.lastError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    session.lastError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => const Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Text(
                      'The code appears on your TV screen once you select this '
                      'device. If you don\'t see it, make sure the TV is awake '
                      'and try again from the previous screen.',
                    ),
                  ),
                ),
                child: const Text('Where do I find the code?'),
              ),
              TextButton(
                onPressed: () => _leave(context),
                child: const Text('Cancel'),
              ),
            ] else if (pairingRequest is TvConfirmOnDevicePairingRequest) ...[
              const AnimatedConnectionRing(
                active: true,
                color: AppColors.glow,
                child: Icon(Icons.tv_rounded, size: 40),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Confirm the pairing request on your TV screen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (session.lastError != null ||
                  session.connectionState == TvConnectionState.error) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  session.lastError ??
                      'The TV did not accept the connection. Try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => _leave(context),
                child: const Text('Cancel'),
              ),
            ] else ...[
              const AnimatedConnectionRing(
                active: true,
                color: AppColors.glow,
                child: Icon(Icons.tv_rounded, size: 40),
              ),
              const SizedBox(height: AppSpacing.md),
              if (session.lastError != null ||
                  session.connectionState == TvConnectionState.error) ...[
                Text(
                  session.lastError ?? 'Could not connect to this TV.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => _leave(context),
                  child: const Text('Back to TVs'),
                ),
              ] else
                Text(
                  'Connecting…',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
