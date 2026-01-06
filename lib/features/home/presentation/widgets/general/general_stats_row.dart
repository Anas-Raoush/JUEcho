import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/shared/stats_card.dart';

/// Shows the general user's dashboard stats (3 cards).
///
/// Data source:
/// - Reads values from [GeneralHomeStatsProvider] using `context.select`
///   so this widget only rebuilds when the selected fields change.
///
/// UI behavior:
/// - While loading and no stats yet -> shows a compact loader.
/// - If stats failed -> shows an error + Retry button.
/// - If stats ready -> shows 3 [StatsCard] widgets.
///
/// Responsive:
/// - On narrow phones: stacks cards vertically (full width).
/// - On normal/wide widths: keeps the original row layout (3 cards in one row).
class GeneralStatsRow extends StatelessWidget {
  const GeneralStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    // Performance: only rebuild when these specific values change.
    final isLoading =
    context.select<GeneralHomeStatsProvider, bool>((p) => p.isLoading);
    final stats =
    context.select<GeneralHomeStatsProvider, dynamic>((p) => p.stats);
    final error =
    context.select<GeneralHomeStatsProvider, String?>((p) => p.error);

    // Loading state (only when we don't have any stats yet).
    if (isLoading && stats == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error/empty state.
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

    // Stats are ready here.
    final s = stats;

    // Simple responsive rule:
    // - Small phones -> column
    // - Normal screens -> original row
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
      // Clean small-device UI: full-width stacked cards.
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