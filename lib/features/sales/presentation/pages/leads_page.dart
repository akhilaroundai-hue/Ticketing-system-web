import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../providers/lead_provider.dart';
import '../../domain/entities/lead.dart';

class LeadsPage extends ConsumerStatefulWidget {
  const LeadsPage({super.key});

  @override
  ConsumerState<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends ConsumerState<LeadsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(leadsStreamProvider);

    // Listen to controller errors
    ref.listen(leadControllerProvider, (prev, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${next.error}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return MainLayout(
      currentPath: '/leads',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24), // Updated padding
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pipeline Management',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900, // Updated font weight
                            color: AppColors.slate900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4), // Added SizedBox
                        Text(
                          'Track and manage your sales leads from proposal to conversion.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                            // fontWeight: FontWeight.w400, // Removed font weight
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.invalidate(leadsProvider),
                    icon: const Icon(LucideIcons.refreshCw, size: 20),
                    tooltip: 'Refresh',
                    color: AppColors.slate400,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: LucideIcons.plus,
                    label: 'Add New Lead',
                    onPressed: () => _showLeadDialog(context, ref),
                  ),
                ],
              ),
            ),

            // Pipeline Stats
            leadsAsync.when(
              data: (leads) {
                final totalCount = leads.length;
                final wonCount = leads
                    .where((d) => d.status == 'win')
                    .length;
                final pendingCount = leads
                    .where((d) => d.status == 'pending')
                    .length;

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      _EnhancedStatCard(
                        label: 'Total Pipeline',
                        value: totalCount.toString(),
                        color: AppColors.primary,
                        icon: LucideIcons.trendingUp,
                      ),
                      const SizedBox(width: 16),
                      _EnhancedStatCard(
                        label: 'Won Leads',
                        value: wonCount.toString(),
                        color: AppColors.success,
                        icon: LucideIcons.trophy,
                      ),
                      const SizedBox(width: 16),
                      _EnhancedStatCard(
                        label: 'Active (Pending)',
                        value: pendingCount.toString(),
                        color: AppColors.info,
                        icon: LucideIcons.target,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Kanban Board
            Expanded(
              child: leadsAsync.when(
                data: (leads) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: ['pending', 'win', 'loss'].map((status) {
                        final statusLeads = leads
                            .where((d) => d.status == status)
                            .toList();
                        return _KanbanColumn(
                          status: status,
                          leads: statusLeads,
                          onStageChange: (lead, newStatus) {
                            ref
                                .read(leadControllerProvider.notifier)
                                .updateLeadStatus(lead.id, newStatus);
                          },
                          onDelete: (lead) {
                            ref
                                .read(leadControllerProvider.notifier)
                                .deleteLead(lead.id);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeadDialog(BuildContext context, WidgetRef ref) {
    final companyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('New Sales Lead', style: TextStyle(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      TextField(
                        controller: companyController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          hintText: 'Type company name...',
                          prefixIcon: const Icon(LucideIcons.building2, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: AppColors.slate50,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Discard', style: TextStyle(color: AppColors.slate500)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (companyController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Company name is required')),
                      );
                      return;
                    }

                    ref.read(leadControllerProvider.notifier).createLead(
                          companyName: companyController.text.trim(),
                          amount: 0,
                          status: 'pending',
                        ).then((_) {
                          if (mounted) Navigator.pop(context);
                        });
                  },
                  child: const Text('Create Lead'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onPressed,
    );
  }
}

class _EnhancedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _EnhancedStatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                    textBaseline: TextBaseline.alphabetic,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String status;
  final List<Lead> leads;
  final void Function(Lead, String) onStageChange;
  final void Function(Lead) onDelete;

  const _KanbanColumn({
    required this.status,
    required this.leads,
    required this.onStageChange,
    required this.onDelete,
  });

  Color get statusColor {
    switch (status) {
      case 'pending': return AppColors.info;
      case 'win': return AppColors.success;
      case 'loss': return AppColors.error;
      default: return AppColors.slate500;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'pending': return 'Open Pipeline';
      case 'win': return 'Won Deals';
      case 'loss': return 'Lost Opportunities';
      default: return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor.withValues(alpha: 0.15), statusColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: statusColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusLabel,
                    style: TextStyle(fontWeight: FontWeight.w800, color: statusColor, fontSize: 13),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${leads.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Lead Cards List
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.slate100.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border.all(color: AppColors.slate200),
              ),
              child: leads.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.inbox, color: AppColors.slate300, size: 32),
                          const SizedBox(height: 8),
                          Text('No leads found', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: leads.length,
                      itemBuilder: (context, index) => _LeadCard(
                        lead: leads[index],
                        color: statusColor,
                        onStageChange: (newStage) => onStageChange(leads[index], newStage),
                        onDelete: () => onDelete(leads[index]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final Color color;
  final void Function(String) onStageChange;
  final VoidCallback onDelete;

  const _LeadCard({
    required this.lead,
    required this.color,
    required this.onStageChange,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator line
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lead.companyName,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.slate900),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _confirmDelete(context),
                      child: Icon(LucideIcons.trash2, size: 14, color: AppColors.slate300),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Raised ${DateFormat.MMMd().format(lead.createdAt)}',
                  style: TextStyle(fontSize: 11, color: AppColors.slate400),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                const Text('ACTIONS:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (lead.status == 'pending') ...[
                      _MiniStatusBtn(label: 'CONVERT', color: AppColors.success, onTap: () => onStageChange('win')),
                      _MiniStatusBtn(label: 'LOSS', color: AppColors.error, onTap: () => onStageChange('loss')),
                    ] else ...[
                      _MiniStatusBtn(label: 'UNDO', color: AppColors.info, onTap: () => onStageChange('pending')),
                      if (lead.status == 'win')
                        _MiniStatusBtn(label: 'LOSS', color: AppColors.error, onTap: () => onStageChange('loss'))
                      else
                        _MiniStatusBtn(label: 'CONVERT', color: AppColors.success, onTap: () => onStageChange('win')),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lead'),
        content: Text('Are you sure you want to remove ${lead.companyName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MiniStatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniStatusBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
          ),
        ),
      ),
    );
  }
}
