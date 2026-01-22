import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../domain/entities/customer.dart';

class CustomerInfoCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;

  const CustomerInfoCard({super.key, required this.customer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.building2,
                      size: 20,
                      color: AppColors.slate700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Customer Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => context.go('/customer/${customer.id}/edit'),
                icon: const Icon(LucideIcons.edit, size: 18),
                tooltip: 'Edit Customer',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),

          // Company Name
          _InfoRow(
            icon: LucideIcons.building,
            label: 'Company',
            value: customer.companyName,
          ),
          const SizedBox(height: 16),

          // Tally Info
          if (customer.tallySerialNo != null) ...[
            _InfoRow(
              icon: LucideIcons.hash,
              label: 'Tally Serial No',
              value: customer.tallySerialNo!,
            ),
            const SizedBox(height: 16),
          ],

          if (customer.tallyLicense != null) ...[
            _InfoRow(
              icon: LucideIcons.key,
              label: 'License',
              value: customer.tallyLicense!,
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 16),

          // AMC & TSS Status
          Row(
            children: [
              Expanded(
                child: _StatusCard(
                  icon: LucideIcons.shieldCheck,
                  label: 'AMC Status',
                  isActive: customer.isAmcActive,
                  expiryDate: customer.amcExpiryDate,
                  daysRemaining: customer.amcDaysRemaining,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusCard(
                  icon: LucideIcons.headphones,
                  label: 'TSS Status',
                  isActive: customer.isTssActive,
                  expiryDate: customer.tssExpiryDate,
                  daysRemaining: customer.tssDaysRemaining,
                  activeColor: AppColors.info,
                  expiredColor: AppColors.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Contact Information
          const Text(
            'Contact Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 16),

          if (customer.contactPerson != null)
            _InfoRow(
              icon: LucideIcons.user,
              label: 'Contact Person',
              value: customer.contactPerson!,
            ),
          if (customer.contactPhone != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: LucideIcons.phone,
              label: 'Phone',
              value: customer.contactPhone!,
            ),
          ],
          if (customer.contactEmail != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              icon: LucideIcons.mail,
              label: 'Email',
              value: customer.contactEmail!,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final DateTime? expiryDate;
  final int daysRemaining;
  final Color activeColor;
  final Color expiredColor;

  const _StatusCard({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.expiryDate,
    required this.daysRemaining,
    this.activeColor = AppColors.success,
    this.expiredColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : expiredColor;
    final dateFormatter = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isActive ? 'Active' : 'Expired',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (expiryDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Expires: ${dateFormatter.format(expiryDate!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.slate600),
            ),
          ],
          if (isActive && daysRemaining > 0 && daysRemaining <= 30) ...[
            const SizedBox(height: 4),
            Text(
              '$daysRemaining days left',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: daysRemaining <= 7 ? AppColors.error : AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
