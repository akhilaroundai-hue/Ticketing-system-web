import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_button.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';

class AccountantDashboardPage extends ConsumerStatefulWidget {
  const AccountantDashboardPage({super.key});

  @override
  ConsumerState<AccountantDashboardPage> createState() =>
      _AccountantDashboardPageState();
}

class _AccountantDashboardPageState
    extends ConsumerState<AccountantDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _priorityFilter = 'All';
  String _customerFilter = 'all';
  String _sortOption = 'newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/accountant',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accountant Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage billing and payments',
                    style: TextStyle(fontSize: 14, color: AppColors.slate500),
                  ),
                  const SizedBox(height: 16),

                  ticketsAsync.when(
                    data: (tickets) {
                      final now = DateTime.now();
                      final pending = tickets
                          .where((t) => t.status == 'BillRaised')
                          .toList();
                      final billed = tickets
                          .where(
                            (t) =>
                                t.status == 'BillProcessed' ||
                                t.status == 'Closed',
                          )
                          .toList();
                      final lastWeek = now.subtract(const Duration(days: 7));
                      final processedThisWeek = billed
                          .where(
                            (t) =>
                                (t.createdAt ?? DateTime(0)).isAfter(lastWeek),
                          )
                          .length;

                      Duration totalAge = Duration.zero;
                      for (final t in pending) {
                        final createdAt = t.createdAt;
                        if (createdAt != null) {
                          totalAge += now.difference(createdAt);
                        }
                      }
                      final avgAgeDays = pending.isEmpty
                          ? 0.0
                          : totalAge.inHours / 24.0 / pending.length;

                      return Row(
                        children: [
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pending bills',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pending.length.toString(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Processed this week',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    processedThisWeek.toString(),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Avg pending age (days)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    avgAgeDays.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  customersAsync.when(
                    data: (customers) {
                      final priorityDropdown = DropdownButtonFormField<String>(
                        initialValue: _priorityFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All priorities'),
                          ),
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'Normal',
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                          DropdownMenuItem(
                            value: 'Critical',
                            child: Text('Critical'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _priorityFilter = value;
                          });
                        },
                      );

                      final customerDropdown = DropdownButtonFormField<String>(
                        initialValue: _customerFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All customers'),
                          ),
                          ...customers.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.companyName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _customerFilter = value;
                          });
                        },
                      );

                      final sortDropdownField = DropdownButtonFormField<String>(
                        initialValue: _sortOption,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('Sort: Newest first'),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: Text('Sort: Oldest first'),
                          ),
                          DropdownMenuItem(
                            value: 'priority',
                            child: Text('Sort: Priority high → low'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _sortOption = value;
                          });
                        },
                      );

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 900;
                          if (isNarrow) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: priorityDropdown),
                                    const SizedBox(width: 12),
                                    Expanded(child: sortDropdownField),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: customerDropdown,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Flexible(flex: 2, child: priorityDropdown),
                              const SizedBox(width: 12),
                              Flexible(flex: 6, child: customerDropdown),
                              const SizedBox(width: 12),
                              Flexible(flex: 3, child: sortDropdownField),
                            ],
                          );
                        },
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 16),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.slate600,
                      tabs: const [
                        Tab(
                          icon: Icon(LucideIcons.clock),
                          text: 'Pending Billing',
                        ),
                        Tab(
                          icon: Icon(LucideIcons.checkCircle),
                          text: 'Billed',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Pending Billing Tab
                  _buildTicketList(
                    ticketsAsync,
                    filter: (ticket) => ticket.status == 'BillRaised',
                    emptyMessage: 'No pending bills',
                    showProcessButton: true,
                  ),
                  // Billed Tab
                  _buildTicketList(
                    ticketsAsync,
                    filter: (ticket) =>
                        ticket.status == 'Closed' ||
                        ticket.status == 'BillProcessed',
                    emptyMessage: 'No processed bills',
                    showProcessButton: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(
    AsyncValue<List<Ticket>> ticketsAsync, {
    required bool Function(Ticket) filter,
    required String emptyMessage,
    required bool showProcessButton,
  }) {
    return ticketsAsync.when(
      data: (tickets) {
        final baseTickets = tickets.where(filter).toList();
        final filteredTickets = _applyFiltersAndSorting(baseTickets);

        if (filteredTickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.receipt, size: 48, color: AppColors.slate300),
                const SizedBox(height: 16),
                Text(emptyMessage, style: TextStyle(color: AppColors.slate500)),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: AppButton.ghost(
                  label: 'Copy CSV',
                  icon: LucideIcons.download,
                  onPressed: filteredTickets.isEmpty
                      ? null
                      : () => _copyCsv(filteredTickets),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: filteredTickets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];
                    return AppCard(
                      onTap: () => context.push('/ticket/${ticket.ticketId}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ticket #${ticket.ticketId.substring(0, 8)} · Priority: ${ticket.priority}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                    Text(
                                      'Customer: ${ticket.customerId}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (showProcessButton)
                                AppButton(
                                  label: 'Process Bill',
                                  icon: LucideIcons.checkCircle,
                                  onPressed: () async {
                                    final error = await ref
                                        .read(
                                          ticketStatusUpdaterProvider.notifier,
                                        )
                                        .updateStatus(
                                          ticket.ticketId,
                                          'Closed',
                                        );
                                    if (context.mounted) {
                                      final success = error == null;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Bill processed'
                                                : 'Failed to process: $error',
                                          ),
                                          backgroundColor: success
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Show assigned agent
                          if (ticket.assignedTo != null &&
                              ticket.assignedTo!.isNotEmpty)
                            ref
                                .watch(
                                  ticketAssignedAgentProvider(
                                    ticket.assignedTo,
                                  ),
                                )
                                .when(
                                  data: (agentData) {
                                    if (agentData == null) {
                                      return const SizedBox();
                                    }
                                    return Row(
                                      children: [
                                        Icon(
                                          LucideIcons.user,
                                          size: 14,
                                          color: AppColors.slate500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Handled by: ${agentData['username']}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.slate600,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () => const SizedBox(),
                                  error: (_, __) => const SizedBox(),
                                ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  List<Ticket> _applyFiltersAndSorting(List<Ticket> tickets) {
    var result = List<Ticket>.from(tickets);

    if (_priorityFilter != 'All') {
      result = result
          .where(
            (t) =>
                (t.priority ?? '').toLowerCase() ==
                _priorityFilter.toLowerCase(),
          )
          .toList();
    }

    if (_customerFilter != 'all') {
      result = result.where((t) => t.customerId == _customerFilter).toList();
    }

    if (_sortOption == 'priority') {
      result.sort(
        (a, b) =>
            _priorityRank(b.priority).compareTo(_priorityRank(a.priority)),
      );
    } else if (_sortOption == 'oldest') {
      result.sort(
        (a, b) =>
            (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)),
      );
    } else {
      result.sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
    }

    return result;
  }

  int _priorityRank(String? priority) {
    if (priority == null) return 0;
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  Future<void> _copyCsv(List<Ticket> tickets) async {
    if (tickets.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('ticketId,title,customerId,priority,status,createdAt');

    for (final t in tickets) {
      final safeTitle = t.title.replaceAll('"', '""');
      buffer.writeln(
        '"${t.ticketId}","$safeTitle","${t.customerId}","${t.priority}","${t.status}","${(t.createdAt ?? DateTime.now()).toIso8601String()}"',
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${tickets.length} rows as CSV to clipboard'),
      ),
    );
  }
}
