import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../models/user_sensor_link.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/linked_sensors_provider.dart';
import '../../../providers/profile_provider.dart';
import 'package:buzzhive_app/providers/sensor_readings_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final email = ref.watch(currentUserEmailProvider);
    final userId = ref.watch(currentUserIdProvider);
    final linksAsync = ref.watch(linkedSensorsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _AccountSection(
            title: 'Account information',
            child: profileAsync.when(
              data: (profile) {
                final displayName = profile?.displayName?.isNotEmpty == true
                    ? profile!.displayName
                    : null;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Email', value: email ?? '—'),
                    if (displayName != null)
                      _InfoRow(label: 'Display name', value: displayName),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  err.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _AccountSection(
            title: 'Account settings',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Change email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangeEmailDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _AccountSection(
            title: 'Linked sensors',
            child: linksAsync.when(
              data: (links) {
                if (links.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No sensors linked.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.go(Routes.sensors),
                          icon: const Icon(Icons.sensors),
                          label: const Text('Go to My Sensors'),
                        ),
                      ],
                    ),
                  );
                }
                if (userId == null) return const SizedBox.shrink();
                return Column(
                  children: links
                      .map((link) => _AccountSensorTile(
                            link: link,
                            userId: userId,
                          ))
                      .toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      err.toString(),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(linkedSensorsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          const _LogoutButton(),
          const SizedBox(height: 12),
          const _DeleteAccountButton(),
        ],
      ),
    );
  }

  void _showChangeEmailDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'New email',
            hintText: 'you@example.com',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newEmail = controller.text.trim();
              if (newEmail.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await ref.read(authRepositoryProvider).updateEmail(newEmail);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmation sent to your new email.')),
                  );
                }
              } on AppException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    bool obscure = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New password',
                  hintText: 'At least 6 characters',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final pw = controller.text;
                final confirm = confirmController.text;
                if (pw.isEmpty || pw.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password must be at least 6 characters.')),
                  );
                  return;
                }
                if (pw != confirm) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match.')),
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                try {
                  await ref.read(authRepositoryProvider).updatePassword(pw);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated.')),
                    );
                  }
                } on AppException catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message)),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _AccountSensorTile extends ConsumerStatefulWidget {
  const _AccountSensorTile({
    required this.link,
    required this.userId,
  });

  final UserSensorLink link;
  final String userId;

  @override
  ConsumerState<_AccountSensorTile> createState() => _AccountSensorTileState();
}

class _AccountSensorTileState extends ConsumerState<_AccountSensorTile> {
  bool _busy = false;

  Future<void> _rename() async {
    final currentName = widget.link.displayName ??
        widget.link.sensor.displayName ??
        widget.link.sensor.firebaseSensorId;
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename sensor'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Sensor name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == currentName) return;

    setState(() => _busy = true);
    try {
      await ref.read(sensorLinkRepositoryProvider).renameSensor(
            widget.userId,
            widget.link.sensor.id,
            newName,
          );
      ref.invalidate(linkedSensorsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sensor renamed to "$newName"')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unlink sensor?'),
        content: Text(
          'Remove "${widget.link.displayName ?? widget.link.sensor.firebaseSensorId}" from your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unlink'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(sensorLinkRepositoryProvider).unlinkSensor(
            widget.userId,
            widget.link.sensor.id,
          );
      ref.invalidate(linkedSensorsProvider);
      ref.invalidate(latestReadingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensor unlinked')),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to unlink')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.link.displayName ??
        widget.link.sensor.displayName ??
        widget.link.sensor.firebaseSensorId;
    final subtitle = 'ID: ${widget.link.sensor.firebaseSensorId}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.sensors, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: _busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _rename,
                  tooltip: 'Rename',
                ),
                IconButton(
                  icon: const Icon(Icons.link_off),
                  onPressed: _unlink,
                  tooltip: 'Unlink',
                ),
              ],
            ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    return FilledButton.tonalIcon(
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('You can sign in again anytime.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        try {
          await authRepo.signOut();
          if (context.mounted) context.go(Routes.login);
        } on Object catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Sign out'),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }
}

class _DeleteAccountButton extends ConsumerWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    return OutlinedButton.icon(
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete account?'),
            content: const Text(
              'This will permanently delete your account and unlink all sensors. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Delete permanently'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        try {
          await authRepo.deleteAccount();
          try { await authRepo.signOut(); } on Object catch (_) {}
          if (context.mounted) context.go(Routes.login);
        } on AppException catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message)),
            );
          }
        } on Object catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString())),
            );
          }
        }
      },
      icon: const Icon(Icons.delete_forever),
      label: const Text('Delete account'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
        side: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
