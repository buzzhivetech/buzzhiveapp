import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

/// Requests the Bluetooth and location permissions required for BLE scanning.
///
/// Returns `true` if all necessary permissions are granted, `false` otherwise.
/// On Android 12+ (API 31), requests BLUETOOTH_SCAN and BLUETOOTH_CONNECT.
/// On older Android, requests ACCESS_FINE_LOCATION.
/// On iOS, requests Bluetooth (handled automatically by flutter_reactive_ble).
Future<bool> ensureBlePermissions() async {
  if (Platform.isAndroid) {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
    final connectOk =
        statuses[Permission.bluetoothConnect]?.isGranted ?? false;
    final locationOk =
        statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    // Android 12+: need scan + connect. Older: need location.
    return (scanOk && connectOk) || locationOk;
  }

  if (Platform.isIOS) {
    final status = await Permission.bluetooth.request();
    return status.isGranted;
  }

  return true;
}
