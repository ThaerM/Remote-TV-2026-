import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../tv/application/tv_session_controller.dart';

/// Lets the user reach a TV that discovery can't see (another subnet, a
/// router that blocks multicast, a phone that restricts it) by typing its
/// address. Every provider probes the address; only a TV whose protocol
/// actually answers is added.
class AddTvByAddressSheet extends ConsumerStatefulWidget {
  const AddTvByAddressSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const AddTvByAddressSheet(),
    );
  }

  @override
  ConsumerState<AddTvByAddressSheet> createState() =>
      _AddTvByAddressSheetState();
}

class _AddTvByAddressSheetState extends ConsumerState<AddTvByAddressSheet> {
  final _controller = TextEditingController();
  String? _error;

  static final _validAddress = RegExp(r'^[A-Za-z0-9.\-:_\[\]]+$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final address = _controller.text.trim();
    if (address.isEmpty || !_validAddress.hasMatch(address)) {
      setState(() => _error = 'Enter an IP address like 192.168.1.20.');
      return;
    }
    setState(() => _error = null);
    final added = await ref
        .read(tvSessionControllerProvider.notifier)
        .addDeviceByAddress(address);
    if (!mounted) return;
    if (added == 0) {
      setState(
        () => _error =
            'No supported TV answered at $address. Check the address and '
            'that the TV is on.',
      );
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isProbing = ref.watch(
      tvSessionControllerProvider.select((s) => s.isProbing),
    );
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add TV by IP address', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "You'll usually find it on the TV under Settings > Network > "
            'Status. The TV must be on.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !isProbing,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'IP address',
              hintText: '192.168.1.20',
              errorText: _error,
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: isProbing ? null : _submit,
            child: isProbing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add TV'),
          ),
        ],
      ),
    );
  }
}
