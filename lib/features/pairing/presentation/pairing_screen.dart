import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routing/app_router.dart';
import '../../../core/design/app_spacing.dart';
import '../../../tv/application/tv_session_controller.dart';
import '../../../tv/domain/tv_domain.dart';

/// Handles both pairing flows exposed by [TvPairingRequest]: a PIN the user
/// types in, or a prompt they must confirm on the TV itself.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(tvSessionControllerProvider);

    ref.listen(tvSessionControllerProvider, (previous, next) {
      if (next.isConnected) {
        context.go(AppRoutes.remote);
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
              const Icon(Icons.pin_rounded, size: 48),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enter the ${pairingRequest.expectedLength}-digit code shown on your TV',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: pairingRequest.expectedLength,
                style: const TextStyle(fontSize: 28, letterSpacing: 8),
                decoration: const InputDecoration(counterText: ''),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => ref
                      .read(tvSessionControllerProvider.notifier)
                      .submitPairingCode(_codeController.text),
                  child: const Text('Confirm'),
                ),
              ),
            ] else if (pairingRequest is TvConfirmOnDevicePairingRequest) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Confirm the pairing request on your TV screen',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              const Text('Connecting…'),
            ],
          ],
        ),
      ),
    );
  }
}
