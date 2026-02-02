import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/notifications/data/notifications_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';
import 'package:juecho/features/feedback/data/graphql/submission_documents.dart';

/// General-user actions on a single submission:
/// - optimistic local reply
/// - update (only while status SUBMITTED)
/// - delete (only while status SUBMITTED)
/// - add reply (only after admin has replied)
class GeneralSingleSubmissionActionsRepository {
  static Future<FeedbackSubmission> makeLocalUserReply({
    required FeedbackSubmission current,
    required String message,
    required ProfileData profile,
  }) async {
    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'GENERAL',
      message: message.trim(),
      byId: profile.userId,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    return current.copyWith(replies: [...current.replies, newReply]);
  }

  static Future<FeedbackSubmission> updateSubmissionAsUser(
      FeedbackSubmission submission,
      ) async {
    if (!submission.canEditOrDelete) {
      throw Exception('Submission can no longer be edited.');
    }

    final req = GraphQLRequest<String>(
      document: updateSubmissionMutation,
      variables: {'input': submission.toUserUpdateInput()},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('updateSubmission errors: ${res.errors}');
      throw Exception('Failed to update submission');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Update returned no data');

    return FeedbackSubmission.fromJson(json);
  }

  static Future<void> deleteSubmissionAsUser(FeedbackSubmission s) async {
    if (!s.canEditOrDelete) {
      throw Exception('Submission can no longer be deleted');
    }

    final req = GraphQLRequest<String>(
      document: deleteSubmissionMutation,
      variables: {'input': {'id': s.id}},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('deleteSubmission errors: ${res.errors}');
      throw Exception('Failed to delete submission');
    }
  }

  static Future<FeedbackSubmission> addUserReply({
    required FeedbackSubmission current,
    required String message,
    required ProfileData profile,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) throw Exception('Reply is empty');

    if (current.adminReplies.isEmpty) {
      throw Exception('You can only reply after an admin has replied');
    }

    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'general',
      message: trimmed,
      byId: profile.userId,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    final updated = current.copyWith(replies: [...current.replies, newReply]);

    final req = GraphQLRequest<String>(
      document: updateSubmissionMutation,
      variables: {
        'input': {
          'id': updated.id,
          'replies': updated.replies.map((r) => r.toJson()).toList(),
          'updatedAt': now.toIso8601String(),
        },
      },
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('addUserReply errors: ${res.errors}');
      throw Exception('Failed to send reply');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Update returned no data');

    final finalUpdated = FeedbackSubmission.fromJson(json);

    // Best-effort notification
    try {
      await NotificationsRepository.createNewUserReplyNotification(
        submission: finalUpdated,
        replyText: trimmed,
      );
    } catch (e) {
      safePrint('createNewUserReplyNotification error: $e');
    }

    return finalUpdated;
  }
}