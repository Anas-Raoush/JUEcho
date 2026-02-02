import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// StatsCard
///
/// Small, reusable card for displaying a single metric.
/// Commonly used in dashboard sections for both general and admin users.
///
/// Displays:
/// - label: short description (typically two lines max)
/// - value: emphasized metric value
///
/// Characteristics:
/// - Presentational only (no business logic)
/// - Safe to rebuild frequently
/// - Uses a subtle shadow and rounded corners for a consistent card feel
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: AppColors.boxShadowColor,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}