import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../../../features/tickets/presentation/providers/ticket_provider.dart';
import '../../../features/customers/presentation/providers/customer_provider.dart';
import '../../../features/dashboard/presentation/providers/app_settings_provider.dart';
import '../../network/connectivity_provider.dart';
import '../../../features/productivity/presentation/widgets/notification_bell.dart';

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

    final canViewAmcReminder = !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewPastTickets = !simplifyNav &&
        (currentUser?.isSupport == true ||
            currentUser?.isSupportHead == true ||
            currentUser?.isAgent == true);
    final canViewBills = !simplifyNav ||
        currentUser?.isAdmin == true ||
        currentUser?.isAccountant == true;
    final canViewSalesOpportunity =
        currentUser?.isSupportHead == true && !simplifyNav;
    final canViewReports = enableReports &&
        !simplifyNav &&
        canSeeScreen('reports') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);
    final canViewDeals = enableDeals &&
        !simplifyNav &&
        canSeeScreen('deals') &&
        (currentUser?.isAdmin == true ||
            currentUser?.isAccountant == true ||
            currentUser?.isSupportHead == true);

    return Container(
      width: 240,
      decoration: const BoxDecoration(color: AppColors.primary),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    LucideIcons.checkSquare,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'TallyCare',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (enableNotifications) const NotificationBell(),
                if (enableGlobalSearch)
                  IconButton(
                    icon: Icon(
                      LucideIcons.search,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    tooltip: 'Search',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const _GlobalSearchDialog(),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Navigation Items
          _NavItem(
            label: showClaimTicketsLabel ? 'Claim Tickets' : 'Dashboard',
            icon: LucideIcons.layoutDashboard,
            path: '/',
            isActive:
                currentPath == '/' ||
                currentPath == '/admin' ||
                currentPath == '/support' ||
                currentPath == '/accountant' ||
                currentPath == '/accountant',
          ),
          if (currentUser?.isAccountant != true)
            _NavItem(
              label: 'Tickets',
              icon: LucideIcons.ticket,
              path: '/tickets',
              isActive: currentPath.startsWith('/tickets') ||
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
          if (canViewBills)
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
          if (currentUser?.isAdmin == true)
            _NavItem(
              label: 'Settings',
              icon: LucideIcons.settings,
              path: '/settings',
              isActive: currentPath.startsWith('/settings'),
            ),

          const Spacer(),

          // User Profile Stub
          const Padding(padding: EdgeInsets.all(16), child: _UserProfile()),
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

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final String path;
  final bool isActive;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.path,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = Colors.white.withValues(alpha: 0.8);
    return InkWell(
      onTap: () => context.go(path),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : inactiveColor,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : inactiveColor,
              ),
            ),
          ],
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
    final canSeeReports = (!simplifyNav) &&
        (isAdmin || isSupportHead || isAccountant);
    final showReportsDestination = enableReports && canSeeReports;

    // Unified bottom navigation structure
    final destinations = <NavigationDestination>[];
    final navRoutes = <String>[];

    destinations.add(
      NavigationDestination(
        icon: const Icon(LucideIcons.layoutDashboard),
        selectedIcon: const Icon(
          LucideIcons.layoutDashboard,
          color: AppColors.primary,
        ),
        label: renameDashboard ? 'Claim Tickets' : 'Dashboard',
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

  void _handleNavigation(
    BuildContext context,
    int index,
    List<String> navRoutes,
  ) {
    final target = navRoutes[index];
    if (target == '/profile') {
      context.push(target);
    } else if (target == '/') {
      context.go('/');
    } else {
      context.go(target);
    }
  }

  int _getSelectedIndex(
    String path,
    List<String> navRoutes,
    bool isAccountant,
  ) {
    for (var i = 0; i < navRoutes.length; i++) {
      if (_matchesRoute(path, navRoutes[i], isAccountant)) {
        return i;
      }
    }
    return 0;
  }

  bool _matchesRoute(String path, String target, bool isAccountant) {
    switch (target) {
      case '/':
        return path == '/' ||
            path == '/admin' ||
            path == '/support' ||
            path == '/moderator' ||
            path == '/accountant';
      case '/tickets':
        if (isAccountant) return false;
        return path.startsWith('/tickets') || path.startsWith('/ticket');
      case '/customers':
        return path.startsWith('/customers') || path.startsWith('/customer');
      case '/revenue':
        return path.startsWith('/revenue');
      case '/reports':
        return path.startsWith('/reports');
      case '/profile':
        return path.startsWith('/profile');
      default:
        return false;
    }
  }
}

class _OfflineBanner extends ConsumerWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    if (!isOffline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(
        children: [
          Icon(LucideIcons.wifiOff, size: 16, color: AppColors.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are offline. Some data may be outdated and changes might fail.',
              style: TextStyle(fontSize: 12, color: AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserProfile extends ConsumerWidget {
  const _UserProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return InkWell(
      onTap: () => context.push('/profile'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.slate200,
              child: Icon(Icons.person, size: 16, color: AppColors.slate500),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user?.role ?? 'Role',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.slate500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
