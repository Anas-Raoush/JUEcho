import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';
import 'package:juecho/features/feedback/data/graphql/submission_documents.dart';

/// General user repository for:
/// - creating submissions (full or rating-only)
/// - listing "my submissions"
/// - fetching a single submission by id
class GeneralSubmissionsRepository {
  static Future<void> createSubmission({
    required ServiceCategories category,
    String? title,
    String? description,
    String? suggestion,
    String? attachmentKey,
    required int rating,
    required ProfileData profile,
  }) async {
    final ownerId = profile.userId;
    final now = DateTime.now().toUtc();

    final model = FeedbackSubmission(
      id: uuid(),
      ownerId: ownerId,
      serviceCategory: category,
      title: title?.trim().isEmpty ?? true ? null : title!.trim(),
      description: description?.trim().isEmpty ?? true ? null : description!.trim(),
      suggestion: suggestion?.trim().isEmpty ?? true ? null : suggestion!.trim(),
      rating: rating,
      attachmentKey: attachmentKey,
      status: FeedbackStatusCategories.submitted,
      createdAt: now,
      updatedAt: now,
    );

    final req = GraphQLRequest<String>(
      document: createSubmissionMutation,
      variables: {
        'input': model.toCreateInput(
          ownerId: ownerId,
          serviceKey: model.serviceCategory.key,
          statusKey: model.status.key,
        ),
      },
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('createSubmission errors: ${res.errors}');
      throw Exception('Failed to create submission');
    }
  }

  static Future<List<FeedbackSubmission>> fetchMySubmissions({
    required ProfileData profile,
  }) async {
    final ownerId = profile.userId;

    final req = GraphQLRequest<String>(
      document: listMySubmissionsQuery,
      variables: {'ownerId': ownerId},
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('listSubmissions errors: ${res.errors}');
      throw Exception('Failed to load submissions');
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

  static Future<List<FeedbackSubmission>> fetchMyFullSubmissions({
    required ProfileData profile,
  }) async {
    final all = await fetchMySubmissions(profile: profile);
    return all.where((s) => s.isFullFeedback).toList();
  }

  static Future<FeedbackSubmission> fetchSubmissionById(String id) async {
    final req = GraphQLRequest<String>(
      document: getSubmissionQuery,
      variables: {'id': id},
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('getSubmission error: ${res.errors}');
      throw Exception('Failed to load submission');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['getSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Submission not found');

    return FeedbackSubmission.fromJson(json);
  }
}