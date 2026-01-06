import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/analytics/data/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsSummary? summary;
  bool isLoading = false;
  String? error;


  Future<void> init() async {
    await load();
  }

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