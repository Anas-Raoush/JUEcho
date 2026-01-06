import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// A small reusable statistics card used in dashboard rows.
///
/// This widget displays:
/// - a short descriptive [label]
/// - a numeric/textual [value]
///
/// Typical usage:
/// - General user dashboard (total submissions, pending reviews, ratings)
/// - Admin dashboard (total received, resolved issues, etc.)
///
/// Design characteristics:
/// - Fixed internal padding for consistent spacing
/// - Rounded corners and soft shadow for card-like appearance
/// - Center-aligned text for compact layouts
///
/// This widget is:
/// - Stateless
/// - Purely presentational (no business logic)
/// - Safe to rebuild frequently
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.label,
    required this.value,
  });

  /// Short descriptive text shown at the top of the card.
  ///
  /// Example:
  /// - "Total feedback submissions"
  /// - "Pending reviews"
  final String label;

  /// Main value displayed prominently in the card.
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Internal spacing to keep content compact but readable
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

      // Card styling
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

      // Vertical layout for label + value
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Label text (secondary importance)
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gray,
            ),
          ),

          const SizedBox(height: 6),

          // Main value (primary emphasis)
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