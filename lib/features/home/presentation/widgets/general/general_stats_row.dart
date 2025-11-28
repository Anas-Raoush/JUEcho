import 'package:flutter/material.dart';
import 'package:juecho/features/home/presentation/widgets/stats_card.dart';

class GeneralStatsRow extends StatelessWidget {
  const GeneralStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: later replace constants with real values from backend
    const totalFeedback = 5;
    const pendingReviews = 3;
    const totalRatings = 2;

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Expanded(
            child: StatsCard(
              label: 'Total feedback\nsubmissions',
              value: '$totalFeedback',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: StatsCard(
              label: 'Total Pending Reviews',
              value: '$pendingReviews',
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: StatsCard(
              label: 'Total rating\nsubmissions',
              value: '$totalRatings',
            ),
          ),
        ],
      ),
    );
  }
}