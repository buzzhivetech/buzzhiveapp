import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/device_claim_controller.dart';
import '../../domain/qr_payload.dart';

/// Primary onboarding path: scan the QR sticker on the device.
///
/// The sticker encodes `buzzhive://claim?d={device_id}&c={claim_code}`.
/// On a successful decode we immediately fire the claim RPC; the shared
/// `ClaimResultHandler` above the tabs pops the screen on success.
class QrScanTab extends ConsumerStatefulWidget {
  const QrScanTab({super.key});

  @override
  ConsumerState<QrScanTab> createState() => _QrScanTabState();
}

class _QrScanTabState extends ConsumerState<QrScanTab> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.qrCode],
  );

  // Guard so we don't fire claim() again for every frame while the RPC runs.
  bool _submitted = false;

  // Permission state starts unknown; we probe in initState.
  _PermissionState _permission = _PermissionState.unknown;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from Settings after granting camera access,
    // re-probe so the scanner view swaps in.
    if (state == AppLifecycleState.resumed &&
        _permission == _PermissionState.denied) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (!mounted) return;
    if (status.isGranted) {
      setState(() => _permission = _PermissionState.granted);
      return;
    }
    if (status.isPermanentlyDenied) {
      setState(() => _permission = _PermissionState.permanentlyDenied);
      return;
    }
    final requested = await Permission.camera.request();
    if (!mounted) return;
    setState(() {
      _permission = requested.isGranted
          ? _PermissionState.granted
          : requested.isPermanentlyDenied
              ? _PermissionState.permanentlyDenied
              : _PermissionState.denied;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_submitted) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    try {
      final payload = QrPayload.parse(raw);
      setState(() {
        _submitted = true;
        _parseError = null;
      });
      _controller.stop();
      ref.read(deviceClaimControllerProvider.notifier).claim(
            deviceId: payload.deviceId,
            claimCode: payload.claimCode,
          );
    } on QrPayloadException catch (e) {
      setState(() => _parseError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset the scanner when the claim controller resets (e.g. user taps the
    // tab away and back after a failure). Keeps re-scanning cheap.
    ref.listen<DeviceClaimState>(deviceClaimControllerProvider, (prev, next) {
      if (next is DeviceClaimFailure && _submitted) {
        setState(() => _submitted = false);
        _controller.start();
      }
    });

    switch (_permission) {
      case _PermissionState.unknown:
        return const Center(child: CircularProgressIndicator());
      case _PermissionState.denied:
        return _PermissionPlaceholder(
          message: 'BuzzHive needs camera access to scan the sensor QR code.',
          actionLabel: 'Grant access',
          onAction: _checkPermission,
        );
      case _PermissionState.permanentlyDenied:
        return const _PermissionPlaceholder(
          message:
              'Camera access was denied. Enable it in Settings to scan QR codes.',
          actionLabel: 'Open Settings',
          onAction: openAppSettings,
        );
      case _PermissionState.granted:
        return _buildScanner(context);
    }
  }

  Widget _buildScanner(BuildContext context) {
    final state = ref.watch(deviceClaimControllerProvider);
    final submitting = state is DeviceClaimSubmitting || _submitted;

    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (ctx, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Camera error: ${error.errorCode.name}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
            ),
          ),
        ),
        // Framing overlay.
        IgnorePointer(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_parseError != null)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _parseError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    submitting
                        ? 'Linking sensor…'
                        : 'Point the camera at the QR code on the sensor sticker.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PermissionState { unknown, granted, denied, permanentlyDenied }

class _PermissionPlaceholder extends StatelessWidget {
  const _PermissionPlaceholder({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => onAction(),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
