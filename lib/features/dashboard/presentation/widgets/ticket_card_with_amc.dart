import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/app_settings_provider.dart';

const Set<String> _stageBilledStatuses = {
  'billprocessed',
  'closed',
};

const Set<String> _autoStartStatuses = {
  'New',
  'Open',
  'Waiting for Customer',
};

/// Converts a DateTime to local time for display
/// Timestamps are stored and retrieved as local time (no timezone conversion needed).
DateTime _toLocalTime(DateTime dateTime) {
  return dateTime;
}

enum TicketCardLayout {
  standard, // Vertical lists: Center Company Name
  compact, // Top Section: Title Left, Overdue Right, Company below Badge
}

class TicketCardWithAmc extends ConsumerWidget {
  final Ticket ticket;
  final bool highlightPriorityCustomer;
  final TicketCardLayout layout;
  final bool forceClaimButton;

  const TicketCardWithAmc({
    super.key,
    required this.ticket,
    this.highlightPriorityCustomer = false,
    this.layout = TicketCardLayout.standard,
    this.forceClaimButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(ticketCustomerProvider(ticket.customerId));
    final isCustomerLoading = customerAsync.isLoading;
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

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
    final currentUser = ref.watch(authProvider);
    final isMyTicket = currentUser?.id == ticket.assignedTo;
    final roleLower = currentUser?.role.trim().toLowerCase() ?? '';
    final canClaimTicket = forceClaimButton ||
        currentUser?.isSupport == true ||
        currentUser?.isSupportHead == true ||
        currentUser?.isAgent == true ||
        roleLower.contains('support');
    final isCompactLayout = layout == TicketCardLayout.compact;

    final hasRibbon = ribbonLabel != null;

    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;
    final disableCardTap = canClaimTicket && isUnassigned;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkSurface
                ? Colors.black.withValues(alpha: 0.25)
                : AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (!isDarkSurface)
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              disableCardTap
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: isCompactLayout
                          ? _buildCompactContent(
                              context: context,
                              ref: ref,
                              headingColor: headingColor,
                              customerAsync: customerAsync,
                              canClaimTicket: canClaimTicket,
                              isMyTicket: isMyTicket,
                              hasRibbon: hasRibbon,
                            )
                          : _buildStandardContent(
                              context: context,
                              ref: ref,
                              headingColor: headingColor,
                              customerAsync: customerAsync,
                              canClaimTicket: canClaimTicket,
                              isMyTicket: isMyTicket,
                              hasRibbon: hasRibbon,
                            ),
                    )
                  : InkWell(
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
                                customerAsync: customerAsync,
                                canClaimTicket: canClaimTicket,
                                isMyTicket: isMyTicket,
                                hasRibbon: hasRibbon,
                              )
                            : _buildStandardContent(
                                context: context,
                                ref: ref,
                                headingColor: headingColor,
                                customerAsync: customerAsync,
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


  Widget _buildStandardContent({
    required BuildContext context,
    required WidgetRef ref,
    required Color headingColor,
    required AsyncValue<Map<String, dynamic>?> customerAsync,
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
    final referenceDateRaw = ticket.updatedAt ?? ticket.createdAt;
    final referenceDate =
        referenceDateRaw == null ? null : _toLocalTime(referenceDateRaw);
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null
            ? timeago.format(
                referenceDate,
                clock: _toLocalTime(DateTime.now().toUtc()),
              )
            : null;
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,
      
    );
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;

    final statusPill = _buildMinimalStatusPill(
      status: ticket.status,
      isUnassigned: isUnassigned,
      isMyTicket: isMyTicket,
    );

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
          ],
        ),
        const SizedBox(height: 8),
        if (statusPill != null) statusPill,
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
    required AsyncValue<Map<String, dynamic>?> customerAsync,
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
    final referenceDateRaw = ticket.updatedAt ?? ticket.createdAt;
    final referenceDate =
        referenceDateRaw == null ? null : _toLocalTime(referenceDateRaw);
    final createdTimestamp = referenceDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(referenceDate)
        : null;
    final createdRelative =
        referenceDate != null
            ? timeago.format(
                referenceDate,
                clock: _toLocalTime(DateTime.now().toUtc()),
              )
            : null;
    final actionButton = _buildActionButtons(
      context: context,
      ref: ref,
      canClaimTicket: canClaimTicket,
      isMyTicket: isMyTicket,
      
    );
    final isUnassigned =
        ticket.assignedTo == null || ticket.assignedTo!.isEmpty;
    final statusPill = _buildMinimalStatusPill(
      status: ticket.status,
      isUnassigned: isUnassigned,
      isMyTicket: isMyTicket,
    );

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
        if (statusPill != null) statusPill,
        if (actionButton != null) ...[
          const SizedBox(height: 12),
          actionButton,
        ],
      ],
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

  Widget? _buildMinimalStatusPill({
    required String status,
    required bool isUnassigned,
    required bool isMyTicket,
  }) {
    final normalized = status.trim().toLowerCase();

    if (_stageBilledStatuses.contains(normalized)) {
      return _buildInfoPill(
        icon: LucideIcons.receipt,
        label: 'Billed',
        iconColor: AppColors.success,
        textColor: AppColors.success,
        backgroundColor: AppColors.success.withValues(alpha: 0.12),
      );
    }

    if (normalized == 'billraised') {
      return _buildInfoPill(
        icon: LucideIcons.fileText,
        label: 'Bill Raised',
        iconColor: AppColors.warning,
        textColor: AppColors.warning,
        backgroundColor: AppColors.warning.withValues(alpha: 0.12),
      );
    }

    if (normalized == 'resolved') {
      return _buildInfoPill(
        icon: LucideIcons.checkCircle,
        label: 'Resolved',
        iconColor: AppColors.success,
        textColor: AppColors.success,
        backgroundColor: AppColors.success.withValues(alpha: 0.12),
      );
    }

    if (!isUnassigned) {
      return _buildInfoPill(
        icon: LucideIcons.userCheck,
        label: isMyTicket ? 'Claimed by you' : 'Claimed',
        iconColor: AppColors.info,
        textColor: AppColors.info,
        backgroundColor: AppColors.info.withValues(alpha: 0.12),
      );
    }

    return null;
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
              foregroundColor: AppColors.info,
              side: BorderSide(color: AppColors.info.withValues(alpha: 0.6)),
            ),
            onPressed: () async {
              context.go(
                '/ticket/${ticket.ticketId}',
                extra: {'autoClaim': true},
              );
            },
          ),
        ),
      );
    }

    // Simplified flow: no hold/resume buttons.

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
