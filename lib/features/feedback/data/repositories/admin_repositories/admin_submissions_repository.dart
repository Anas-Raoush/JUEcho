import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/data/models/submissions_page.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/admin_submissions_sort.dart';
import 'package:juecho/features/feedback/data/graphql/submission_documents.dart';

/// Admin-side data access for listing submissions with:
/// - pagination (limit + nextToken)
/// - server-side filtering (status/category/rating/urgency)
/// - scopes:
///   - "New" scope: only SUBMITTED
///   - "Review" scope: NOT SUBMITTED (a set of statuses)
class AdminSubmissionsRepository {
  static Future<SubmissionsPage> fetchSubmissionsPage({
    Map<String, dynamic>? filter,
    int limit = 20,
    String? nextToken,
  }) async {
    final req = GraphQLRequest<String>(
      document: listSubmissionsPagedQuery,
      variables: {
        'filter': filter,
        'limit': limit,
        'nextToken': nextToken,
      },
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchSubmissionsPage errors: ${res.errors}');
      throw Exception('Failed to load submissions page');
    }

    if (res.data == null) {
      return const SubmissionsPage(items: [], nextToken: null);
    }

    // Debug: helpful while building filters/pagination
    safePrint('RAW res.data = ${res.data}');

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final list = decoded['listSubmissions'] as Map<String, dynamic>?;

    final items = (list?['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(FeedbackSubmission.fromJson)
        .toList();

    final token = list?['nextToken'] as String?;

    // You computed counts here; if you don't use it, you can remove this block.
    final statusCounts = <String, int>{};
    for (final s in items) {
      final k = s.status.key;
      statusCounts[k] = (statusCounts[k] ?? 0) + 1;
    }

    // Ensure newest first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SubmissionsPage(items: items, nextToken: token);
  }

  static Future<List<FeedbackSubmission>> fetchAdminReviewSubmissions() async {
    final req = GraphQLRequest<String>(document: listAdminReviewSubmissionsQuery);
    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchAdminReviewSubmissions errors: ${res.errors}');
      throw Exception('Failed to load submissions for review');
    }
    if (res.data == null) return [];

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final list = decoded['listSubmissions'] as Map<String, dynamic>?;
    final items = list?['items'] as List<dynamic>? ?? [];

    final submissions = items
        .whereType<Map<String, dynamic>>()
        .map(FeedbackSubmission.fromJson)
        .toList();

    submissions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return submissions;
  }

  static Future<List<FeedbackSubmission>> fetchAllSubmissionsForAdmin() async {
    final req = GraphQLRequest<String>(document: listAllSubmissionsForAdminQuery);
    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchAllSubmissionsForAdmin errors: ${res.errors}');
      throw Exception('Failed to load submissions');
    }
    if (res.data == null) return [];

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final list = decoded['listSubmissions'] as Map<String, dynamic>?;
    final items = list?['items'] as List<dynamic>? ?? [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(FeedbackSubmission.fromJson)
        .toList();
  }

  /// Builds the GraphQL filter map used in listSubmissionsPagedQuery.
  ///
  /// Important rules:
  /// - New scope forces status == SUBMITTED
  /// - Review scope uses OR-list of statuses (not SUBMITTED)
  /// - If user picks a specific status in UI, it overrides review OR list
  ///   (so we remove 'or' first).
  static Map<String, dynamic>? buildAdminFilter({
    required bool isAdminNewScope,
    required bool isAdminReviewScope,
    required AdminSubmissionsFilter filter,
  }) {
    final f = <String, dynamic>{};

    if (isAdminNewScope) {
      f['status'] = {'eq': 'SUBMITTED'};
    }

    if (isAdminReviewScope) {
      const reviewStatuses = [
        'RESOLVED',
        'IN_PROGRESS',
        'REJECTED',
        'MORE_INFO_NEEDED',
        'UNDER_REVIEW'
      ];

      f['or'] = reviewStatuses.map((s) => {'status': {'eq': s}}).toList();
    }

    if (filter.category != null) {
      f['serviceCategory'] = {'eq': filter.category!.key};
    }

    if (filter.status != null) {
      f.remove('or'); // important override
      f['status'] = {'eq': filter.status!.key};
    }

    if (filter.rating != null) {
      f['rating'] = {'eq': filter.rating};
    }

    if (filter.urgency != null) {
      f['urgency'] = {'eq': filter.urgency};
    }

    return f.isEmpty ? null : f;
  }
}