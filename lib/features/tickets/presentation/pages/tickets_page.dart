import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../dashboard/presentation/widgets/ticket_card_with_amc.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/app_settings_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import 'unclaimed_tickets_split_page.dart';

enum TicketQuickView {
  my,
  unclaimed,
  inProgress,
  pending,
  resolvedToday,
  responseAlerts,
}

enum CustomerCategoryFilter { normal, priority }

class TicketsPage extends ConsumerStatefulWidget {
  final String? initialView;

  const TicketsPage({super.key, this.initialView});

  @override
  ConsumerState<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends ConsumerState<TicketsPage>
    with TickerProviderStateMixin {
  late TabController _supportTabController;
  late TabController _customerCategoryTabController;
  late TabController _normalQuickTabController;
  late TabController _amcQuickTabController;
  bool _didInitDeepLinkView = false;
  final Set<String> _dismissedMyTicketIds = <String>{};

  @override
  void initState() {
    super.initState();
    _supportTabController = TabController(length: 1, vsync: this);
    _customerCategoryTabController = TabController(length: 2, vsync: this);
    _normalQuickTabController = TabController(length: 2, vsync: this);
    _amcQuickTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _customerCategoryTabController.dispose();
    _normalQuickTabController.dispose();
    _amcQuickTabController.dispose();
    _supportTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final isSupport = currentUser?.isSupport == true;
    final view = widget.initialView;

    if (!_didInitDeepLinkView && view != null) {
      _didInitDeepLinkView = true;
      Future.microtask(() {
        if (!mounted) return;
        ref.read(ticketFilterProvider.notifier).setFilter(null);
      });
    }

    final currentPath = view == null ? '/tickets' : '/tickets?view=$view';

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: _buildBody(
          isSupport: isSupport,
          view: view,
          currentUser: currentUser,
        ),
      ),
    );
  }

  Widget _buildPrimaryTicketsView() {
    return Column(
      children: [
        // Header Area with Segmented Control
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tickets',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your queues',
                        style: TextStyle(fontSize: 13, color: AppColors.slate500),
                      ),
                    ],
                  ),
                  // Modern Segmented Control
                  Container(
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: TabBar(
                      controller: _customerCategoryTabController,
                      isScrollable: true,
                      labelColor: AppColors.slate900,
                      unselectedLabelColor: AppColors.slate500,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                      tabs: const [
                        Tab(text: 'Normal'),
                        Tab(text: 'AMC / Priority'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.slate200),
        Expanded(
          child: TabBarView(
            controller: _customerCategoryTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildCustomerQuickTabs(
                category: CustomerCategoryFilter.normal,
                controller: _normalQuickTabController,
              ),
              _buildCustomerQuickTabs(
                category: CustomerCategoryFilter.priority,
                controller: _amcQuickTabController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerQuickTabs({
    required CustomerCategoryFilter category,
    required TabController controller,
  }) {
    return Column(
      children: [
        // Secondary Tabs (Today / Pending)
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.slate200),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(LucideIcons.clock, size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              const Text(
                'Previous Days Pending',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: TicketsView(
              key: ValueKey('tickets_${category.name}_pending'),
              showAllTickets: true,
              quickView: TicketQuickView.pending,
              showCustomerTabs: false,
              forcedCustomerCategory: category,
              excludeToday: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody({
    required bool isSupport,
    required String? view,
    required Agent? currentUser,
  }) {
    switch (view) {
      case 'my':
        return _buildMyTicketsParallelView();
      case 'unclaimed':
        if (isSupport || currentUser?.isSupportHead == true) {
          return _buildUnclaimedParallelView();
        }
        return const TicketsView(
          showAllTickets: false,
          showOnlyUnclaimed: true,
          quickView: TicketQuickView.unclaimed,
        );
      case 'unclaimed_split':
        return const UnclaimedTicketsSplitPage();
      case 'in_progress':
        return _buildInProgressParallelView();
      case 'pending':
        return const TicketsView(
          showAllTickets: true,
          quickView: TicketQuickView.pending,
        );
      case 'resolved_today':
        return const TicketsView(
          showAllTickets: true,
          quickView: TicketQuickView.resolvedToday,
          showAssigneesFilter: false,
        );
      case 'response_alerts':
        return const TicketsView(
          showAllTickets: false,
          showOnlyMine: true,
          quickView: TicketQuickView.responseAlerts,
        );
      default:
        if (isSupport) {
          return _buildSupportView();
        }
        return _buildPrimaryTicketsView();
    }
  }

  Widget _buildSupportView() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Tickets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your ticket queue',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Normal Customers Tickets
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Normal Customers',
                        subtitle: 'Regular tickets',
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: const TicketsView(
                          showAllTickets: false,
                          showOnlyMine: true,
                          showCustomerTabs: false,
                          forcedCustomerCategory: CustomerCategoryFilter.normal,
                          excludeCompleted: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right: AMC Customers Tickets
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'AMC Customers',
                        subtitle: 'Priority tickets',
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: const TicketsView(
                          showAllTickets: false,
                          showOnlyMine: true,
                          showCustomerTabs: false,
                          forcedCustomerCategory:
                              CustomerCategoryFilter.priority,
                          excludeCompleted: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInProgressParallelView() {
    return Consumer(
      builder: (context, ref, child) {
        final ticketsAsync = ref.watch(ticketsStreamProvider);
        final currentUser = ref.watch(authProvider);

        return ticketsAsync.when(
          data: (allTickets) {
            // Filter in-progress tickets assigned to current user
            final inProgressTickets =
                allTickets
                    .where(
                      (t) =>
                          t.assignedTo == currentUser?.id &&
                          [
                            'In Progress',
                            'OnHold',
                            'WaitingForCustomer',
                          ].contains(t.status),
                    )
                    .toList()
                  ..sort(
                    (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
                      b.createdAt ?? DateTime(0),
                    ),
                  );

            // Separate into normal and priority tickets
            final normalTickets = <Ticket>[];
            final priorityTickets = <Ticket>[];

            for (final ticket in inProgressTickets) {
              // We'll filter in the _buildTicketList method based on customer data
              // For now, pass all tickets to both lists
              normalTickets.add(ticket);
              priorityTickets.add(ticket);
            }

            final showAssignmentDesk = currentUser?.isAgent == true;
            final claimedTickets = showAssignmentDesk
                ? allTickets
                    .where(
                      (t) =>
                          t.assignedTo != null &&
                          t.assignedTo!.isNotEmpty &&
                          !_isCompletedTicket(t),
                    )
                    .toList()
                : const <Ticket>[];

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'In Progress Tickets',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tickets currently being worked on',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final currentUser = ref.read(authProvider);
                          if (currentUser?.isAdmin == true) {
                            context.go('/admin');
                          } else if (currentUser?.isAccountant == true) {
                            context.go('/accountant');
                          } else if (currentUser?.isSupport == true) {
                            context.go('/support');
                          } else {
                            context.go('/'); // Default to agent dashboard
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Dashboard',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.slate100,
                          foregroundColor: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Normal Customer Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Normal Customer Tickets',
                                subtitle: 'Regular customer tickets',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  normalTickets,
                                  isPriority: false,
                                  showDismissIcon: true,
                                  onDismiss: _dismissMyTicket,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Middle: Priority Customer Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Priority Customer Tickets',
                                subtitle: 'AMC customer tickets',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  priorityTickets,
                                  isPriority: true,
                                  showDismissIcon: true,
                                  onDismiss: _dismissMyTicket,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showAssignmentDesk) ...[
                          const SizedBox(width: 24),
                          // Right: Agent assignment sidebar
                          SizedBox(
                            width: 320,
                            child: AgentAssignmentSidebar(
                              claimedTickets: claimedTickets,
                              currentUser: currentUser,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildMyTicketsParallelView() {
    return Consumer(
      builder: (context, ref, child) {
        final ticketsAsync = ref.watch(ticketsStreamProvider);
        final currentUser = ref.watch(authProvider);

        return ticketsAsync.when(
          data: (allTickets) {
            // Filter my tickets (assigned to current user)
            final allMyTickets =
                allTickets
                    .where((t) => t.assignedTo == currentUser?.id)
                    .where((t) => !_dismissedMyTicketIds.contains(t.ticketId))
                    .toList()
                  ..sort(
                    (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
                      b.createdAt ?? DateTime(0),
                    ),
                  );

            final myTickets = allMyTickets.where((t) => !_isCompletedTicket(t)).toList();

            // Separate into normal and priority tickets
            final normalTickets = <Ticket>[];
            final priorityTickets = <Ticket>[];

            for (final ticket in myTickets) {
              normalTickets.add(ticket);
              priorityTickets.add(ticket);
            }

            final now = DateTime.now();
            final assignedCount = allMyTickets.length;
            final activeCount = myTickets.length;
            final resolvedTodayCount = allMyTickets.where((t) {
              if (!_isCompletedTicket(t)) return false;
              final updated = t.updatedAt ?? t.createdAt;
              if (updated == null) return false;
              return updated.year == now.year &&
                  updated.month == now.month &&
                  updated.day == now.day;
            }).length;
            final awaitingResponseCount = myTickets
                .where(
                  (t) =>
                      t.status == 'Waiting for Customer' ||
                      t.status == 'WaitingForCustomer',
                )
                .length;

            final showAssignmentDesk = currentUser?.isAgent == true;
            final claimedTickets = showAssignmentDesk
                ? allTickets
                    .where(
                      (t) =>
                          t.assignedTo != null &&
                          t.assignedTo!.isNotEmpty &&
                          !_isCompletedTicket(t),
                    )
                    .toList()
                : const <Ticket>[];

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Tickets',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tickets assigned to you',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                            if (assignedCount > 0) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildMyTicketsStatChip(
                                    label: 'Assigned',
                                    value: assignedCount,
                                    color: AppColors.primary,
                                  ),
                                  _buildMyTicketsStatChip(
                                    label: 'Active',
                                    value: activeCount,
                                    color: AppColors.info,
                                  ),
                                  _buildMyTicketsStatChip(
                                    label: 'Resolved today',
                                    value: resolvedTodayCount,
                                    color: AppColors.success,
                                  ),
                                  _buildMyTicketsStatChip(
                                    label: 'Awaiting reply',
                                    value: awaitingResponseCount,
                                    color: AppColors.warning,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final currentUser = ref.read(authProvider);
                          if (currentUser?.isAdmin == true) {
                            context.go('/admin');
                          } else if (currentUser?.isAccountant == true) {
                            context.go('/accountant');
                          } else if (currentUser?.isSupport == true) {
                            context.go('/support');
                          } else {
                            context.go('/'); // Default to agent dashboard
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Dashboard',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.slate100,
                          foregroundColor: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Normal Customer Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Normal Customer Tickets',
                                subtitle: 'Regular customer tickets',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  normalTickets,
                                  isPriority: false,
                                  showDismissIcon: true,
                                  onDismiss: _dismissMyTicket,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Middle: Priority Customer Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Priority Customer Tickets',
                                subtitle: 'AMC customer tickets',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  priorityTickets,
                                  isPriority: true,
                                  showDismissIcon: true,
                                  onDismiss: _dismissMyTicket,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showAssignmentDesk) ...[
                          const SizedBox(width: 24),
                          SizedBox(
                            width: 320,
                            child: AgentAssignmentSidebar(
                              claimedTickets: claimedTickets,
                              currentUser: currentUser,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        );
      },
    );
  }

  Widget _buildUnclaimedParallelView() {
    return Consumer(
      builder: (context, ref, child) {
        final ticketsAsync = ref.watch(ticketsStreamProvider);

        return ticketsAsync.when(
          data: (allTickets) {
            // Filter unclaimed tickets
            final unclaimedTickets =
                allTickets
                    .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                    .toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );

            // Separate into normal and priority tickets
            final normalTickets = <Ticket>[];
            final priorityTickets = <Ticket>[];

            for (final ticket in unclaimedTickets) {
              // We'll filter in the _buildTicketList method based on customer data
              // For now, pass all tickets to both lists
              normalTickets.add(ticket);
              priorityTickets.add(ticket);
            }

            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Unclaimed Tickets',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Available tickets for assignment',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final currentUser = ref.read(authProvider);
                          if (currentUser?.isAdmin == true) {
                            context.go('/admin');
                          } else if (currentUser?.isAccountant == true) {
                            context.go('/accountant');
                          } else if (currentUser?.isSupport == true) {
                            context.go('/support');
                          } else {
                            context.go('/'); // Default to agent dashboard
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back to Dashboard',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.slate100,
                          foregroundColor: AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Normal Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Normal Tickets',
                                subtitle: 'Regular tickets',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  normalTickets,
                                  isPriority: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right: Priority Tickets
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeader(
                                title: 'Priority Tickets',
                                subtitle: 'AMC customers',
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _buildTicketList(
                                  priorityTickets,
                                  isPriority: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error loading tickets: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketList(
    List<Ticket> tickets, {
    required bool isPriority,
    bool showDismissIcon = false,
    void Function(Ticket ticket)? onDismiss,
  }) {
    return Consumer(
      builder: (context, ref, child) {
        // Filter tickets based on customer AMC status
        final filteredTickets = <Ticket>[];

        for (final ticket in tickets) {
          final customerAsync = ref.watch(
            ticketCustomerProvider(ticket.customerId),
          );
          final shouldInclude = customerAsync.maybeWhen(
            data: (data) {
              if (data == null) return !isPriority; // No customer data = normal
              final customer = Customer.fromJson(data);
              return isPriority ? customer.isAmcActive : !customer.isAmcActive;
            },
            orElse: () => !isPriority, // Default to normal if loading/error
          );

          if (shouldInclude) {
            filteredTickets.add(ticket);
          }
        }

        if (filteredTickets.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  isPriority ? LucideIcons.sparkles : LucideIcons.users,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No ${isPriority ? 'priority' : 'normal'} tickets',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: filteredTickets.length,
          itemBuilder: (context, index) {
            final ticket = filteredTickets[index];
            final canDismiss = showDismissIcon &&
                onDismiss != null &&
                _isCompletedTicket(ticket);
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    TicketCardWithAmc(
                      ticket: ticket,
                      layout: TicketCardLayout.compact,
                    ),
                    if (canDismiss)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(6),
                            iconSize: 18,
                            tooltip: 'Remove from My Tickets',
                            icon: const Icon(
                              LucideIcons.trash,
                              color: AppColors.slate600,
                            ),
                            onPressed: () {
                              onDismiss(ticket);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ticket removed from My Tickets'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isCompletedTicket(Ticket ticket) {
    return _isCompletedStatus(ticket.status);
  }

  void _dismissMyTicket(Ticket ticket) {
    if (!_isCompletedTicket(ticket)) return;
    setState(() {
      _dismissedMyTicketIds.add(ticket.ticketId);
    });
  }

  Widget _buildMyTicketsStatChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

bool _isCompletedStatus(String? status) {
  if (status == null) return false;
  final normalized = status.trim().toLowerCase();
  return const {'resolved', 'closed', 'billprocessed'}.contains(normalized);
}

class AgentAssignmentSidebar extends ConsumerWidget {
  const AgentAssignmentSidebar({
    super.key,
    required this.claimedTickets,
    required this.currentUser,
  });

  final List<Ticket> claimedTickets;
  final Agent? currentUser;

  bool get _canReassign {
    if (currentUser == null) return false;
    return currentUser!.isAgent == true ||
        currentUser!.isSupport == true ||
        currentUser!.isSupportHead == true ||
        currentUser!.isAdmin == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(agentsListProvider);
    final sortedTickets = [...claimedTickets]
      ..sort(
        (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0))
            .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)),
      );
    final visibleTickets = sortedTickets.take(6).toList();
    final myClaimCount =
        claimedTickets.where((t) => t.assignedTo == currentUser?.id).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Assignment Desk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${claimedTickets.length} active',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(
                label: 'I\'m handling',
                value: myClaimCount.toString(),
                color: AppColors.primary,
              ),
              _buildStatChip(
                label: 'Others handling',
                value: (claimedTickets.length - myClaimCount).toString(),
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: agentsAsync.when(
              data: (agents) {
                if (visibleTickets.isEmpty) {
                  return _buildEmptyState();
                }
                final agentMap = {
                  for (final agent in agents) agent['id']: agent,
                };
                return ListView.separated(
                  itemCount: visibleTickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ticket = visibleTickets[index];
                    final assignedAgent = agentMap[ticket.assignedTo];
                    final agentName =
                        assignedAgent?['full_name'] ??
                            assignedAgent?['username'] ??
                            'Unknown';
                    final status = ticket.status;
                    final createdLabel = ticket.createdAt != null
                        ? timeago.format(ticket.createdAt!)
                        : 'Unknown';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.slate200),
                        color: AppColors.slate50,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.userCheck,
                                size: 14,
                                color: AppColors.slate500,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Assigned to $agentName',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildStatusPill(status),
                                  const SizedBox(width: 8),
                                  Icon(
                                    LucideIcons.clock3,
                                    size: 12,
                                    color: AppColors.slate400,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      createdLabel,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.slate500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              if (_canReassign) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    icon: Icon(
                                      LucideIcons.arrowLeftRight,
                                      size: 14,
                                    ),
                                    label: const Text('Reassign'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                    onPressed: () => _showReassignSheet(
                                      context,
                                      ref,
                                      ticket,
                                      agents,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (err, _) => Center(
                child: Text(
                  'Failed to load agents\n$err',
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color color;
    switch (status) {
      case 'In Progress':
      case 'OnHold':
      case 'WaitingForCustomer':
        color = AppColors.warning;
        break;
      case 'Resolved':
      case 'BillRaised':
      case 'BillProcessed':
        color = AppColors.success;
        break;
      case 'Closed':
        color = AppColors.slate500;
        break;
      default:
        color = AppColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.layoutGrid,
          color: AppColors.slate300,
          size: 32,
        ),
        const SizedBox(height: 12),
        const Text(
          'No assigned tickets',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.slate600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Claim or assign tickets to see them here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.slate500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _showReassignSheet(
    BuildContext context,
    WidgetRef ref,
    Ticket ticket,
    List<Map<String, dynamic>> agents,
  ) async {
    if (!_canReassign) return;

    final visibleAgents = agents
        .where(
          (agent) =>
              (agent['role'] as String?)
                  ?.toLowerCase()
                  .contains('support') ==
              true,
        )
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reassign "${ticket.title}"',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...visibleAgents.map(
                  (agent) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(agent['full_name'] ?? agent['username']),
                    subtitle: Text(
                      (agent['role'] as String?)?.toUpperCase() ?? '',
                    ),
                    trailing: const Icon(LucideIcons.arrowRight),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      final success = await ref
                          .read(ticketAssignerProvider.notifier)
                          .assignTicket(ticket.ticketId, agent['id'] as String);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Reassigned to ${agent['full_name']}'
                                  : 'Failed to reassign',
                            ),
                            backgroundColor: success
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TicketSearchField extends ConsumerStatefulWidget {
  const TicketSearchField({super.key});

  @override
  ConsumerState<TicketSearchField> createState() => _TicketSearchFieldState();
}

class _TicketSearchFieldState extends ConsumerState<TicketSearchField> {
  late TextEditingController _controller;
  Timer? _debounce;
  final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(999),
    borderSide: BorderSide(color: AppColors.slate200),
  );

  @override
  void initState() {
    super.initState();
    final initial = ref.read(ticketSearchQueryProvider).trim();
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(ticketSearchQueryProvider.notifier).setQuery(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {});
    ref.read(ticketSearchQueryProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(ticketSearchQueryProvider, (previous, next) {
      if (next != _controller.text) {
        _controller.text = next;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: next.length),
        );
      }
    });

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: 'Search tickets…',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: _clear,
              ),
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class TicketsView extends ConsumerStatefulWidget {
  final bool showAllTickets;
  final bool showOnlyUnclaimed;
  final bool showOnlyMine;
  final bool excludeCompleted;
  final TicketQuickView? quickView;
  final bool showCustomerTabs;
  final CustomerCategoryFilter initialCustomerCategory;
  final CustomerCategoryFilter? forcedCustomerCategory;
  final bool showAssigneesFilter;
  final bool excludeToday;

  const TicketsView({
    super.key,
    this.showAllTickets = true,
    this.showOnlyUnclaimed = false,
    this.showOnlyMine = false,
    this.excludeCompleted = false,
    this.quickView,
    this.showCustomerTabs = true,
    this.initialCustomerCategory = CustomerCategoryFilter.normal,
    this.forcedCustomerCategory,
    this.showAssigneesFilter = true,
    this.excludeToday = false,
  });

  @override
  ConsumerState<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends ConsumerState<TicketsView>
    with SingleTickerProviderStateMixin {
  String _responseTimeFilter = 'all';
  late CustomerCategoryFilter _customerCategoryFilter;
  bool _filtersVisible = false;
  late final TabController _customerTabController;
  CustomerCategoryFilter get _effectiveInitialCategory =>
      widget.forcedCustomerCategory ?? widget.initialCustomerCategory;
  bool get _isCustomerCategoryLocked => widget.forcedCustomerCategory != null;

  @override
  void initState() {
    super.initState();
    _customerCategoryFilter = _effectiveInitialCategory;
    _customerTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _effectiveInitialCategory == CustomerCategoryFilter.priority
          ? 1
          : 0,
    );
    _customerTabController.addListener(_handleCustomerTabChange);
  }

  @override
  void didUpdateWidget(covariant TicketsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final forced = widget.forcedCustomerCategory;
    if (forced != null && forced != _customerCategoryFilter) {
      _customerCategoryFilter = forced;
      final desiredIndex = forced == CustomerCategoryFilter.priority ? 1 : 0;
      if (_customerTabController.index != desiredIndex) {
        _customerTabController.index = desiredIndex;
      }
    }
  }

  void _handleCustomerTabChange() {
    if (_customerTabController.indexIsChanging) return;
    if (_isCustomerCategoryLocked) {
      final desiredIndex =
          _customerCategoryFilter == CustomerCategoryFilter.priority ? 1 : 0;
      if (_customerTabController.index != desiredIndex) {
        _customerTabController.index = desiredIndex;
      }
      return;
    }
    final newFilter = _customerTabController.index == 0
        ? CustomerCategoryFilter.normal
        : CustomerCategoryFilter.priority;
    if (newFilter != _customerCategoryFilter) {
      setState(() {
        _customerCategoryFilter = newFilter;
      });
    }
  }

  @override
  void dispose() {
    _customerTabController.removeListener(_handleCustomerTabChange);
    _customerTabController.dispose();
    super.dispose();
  }

  void _setCustomerCategoryFilter(CustomerCategoryFilter filter) {
    if (_customerCategoryFilter == filter) return;
    setState(() {
      _customerCategoryFilter = filter;
    });
    final desiredIndex = filter == CustomerCategoryFilter.normal ? 0 : 1;
    if (_customerTabController.index != desiredIndex) {
      _customerTabController.animateTo(desiredIndex);
    }
  }

  void _clearAllFilters() {
    ref.read(ticketSearchQueryProvider.notifier).setQuery('');
    ref.read(ticketPriorityFilterProvider.notifier).setFilter('All');
    ref.read(ticketAssigneeFilterProvider.notifier).setAll();
    ref.read(ticketFilterProvider.notifier).setFilter(null);
    ref.read(ticketSortProvider.notifier).setSort('sla');
    setState(() {
      _responseTimeFilter = 'all';
      _filtersVisible = false;
    });
    _setCustomerCategoryFilter(_effectiveInitialCategory);
  }

  Widget _buildCustomerCategoryTabs({bool compact = false}) {
    final isAmcSelected =
        _customerCategoryFilter == CustomerCategoryFilter.priority;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
          vertical: compact ? 4 : 6,
        ),
        child: TabBar(
          controller: _customerTabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: isAmcSelected
                  ? const [Color(0xFF0EA5E9), Color(0xFF10B981)]
                  : const [Color(0xFF0EA472), Color(0xFF12B886)],
            ),
          ),
          indicatorPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 4,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.slate500,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(
              icon: Icon(LucideIcons.users, size: 18),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text('Normal Customers'),
              ),
            ),
            Tab(
              icon: Icon(LucideIcons.sparkles, size: 18),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text('AMC Customers'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final currentUser = ref.watch(authProvider);
    final statusFilter = ref.watch(ticketFilterProvider);
    final searchQuery = ref.watch(ticketSearchQueryProvider);
    final priorityFilter = ref.watch(ticketPriorityFilterProvider);
    final assigneeFilter = ref.watch(ticketAssigneeFilterProvider);
    final sortOption = ref.watch(ticketSortProvider);
    final effectiveSortOption =
        (currentUser?.isSupport == true &&
            widget.showAllTickets == false &&
            widget.showOnlyUnclaimed == true)
        ? 'oldest'
        : sortOption;
    final agentsAsync = ref.watch(agentsListProvider);
    final customersAsync = ref.watch(customersListProvider);
    final responseTimeFilter = _responseTimeFilter;
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final shouldShowCustomerTabs =
        widget.forcedCustomerCategory == null &&
        widget.showCustomerTabs &&
        !widget.showOnlyUnclaimed &&
        (widget.showAllTickets ||
            widget.quickView != null ||
            (currentUser?.isSupport == true && widget.showAllTickets == false));

    return Padding(
      padding: widget.forcedCustomerCategory != null
          ? EdgeInsets.zero
          : const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showAllTickets) ...[
            SectionHeader(
              title: 'All Tickets',
              subtitle: 'Support queue overview',
              trailing: AppButton.ghost(
                label: 'Clear all filters',
                icon: LucideIcons.x,
                onPressed: _clearAllFilters,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (shouldShowCustomerTabs) ...[
            _buildCustomerCategoryTabs(compact: !widget.showAllTickets),
            SizedBox(height: widget.showAllTickets ? 16 : 12),
          ],
          if (widget.showAllTickets) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final searchField = SizedBox(
                  width: isNarrow ? double.infinity : 320,
                  child: const TicketSearchField(),
                );
                final filterButton = AppButton.secondary(
                  label: _filtersVisible ? 'Hide filters' : 'Show filters',
                  icon: LucideIcons.slidersHorizontal,
                  onPressed: () {
                    setState(() {
                      _filtersVisible = !_filtersVisible;
                    });
                  },
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 8),
                      filterButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    searchField,
                    const SizedBox(width: 12),
                    filterButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _filtersVisible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 600;

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildPriorityDropdown(ref, priorityFilter),
                                  const SizedBox(height: 8),
                                  if (widget.showAssigneesFilter) ...[
                                    _buildAssigneeDropdown(
                                      ref,
                                      agentsAsync,
                                      currentUser,
                                      assigneeFilter,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  _buildSortDropdown(ref, sortOption),
                                ],
                              );
                            }

                            return Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                SizedBox(
                                  width: 180,
                                  child: _buildPriorityDropdown(
                                    ref,
                                    priorityFilter,
                                  ),
                                ),
                                if (widget.showAssigneesFilter)
                                  SizedBox(
                                    width: 180,
                                    child: _buildAssigneeDropdown(
                                      ref,
                                      agentsAsync,
                                      currentUser,
                                      assigneeFilter,
                                    ),
                                  ),
                                SizedBox(
                                  width: 180,
                                  child: _buildSortDropdown(ref, sortOption),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: statusFilter == null,
                              onSelected: (_) {
                                ref
                                    .read(ticketFilterProvider.notifier)
                                    .setFilter(null);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Open'),
                              selected: statusFilter == 'Open',
                              onSelected: (_) {
                                ref
                                    .read(ticketFilterProvider.notifier)
                                    .setFilter('Open');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Closed'),
                              selected: statusFilter == 'Closed',
                              onSelected: (_) {
                                ref
                                    .read(ticketFilterProvider.notifier)
                                    .setFilter('Closed');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('All response times'),
                              selected: responseTimeFilter == 'all',
                              onSelected: (_) {
                                setState(() {
                                  _responseTimeFilter = 'all';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('At risk soon'),
                              selected: responseTimeFilter == 'at_risk',
                              onSelected: (_) {
                                setState(() {
                                  _responseTimeFilter = 'at_risk';
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Overdue'),
                              selected: responseTimeFilter == 'overdue',
                              onSelected: (_) {
                                setState(() {
                                  _responseTimeFilter = 'overdue';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
          Expanded(
            child: ticketsAsync.when(
              data: (allTickets) {
                // Filter tickets based on view type
                List<Ticket> tickets = List<Ticket>.of(allTickets);

                if (widget.excludeToday) {
                  final today = DateTime.now();
                  tickets = tickets.where((t) {
                    final createdDate = t.createdAt ?? DateTime(1970);
                    return !(createdDate.year == today.year &&
                        createdDate.month == today.month &&
                        createdDate.day == today.day);
                  }).toList();
                }

                if (widget.showOnlyUnclaimed) {
                  tickets = allTickets
                      .where(
                        (t) => t.assignedTo == null || t.assignedTo!.isEmpty,
                      )
                      .toList();
                } else if (widget.showOnlyMine && currentUser != null) {
                  tickets = allTickets
                      .where((t) => t.assignedTo == currentUser.id)
                      .toList();
                }

                if (widget.excludeCompleted) {
                  tickets = tickets
                      .where((t) => !_isCompletedStatus(t.status))
                      .toList();
                }

                final Map<String, Customer> customersById = customersAsync
                    .maybeWhen(
                      data: (customers) => {for (final c in customers) c.id: c},
                      orElse: () => const <String, Customer>{},
                    );

                final shouldFilterByCustomerCategory =
                    widget.forcedCustomerCategory != null ||
                    shouldShowCustomerTabs;

                if (shouldFilterByCustomerCategory) {
                  // Use forcedCustomerCategory if set, otherwise use the state variable
                  final effectiveCategory =
                      widget.forcedCustomerCategory ?? _customerCategoryFilter;

                  tickets = tickets.where((t) {
                    final customer = customersById[t.customerId];
                    final isAmcActive = customer?.isAmcActive ?? false;
                    if (effectiveCategory == CustomerCategoryFilter.priority) {
                      return isAmcActive;
                    }
                    return !isAmcActive;
                  }).toList();
                }

                final qv = widget.quickView;
                if (qv != null) {
                  if (qv == TicketQuickView.inProgress) {
                    tickets = tickets
                        .where((t) => t.status == 'In Progress')
                        .toList();
                  } else if (qv == TicketQuickView.pending) {
                    tickets = tickets
                        .where((t) => !_isCompletedStatus(t.status))
                        .toList();
                  } else if (qv == TicketQuickView.resolvedToday) {
                    final today = DateTime.now();
                    tickets = tickets.where((t) {
                      if (!_isCompletedStatus(t.status)) {
                        return false;
                      }
                      final updatedAt = t.updatedAt;
                      if (updatedAt == null) return false;
                      return updatedAt.year == today.year &&
                          updatedAt.month == today.month &&
                          updatedAt.day == today.day;
                    }).toList();
                  } else if (qv == TicketQuickView.responseAlerts) {
                    final now = DateTime.now();

                    tickets =
                        tickets.where((t) {
                          if (_isCompletedStatus(t.status)) return false;
                          final due = _computeTargetDueForList(
                            t,
                            advancedSettings,
                          );
                          if (due == null) return false;
                          final remainingMinutes = due
                              .difference(now)
                              .inMinutes;
                          return remainingMinutes <= 60;
                        }).toList()..sort((a, b) {
                          final aDue =
                              _computeTargetDueForList(a, advancedSettings) ??
                              now.add(const Duration(days: 365));
                          final bDue =
                              _computeTargetDueForList(b, advancedSettings) ??
                              now.add(const Duration(days: 365));
                          return aDue.compareTo(bDue);
                        });
                  }
                }

                final query = searchQuery.trim().toLowerCase();
                if (query.isNotEmpty) {
                  tickets = tickets.where((t) {
                    final title = t.title.toString().toLowerCase();
                    final description = (t.description ?? '')
                        .toString()
                        .toLowerCase();
                    final id = t.ticketId.toString().toLowerCase();
                    final createdBy = t.createdBy.toString().toLowerCase();
                    return title.contains(query) ||
                        description.contains(query) ||
                        id.contains(query) ||
                        createdBy.contains(query);
                  }).toList();
                }

                if (priorityFilter != 'All') {
                  tickets = tickets
                      .where(
                        (t) =>
                            (t.priority ?? '').toLowerCase() ==
                            priorityFilter.toLowerCase(),
                      )
                      .toList();
                }

                if (assigneeFilter != 'all') {
                  if (assigneeFilter == 'unassigned') {
                    tickets = tickets
                        .where(
                          (t) => t.assignedTo == null || t.assignedTo!.isEmpty,
                        )
                        .toList();
                  } else if (assigneeFilter == 'me' && currentUser != null) {
                    tickets = tickets
                        .where((t) => t.assignedTo == currentUser.id)
                        .toList();
                  } else if (assigneeFilter.startsWith('agent:')) {
                    final agentId = assigneeFilter.substring(6);
                    tickets = tickets
                        .where((t) => t.assignedTo == agentId)
                        .toList();
                  }
                }

                if (responseTimeFilter != 'all') {
                  final now = DateTime.now();
                  tickets = tickets.where((t) {
                    final due = _computeTargetDueForList(t, advancedSettings);
                    if (due == null) return false;
                    if (_isCompletedStatus(t.status)) {
                      return false;
                    }
                    final minutes = due.difference(now).inMinutes;
                    if (responseTimeFilter == 'at_risk') {
                      return minutes >= 0 && minutes < 60;
                    }
                    if (responseTimeFilter == 'overdue') {
                      return minutes < 0;
                    }
                    return true;
                  }).toList();
                }

                int compareUrgency(Ticket a, Ticket b) {
                  if (a.slaDue != null && b.slaDue != null) {
                    return a.slaDue!.compareTo(b.slaDue!);
                  }
                  if (a.slaDue != null) return -1;
                  if (b.slaDue != null) return 1;
                  return (b.createdAt ?? DateTime(0)).compareTo(
                    a.createdAt ?? DateTime(0),
                  );
                }

                int priorityRank(String? priority) {
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

                if (effectiveSortOption == 'sla') {
                  tickets.sort(compareUrgency);
                } else if (effectiveSortOption == 'newest') {
                  tickets.sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );
                } else if (effectiveSortOption == 'oldest') {
                  tickets.sort(
                    (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
                      b.createdAt ?? DateTime(0),
                    ),
                  );
                } else if (effectiveSortOption == 'priority') {
                  tickets.sort(
                    (a, b) => priorityRank(
                      b.priority,
                    ).compareTo(priorityRank(a.priority)),
                  );
                }

                if (tickets.isEmpty) {
                  return EmptyStateCard(
                    icon: widget.showOnlyUnclaimed
                        ? LucideIcons.checkCircle
                        : LucideIcons.inbox,
                    title: widget.showOnlyUnclaimed
                        ? 'All tickets are claimed!'
                        : widget.showOnlyMine
                        ? 'No tickets assigned to you'
                        : 'No tickets found',
                    subtitle: widget.showOnlyUnclaimed
                        ? 'Great work!'
                        : 'Tickets will appear here',
                  );
                }

                // Enforce FIFO queue (oldest at top)
                tickets.sort(
                  (a, b) => (a.createdAt ?? DateTime(0)).compareTo(
                    b.createdAt ?? DateTime(0),
                  ),
                );

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return TicketCardWithAmc(
                      ticket: tickets[index],
                      layout: TicketCardLayout.standard,
                      highlightPriorityCustomer:
                          currentUser?.isSupport == true &&
                          widget.showAllTickets == false &&
                          _customerCategoryFilter ==
                              CustomerCategoryFilter.priority,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading tickets: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDropdown(WidgetRef ref, String priorityFilter) {
    return DropdownButtonFormField<String>(
      initialValue: priorityFilter,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const [
        DropdownMenuItem(value: 'All', child: Text('All priorities')),
        DropdownMenuItem(value: 'Low', child: Text('Low')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'High', child: Text('High')),
        DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
      ],
      onChanged: (value) {
        if (value != null) {
          ref.read(ticketPriorityFilterProvider.notifier).setFilter(value);
        }
      },
    );
  }

  Widget _buildAssigneeDropdown(
    WidgetRef ref,
    AsyncValue<List<Map<String, dynamic>>> agentsAsync,
    dynamic currentUser,
    String assigneeFilter,
  ) {
    return agentsAsync.when(
      data: (agents) {
        final items = <DropdownMenuItem<String>>[
          const DropdownMenuItem(value: 'all', child: Text('All assignees')),
          const DropdownMenuItem(
            value: 'unassigned',
            child: Text('Unassigned'),
          ),
          if (currentUser != null)
            const DropdownMenuItem(value: 'me', child: Text('Assigned to me')),
        ];

        for (final agent in agents) {
          final id = agent['id'] as String?;
          if (id == null) continue;
          final name =
              (agent['full_name'] as String?) ??
              (agent['username'] as String?) ??
              'Agent';
          items.add(
            DropdownMenuItem(
              value: 'agent:$id',
              child: Text(name, overflow: TextOverflow.ellipsis),
            ),
          );
        }

        final selected = items.any((item) => item.value == assigneeFilter)
            ? assigneeFilter
            : 'all';

        return DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: items,
          onChanged: (value) {
            if (value == null) return;
            final notifier = ref.read(ticketAssigneeFilterProvider.notifier);
            if (value == 'all') {
              notifier.setAll();
            } else if (value == 'unassigned') {
              notifier.setUnassigned();
            } else if (value == 'me') {
              notifier.setMe();
            } else if (value.startsWith('agent:')) {
              notifier.setAgent(value.substring(6));
            }
          },
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSortDropdown(WidgetRef ref, String sortOption) {
    return DropdownButtonFormField<String>(
      initialValue: sortOption,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const [
        DropdownMenuItem(value: 'sla', child: Text('Response time / urgency')),
        DropdownMenuItem(value: 'newest', child: Text('Newest first')),
        DropdownMenuItem(value: 'oldest', child: Text('Oldest first')),
        DropdownMenuItem(value: 'priority', child: Text('Priority')),
      ],
      onChanged: (value) {
        if (value != null) {
          ref.read(ticketSortProvider.notifier).setSort(value);
        }
      },
    );
  }

  DateTime? _computeTargetDueForList(Ticket t, dynamic advancedSettings) {
    if (t.slaDue != null) {
      return t.slaDue;
    }
    if (advancedSettings == null) return null;
    try {
      final minutes = advancedSettings.slaMinutesForPriority(t.priority);
      if (minutes <= 0) return null;
      final createdAt = t.createdAt;
      if (createdAt == null) return null;
      return createdAt.add(Duration(minutes: minutes));
    } catch (_) {
      return null;
    }
  }
}
