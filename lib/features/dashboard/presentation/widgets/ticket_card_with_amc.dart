import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../../../core/design_system/components/status_badge.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/app_settings_provider.dart';

const Set<String> _stagePendingStatuses = {
  'in progress',
  'inprogress',
  'waiting for customer',
  'waitingforcustomer',
  'waiting',
  'onhold',
  'pending',
  'acknowledged',
  'assigned',
};

const Set<String> _stageResolvedStatuses = {
  'resolved',
};

const Set<String> _stageBilledStatuses = {
  'billraised',
  'billprocessed',
  'closed',
};

const Set<String> _autoStartStatuses = {
  'New',
  'Open',
  'Waiting for Customer',
};

enum TicketCardLayout {
  standard, // Vertical lists: Center Company Name
  compact, // Top Section: Title Left, Overdue Right, Company below Badge
}

class TicketCardWithAmc extends ConsumerWidget {
  final Ticket ticket;
  final bool highlightPriorityCustomer;
  final TicketCardLayout layout;

  const TicketCardWithAmc({
    super.key,
    required this.ticket,
    this.highlightPriorityCustomer = false,
    this.layout = TicketCardLayout.standard,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(ticketCustomerProvider(ticket.customerId));
    final isCustomerLoading = customerAsync.isLoading;
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    final slaChip = _buildSlaChip(ticket, advancedSettings);

    Color? cardBackgroundColor;
    Color? borderColor;
    Color? ribbonColor;
    Color? ribbonTextColor;
    String? ribbonLabel;
    IconData? ribbonIcon;

    if (!isCustomerLoading &&
        (ticket.assignedTo == null || ticket.assignedTo!.isEmpty)) {
      final slaColors = _getSlaColors(ticket, advancedSettings);
      cardBackgroundColor = slaColors['background'];
      borderColor = slaColors['border'];
    }

    final isPriorityCustomer =
        highlightPriorityCustomer ||
        customerAsync.maybeWhen(
          data: (data) {
            if (data == null) return false;
            return Customer.fromJson(data).isAmcActive;
          },
          orElse: () => false,
        );

    if (customerAsync.hasValue && customerAsync.value != null) {
      final customer = Customer.fromJson(customerAsync.value!);
      if (customer.isAmcActive) {
        cardBackgroundColor = const Color(0xFFDBEAFE); // calm blue background
        borderColor = const Color(0xFF60A5FA); // blue-400 border
        ribbonColor = const Color(0xFF1D4ED8); // solid blue ribbon
        ribbonTextColor = Colors.white;
        ribbonLabel = 'AMC Priority';
        ribbonIcon = LucideIcons.sparkles;
      } else {
        cardBackgroundColor = Colors.white;
        borderColor = AppColors.border;
        ribbonColor = const Color(0xFFF1F5F9);
        ribbonTextColor = AppColors.slate700;
        ribbonLabel = 'Standard';
        ribbonIcon = LucideIcons.users;
      }
    } else if (isPriorityCustomer) {
      cardBackgroundColor ??= Colors.white;
      borderColor ??= AppColors.border;
      ribbonColor ??= const Color(0xFFF1F5F9);
      ribbonTextColor ??= AppColors.slate700;
      ribbonLabel ??= 'Priority';
      ribbonIcon ??= LucideIcons.star;
    }

    final backgroundColor = cardBackgroundColor ?? Colors.white;
    final bool isDarkSurface =
        ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    final Color headingColor = isDarkSurface
        ? Colors.white
        : AppColors.slate900;
    final Color bodyColor = isDarkSurface
        ? Colors.white.withValues(alpha: 0.85)
        : AppColors.slate600;
    final Color subtleIconColor = isDarkSurface
        ? Colors.white.withValues(alpha: 0.7)
        : AppColors.slate400;

    final currentUser = ref.watch(authProvider);
    final isMyTicket = currentUser?.id == ticket.assignedTo;
    final canClaimTicket = currentUser?.isSupport == true ||
        currentUser?.isSupportHead == true ||
        currentUser?.isAgent == true;
    final isCompactLayout = layout == TicketCardLayout.compact;

    final hasRibbon = ribbonLabel != null;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderColor != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkSurface
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              InkWell(
                onTap: () => context.push('/ticket/${ticket.ticketId}'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: isCompactLayout
                      ? _buildCompactContent(
                          context: context,
                          ref: ref,
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          subtleIconColor: subtleIconColor,
                          customerAsync: customerAsync,
                          slaChip: slaChip,
                          canClaimTicket: canClaimTicket,
                          isMyTicket: isMyTicket,
                          hasRibbon: hasRibbon,
                        )
                      : _buildStandardContent(
                          context: context,
                          ref: ref,
                          headingColor: headingColor,
                          bodyColor: bodyColor,
                          subtleIconColor: subtleIconColor,
                          customerAsync: customerAsync,
                          slaChip: slaChip,
                          canClaimTicket: canClaimTicket,
                          isMyTicket: isMyTicket,
                          hasRibbon: hasRibbon,
                        ),
                ),
              ),
              if (ribbonLabel != null)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: _buildRibbon(
                    label: ribbonLabel,
                    color: ribbonColor ?? Colors.white,
                    textColor: ribbonTextColor ?? AppColors.slate700,
                    icon: ribbonIcon,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRibbon({
    required String label,
    required Color color,
    required Color textColor,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getSlaColors(Ticket ticket, dynamic advancedSettings) {
    final now = DateTime.now();
    final slaDue = _computeTargetDue(ticket, advancedSettings);

    if (slaDue != null) {
      final minutes = slaDue.difference(now).inMinutes;

      if (minutes >= 60) {
        return {
          'background': AppColors.success.withValues(alpha: 0.08),
          'border': AppColors.success.withValues(alpha: 0.3),
        };
      } else if (minutes >= 0) {
        return {
          'background': AppColors.warning.withValues(alpha: 0.08),
          'border': AppColors.warning.withValues(alpha: 0.3),
        };
      } else {
        return {
          'background': AppColors.error.withValues(alpha: 0.08),
          'border': AppColors.error.withValues(alpha: 0.3),
        };
      }
    }

    final ageMinutes = now.difference(ticket.createdAt ?? now).inMinutes;
    if (ageMinutes < 60) {
      return {
        'background': AppColors.success.withValues(alpha: 0.04),
        'border': AppColors.success.withValues(alpha: 0.2),
      };
    } else if (ageMinutes < 4 * 60) {
      return {
        'background': AppColors.warning.withValues(alpha: 0.04),
        'border': AppColors.warning.withValues(alpha: 0.2),
      };
    } else {
      return {
        'background': AppColors.error.withValues(alpha: 0.04),
        'border': AppColors.error.withValues(alpha: 0.2),
      };
    }
  }

  DateTime? _computeTargetDue(Ticket ticket, dynamic advancedSettings) {
    if (ticket.slaDue != null) {
      return ticket.slaDue;
    }

    if (advancedSettings == null) return null;

    try {
      final minutes = advancedSettings.slaMinutesForPriority(ticket.priority);
      if (minutes <= 0) return null;
      final createdAt = ticket.createdAt;
      if (createdAt == null) return null;
      return createdAt.add(Duration(minutes: minutes));
    } catch (_) {
      return null;
    }
  }

  Widget? _buildSlaChip(Ticket ticket, dynamic advancedSettings) {
    final slaDue = _computeTargetDue(ticket, advancedSettings);
    if (slaDue == null) return null;

    if (['Resolved', 'Closed', 'BillProcessed'].contains(ticket.status)) {
      return null;
    }

    final now = DateTime.now();
    final diff = slaDue.difference(now);
    final minutes = diff.inMinutes;

    String label;
    Color bg;
    Color fg;

    if (minutes >= 60) {
      final hours = (minutes / 60).ceil();
      label = 'Due in ${hours}h';
      bg = AppColors.success.withValues(alpha: 0.1);
      fg = AppColors.success;
    } else if (minutes >= 0) {
      label = 'Due in ${minutes}m';
      bg = AppColors.warning.withValues(alpha: 0.1);
      fg = AppColors.warning;
    } else {
      final overdueMinutes = -minutes;
      if (overdueMinutes >= 60) {
        final hours = (overdueMinutes / 60).ceil();
        label = 'Overdue by ${hours}h';
      } else {
        label = 'Overdue by ${overdueMinutes}m';
      }
      bg = AppColors.error.withValues(alpha: 0.1);
      fg = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  Widget _buildStandardContent({
    required BuildContext context,
    required WidgetRef ref,
    required Color headingColor,
    required Color bodyColor,
    required Color subtleIconColor,
    required AsyncValue<Map<String, dynamic>?> customerAsync,
    Widget? slaChip,
    required bool canClaimTicket,
    required bool isMyTicket,
    required bool hasRibbon,
  }) {
    final customer = customerAsync.maybeWhen(
      data: (data) => data == null ? null : Customer.fromJson(data),
      orElse: () => null,
    );
    final companyName = customer?.companyName.trim().isEmpty == true
        ? null
        : customer?.companyName;
    final referenceDate =
        (ticket.updatedAt ?? ticket.createdAt)?.toLocal();
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null ? timeago.format(referenceDate) : null;
    final assignmentChip = _buildAssignmentChip(ref, isMyTicket);
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,
    );
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;

    final metadataChips = <Widget>[
      _buildStatusBadge(ticket.status),
      if (assignmentChip != null) assignmentChip,
      if (assignmentChip == null && isUnassigned)
        _buildInfoPill(
          icon: LucideIcons.userPlus,
          label: 'Unassigned',
          iconColor: AppColors.slate500,
          backgroundColor: AppColors.slate100,
          textColor: AppColors.slate700,
        ),
      if (slaChip != null) slaChip,
      if (customer != null &&
          (customer.isAmcActive || highlightPriorityCustomer))
        _AmcBadge(isActive: customer.isAmcActive),
      if (_shouldShowBillingChip(ticket.status))
        _buildAmountChip(ticket.billAmount),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyName != null || createdTimestamp != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: companyName != null
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.building2,
                            size: 18,
                            color: AppColors.slate500,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              companyName,
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: headingColor,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'No company linked',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate500,
                        ),
                      ),
              ),
              if (createdTimestamp != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      createdTimestamp,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate900,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    if (createdRelative != null)
                      Text(
                        createdRelative,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _buildPriorityIcon(ticket.priority),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ticket.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(ticket.status),
          ],
        ),
        const SizedBox(height: 10),
        _buildStatusProgressBar(ticket.status),
        const SizedBox(height: 8),
        if (metadataChips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metadataChips,
          ),
        if (actionButton != null) ...[
          const SizedBox(height: 12),
          actionButton,
        ],
      ],
    );
  }

  Widget _buildCompactContent({
    required BuildContext context,
    required WidgetRef ref,
    required Color headingColor,
    required Color bodyColor,
    required Color subtleIconColor,
    required AsyncValue<Map<String, dynamic>?> customerAsync,
    Widget? slaChip,
    required bool canClaimTicket,
    required bool isMyTicket,
    required bool hasRibbon,
  }) {
    final customer = customerAsync.maybeWhen(
      data: (data) => data == null ? null : Customer.fromJson(data),
      orElse: () => null,
    );
    final companyName = customer?.companyName.trim().isEmpty == true
        ? null
        : customer?.companyName;
    final referenceDate =
        (ticket.updatedAt ?? ticket.createdAt)?.toLocal();
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null ? timeago.format(referenceDate) : null;
    final assignmentChip = _buildAssignmentChip(ref, isMyTicket);
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,
    );
    final metadataChips = <Widget>[
      _buildStatusBadge(ticket.status),
      if (assignmentChip != null) assignmentChip,
      if (assignmentChip == null)
        _buildInfoPill(
          icon: LucideIcons.userPlus,
          label: 'Unassigned',
          iconColor: AppColors.slate500,
          backgroundColor: AppColors.slate100,
          textColor: AppColors.slate700,
        ),
      if (slaChip != null) slaChip,
      if (customer != null &&
          (customer.isAmcActive || highlightPriorityCustomer))
        _AmcBadge(isActive: customer.isAmcActive),
      if (_shouldShowBillingChip(ticket.status))
        _buildAmountChip(ticket.billAmount),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (companyName != null || createdTimestamp != null) ...[
          Padding(
            padding: EdgeInsets.only(right: hasRibbon ? 88 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: companyName != null
                      ? Text(
                          companyName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: headingColor,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'No company linked',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate500,
                          ),
                        ),
                ),
                if (createdTimestamp != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        createdTimestamp,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (createdRelative != null)
                        Text(
                          createdRelative,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.slate600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _buildPriorityIcon(ticket.priority),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ticket.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: headingColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatusProgressBar(ticket.status),
        const SizedBox(height: 8),
        if (metadataChips.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: metadataChips,
          ),
        if (actionButton != null) ...[
          const SizedBox(height: 12),
          actionButton,
        ],
      ],
    );
  }

  Widget? _buildAssignmentChip(WidgetRef ref, bool isMyTicket) {
    final assignedTo = ticket.assignedTo;
    if (assignedTo == null || assignedTo.isEmpty) return null;

    final assignedAgentAsync = ref.watch(
      ticketAssignedAgentProvider(assignedTo),
    );

    return assignedAgentAsync.when(
      data: (agentData) {
        final displayName = (agentData?['full_name'] ??
                agentData?['username'] ??
                'Assigned')
            .toString();
        final label = isMyTicket
            ? 'Assigned to you'
            : 'Assigned to $displayName';
        return _buildInfoPill(
          icon: LucideIcons.userCheck,
          label: label,
          iconColor: AppColors.success,
          textColor: AppColors.success,
          backgroundColor: AppColors.success.withValues(alpha: 0.12),
        );
      },
      loading: () => _buildInfoPill(
        icon: LucideIcons.userCheck,
        label: 'Assigning…',
        iconColor: AppColors.slate500,
        textColor: AppColors.slate600,
        backgroundColor: AppColors.slate100,
      ),
      error: (_, __) => _buildInfoPill(
        icon: LucideIcons.userCheck,
        label: 'Claimed',
        iconColor: AppColors.slate500,
        textColor: AppColors.slate600,
        backgroundColor: AppColors.slate100,
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor ?? AppColors.slate600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildActionButtons({
    required BuildContext context,
    required WidgetRef ref,
    required bool canClaimTicket,
    required bool isMyTicket,
  }) {
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;

    final buttons = <Widget>[];

    if (canClaimTicket && isUnassigned) {
      buttons.add(
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.userCheck, size: 16),
            label: const Text('Claim ticket'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.slate900,
              side: BorderSide(color: AppColors.border),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final currentUser = ref.read(authProvider);
              if (currentUser == null) return;

              final success = await ref
                  .read(ticketAssignerProvider.notifier)
                  .assignTicket(ticket.ticketId, currentUser.id);

              if (!context.mounted) return;
              if (success) {
                ref.invalidate(ticketsStreamProvider);
                String message = 'Ticket claimed successfully';
                Color snackColor = AppColors.success;

                if (_autoStartStatuses.contains(ticket.status)) {
                  final statusError = await ref
                      .read(ticketStatusUpdaterProvider.notifier)
                      .updateStatus(ticket.ticketId, 'In Progress');

                  if (!context.mounted) return;

                  if (statusError != null) {
                    message =
                        'Ticket claimed but failed to start work: $statusError';
                    snackColor = AppColors.error;
                  } else {
                    message = 'Ticket claimed and moved to In Progress';
                  }
                }

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: snackColor,
                  ),
                );

                context.push('/ticket/${ticket.ticketId}');
              } else {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to claim ticket'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ),
      );
    }

    if (isMyTicket && !isUnassigned) {
      if (ticket.status == 'In Progress') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton.icon(
              icon: const Icon(LucideIcons.pauseCircle, size: 16),
              label: const Text('Put on Hold'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _updateTicketStatus(
                context,
                ref,
                'On Hold',
              ),
            ),
          ),
        );
      } else if (ticket.status == 'On Hold') {
        buttons.add(
          SizedBox(
            width: double.infinity,
            height: 40,
            child: FilledButton.icon(
              icon: const Icon(LucideIcons.playCircle, size: 16),
              label: const Text('Resume Work'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _updateTicketStatus(
                context,
                ref,
                'In Progress',
              ),
            ),
          ),
        );
      }
    }

    if (buttons.isEmpty) {
      if (ticket.status == 'BillRaised') {
        return const SizedBox.shrink();
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i != buttons.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Future<void> _updateTicketStatus(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await ref
        .read(ticketStatusUpdaterProvider.notifier)
        .updateStatus(ticket.ticketId, status);

    if (!context.mounted) return;

    final success = error == null;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (status == 'On Hold' ? 'Ticket paused' : 'Ticket resumed')
              : 'Failed to update status: $error',
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    StatusVariant variant;
    if (status.contains('New') || status.contains('Open')) {
      variant = StatusVariant.info;
    } else if (status.contains('Progress')) {
      variant = StatusVariant.warning;
    } else if (status.contains('Resolved')) {
      variant = StatusVariant.success;
    } else {
      variant = StatusVariant.neutral;
    }

    return StatusBadge(label: status, variant: variant);
  }

  Widget _buildAmountChip(num? amount) {
    final label = amount == null
        ? 'Amount pending'
        : 'Amount: ₹${amount.toStringAsFixed(0)}';
    return _buildInfoPill(
      icon: LucideIcons.indianRupee,
      label: label,
      iconColor: AppColors.slate500,
      textColor: AppColors.slate700,
      backgroundColor: AppColors.slate100,
    );
  }

  bool _shouldShowBillingChip(String status) {
    return [
      'BillRaised',
      'BillProcessed',
      'Resolved',
      'Closed',
    ].contains(status);
  }

  Widget _buildPriorityIcon(String? priority) {
    Color color;
    IconData icon;

    final p = (priority ?? 'medium').toLowerCase();
    switch (p) {
      case 'urgent':
        color = AppColors.error;
        icon = LucideIcons.zap;
        break;
      case 'high':
        color = AppColors.warning;
        icon = LucideIcons.alertCircle;
        break;
      case 'medium':
        color = AppColors.info;
        icon = LucideIcons.flag;
        break;
      case 'low':
        color = AppColors.success;
        icon = LucideIcons.flag;
        break;
      default:
        color = AppColors.slate400;
        icon = LucideIcons.flag;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildStatusProgressBar(String status) {
    const stageLabels = ['Start', 'Pending', 'Resolved', 'Billed'];
    final activeIndex = _statusStageIndex(status);
    final totalSegments = stageLabels.length * 2 - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(totalSegments, (index) {
            if (index.isOdd) {
              final connectorIndex = index ~/ 2;
              final isFilled = activeIndex > connectorIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  color: isFilled ? AppColors.success : AppColors.slate200,
                ),
              );
            }

            final nodeIndex = index ~/ 2;
            final isReached = activeIndex >= nodeIndex;
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isReached ? AppColors.success : Colors.white,
                border: Border.all(
                  color: isReached ? AppColors.success : AppColors.slate200,
                  width: 2,
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: stageLabels
              .map(
                (label) => Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  int _statusStageIndex(String status) {
    final normalized = status.trim().toLowerCase();
    if (_stageBilledStatuses.contains(normalized)) return 3;
    if (_stageResolvedStatuses.contains(normalized)) return 2;
    if (_stagePendingStatuses.contains(normalized)) return 1;
    return 0;
  }

}

class _AmcBadge extends StatelessWidget {
  final bool isActive;

  const _AmcBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? LucideIcons.checkCircle : LucideIcons.alertCircle,
              size: 10,
              color: isActive ? AppColors.success : AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'AMC' : 'AMC Expired',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isActive ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
