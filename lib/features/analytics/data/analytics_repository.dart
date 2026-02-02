import 'dart:io';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/repositories/admin_repositories/admin_submissions_repository.dart';
import 'package:path_provider/path_provider.dart';

/// Count of full submissions for a specific [ServiceCategories] value.
class ServiceCount {
  /// Service category bucket.
  final ServiceCategories category;

  /// Number of submissions in this bucket.
  final int count;

  const ServiceCount(this.category, this.count);
}

/// Monthly aggregate bucket used for the "over time" chart.
class MonthlyCount {
  /// Calendar year.
  final int year;

  /// Calendar month in range 1..12.
  final int month;

  /// Number of submissions recorded for [year]-[month].
  final int count;

  const MonthlyCount(this.year, this.month, this.count);
}

/// Chart-facing analytics output:
/// - Top 3 services by full submissions
/// - Last 12 months of full submissions counts
class AnalyticsSummary {
  /// Donut chart dataset:
  /// - Contains the top 3 services by count.
  /// - Built from full feedback only.
  final List<ServiceCount> countsByServiceTop3;

  /// Monthly bar chart dataset:
  /// - Contains up to the last 12 months (chronological order).
  /// - Built from full feedback only.
  final List<MonthlyCount> countsByMonthLast12;

  const AnalyticsSummary({
    required this.countsByServiceTop3,
    required this.countsByMonthLast12,
  });
}

/// Aggregated per-service row used for reporting/export.
class ServiceReportRow {
  /// Service category represented by this row.
  final ServiceCategories service;

  /// Number of full submissions (isFullFeedback).
  final int fullSubmissions;

  /// Number of rating-only submissions (!isFullFeedback).
  final int ratingOnly;

  /// Number of submissions that have a rating > 0 (full + rating-only).
  final int ratingsCount;

  /// Sum of ratings across all submissions with rating > 0.
  final int ratingsSum;

  /// Number of resolved submissions among full submissions only.
  final int resolvedFull;

  const ServiceReportRow({
    required this.service,
    required this.fullSubmissions,
    required this.ratingOnly,
    required this.ratingsCount,
    required this.ratingsSum,
    required this.resolvedFull,
  });

  /// Average rating across all rated submissions for this service.
  ///
  /// Returns null when [ratingsCount] is zero.
  double? get avgRating => ratingsCount == 0 ? null : ratingsSum / ratingsCount;

  /// Resolution rate across full submissions for this service.
  ///
  /// Returns null when [fullSubmissions] is zero.
  double? get resolutionRate =>
      fullSubmissions == 0 ? null : resolvedFull / fullSubmissions;
}

/// Report container for per-service analytics metrics.
class ServiceReport {
  final List<ServiceReportRow> rows;

  const ServiceReport({required this.rows});

  /// Returns the top 3 services by [ServiceReportRow.fullSubmissions].
  List<ServiceReportRow> get top3ByFullSubmissions {
    final sorted = [...rows]
      ..sort((a, b) => b.fullSubmissions.compareTo(a.fullSubmissions));
    return sorted.take(3).toList();
  }

  /// Returns the bottom 3 services by [ServiceReportRow.avgRating].
  ///
  /// Rows without ratings are excluded.
  List<ServiceReportRow> get bottom3ByAvgRating {
    final filtered = rows.where((r) => r.avgRating != null).toList()
      ..sort((a, b) => a.avgRating!.compareTo(b.avgRating!));
    return filtered.take(3).toList();
  }
}

/// Admin-only analytics repository.
///
/// Data source
/// - Fetches submissions using [AdminSubmissionsRepository.fetchAllSubmissionsForAdmin].
///
/// Output
/// - [AnalyticsSummary] -> chart-friendly aggregates (top 3 services, last 12 months).
/// - [ServiceReport] -> per-service metrics used for export/reporting.
/// - CSV export -> one row per service (aggregated, stable, human-readable).
///
/// Notes
/// - Charts are built using FULL feedback only ([FeedbackSubmission.isFullFeedback]).
/// - The service report uses both full and rating-only submissions.
/// - Uses full dataset scans (admin scope) via [AdminSubmissionsRepository].
/// - Aggregations are computed locally.
class AnalyticsRepository {
  /// Builds chart aggregates:
  /// - Top 3 services by full submissions count
  /// - Last 12 months counts (full feedback only)
  ///
  /// Chart rules
  /// - Only full feedback is counted for both charts.
  /// - Monthly buckets use local time for grouping to match UI expectations.
  static Future<AnalyticsSummary> fetchAnalyticsSummary() async {
    try {
      final submissions =
      await AdminSubmissionsRepository.fetchAllSubmissionsForAdmin();

      // Full feedback only.
      final full = submissions.where((s) => s.isFullFeedback).toList();

      // ---------- Counts by service category ----------
      final Map<ServiceCategories, int> perService = {};
      for (final s in full) {
        perService[s.serviceCategory] = (perService[s.serviceCategory] ?? 0) + 1;
      }

      final countsByService = perService.entries
          .map((e) => ServiceCount(e.key, e.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      final top3 = countsByService.take(3).toList();

      // ---------- Counts by month ----------
      // Key format: YYYY-MM
      final Map<String, int> perMonth = {};
      for (final s in full) {
        final dt = s.createdAt.toLocal();
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        perMonth[key] = (perMonth[key] ?? 0) + 1;
      }

      final monthly = perMonth.entries.map((e) {
        final parts = e.key.split('-');
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

  /// Builds a per-service report covering:
  /// - full submissions count
  /// - rating-only count
  /// - ratings count and average rating
  /// - resolved full count and resolution rate
  ///
  /// Output
  /// - One row per [ServiceCategories] value.
  /// - Default sorting is by most full submissions first.
  static Future<ServiceReport> fetchServiceReport() async {
    try {
      final submissions =
      await AdminSubmissionsRepository.fetchAllSubmissionsForAdmin();

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

      rows.sort((a, b) => b.fullSubmissions.compareTo(a.fullSubmissions));

      return ServiceReport(rows: rows);
    } catch (e, st) {
      safePrint('fetchServiceReport error: $e\n$st');
      rethrow;
    }
  }

  /// Exports a CSV report with one row per service.
  ///
  /// Output
  /// - File is written to the application's documents directory.
  /// - Returns the absolute path to the created file.
  ///
  /// CSV columns
  /// - Service
  /// - Full Submissions
  /// - Rating-only
  /// - Ratings Count
  /// - Average Rating
  /// - Resolved (Full)
  /// - Resolution Rate (percentage)
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

/// Internal mutable aggregation bucket used by [AnalyticsRepository].
class _ServiceAgg {
  int fullSubmissions = 0;
  int ratingOnly = 0;
  int ratingsCount = 0;
  int ratingsSum = 0;
  int resolvedFull = 0;
}