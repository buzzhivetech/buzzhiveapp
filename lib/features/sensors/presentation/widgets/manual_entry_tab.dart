import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/device_claim_controller.dart';

/// Fallback tab: user types the device ID and claim code from the sticker.
class ManualEntryTab extends ConsumerStatefulWidget {
  const ManualEntryTab({super.key, this.initialDeviceId});

  final String? initialDeviceId;

  @override
  ConsumerState<ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends ConsumerState<ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deviceIdController;
  final _claimCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _deviceIdController = TextEditingController(text: widget.initialDeviceId ?? '');
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _claimCodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(deviceClaimControllerProvider.notifier).claim(
          deviceId: _deviceIdController.text.trim(),
          claimCode: _claimCodeController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceClaimControllerProvider);
    final submitting = state is DeviceClaimSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Type the device ID and claim code printed on the sticker on the back of your sensor.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _deviceIdController,
              decoration: const InputDecoration(
                labelText: 'Device ID',
                hintText: 'e.g. 10001',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter the device ID' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _claimCodeController,
              decoration: const InputDecoration(
                labelText: 'Claim code',
                hintText: '8 characters (e.g. 7K3M9PQT)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) => submitting ? null : _submit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter the claim code';
                if (v.trim().length < 6) return 'Claim code looks too short';
                return null;
              },
            ),
            if (state is DeviceClaimFailure) ...[
              const SizedBox(height: 16),
              Text(
                state.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: submitting ? null : _submit,
              child: submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Claim sensor'),
            ),
          ],
        ),
      ),
    );
  }
}
