import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/ticket_card_with_amc.dart';
import '../widgets/animated_create_ticket_fab.dart';
import '../widgets/create_ticket_dialog.dart';

class SupportDashboardPage extends ConsumerWidget {
  const SupportDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final currentUser = ref.watch(authProvider);
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/support',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreateTicketDialog(isSupport: true),
            );
          },
        ),
        body: ticketsAsync.when(
          data: (allTickets) {
            final myTickets =
                allTickets.where((t) => t.assignedTo == currentUser?.id).toList();
            final unclaimedTickets =
                allTickets
                    .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                    .toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );

            final customersById = customersAsync.maybeWhen(
              data: (customers) => {for (final c in customers) c.id: c},
              orElse: () => const <String, Customer>{},
            );

            final resolvedStatuses = {'Resolved', 'Closed', 'BillProcessed'};
            final myInProgress =
                myTickets.where((t) => t.status == 'In Progress').length;
            final myResolvedToday = myTickets.where((t) {
              final today = DateTime.now();
              final updatedAt = t.updatedAt ?? DateTime(1970);
              return resolvedStatuses.contains(t.status) &&
                  updatedAt.year == today.year &&
                  updatedAt.month == today.month &&
                  updatedAt.day == today.day;
            }).length;

            final now = DateTime.now();
            final mySlaWarnings = myTickets.where((t) {
              if (resolvedStatuses.contains(t.status)) return false;
              final slaDue = t.slaDue;
              if (slaDue == null) return false;
              return slaDue.difference(now).inMinutes <= 60;
            }).length;

            final queueStats = [
              _QueueStat(
                label: 'Unclaimed',
                subtitle: 'Waiting claim',
                icon: LucideIcons.inbox,
                count: unclaimedTickets.length,
                color: AppColors.warning,
                route: '/tickets?view=unclaimed',
              ),
              _QueueStat(
                label: 'My Tickets',
                subtitle: 'Assigned to me',
                icon: LucideIcons.userCheck,
                count: myTickets.length,
                color: AppColors.primary,
                route: '/tickets?view=assigned',
              ),
              _QueueStat(
                label: 'In Progress',
                subtitle: 'Currently active',
                icon: LucideIcons.playCircle,
                count: myInProgress,
                color: AppColors.info,
                route: '/tickets?view=in_progress',
              ),
              _QueueStat(
                label: 'Resolved Today',
                subtitle: 'Closed today',
                icon: LucideIcons.checkCircle2,
                count: myResolvedToday,
                color: AppColors.success,
                route: '/tickets?view=resolved',
              ),
              _QueueStat(
                label: 'Response Alerts',
                subtitle: 'Near SLA',
                icon: LucideIcons.alertTriangle,
                count: mySlaWarnings,
                color: AppColors.error,
                route: '/tickets?view=alerts',
              ),
            ];

            List<Ticket> _filterTickets(bool isAmc) {
              return unclaimedTickets.where((ticket) {
                final customer = customersById[ticket.customerId];
                final amcActive = customer?.isAmcActive ?? false;
                return isAmc ? amcActive : !amcActive;
              }).toList();
            }

            final normalTickets = _filterTickets(false);
            final amcTickets = _filterTickets(true);
            final forceClaimButton = currentUser?.isSupportHead == true;
            final isCustomersLoading = customersAsync.isLoading;
            final unclaimedSection = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Unclaimed Tickets',
                  subtitle: '${unclaimedTickets.length} tickets waiting',
                  icon: LucideIcons.inbox,
                  iconColor: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCustomersLoading) ...[
                        const LinearProgressIndicator(
                          minHeight: 3,
                          backgroundColor: AppColors.slate100,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTicketColumn(
                              context,
                              title: 'Normal Customers',
                              subtitle: 'Regular tickets',
                              tickets: normalTickets,
                              isAmc: false,
                              forceClaimButton: forceClaimButton,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildTicketColumn(
                              context,
                              title: 'AMC Customers',
                              subtitle: 'Priority tickets',
                              tickets: amcTickets,
                              isAmc: true,
                              forceClaimButton: forceClaimButton,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WelcomeHeader(
                    name: currentUser?.username ?? 'Support',
                    subtitle: 'Your support dashboard and ticket queue',
                    trailing: AppButton.ghost(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () => ref.invalidate(ticketsStreamProvider),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _QueueStatTiles(stats: queueStats),
                  const SizedBox(height: 24),
                  unclaimedSection,
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error loading dashboard: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketColumn(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Ticket> tickets,
    required bool isAmc,
    required bool forceClaimButton,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
        ),
        const SizedBox(height: 12),
        _buildTicketList(
          context,
          tickets,
          isAmc: isAmc,
          forceClaimButton: forceClaimButton,
        ),
      ],
    );
  }

  Widget _buildTicketList(
    BuildContext context,
    List<Ticket> tickets, {
    required bool isAmc,
    required bool forceClaimButton,
  }) {
    if (tickets.isEmpty) {
      return EmptyStateCard(
        icon: isAmc ? LucideIcons.sparkles : LucideIcons.users,
        title: isAmc ? 'No AMC tickets waiting' : 'No normal tickets waiting',
        subtitle: isAmc
            ? 'Priority customers are all covered right now.'
            : 'Regular customer queue is empty.',
      );
    }

    final limitedTickets = tickets.take(10).toList();
    final showViewAll = tickets.length > limitedTickets.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...limitedTickets.map(
          (ticket) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TicketCardWithAmc(
              ticket: ticket,
              layout: TicketCardLayout.compact,
              forceClaimButton: forceClaimButton,
            ),
          ),
        ),
        if (showViewAll)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/tickets?view=unclaimed'),
              child: Text(
                'View all ${tickets.length} ${isAmc ? 'AMC' : 'normal'} tickets →',
              ),
            ),
          ),
      ],
    );
  }
}

class _QueueStat {
  final String label;
  final String subtitle;
  final IconData icon;
  final int count;
  final Color color;
  final String? route;

  const _QueueStat({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.color,
    this.route,
  });
}

class _QueueStatTiles extends StatelessWidget {
  final List<_QueueStat> stats;

  const _QueueStatTiles({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: stats
          .map((stat) => _QueueStatTile(stat: stat))
          .toList(growable: false),
    );
  }
}

class _QueueStatTile extends StatelessWidget {
  final _QueueStat stat;

  const _QueueStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: 140,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate200.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: stat.color.withValues(alpha: 0.15),
                  child: Icon(stat.icon, size: 18, color: stat.color),
                ),
                const SizedBox(height: 8),
                Text(
                  stat.label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate500),
                ),
              ],
            ),
            Text(
              '${stat.count}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
      ),
    );

    if (stat.route == null) return tile;

    return InkWell(
      onTap: () => context.push(stat.route!),
      child: tile,
    );
  }
}
