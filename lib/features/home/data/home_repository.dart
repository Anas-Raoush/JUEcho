import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/repositories/admin_repositories/admin_submissions_repository.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_submissions_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// GeneralDashboardStats
///
/// Aggregate statistics for the GENERAL user dashboard.
///
/// Metrics:
/// - totalFullFeedback: count of submissions considered "full feedback" (not rating-only)
/// - pendingReviews: full submissions that are not yet in a terminal state
/// - ratingOnlyCount: submissions containing only a rating (no full feedback content)
class GeneralDashboardStats {
  final int totalFullFeedback;
  final int pendingReviews;
  final int ratingOnlyCount;

  const GeneralDashboardStats({
    required this.totalFullFeedback,
    required this.pendingReviews,
    required this.ratingOnlyCount,
  });
}

/// AdminDashboardStats
///
/// Aggregate statistics for the ADMIN dashboard.
///
/// Metrics:
/// - submissionsReceived: count of full feedback submissions received by the system
/// - resolvedIssues: count of full feedback submissions marked as resolved
/// - topRatedServiceLabel: service label with the highest average rating (if rating data exists)
/// - bottomRatedServiceLabel: service label with the lowest average rating (if rating data exists)
class AdminDashboardStats {
  final int submissionsReceived;
  final int resolvedIssues;
  final String? topRatedServiceLabel;
  final String? bottomRatedServiceLabel;

  const AdminDashboardStats({
    required this.submissionsReceived,
    required this.resolvedIssues,
    required this.topRatedServiceLabel,
    required this.bottomRatedServiceLabel,
  });
}

/// HomeRepository
///
/// Read-only repository responsible for computing dashboard-level metrics.
///
/// Rationale:
/// - Keeps aggregation logic out of UI widgets and providers.
/// - Reuses existing submission repositories for data retrieval.
/// - Centralizes calculation rules so they remain consistent across the app.
///
/// Data sources:
/// - General stats -> GeneralSubmissionsRepository.fetchMySubmissions(profile)
/// - Admin stats   -> AdminSubmissionsRepository.fetchAllSubmissionsForAdmin()
class HomeRepository {
  /// Computes GENERAL dashboard statistics for the current user.
  ///
  /// Data:
  /// - Pulls the user's submissions using the owner scope derived from profile.
  ///
  /// Rules:
  /// - Full feedback: s.isFullFeedback == true
  /// - Rating-only  : total submissions - full feedback count
  /// - Pending reviews: full feedback submissions not in terminal states:
  ///   -> resolved
  ///   -> rejected
  static Future<GeneralDashboardStats> fetchGeneralDashboardStats({
    required ProfileData profile,
  }) async {
    try {
      final submissions =
      await GeneralSubmissionsRepository.fetchMySubmissions(profile: profile);

      final full = submissions.where((s) => s.isFullFeedback).toList();
      final ratingOnly = submissions.length - full.length;

      final pending = full.where((s) {
        switch (s.status) {
          case FeedbackStatusCategories.resolved:
          case FeedbackStatusCategories.rejected:
            return false;
          default:
            return true;
        }
      }).length;

      return GeneralDashboardStats(
        totalFullFeedback: full.length,
        pendingReviews: pending,
        ratingOnlyCount: ratingOnly,
      );
    } catch (e, st) {
      safePrint('fetchGeneralDashboardStats error: $e\n$st');
      rethrow;
    }
  }

  /// Computes ADMIN dashboard statistics across the system.
  ///
  /// Data:
  /// - Admin can read all submissions (not scoped by owner).
  ///
  /// Rules:
  /// - submissionsReceived: counts ONLY full feedback submissions
  /// - resolvedIssues: counts ONLY full submissions in resolved status
  /// - top/bottom rated service: computed from all submissions with rating > 0
  ///
  /// Behavior:
  /// - If no submissions exist -> return zeros and null labels
  static Future<AdminDashboardStats> fetchAdminDashboardStats() async {
    try {
      final submissions =
      await AdminSubmissionsRepository.fetchAllSubmissionsForAdmin();

      if (submissions.isEmpty) {
        return const AdminDashboardStats(
          submissionsReceived: 0,
          resolvedIssues: 0,
          topRatedServiceLabel: null,
          bottomRatedServiceLabel: null,
        );
      }

      final full = submissions.where((s) => s.isFullFeedback).toList();

      final total = full.length;
      final resolved = full
          .where((s) => s.status == FeedbackStatusCategories.resolved)
          .length;

      final Map<ServiceCategories, _RatingAgg> ratingAgg = {};

      for (final s in submissions) {
        final r = s.rating;
        if (r <= 0) continue;

        final agg = ratingAgg.putIfAbsent(
          s.serviceCategory,
              () => _RatingAgg(0, 0),
        );
        agg.sum += r;
        agg.count += 1;
      }

      String? topLabel;
      String? bottomLabel;

      if (ratingAgg.isNotEmpty) {
        ServiceCategories? topCat;
        double? topAvg;

        ServiceCategories? bottomCat;
        double? bottomAvg;

        ratingAgg.forEach((cat, agg) {
          final avg = agg.sum / agg.count;

          if (topAvg == null || avg > topAvg!) {
            topAvg = avg;
            topCat = cat;
          }
          if (bottomAvg == null || avg < bottomAvg!) {
            bottomAvg = avg;
            bottomCat = cat;
          }
        });

        topLabel = topCat?.label;
        bottomLabel = bottomCat?.label;
      }

      return AdminDashboardStats(
        submissionsReceived: total,
        resolvedIssues: resolved,
        topRatedServiceLabel: topLabel,
        bottomRatedServiceLabel: bottomLabel,
      );
    } catch (e, st) {
      safePrint('fetchAdminDashboardStats error: $e\n$st');
      rethrow;
    }
  }
}

/// _RatingAgg
///
/// Internal accumulator used to compute average ratings per service category:
/// - sum: total ratings
/// - count: number of rating entries
///
/// Average = sum / count
class _RatingAgg {
  int sum;
  int count;
  _RatingAgg(this.sum, this.count);
}