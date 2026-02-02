import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/analytics/data/analytics_repository.dart';

/// Donut chart for service distribution.
///
/// Input
/// - [data] is expected to contain up to the top 3 services by submission count.
///
/// Empty state
/// - Renders a simple message when [data] is empty.
///
/// Chart library
/// - Uses fl_chart's [PieChart].
///
/// Notes
/// - Colors are derived from [AppColors.primary] with varying alpha so the chart
///   remains brand-consistent without additional palette dependencies.
class ServicesDonutChart extends StatelessWidget {
  final List<ServiceCount> data;

  const ServicesDonutChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No feedback reports yet.',
          style: TextStyle(color: AppColors.gray),
        ),
      );
    }

    final total = data.fold<int>(0, (sum, e) => sum + e.count);

    final colors = List.generate(
      data.length,
          (i) => AppColors.primary.withValues(
        alpha: 0.3 + 0.6 * (i / (data.length)),
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              startDegreeOffset: -90,
              sections: [
                for (int i = 0; i < data.length; i++)
                  PieChartSectionData(
                    value: data[i].count.toDouble(),
                    color: colors[i],
                    radius: 60,
                    title: '',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < data.length; i++)
              _LegendItem(
                color: colors[i],
                label: '${data[i].category.label} (${data[i].count}/$total)',
              ),
          ],
        ),
      ],
    );
  }
}

/// Legend item mapping a chart segment color to a readable label.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}