import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';

// ==========================
// CHART MODELS (keep these)
// ==========================

class ServiceCount {
  final ServiceCategories category;
  final int count;
  const ServiceCount(this.category, this.count);
}

class MonthlyCount {
  final int year;
  final int month; // 1..12
  final int count;
  const MonthlyCount(this.year, this.month, this.count);
}

class AnalyticsSummary {
  /// For donut chart (you want top 3 only)
  final List<ServiceCount> countsByServiceTop3;

  /// For monthly bar chart (last 12 months)
  final List<MonthlyCount> countsByMonthLast12;

  const AnalyticsSummary({
    required this.countsByServiceTop3,
    required this.countsByMonthLast12,
  });
}

// ==========================
// REPORT MODELS (new)
// ==========================

class ServiceReportRow {
  final ServiceCategories service;

  final int fullSubmissions; // isFullFeedback
  final int ratingOnly;      // !isFullFeedback
  final int ratingsCount;    // rating > 0 (full + rating-only)
  final int ratingsSum;
  final int resolvedFull;    // resolved among full submissions

  const ServiceReportRow({
    required this.service,
    required this.fullSubmissions,
    required this.ratingOnly,
    required this.ratingsCount,
    required this.ratingsSum,
    required this.resolvedFull,
  });

  double? get avgRating => ratingsCount == 0 ? null : ratingsSum / ratingsCount;

  double? get resolutionRate =>
      fullSubmissions == 0 ? null : resolvedFull / fullSubmissions;
}

class ServiceReport {
  final List<ServiceReportRow> rows;
  const ServiceReport({required this.rows});

  List<ServiceReportRow> get top3ByFullSubmissions {
    final sorted = [...rows]
      ..sort((a, b) => b.fullSubmissions.compareTo(a.fullSubmissions));
    return sorted.take(3).toList();
  }

  List<ServiceReportRow> get bottom3ByAvgRating {
    final filtered = rows.where((r) => r.avgRating != null).toList()
      ..sort((a, b) => a.avgRating!.compareTo(b.avgRating!));
    return filtered.take(3).toList();
  }
}

// ==========================
// REPOSITORY
// ==========================

class AnalyticsRepository {
  /// CHARTS: builds Top3-by-service + last12-by-month.
  ///
  /// Uses FULL feedback only for both charts.
  static Future<AnalyticsSummary> fetchAnalyticsSummary() async {
    try {
      final submissions = await FeedbackRepository.fetchAllSubmissionsForAdmin();

      // Only full feedback, not rating-only.
      final full = submissions.where((s) => s.isFullFeedback).toList();

      // ---- 1) Counts by service category ----
      final Map<ServiceCategories, int> perService = {};
      for (final s in full) {
        perService[s.serviceCategory] = (perService[s.serviceCategory] ?? 0) + 1;
      }

      // Convert to list, sort by COUNT desc, take TOP 3
      final countsByServiceTop3 = perService.entries
          .map((e) => ServiceCount(e.key, e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      final top3 = countsByServiceTop3.take(3).toList();

      // ---- 2) Counts by month (year + month) ----
      final Map<String, int> perMonth = {}; // key = 'YYYY-MM'
      for (final s in full) {
        final dt = s.createdAt.toLocal(); // chart months in local time display
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        perMonth[key] = (perMonth[key] ?? 0) + 1;
      }

      final monthly = perMonth.entries.map((e) {
        final parts = e.key.split('-'); // ["2025","02"]
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        return MonthlyCount(year, month, e.value);
      }).toList()
        ..sort((a, b) {
          if (a.year != b.year) return a.year.compareTo(b.year);
          return a.month.compareTo(b.month);
        });

      final last12 = monthly.length <= 12
          ? monthly
          : monthly.sublist(monthly.length - 12);

      return AnalyticsSummary(
        countsByServiceTop3: top3,
        countsByMonthLast12: last12,
      );
    } catch (e, st) {
      safePrint('fetchAnalyticsSummary error: $e\n$st');
      rethrow;
    }
  }

  /// REPORT: one row per service:
  /// - full submissions
  /// - rating-only
  /// - ratings count + avg
  /// - resolved full + resolution rate
  static Future<ServiceReport> fetchServiceReport() async {
    try {
      final submissions = await FeedbackRepository.fetchAllSubmissionsForAdmin();

      final Map<ServiceCategories, _ServiceAgg> agg = {};

      for (final s in submissions) {
        final service = s.serviceCategory;
        final a = agg.putIfAbsent(service, () => _ServiceAgg());

        if (s.isFullFeedback) {
          a.fullSubmissions += 1;
          if (s.status == FeedbackStatusCategories.resolved) {
            a.resolvedFull += 1;
          }
        } else {
          a.ratingOnly += 1;
        }

        final r = s.rating;
        if (r > 0) {
          a.ratingsCount += 1;
          a.ratingsSum += r;
        }
      }

      final rows = ServiceCategories.values.map((service) {
        final a = agg[service] ?? _ServiceAgg();
        return ServiceReportRow(
          service: service,
          fullSubmissions: a.fullSubmissions,
          ratingOnly: a.ratingOnly,
          ratingsCount: a.ratingsCount,
          ratingsSum: a.ratingsSum,
          resolvedFull: a.resolvedFull,
        );
      }).toList();

      // Default sort: most full submissions first
      rows.sort((a, b) => b.fullSubmissions.compareTo(a.fullSubmissions));

      return ServiceReport(rows: rows);
    } catch (e, st) {
      safePrint('fetchServiceReport error: $e\n$st');
      rethrow;
    }
  }

  /// EXPORT: meaningful aggregated CSV (one row per service).
  static Future<String> exportServiceReportCsv() async {
    final report = await fetchServiceReport();

    final buffer = StringBuffer();
    buffer.writeln(
      'Service,Full Submissions,Rating-only,Ratings Count,Average Rating,Resolved (Full),Resolution Rate',
    );

    for (final row in report.rows) {
      final avg = row.avgRating;
      final rr = row.resolutionRate;

      final avgStr = avg == null ? '' : avg.toStringAsFixed(2);
      final rrStr = rr == null ? '' : (rr * 100).toStringAsFixed(1);

      buffer.writeln(
        '"${row.service.label}",'
            '${row.fullSubmissions},'
            '${row.ratingOnly},'
            '${row.ratingsCount},'
            '$avgStr,'
            '${row.resolvedFull},'
            '$rrStr%',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    final path = '${dir.path}/juecho_service_report_$ts.csv';
    final file = File(path);
    await file.writeAsString(buffer.toString());

    return path;
  }
}

class _ServiceAgg {
  int fullSubmissions = 0;
  int ratingOnly = 0;
  int ratingsCount = 0;
  int ratingsSum = 0;
  int resolvedFull = 0;
}
