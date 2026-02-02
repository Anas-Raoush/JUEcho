import 'package:flutter/foundation.dart';

import 'package:juecho/features/analytics/data/analytics_repository.dart';

/// State holder for admin analytics summary.
///
/// Responsibilities
/// - Loads [AnalyticsSummary] from [AnalyticsRepository].
/// - Exposes loading and error state for UI.
///
/// Notes
/// - [init] is a convenience wrapper around [load].
class AnalyticsProvider extends ChangeNotifier {
  /// Latest loaded summary (null until load succeeds).
  AnalyticsSummary? summary;

  /// Loading flag for analytics fetch.
  bool isLoading = false;

  /// User-facing error message for UI.
  String? error;

  /// Convenience initializer for screens that call init once.
  Future<void> init() async {
    await load();
  }

  /// Loads summary aggregates used by analytics charts.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      summary = await AnalyticsRepository.fetchAnalyticsSummary();
    } catch (_) {
      error = 'Could not load analytics.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}