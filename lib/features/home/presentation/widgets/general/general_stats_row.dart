import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/shared/stats_card.dart';

/// GeneralStatsRow
///
/// Dashboard statistics row for GENERAL users (3 cards).
///
/// Data source:
/// - GeneralHomeStatsProvider
///
/// UI states:
/// - Initial load (stats == null and isLoading) -> loader
/// - Not loaded / failed (stats == null) -> error + retry
/// - Loaded -> responsive row/column rendering of three StatsCard widgets
///
/// Rebuild strategy:
/// - Uses context.select to rebuild only when relevant provider fields change.
class GeneralStatsRow extends StatelessWidget {
  const GeneralStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading =
    context.select<GeneralHomeStatsProvider, bool>((p) => p.isLoading);
    final stats =
    context.select<GeneralHomeStatsProvider, dynamic>((p) => p.stats);
    final error =
    context.select<GeneralHomeStatsProvider, String?>((p) => p.error);

    if (isLoading && stats == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (stats == null) {
      return Column(
        children: [
          Text(
            error ?? 'Could not load your stats.',
            style: const TextStyle(color: AppColors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: context.read<GeneralHomeStatsProvider>().refresh,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final s = stats;
    final isSmallPhone = MediaQuery.of(context).size.width < 350;

    final cards = <Widget>[
      StatsCard(
        label: 'Total feedback\nsubmissions',
        value: '${s.totalFullFeedback}',
      ),
      StatsCard(
        label: 'Total pending\nreviews',
        value: '${s.pendingReviews}',
      ),
      StatsCard(
        label: 'Total rating\nsubmissions',
        value: '${s.ratingOnlyCount}',
      ),
    ];

    if (isSmallPhone) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 8),
          cards[1],
          const SizedBox(height: 8),
          cards[2],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 8),
        Expanded(child: cards[1]),
        const SizedBox(width: 8),
        Expanded(child: cards[2]),
      ],
    );
  }
}