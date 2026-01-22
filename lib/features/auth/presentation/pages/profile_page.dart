import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final isSupport = user?.isSupport == true;

    return MainLayout(
      currentPath: '/profile',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'My Profile'),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.slate200,
                      child: Icon(
                        LucideIcons.user,
                        size: 40,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'User',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      user?.role ?? 'Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildInfoRow('Username', user?.username ?? '-'),
                    const Divider(height: 32),
                    _buildInfoRow('Full name', user?.fullName ?? '-'),
                  ],
                ),
              ),
              if (isSupport) ...[
                const SizedBox(height: 24),
                const Text(
                  'My Support Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: ticketsAsync.when(
                    data: (tickets) {
                      final currentUser = user;
                      if (currentUser == null) {
                        return const Text(
                          'No agent information available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                          ),
                        );
                      }

                      final myTickets = tickets
                          .where((t) => t.assignedTo == currentUser.id)
                          .toList();

                      if (myTickets.isEmpty) {
                        return const Text(
                          'No tickets assigned to you yet. Your support stats will appear here once you start working on tickets.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                          ),
                        );
                      }

                      final now = DateTime.now();
                      final lookbackStart = now.subtract(
                        const Duration(days: 30),
                      );
                      final resolvedStatuses = <String>[
                        'Resolved',
                        'Closed',
                        'BillProcessed',
                      ];

                      final myResolvedLast30d = myTickets.where((t) {
                        if (!resolvedStatuses.contains(t.status)) return false;
                        final updatedAt = t.updatedAt;
                        if (updatedAt == null) return false;
                        return updatedAt.isAfter(lookbackStart);
                      }).toList();

                      final myActive = myTickets
                          .where((t) => !resolvedStatuses.contains(t.status))
                          .length;

                      Duration totalResolution = Duration.zero;
                      for (final t in myResolvedLast30d) {
                        final updatedAt = t.updatedAt;
                        final createdAt = t.createdAt;
                        if (updatedAt != null && createdAt != null) {
                          totalResolution += updatedAt.difference(createdAt);
                        }
                      }

                      double? avgResolutionHours;
                      if (myResolvedLast30d.isNotEmpty) {
                        avgResolutionHours =
                            totalResolution.inMinutes /
                            myResolvedLast30d.length /
                            60.0;
                      }

                      String avgResolutionLabel;
                      if (avgResolutionHours == null) {
                        avgResolutionLabel = '—';
                      } else if (avgResolutionHours >= 48) {
                        final days = avgResolutionHours / 24.0;
                        avgResolutionLabel = '${days.toStringAsFixed(1)} d';
                      } else {
                        avgResolutionLabel =
                            '${avgResolutionHours.toStringAsFixed(1)} h';
                      }

                      bool isResolvedStatus(String status) =>
                          resolvedStatuses.contains(status);

                      final mySlaWarnings = myTickets.where((t) {
                        if (isResolvedStatus(t.status)) return false;
                        final slaDue = t.slaDue;
                        if (slaDue == null) return false;
                        final remainingMinutes = slaDue
                            .difference(now)
                            .inMinutes;
                        return remainingMinutes <= 60;
                      }).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Based on the last 30 days of ticket activity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SupportProfileStat(
                                label: 'Assigned to me (all time)',
                                value: myTickets.length.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Active now',
                                value: myActive.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Resolved (last 30d)',
                                value: myResolvedLast30d.length.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Avg resolution time',
                                value: avgResolutionLabel,
                              ),
                              _SupportProfileStat(
                                label: 'Response time warnings',
                                value: mySlaWarnings.toString(),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Error loading support metrics: $err',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Change Password',
                        icon: LucideIcons.lock,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const _ChangePasswordDialog(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Logout',
                        icon: LucideIcons.logOut,
                        variant: AppButtonVariant.destructive,
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.slate500)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.slate900,
          ),
        ),
      ],
    );
  }
}

class _SupportProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _SupportProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider);
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    final currentPassword = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final response = await client.rpc(
        'change_agent_password',
        params: {
          'p_agent_id': user.id,
          'p_current_password': currentPassword,
          'p_new_password': newPassword,
        },
      );

      if (!mounted) return;

      final success = response is Map && (response['success'] == true);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final message = (response is Map && response['message'] is String)
            ? response['message'] as String
            : 'Failed to change password. Please check your current password.';
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error changing password: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password should be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: _isSubmitting ? 'Saving...' : 'Update Password',
                      icon: LucideIcons.check,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
