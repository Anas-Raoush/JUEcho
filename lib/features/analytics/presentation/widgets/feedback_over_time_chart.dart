import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/analytics/data/analytics_repository.dart';

/// Bar chart showing feedback activity over time (monthly buckets).
///
/// Input
/// - [data] is expected to be in chronological order (oldest -> newest).
///
/// Empty state
/// - Renders a simple message when [data] is empty.
///
/// Chart library
/// - Uses fl_chart's [BarChart].
class FeedbackOverTimeChart extends StatelessWidget {
  final List<MonthlyCount> data;

  const FeedbackOverTimeChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No feedback activity yet.',
          style: TextStyle(color: AppColors.gray),
        ),
      );
    }

    final maxCount =
    data.map((e) => e.count).fold<int>(0, (max, c) => c > max ? c : max);

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < data.length; i++) {
      final m = data[i];
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: m.count.toDouble(),
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
              color: AppColors.primary,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: (maxCount + 1).toDouble(),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.gray.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }

                  final m = data[index];
                  final label = _monthShortLabel(m.month);

                  return SideTitleWidget(
                    space: 4,
                    meta: meta,
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: bars,
        ),
      ),
    );
  }

  /// Returns short English month labels for 1..12.
  String _monthShortLabel(int month) {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (month < 1 || month > 12) return '';
    return labels[month - 1];
  }
}