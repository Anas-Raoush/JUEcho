import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/shared/stats_card.dart';

/// Admin stats grid shown on the admin dashboard.
///
/// Responsive behavior:
/// - Normal phones/tablets: 2x2 grid (two rows, two cards per row).
/// - Very small widths: switches to a single column (one card per row)
///   to avoid tight squeezing / ugly overflow.
///
/// Data behavior:
/// - Shows a loader while first loading.
/// - Shows a retry UI if stats are null.
class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key});

  /// Width at which we switch to a single-column layout.
  /// You can tweak this if your cards still look tight.
  static const double _singleColumnBreakpoint = 340;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminHomeStatsProvider>(
      builder: (context, p, _) {
        // First-time loading (no cached stats yet)
        if (p.isLoading && p.stats == null) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Failed / not loaded
        if (p.stats == null) {
          return Column(
            children: [
              const Text(
                'Could not load admin stats.',
                style: TextStyle(color: AppColors.red, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: p.load,
                child: const Text('Retry'),
              ),
            ],
          );
        }

        final s = p.stats!;

        // Use LayoutBuilder to decide layout based on actual available width.
        return LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final bool singleColumn = w < _singleColumnBreakpoint;

            final cards = <Widget>[
              StatsCard(
                label: 'Submissions\nreceived',
                value: '${s.submissionsReceived}',
              ),
              StatsCard(
                label: 'Resolved\nissues',
                value: '${s.resolvedIssues}',
              ),
              StatsCard(
                label: 'Top rated\nservice',
                value: s.topRatedServiceLabel ?? '-',
              ),
              StatsCard(
                label: 'Lowest rated\nservice',
                value: s.bottomRatedServiceLabel ?? '-',
              ),
            ];

            //  Small devices: one card per row (column layout)
            if (singleColumn) {
              return Column(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    cards[i],
                    if (i != cards.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }

            //  Normal: 2x2 grid (same look you already had)
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 8),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 8),
                    Expanded(child: cards[3]),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}