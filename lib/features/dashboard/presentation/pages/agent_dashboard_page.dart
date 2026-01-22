import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../widgets/create_ticket_dialog.dart';
import '../widgets/ticket_card_with_amc.dart';

class AgentDashboardPage extends ConsumerWidget {
  final String currentPath;
  const AgentDashboardPage({super.key, this.currentPath = '/'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreateTicketDialog(isSupport: true),
            );
          },
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: const Text(
            'Create Ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.primary,
        ),
        body: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: WelcomeHeader(
                name: user?.username ?? 'Agent',
                subtitle: "Here's what's happening today",
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppButton.ghost(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () {
                        ref.invalidate(ticketsStreamProvider);
                        ref.invalidate(customersListProvider);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/tickets?view=unclaimed'),
                      icon: const Icon(Icons.list_alt, size: 18),
                      label: const Text(
                        'View All Unclaimed',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tickets List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ticketsAsync.when(
                  data: (tickets) {
                    final customersAsync = ref.watch(customersListProvider);

                    return customersAsync.when(
                      data: (customers) {
                        final customerMap = {for (var c in customers) c.id: c};
                        final today = DateTime.now();

                        // Filter unclaimed tickets
                        final allUnclaimed = tickets
                            .where((t) {
                              final isClosed = ['Resolved', 'Closed'].contains(t.status);
                              final hasAssignee = t.assignedTo != null && t.assignedTo!.isNotEmpty;
                              return !isClosed && !hasAssignee;
                            })
                            .toList();

                        // Today's unclaimed tickets
                        final todayUnclaimed = allUnclaimed
                            .where((t) {
                              final createdDate = (t.createdAt ?? DateTime(1970)).toLocal();
                              return createdDate.year == today.year &&
                                  createdDate.month == today.month &&
                                  createdDate.day == today.day;
                            })
                            .toList()
                          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                                a.createdAt ?? DateTime(0),
                              ));

                        // Pending unclaimed from previous dates
                        final pendingUnclaimed = allUnclaimed
                            .where((t) {
                              final createdDate = (t.createdAt ?? DateTime(1970)).toLocal();
                              return !(createdDate.year == today.year &&
                                  createdDate.month == today.month &&
                                  createdDate.day == today.day);
                            })
                            .toList();

                        return _UnclaimedTicketsListView(
                          tickets: todayUnclaimed,
                          customerMap: customerMap,
                          title: "Today's Unclaimed",
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Center(child: Text('Error loading customers: $err')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnclaimedTicketsListView extends StatelessWidget {
  final List<dynamic> tickets;
  final Map<String, dynamic> customerMap;
  final String title;

  const _UnclaimedTicketsListView({
    required this.tickets,
    required this.customerMap,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.calendar, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "$title (${tickets.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List Content
        Expanded(
          child: _buildTicketsList(context),
        ),
      ],
    );
  }

  Widget _buildTicketsList(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: AppColors.slate300,
            ),
            const SizedBox(height: 16),
            Text(
              'No unclaimed tickets',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final customer = customerMap[ticket.customerId];
        final isAmc = customer?.isAmcActive ?? false;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.go('/ticket/${ticket.ticketId}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    customer?.companyName ?? 'Unknown Customer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAmc)
                                  Container(
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
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer Row
                  Row(
                    children: [
                      Text(
                        isAmc ? 'AMC Priority' : 'Standard Ticket',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(ticket.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color;
    String label = priority ?? 'Medium';

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _EmptyListPlaceholder extends StatelessWidget {
  final String label;
  const _EmptyListPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(label, style: const TextStyle(color: AppColors.slate500)),
      ),
    );
  }
}
