import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class GeneralStatsRow extends StatelessWidget {
  const GeneralStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: later replace constants with real values from backend
    const totalFeedback = 5;
    const pendingReviews = 3;
    const totalRatings = 2;

    return SizedBox(
      height: 96, // fixed height so all three cards are identical
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Expanded(
            child: _StatusCard(
              label: 'Total feedback\nsubmissions',
              value: '$totalFeedback',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatusCard(
              label: 'Pending Reviews',
              value: '$pendingReviews',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _StatusCard(
              label: 'Total rating\nsubmissions',
              value: '$totalRatings',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
        mainAxisAlignment: MainAxisAlignment.center, // centers text vertically
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
