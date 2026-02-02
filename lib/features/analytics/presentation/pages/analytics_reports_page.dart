import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/analytics/presentation/provider/analytics_provider.dart';
import 'package:juecho/features/analytics/presentation/widgets/analytics_export_button.dart';
import 'package:juecho/features/analytics/presentation/widgets/feedback_over_time_chart.dart';
import 'package:juecho/features/analytics/presentation/widgets/services_donut_chart.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';

/// Admin analytics screen showing chart summaries and export actions.
///
/// Responsibilities
/// - Triggers [AnalyticsProvider.init] after first frame (context-safe).
/// - Renders:
///   - Services donut chart (top services by full feedback)
///   - Feedback over time chart (last 12 months, full feedback)
///   - Export button for service report CSV
///
/// Responsive layout
/// - Constrains max width on wide screens.
/// - Applies consistent horizontal padding.
class AnalyticsReportsPage extends StatefulWidget {
  const AnalyticsReportsPage({super.key});

  static const routeName = '/admin-analytics';

  @override
  State<AnalyticsReportsPage> createState() => _AnalyticsReportsPageState();
}

class _AnalyticsReportsPageState extends State<AnalyticsReportsPage> {
  @override
  void initState() {
    super.initState();

    // Initialize provider after the first frame to avoid context timing issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<AnalyticsProvider>();
      if (p.summary == null && !p.isLoading) {
        p.init();
      }
    });
  }

  /// Max content width to avoid stretching on desktop screens.
  double _maxWidthFor(double w) {
    if (w >= 1200) return 1000;
    if (w >= 900) return 900;
    if (w >= 700) return 650;
    return double.infinity;
  }

  /// Horizontal padding that scales slightly on very narrow devices.
  EdgeInsets _pagePaddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 4);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: _pagePaddingFor(w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageTitle(title: 'Analytics and Reports'),
                    const SizedBox(height: 8),
                    Consumer<AnalyticsProvider>(
                      builder: (context, p, _) {
                        if (p.isLoading && p.summary == null) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (p.summary == null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Column(
                              children: [
                                Text(
                                  p.error ??
                                      'Could not load analytics. Please try again later.',
                                  style: const TextStyle(color: AppColors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: p.load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final summary = p.summary!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Highest reporting services',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ServicesDonutChart(
                                      data: summary.countsByServiceTop3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: AppColors.card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Feedback patterns over time',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    FeedbackOverTimeChart(
                                      data: summary.countsByMonthLast12,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: const [
                                Text(
                                  'Export analytics as',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(width: 12),
                                AnalyticsExportButton(),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}