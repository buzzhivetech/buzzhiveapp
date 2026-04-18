import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/ble_scan_tab.dart';
import 'widgets/claim_result_handler.dart';
import 'widgets/manual_entry_tab.dart';
import 'widgets/qr_scan_tab.dart';

/// Customer-ready onboarding for a BuzzHive sensor.
///
/// Three ways in, in order of preference:
///   1. QR scan   — primary. Sticker encodes buzzhive://claim?d=&c=.
///   2. BLE scan  — for factory-fresh devices powered on nearby.
///   3. Manual    — always-works fallback when the sticker is damaged.
///
/// All three funnel into [DeviceClaimRepository.claim] (via the
/// controller) which hits the `claim_sensor` Supabase RPC.
class AddSensorScreen extends ConsumerWidget {
  const AddSensorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Sensor'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
              Tab(icon: Icon(Icons.bluetooth_searching), text: 'Bluetooth'),
              Tab(icon: Icon(Icons.keyboard), text: 'Manual'),
            ],
          ),
        ),
        body: const ClaimResultHandler(
          child: SafeArea(
            child: TabBarView(
              children: [
                QrScanTab(),
                BleScanTab(),
                ManualEntryTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
