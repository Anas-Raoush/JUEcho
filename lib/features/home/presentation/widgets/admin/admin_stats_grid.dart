import 'package:flutter/material.dart';
import 'package:juecho/features/home/presentation/widgets/stats_card.dart';
class AdminStatsGrid extends StatelessWidget {
  const AdminStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: wire these values to a real analytics repository
    const submissionsReceived = 100;
    const topRatedService = 'Library';
    const bottomRatedService = 'Food';
    const resolvedIssues = 5;

    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: StatsCard(
                label: 'Submissions received',
                value: '$submissionsReceived',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                label: 'Top rated service',
                value: topRatedService,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: StatsCard(
                label: 'Bottom rated service',
                value: bottomRatedService,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                label: 'Numbers of resolved issues',
                value: '$resolvedIssues',
              ),
            ),
          ],
        ),
      ],
    );
  }
}