import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';


class SalesOpportunityPage extends ConsumerWidget {
  const SalesOpportunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/sales-opportunity',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Unclaimed Tickets',
                subtitle: 'All tickets awaiting assignment',
              ),
              const SizedBox(height: 24),

              // Excel-like Table
              Expanded(
                child: ticketsAsync.when(
                  data: (allTickets) {
                    // Filter unclaimed tickets
                    final unclaimedTickets = allTickets
                        .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                        .toList()
                      ..sort(
                        (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                          a.createdAt ?? DateTime(0),
                        ),
                      );

                    if (unclaimedTickets.isEmpty) {
                      return const EmptyStateCard(
                        icon: LucideIcons.checkCircle,
                        title: 'All tickets are claimed!',
                        subtitle: 'Great work!',
                      );
                    }

                    return customersAsync.when(
                      data: (customers) {
                        final customersById = {
                          for (final c in customers) c.id: c
                        };

                        return _UnclaimedTicketsTable(
                          tickets: unclaimedTickets,
                          customersById: customersById,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error loading customers: $err'),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    child: Text('Error loading tickets: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnclaimedTicketsTable extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, Customer> customersById;

  const _UnclaimedTicketsTable({
    required this.tickets,
    required this.customersById,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _HeaderCell('Ticket ID', flex: 1),
                _HeaderCell('Title', flex: 3),
                _HeaderCell('Customer', flex: 2),
                _HeaderCell('Priority', flex: 1),
                _HeaderCell('Status', flex: 1),
                _HeaderCell('Created', flex: 2),
                _HeaderCell('Category', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table Body
          Expanded(
            child: ListView.separated(
              itemCount: tickets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final customer = customersById[ticket.customerId];
                final isAmc = customer?.isAmcActive ?? false;

                return InkWell(
                  onTap: () => context.go('/ticket/${ticket.ticketId}'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _DataCell(
                          ticket.ticketId,
                          flex: 1,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _DataCell(
                          ticket.title,
                          flex: 3,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        _DataCell(
                          customer?.companyName ?? 'Unknown',
                          flex: 2,
                          badge: isAmc
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.info.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'AMC',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        _DataCell(
                          ticket.priority ?? 'Medium',
                          flex: 1,
                          badge: _getPriorityBadge(ticket.priority),
                        ),
                        _DataCell(
                          ticket.status,
                          flex: 1,
                          badge: _getStatusBadge(ticket.status),
                        ),
                        _DataCell(
                          _formatDate(ticket.createdAt),
                          flex: 2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate600,
                          ),
                        ),
                        _DataCell(
                          ticket.category ?? 'General',
                          flex: 1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('HH:mm').format(date);
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  Widget _getPriorityBadge(String? priority) {
    Color color;
    switch (priority?.toLowerCase()) {
      case 'urgent':
        color = AppColors.error;
        break;
      case 'high':
        color = Colors.orange;
        break;
      case 'low':
        color = AppColors.slate400;
        break;
      default:
        color = AppColors.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority ?? 'Medium',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _getStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'new':
        color = AppColors.info;
        break;
      case 'open':
        color = AppColors.primary;
        break;
      case 'in progress':
      case 'inprogress':
        color = Colors.orange;
        break;
      case 'resolved':
      case 'closed':
        color = AppColors.success;
        break;
      default:
        color = AppColors.slate500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.slate700,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final TextStyle? style;
  final Widget? badge;

  const _DataCell(
    this.text, {
    required this.flex,
    this.style,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: badge != null
          ? badge!
          : Text(
              text,
              style: style ??
                  const TextStyle(
                    fontSize: 13,
                    color: AppColors.slate900,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
