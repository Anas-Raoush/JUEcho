import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/shared/stats_card.dart';

/// AdminStatsGrid
///
/// Dashboard stats summary for admin users.
///
/// Data source:
/// - AdminHomeStatsProvider
///
/// UI states:
/// - Initial load (stats == null and isLoading) -> loader
/// - Not loaded / failed (stats == null) -> error + retry
/// - Loaded -> responsive grid rendering four StatsCard widgets
///
/// Responsive layout:
/// - On small widths (< _singleColumnBreakpoint): render as a single column.
/// - Otherwise: render a 2x2 grid using two rows.
class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key});

  static const double _singleColumnBreakpoint = 340;

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminHomeStatsProvider>(
      builder: (context, p, _) {
        if (p.isLoading && p.stats == null) {
          return const SizedBox(
            height: 90,
            child: Center(child: CircularProgressIndicator()),
          );
        }

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