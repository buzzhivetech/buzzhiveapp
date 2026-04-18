import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../providers/linked_sensors_provider.dart';
import '../../../../providers/sensor_readings_provider.dart';
import '../../application/device_claim_controller.dart';

/// Shared listener used by each tab in [AddSensorScreen]. Watches the
/// [deviceClaimControllerProvider], invalidates downstream data, pops
/// on success, and surfaces failures via a SnackBar.
class ClaimResultHandler extends ConsumerWidget {
  const ClaimResultHandler({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<DeviceClaimState>(deviceClaimControllerProvider, (prev, next) {
      if (next is DeviceClaimSuccess) {
        ref.invalidate(linkedSensorsProvider);
        ref.invalidate(latestReadingsProvider);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensor linked. Waiting for first reading.')),
        );
        context.pop();
      } else if (next is DeviceClaimFailure) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });
    return child;
  }
}
