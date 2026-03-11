import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/sensor_readings_provider.dart';

class AddSensorScreen extends ConsumerStatefulWidget {
  const AddSensorScreen({super.key});

  @override
  ConsumerState<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends ConsumerState<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sensorIdController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _sensorIdController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _linkSensor() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final sensorId = _sensorIdController.text.trim();
    final displayName = _displayNameController.text.trim().isEmpty
        ? null
        : _displayNameController.text.trim();

    if (sensorId.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a sensor ID';
        _isLoading = false;
      });
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() {
        _errorMessage = 'You must be signed in to link a sensor';
        _isLoading = false;
      });
      return;
    }

    final dataRepo = ref.read(sensorDataRepositoryProvider);
    final linkRepo = ref.read(sensorLinkRepositoryProvider);

    try {
      final exists = await dataRepo.sensorExists(sensorId);
      if (!exists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Sensor not found. Check the ID and try again.';
            _isLoading = false;
          });
        }
        return;
      }

      await linkRepo.linkSensor(userId, sensorId, displayName: displayName);
      ref.invalidate(linkedSensorsProvider);
      ref.invalidate(latestReadingsProvider);
      if (mounted) {
        context.pop();
      }
    } on ValidationException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sensor'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Link a sensor by its ID. The sensor must exist in the system (Firebase).',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _sensorIdController,
                  decoration: const InputDecoration(
                    labelText: 'Sensor ID',
                    hintText: 'e.g. 10001',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a sensor ID';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _linkSensor(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                    hintText: 'e.g. Back yard hive',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) => _linkSensor(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _linkSensor,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Link sensor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
