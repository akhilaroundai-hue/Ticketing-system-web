import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/design_system/design_system.dart';
import '../providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../../core/design_system/components/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/create_ticket_dialog.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> {
  DateTime? _selectedDate = DateTime.now();
  String _customerQuery = '';
  String _amountQuery = '';
  String _issueQuery = '';
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _issueController = TextEditingController();
  String? _markingTicketId;
  bool _showAnalytics = true;

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = DateTime.now();
      _customerQuery = '';
      _amountQuery = '';
      _issueQuery = '';
      _customerController.clear();
      _amountController.clear();
      _issueController.clear();
    });
  }

  Future<void> _markTicketAsBilled(Ticket ticket) async {
    if (_markingTicketId == ticket.ticketId) return;
    final messenger = ScaffoldMessenger.of(context);
    final currentUser = ref.read(authProvider);
    if (currentUser?.isAccountant != true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Only accountants can mark bills as processed.'),
        ),
      );
      return;
    }

    setState(() => _markingTicketId = ticket.ticketId);
    final error = await ref
        .read(ticketStatusUpdaterProvider.notifier)
        .updateStatus(ticket.ticketId, 'Closed');
    if (!mounted) return;
    setState(() => _markingTicketId = null);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Marked as billed and completed' : 'Failed to update: $error',
        ),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final currentUser = ref.watch(authProvider);
    final isAccountant = currentUser?.isAccountant == true;

    return MainLayout(
      currentPath: '/bills',
      child: Container(
        color: AppColors.slate50,
        child: ticketsAsync.when(
          data: (tickets) {
            return customersAsync.when(
              data: (customers) {
                return agentsAsync.when(
                  data: (agents) {
                    // Filter logic
                    final filteredTickets = tickets.where((t) {
                      final hasBillAmount = (t.billAmount ?? 0) > 0;
                      final isBillTicket = t.status == 'BillRaised' ||
                          t.status == 'BillProcessed' ||
                          (t.status == 'Closed' && hasBillAmount);
                      if (!isBillTicket) return false;

                      // Date filter
                      if (_selectedDate != null) {
                        final updatedAt = t.updatedAt ?? DateTime(0);
                        if (updatedAt.year != _selectedDate!.year ||
                            updatedAt.month != _selectedDate!.month ||
                            updatedAt.day != _selectedDate!.day) {
                          return false;
                        }
                      }

                      // Customer filter
                      if (_customerQuery.isNotEmpty) {
                        final customer = customers.firstWhere(
                          (c) => c.id == t.customerId,
                          orElse: () => const Customer(
                            id: '',
                            companyName: 'Unknown',
                          ),
                        );
                        if (!customer.companyName
                            .toLowerCase()
                            .contains(_customerQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      // Issue filter
                      if (_issueQuery.isNotEmpty) {
                        if (!t.title
                            .toLowerCase()
                            .contains(_issueQuery.toLowerCase())) {
                          return false;
                        }
                      }

                      // Amount filter
                      if (_amountQuery.isNotEmpty) {
                        final amount = t.billAmount?.toString() ?? '';
                        if (!amount.contains(_amountQuery)) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    // Sort: newest first
                    filteredTickets.sort(
                      (a, b) => (b.updatedAt ?? DateTime(0))
                          .compareTo(a.updatedAt ?? DateTime(0)),
                    );

                    final billedStatuses = {'Closed'};
                    final billedTotal = filteredTickets
                        .where((t) => billedStatuses.contains(t.status))
                        .fold<double>(
                          0,
                          (prev, t) => prev + (t.billAmount ?? 0),
                        );
                    final awaitingBillingTotal = 0.0;
                    final pendingCompletionTotal = filteredTickets
                        .where((t) => t.status == 'BillRaised')
                        .fold<double>(
                          0,
                          (prev, t) => prev + (t.billAmount ?? 0),
                        );
                    final unbilledTotal =
                        awaitingBillingTotal + pendingCompletionTotal;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isAccountant) ...[
                            AppCard(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(
                                    LucideIcons.info,
                                    size: 18,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Read-only access: only accountants can mark tickets as billed.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: SectionHeader(
                                  title: 'Bills',
                                  subtitle: 'Manage raised bills and payments',
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isAccountant)
                                    FilledButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => const CreateTicketDialog(),
                                        );
                                      },
                                      icon: const Icon(LucideIcons.plus, size: 16),
                                      label: const Text('Create Ticket'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  TextButton.icon(
                                    onPressed: _clearFilters,
                                    icon: const Icon(LucideIcons.rotateCcw, size: 16),
                                    label: const Text('Reset Filters'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Filter Bar
                          _buildFilterBar(),
                          
                          const SizedBox(height: 24),

                          // Analytics Section with Hide/Show toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Analytics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate900,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _showAnalytics = !_showAnalytics),
                                icon: Icon(
                                  _showAnalytics ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 16,
                                ),
                                label: Text(_showAnalytics ? 'Hide' : 'Show'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                          if (_showAnalytics) ...[
                            const SizedBox(height: 12),
                            _buildTotalsCard(
                              billedTotal: billedTotal,
                              unbilledTotal: unbilledTotal,
                              awaitingBillingTotal: awaitingBillingTotal,
                              pendingCompletionTotal: pendingCompletionTotal,
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Bills List
                          if (filteredTickets.isEmpty)
                            const EmptyStateCard(
                              icon: LucideIcons.receipt,
                              title: 'No bills found',
                              subtitle: 'Try adjusting your filters',
                            )
                          else
                            ...filteredTickets.map((ticket) {
                              final customer = customers.firstWhere(
                                (c) => c.id == ticket.customerId,
                                orElse: () => const Customer(id: '', companyName: 'Unknown'),
                              );
                              final agent = agents.firstWhere(
                                (a) => a['id'] == ticket.assignedTo,
                                orElse: () => <String, dynamic>{'username': 'Unknown'},
                              );
                              final agentName = agent['full_name'] ?? agent['username'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _BillListItem(
                                  ticket: ticket,
                                  customerName: customer.companyName,
                                  agentName: agentName,
                                  onMarkAsBilled: ticket.status == 'BillRaised'
                                      ? () => _markTicketAsBilled(ticket)
                                      : null,
                                  isProcessing: _markingTicketId == ticket.ticketId,
                                  canMarkAsBilled: isAccountant,
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading bills: $err')),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Date Filter
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.slate200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDate == null
                              ? 'Filter by Date'
                              : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                          style: TextStyle(
                            fontSize: 13,
                            color: _selectedDate == null ? AppColors.slate400 : AppColors.slate900,
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDate != null)
                          IconButton(
                            icon: const Icon(LucideIcons.x, size: 14),
                            onPressed: () => setState(() => _selectedDate = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Customer Search
              Expanded(
                flex: 3,
                child: _buildSearchField(
                  controller: _customerController,
                  hint: 'Search Customer...',
                  icon: LucideIcons.building,
                  onChanged: (val) => setState(() => _customerQuery = val),
                  onClear: () {
                    _customerController.clear();
                    setState(() => _customerQuery = '');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Issue Name Search
              Expanded(
                flex: 3,
                child: _buildSearchField(
                  controller: _issueController,
                  hint: 'Search Issue...',
                  icon: LucideIcons.ticket,
                  onChanged: (val) => setState(() => _issueQuery = val),
                  onClear: () {
                    _issueController.clear();
                    setState(() => _issueQuery = '');
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Amount Filter
              Expanded(
                flex: 2,
                child: _buildSearchField(
                  controller: _amountController,
                  hint: 'Amount (₹)...',
                  icon: LucideIcons.indianRupee,
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(() => _amountQuery = val),
                  onClear: () {
                    _amountController.clear();
                    setState(() => _amountQuery = '');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.slate400),
          prefixIcon: Icon(icon, size: 16, color: AppColors.slate500),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 14),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
        ),
      ),
    );
  }

  Widget _buildTotalsCard({
    required double billedTotal,
    required double unbilledTotal,
    required double awaitingBillingTotal,
    required double pendingCompletionTotal,
  }) {
    final grandTotal = billedTotal + unbilledTotal;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.indianRupee,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Bill Amount',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _AmountSummaryTile(
                label: 'Collected (Billed)',
                amount: billedTotal,
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _AmountSummaryTile(
                label: 'Unbilled Total',
                amount: unbilledTotal,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AmountSummaryTile(
                label: 'Awaiting Billing (Closed)',
                amount: awaitingBillingTotal,
                color: AppColors.info,
              ),
              const SizedBox(width: 12),
              _AmountSummaryTile(
                label: 'Pending Completion (Bill Raised)',
                amount: pendingCompletionTotal,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillListItem extends StatelessWidget {
  final Ticket ticket;
  final String customerName;
  final String agentName;
  final VoidCallback? onMarkAsBilled;
  final bool isProcessing;
  final bool canMarkAsBilled;

  const _BillListItem({
    required this.ticket,
    required this.customerName,
    required this.agentName,
    required this.canMarkAsBilled,
    this.onMarkAsBilled,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Left Section: Issue & Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.building, size: 14, color: AppColors.slate400),
                    const SizedBox(width: 6),
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Section: Amount & Status & Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${ticket.billAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: _statusLabel(ticket.status),
                    variant: _statusVariant(ticket.status),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    ticket.updatedAt != null ? timeago.format(ticket.updatedAt!) : '',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Raised by: $agentName',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
              if (onMarkAsBilled != null && canMarkAsBilled) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : onMarkAsBilled,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.checkCircle, size: 16),
                    label: Text(
                      isProcessing ? 'Marking...' : 'Mark as Billed',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'BillRaised':
      return 'Pending';
    case 'BillProcessed':
      return 'Billed';
    case 'Closed':
      return 'Billed & Completed';
    default:
      return status;
  }
}

StatusVariant _statusVariant(String status) {
  switch (status) {
    case 'BillRaised':
      return StatusVariant.warning;
    case 'BillProcessed':
      return StatusVariant.success;
    case 'Closed':
      return StatusVariant.info;
    default:
      return StatusVariant.neutral;
  }
}

class _AmountSummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountSummaryTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = _darkenColor(color);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _darkenColor(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness(
    (hsl.lightness - amount).clamp(0.0, 1.0),
  );
  return darkened.toColor();
}
