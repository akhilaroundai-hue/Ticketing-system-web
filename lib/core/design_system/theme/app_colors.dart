import 'package:flutter/material.dart';

class AppColors {
  // Slate Palette (Cool Grays) - Inspired by shadcn/ui
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // Primary Brand Colors (AroundTally/Sidharth IT Solutions - Blue)
  static const Color primary = Color(0xFF0066cc); // AroundTally primary blue
  static const Color primaryDark = Color(0xFF004499); // Darker blue
  static const Color primaryLight = Color(0xFF3399ff); // Lighter blue
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Semantic Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color info = Color(0xFF3B82F6); // Blue 500
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100

  // Status Colors (for tickets, deals, etc.)
  static const Color statusNew = Color(0xFF3B82F6); // Blue
  static const Color statusOpen = Color(0xFF6366F1); // Indigo
  static const Color statusInProgress = Color(0xFFF59E0B); // Amber
  static const Color statusWaiting = Color(0xFF8B5CF6); // Violet
  static const Color statusResolved = Color(0xFF10B981); // Emerald
  static const Color statusClosed = Color(0xFF64748B); // Slate

  // Priority Colors
  static const Color priorityCritical = Color(0xFFDC2626); // Red 600
  static const Color priorityHigh = Color(0xFFF59E0B); // Amber 500
  static const Color priorityNormal = Color(0xFF3B82F6); // Blue 500
  static const Color priorityLow = Color(0xFF64748B); // Slate 500

  // Backgrounds
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceAlt = slate50;
  static const Color surfaceHover = slate100;

  // Text
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate500;
  static const Color textMuted = slate400;
  static const Color textOnPrimary = Colors.white;

  // Borders
  static const Color border = slate200;
  static const Color borderFocus = primary;
  static const Color borderHover = slate300;

  // Helper methods for status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return statusNew;
      case 'open':
        return statusOpen;
      case 'in progress':
        return statusInProgress;
      case 'waiting for customer':
        return statusWaiting;
      case 'resolved':
      case 'billraised':
      case 'billprocessed':
        return statusResolved;
      case 'closed':
        return statusClosed;
      default:
        return slate500;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'normal':
        return priorityNormal;
      case 'low':
        return priorityLow;
      default:
        return slate400;
    }
  }
}
