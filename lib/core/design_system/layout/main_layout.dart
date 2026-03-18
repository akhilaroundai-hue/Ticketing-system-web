import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../../features/customers/presentation/providers/customer_provider.dart';
import '../../../features/dashboard/presentation/providers/app_settings_provider.dart';
import '../../network/connectivity_provider.dart';
import '../../../features/productivity/presentation/widgets/notification_bell.dart';
import '../../../features/chat/presentation/providers/chat_provider.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({super.key, required this.child, required this.currentPath});

  @override
  Widget build(BuildContext context) {
    // Responsive check
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            const _OfflineBanner(),
            Expanded(
              child: Row(
                children: [
                  _Sidebar(currentPath: currentPath),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const _OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: _BottomNav(currentPath: currentPath),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  final String currentPath;

  const _Sidebar({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final advSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final role = currentUser?.role ?? 'Support';
    final isSales = currentUser?.isSales == true;
    final simplifyNav =
        currentUser?.isSupport == true || currentUser?.isSupportHead == true;

    // Feature flags (global enable/disable)
    final enableNotifications = appSettings == null
        ? true
        : (appSettings['enable_notifications'] ?? true);
    final enableGlobalSearch = appSettings == null
        ? true
        : (appSettings['enable_global_search'] ?? true);
    final enableReports = appSettings == null
        ? true
        : (appSettings['enable_reports'] ?? true);
    final enableDeals = appSettings == null
        ? true
        : (appSettings['enable_deals'] ?? true);

    // Per-role screen visibility (uses advanced settings if available)
    bool canSeeScreen(String screenId) {
      if (advSettings == null) return true;
      return advSettings.canRoleSeeScreen(role, screenId);
    }

    final showClaimTicketsLabel =
        currentUser?.isSupport == true || currentUser?.isSupportHead == true;
    final showBillsAsDashboard = currentUser?.isAccountant == true;

    final canViewAmcReminder =
        !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewPastTickets =
        !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewBills =
        !simplifyNav ||
        currentUser?.isAdmin == true ||
        currentUser?.isAccountant == true;
    final canViewSalesOpportunity =
        currentUser?.isSupportHead == true && !simplifyNav;
    final canViewReports =
        enableReports &&
        !simplifyNav &&
        canSeeScreen('reports') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);
    final canViewDeals =
        enableDeals &&
        !simplifyNav &&
        canSeeScreen('deals') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.slate900],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Area - Enterprise styled
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.checkSquare,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TallyCare',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Enterprise',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Search & Notifications
          if (enableGlobalSearch || enableNotifications)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (enableGlobalSearch)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => const _GlobalSearchDialog(),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.search,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Search...',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (enableNotifications) ...[
                    const SizedBox(width: 8),
                    IconTheme(
                      data: IconThemeData(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      child: const NotificationBell(),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  // Navigation Items
                  _NavItem(
                    label: showBillsAsDashboard
                        ? 'Bills'
                        : (isSales
                              ? 'Dashboard'
                              : (showClaimTicketsLabel
                                    ? 'Claim Tickets'
                                    : 'Dashboard')),
                    icon: showBillsAsDashboard
                        ? LucideIcons.receipt
                        : LucideIcons.layoutDashboard,
                    path: showBillsAsDashboard
                        ? '/accountant'
                        : (isSales ? '/sales' : '/'),
                    isActive:
                        currentPath == '/' ||
                        currentPath == '/admin' ||
                        currentPath == '/support' ||
                        currentPath == '/accountant' ||
                        currentPath == '/sales',
                  ),
                  if (currentUser?.isAccountant != true)
                    _NavItem(
                      label: isSales ? 'My Tickets' : 'Tickets',
                      icon: LucideIcons.ticket,
                      path: '/tickets',
                      isActive:
                          currentPath.startsWith('/tickets') ||
                          currentPath.startsWith('/ticket'),
                    ),
                  _NavItem(
                    label: 'Customers',
                    icon: LucideIcons.users,
                    path: '/customers',
                    isActive:
                        currentPath.startsWith('/customers') ||
                        currentPath.startsWith('/customer'),
                  ),
                  if (canViewAmcReminder)
                    _NavItem(
                      label: 'AMC Reminder',
                      icon: LucideIcons.calendarClock,
                      path: '/amc-reminder',
                      isActive: currentPath.startsWith('/amc-reminder'),
                    ),
                  if (canViewBills && !showBillsAsDashboard)
                    _NavItem(
                      label: 'Bills',
                      icon: LucideIcons.receipt,
                      path: '/bills',
                      isActive: currentPath.startsWith('/bills'),
                    ),
                  if (canViewPastTickets)
                    _NavItem(
                      label: 'Past Tickets',
                      icon: LucideIcons.archive,
                      path: '/past-tickets',
                      isActive: currentPath == '/past-tickets',
                    ),
                  if (currentUser?.isAdmin == true ||
                      currentUser?.isAccountant == true)
                    _NavItem(
                      label: 'Revenue',
                      icon: LucideIcons.indianRupee,
                      path: '/revenue',
                      isActive: currentPath.startsWith('/revenue'),
                    ),
                  if (canViewSalesOpportunity)
                    _NavItem(
                      label: 'Sales Opportunity',
                      icon: LucideIcons.trendingUp,
                      path: '/sales-opportunity',
                      isActive: currentPath.startsWith('/sales-opportunity'),
                    ),
                  if (canViewReports)
                    _NavItem(
                      label: 'Reports',
                      icon: LucideIcons.barChart,
                      path: '/reports',
                      isActive: currentPath.startsWith('/reports'),
                    ),
                  if (currentUser?.isAdmin == true) ...[
                    _NavItem(
                      label: 'User Management',
                      icon: LucideIcons.users,
                      path: '/users',
                      isActive: currentPath.startsWith('/users'),
                    ),
                  ],
                  if (canViewDeals)
                    _NavItem(
                      label: 'Deals',
                      icon: LucideIcons.briefcase,
                      path: '/deals',
                      isActive: currentPath.startsWith('/deals'),
                    ),
                  if (currentUser?.isSales == true ||
                      currentUser?.isAccountant == true ||
                      currentUser?.isAdmin == true)
                    _NavItem(
                      label: 'Leads',
                      icon: LucideIcons.target,
                      path: '/leads',
                      isActive: currentPath.startsWith('/leads'),
                    ),
                  _NavItem(
                    label: 'Proposals',
                    icon: LucideIcons.fileText,
                    path: '/proposal-generator',
                    isActive: currentPath.startsWith('/proposal-generator'),
                  ),
                  _NavItem(
                    label: 'Team Chat',
                    icon: LucideIcons.messageSquare,
                    path: '/chat',
                    isActive: currentPath.startsWith('/chat'),
                    badgeCount: currentPath.startsWith('/chat')
                        ? 0
                        : ref.watch(chatUnreadCountProvider),
                  ),
                  if (currentUser?.isAdmin == true)
                    _NavItem(
                      label: 'Settings',
                      icon: LucideIcons.settings,
                      path: '/settings',
                      isActive: currentPath.startsWith('/settings'),
                    ),

                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: _UserProfile(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  const _GlobalSearchDialog();

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 640,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Global Search',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search tickets or customers...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 360,
                child: ticketsAsync.when(
                  data: (tickets) {
                    return customersAsync.when(
                      data: (customers) {
                        final q = _query.toLowerCase();

                        final ticketResults = q.isEmpty
                            ? <dynamic>[]
                            : tickets
                                  .where((t) {
                                    final title = t.title.toLowerCase();
                                    final id = t.ticketId.toLowerCase();
                                    final desc = (t.description ?? '')
                                        .toString()
                                        .toLowerCase();
                                    return title.contains(q) ||
                                        id.contains(q) ||
                                        desc.contains(q);
                                  })
                                  .take(10)
                                  .toList();

                        final customerResults = q.isEmpty
                            ? <dynamic>[]
                            : customers
                                  .where((c) {
                                    final name = c.companyName.toLowerCase();
                                    final apiKey = c.apiKey.toLowerCase();
                                    return name.contains(q) ||
                                        apiKey.contains(q);
                                  })
                                  .take(10)
                                  .toList();

                        if (ticketResults.isEmpty && customerResults.isEmpty) {
                          return const Center(
                            child: Text(
                              'Type to search tickets or customers',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.slate500,
                              ),
                            ),
                          );
                        }

                        return ListView(
                          children: [
                            if (ticketResults.isNotEmpty) ...[
                              const Text(
                                'Tickets',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ticketResults.map((t) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    LucideIcons.ticket,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    t.title ?? 'Ticket',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'ID: ${t.ticketId}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.go('/ticket/${t.ticketId}');
                                  },
                                );
                              }),
                              const SizedBox(height: 12),
                            ],
                            if (customerResults.isNotEmpty) ...[
                              const Text(
                                'Customers',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...customerResults.map((c) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    LucideIcons.users,
                                    size: 18,
                                    color: AppColors.slate700,
                                  ),
                                  title: Text(
                                    c.companyName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    c.apiKey,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    context.go('/customer/${c.id}');
                                  },
                                );
                              }),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error loading customers: $err',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (err, _) => Center(
                    child: Text(
                      'Error loading tickets: $err',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
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

class _NavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.isActive,
    this.badgeCount = 0,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.6);
    final hoverColor = Colors.white.withValues(alpha: 0.08);
    final activeColor = AppColors.primaryLight;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go(widget.path),
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? activeColor.withValues(alpha: 0.15)
                    : (_isHovered ? hoverColor : Colors.transparent),
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? activeColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 18,
                      color: widget.isActive ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: widget.isActive
                                ? Colors.white
                                : inactiveColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.badgeCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              widget.badgeCount > 9
                                  ? '9+'
                                  : widget.badgeCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  final String currentPath;

  const _BottomNav({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final enableReports = appSettings == null
        ? true
        : (appSettings['enable_reports'] ?? true);

    final isAccountant = currentUser?.isAccountant == true;
    final isAdmin = currentUser?.isAdmin == true;
    final isSupportHead = currentUser?.isSupportHead == true;
    final simplifyNav =
        currentUser?.isSupport == true || currentUser?.isSupportHead == true;
    final renameDashboard = simplifyNav;
    final canSeeRevenue = isAdmin || isAccountant;
    final canSeeReports =
        (!simplifyNav) && (isAdmin || isSupportHead || isAccountant);
    final showReportsDestination = enableReports && canSeeReports;

    // Unified bottom navigation structure
    final destinations = <NavigationDestination>[];
    final navRoutes = <String>[];

    destinations.add(
      NavigationDestination(
        icon: Icon(
          isAccountant ? LucideIcons.receipt : LucideIcons.layoutDashboard,
        ),
        selectedIcon: Icon(
          isAccountant ? LucideIcons.receipt : LucideIcons.layoutDashboard,
          color: AppColors.primary,
        ),
        label: isAccountant
            ? 'Bills'
            : (renameDashboard ? 'Claim Tickets' : 'Dashboard'),
      ),
    );
    navRoutes.add('/');

    // Tickets - shown for non-accountants
    if (!isAccountant) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.ticket),
          selectedIcon: Icon(LucideIcons.ticket, color: AppColors.primary),
          label: 'Tickets',
        ),
      );
      navRoutes.add('/tickets');
    }

    // Customers - shown for all
    destinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.users),
        selectedIcon: Icon(LucideIcons.users, color: AppColors.primary),
        label: 'Customers',
      ),
    );
    navRoutes.add('/customers');

    // Proposals
    destinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.fileText),
        selectedIcon: Icon(LucideIcons.fileText, color: AppColors.primary),
        label: 'Proposals',
      ),
    );
    navRoutes.add('/proposal-generator');

    // Chat
    final rawChatUnread = ref.watch(chatUnreadCountProvider);
    final chatUnread = currentPath.startsWith('/chat') ? 0 : rawChatUnread;
    destinations.add(
      NavigationDestination(
        icon: chatUnread > 0
            ? Badge(
                label: Text(chatUnread > 9 ? '9+' : chatUnread.toString()),
                child: const Icon(LucideIcons.messageSquare),
              )
            : const Icon(LucideIcons.messageSquare),
        selectedIcon: chatUnread > 0
            ? Badge(
                label: Text(chatUnread > 9 ? '9+' : chatUnread.toString()),
                child: const Icon(
                  LucideIcons.messageSquare,
                  color: AppColors.primary,
                ),
              )
            : const Icon(LucideIcons.messageSquare, color: AppColors.primary),
        label: 'Chat',
      ),
    );
    navRoutes.add('/chat');

    // Leads - for sales, accountant & admin
    if (currentUser?.isSales == true ||
        currentUser?.isAccountant == true ||
        currentUser?.isAdmin == true) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.target),
          selectedIcon: Icon(LucideIcons.target, color: AppColors.primary),
          label: 'Leads',
        ),
      );
      navRoutes.add('/leads');
    }

    // Revenue - only for admin/accountant
    if (canSeeRevenue) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.indianRupee),
          selectedIcon: Icon(LucideIcons.indianRupee, color: AppColors.primary),
          label: 'Revenue',
        ),
      );
      navRoutes.add('/revenue');
    }

    // Reports - shown for admins, moderators, accountants when enabled
    if (showReportsDestination) {
      destinations.add(
        const NavigationDestination(
          icon: Icon(LucideIcons.barChart3),
          selectedIcon: Icon(LucideIcons.barChart3, color: AppColors.primary),
          label: 'Reports',
        ),
      );
      navRoutes.add('/reports');
    }

    // Profile - always shown
    destinations.add(
      const NavigationDestination(
        icon: Icon(LucideIcons.user),
        selectedIcon: Icon(LucideIcons.user, color: AppColors.primary),
        label: 'Profile',
      ),
    );
    navRoutes.add('/profile');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        selectedIndex: _getSelectedIndex(currentPath, navRoutes, isAccountant),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 64,
        onDestinationSelected: (index) =>
            _handleNavigation(context, index, navRoutes),
        destinations: destinations,
      ),
    );
  }

  int _getSelectedIndex(
    String current,
    List<String> routes,
    bool isAccountant,
  ) {
    // Exact matches first
    final exactIndex = routes.indexOf(current);
    if (exactIndex != -1) return exactIndex;

    // Special cases
    if (current.startsWith('/ticket')) {
      final ticketIndex = routes.indexOf('/tickets');
      if (ticketIndex != -1) return ticketIndex;
    }
    if (current.startsWith('/customer')) {
      final customerIndex = routes.indexOf('/customers');
      if (customerIndex != -1) return customerIndex;
    }
    // Admin, Accountant, Support dashboards map to '/'
    if (current == '/admin' ||
        current == '/support' ||
        (isAccountant && current == '/accountant') ||
        current == '/sales') {
      return 0; // Home is always 0
    }

    // Fallback: prefix matching
    // Sort routes by length desc to match longest prefix first (e.g. /users vs /)
    final sortedIndices = List.generate(routes.length, (i) => i)
      ..sort((a, b) => routes[b].length.compareTo(routes[a].length));

    for (final index in sortedIndices) {
      final route = routes[index];
      if (route == '/') continue; // Skip root for prefix matching
      if (current.startsWith(route)) {
        return index;
      }
    }

    return 0; // Default to home
  }

  void _handleNavigation(BuildContext context, int index, List<String> routes) {
    if (index >= 0 && index < routes.length) {
      context.go(routes[index]);
    }
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);

    return connectivityAsync.when(
      data: (status) {
        final isOffline = status == ConnectivityResult.none;

        if (!isOffline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          color: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: const Text(
            'You are offline. Some features may be unavailable.',
            style: TextStyle(color: Colors.white, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _UserProfile extends ConsumerWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);

    return InkWell(
      onTap: () => context.go('/profile'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                currentUser?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    currentUser?.role ?? 'Role',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
