import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// Dashboard statistics model for GENERAL users.
///
/// Used to summarize the current user's submissions:
/// - [totalFullFeedback]  : count of full submissions (title/description/etc.)
/// - [pendingReviews]     : full submissions that are still NOT resolved/rejected
/// - [ratingOnlyCount]    : submissions that only contain a rating (no full feedback)
class GeneralDashboardStats {
  /// Full feedback submissions count (not rating-only).
  final int totalFullFeedback;

  /// Full feedback submissions that are still being processed (not resolved/rejected).
  final int pendingReviews;

  /// Rating-only submissions count.
  final int ratingOnlyCount;

  const GeneralDashboardStats({
    required this.totalFullFeedback,
    required this.pendingReviews,
    required this.ratingOnlyCount,
  });
}

/// Dashboard statistics model for ADMINS.
///
/// Used to summarize overall system status:
/// - [submissionsReceived]      : number of full feedback submissions received
/// - [resolvedIssues]           : number of full feedback submissions with status "resolved"
/// - [topRatedServiceLabel]     : service label with the highest average rating (based on ratings submitted)
/// - [bottomRatedServiceLabel]  : service label with the lowest average rating (based on ratings submitted)
class AdminDashboardStats {
  /// Total received full feedback submissions (admin scope).
  final int submissionsReceived;

  /// Full feedback submissions marked as resolved.
  final int resolvedIssues;

  /// Label for the service with the highest average rating.
  /// Null when there is not enough rating data.
  final String? topRatedServiceLabel;

  /// Label for the service with the lowest average rating.
  /// Null when there is not enough rating data.
  final String? bottomRatedServiceLabel;

  const AdminDashboardStats({
    required this.submissionsReceived,
    required this.resolvedIssues,
    required this.topRatedServiceLabel,
    required this.bottomRatedServiceLabel,
  });
}

/// Repository that computes dashboard statistics for home pages.
///
/// Why this exists:
/// - Keeps "dashboard calculations" out of UI widgets.
/// - Reuses existing repository methods from [FeedbackRepository].
/// - Encapsulates counting/filtering logic in one place.
///
/// Notes:
/// - General stats require a [ProfileData] because fetching "my submissions"
///   is scoped by the user's ownerId/userId.
/// - Admin stats do NOT require profile because admin sees all submissions.
class HomeRepository {
  /// Fetch statistics for the GENERAL user dashboard.
  ///
  /// Data source:
  /// - Uses [FeedbackRepository.fetchMySubmissions] (requires [profile]).
  ///
  /// Calculation rules:
  /// - Full feedback = submissions where `s.isFullFeedback == true`
  /// - Rating-only = total submissions - full feedback count
  /// - Pending reviews = full feedback submissions that are NOT:
  ///   - resolved
  ///   - rejected
  ///
  /// Throws:
  /// - rethrows any exception from data fetching so the provider/UI
  ///   can show an error state.
  static Future<GeneralDashboardStats> fetchGeneralDashboardStats({
    required ProfileData profile,
  }) async {
    try {
      // Fetch only the current user's submissions.
      final submissions = await FeedbackRepository.fetchMySubmissions(
        profile: profile,
      );

      // Separate "full feedback" from "rating-only".
      final full = submissions.where((s) => s.isFullFeedback).toList();
      final ratingOnly = submissions.length - full.length;

      // Pending are full submissions that aren't resolved.
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

  /// Fetch statistics for the ADMIN dashboard.
  ///
  /// Data source:
  /// - Uses [FeedbackRepository.fetchAllSubmissionsForAdmin]
  ///
  /// Calculation rules:
  /// - "submissionsReceived" counts only FULL feedback submissions.
  /// - "resolvedIssues" counts only FULL submissions with status resolved.
  /// - Top/bottom rated services are computed using ALL submissions
  ///   that have `rating > 0`, including rating-only submissions.
  ///
  /// If there are no submissions:
  /// - returns zeros and null labels.
  ///
  /// Throws:
  /// - rethrows any exception so the provider/UI can handle it.
  static Future<AdminDashboardStats> fetchAdminDashboardStats() async {
    try {
      // Admin can see all submissions.
      final submissions = await FeedbackRepository.fetchAllSubmissionsForAdmin();

      // No data: return default.
      if (submissions.isEmpty) {
        return const AdminDashboardStats(
          submissionsReceived: 0,
          resolvedIssues: 0,
          topRatedServiceLabel: null,
          bottomRatedServiceLabel: null,
        );
      }

      // Only full feedback counts for total & resolved issues.
      final full = submissions.where((s) => s.isFullFeedback).toList();

      final total = full.length;
      final resolved = full
          .where((s) => s.status == FeedbackStatusCategories.resolved)
          .length;

      // Aggregate ratings per service category:
      // sum of ratings + count of ratings, then compute average.
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

      // Determine the highest/lowest average rating service.
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

/// Internal helper class for rating aggregation.
///
/// Stores:
/// - [sum]   : total of ratings for a given service
/// - [count] : number of rating entries for a given service
///
/// Used to compute average: `sum / count`.
class _RatingAgg {
  int sum;
  int count;
  _RatingAgg(this.sum, this.count);
}