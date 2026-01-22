import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusVariant {
  success, // Green (Active, Resolved)
  warning, // Amber (Expiring, In Progress)
  error, // Red (Expired, Critical)
  info, // Blue (New, TSS)
  neutral, // Gray (Closed, Unknown)
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusVariant variant;
  final bool outlined;

  const StatusBadge({
    super.key,
    required this.label,
    required this.variant,
    this.outlined = false,
  });

  Color get _color {
    switch (variant) {
      case StatusVariant.success:
        return AppColors.success;
      case StatusVariant.warning:
        return AppColors.warning;
      case StatusVariant.error:
        return AppColors.error;
      case StatusVariant.info:
        return AppColors.info;
      case StatusVariant.neutral:
        return AppColors.slate500;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: outlined ? color : color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
