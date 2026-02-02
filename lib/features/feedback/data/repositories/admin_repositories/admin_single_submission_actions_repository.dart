import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/notifications/data/notifications_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';
import 'package:juecho/features/feedback/data/graphql/submission_documents.dart';

/// Repository for admin actions on a *single* submission:
/// - update status / urgency / internal notes
/// - add reply
/// - delete
///
/// Also triggers notifications (best-effort).
class AdminSingleSubmissionActionsRepository {
  static Future<FeedbackSubmission> updateSubmissionAsAdminMeta({
    required FeedbackSubmission current,
    required FeedbackStatusCategories status,
    int? urgency,
    String? internalNotes,
    required ProfileData profile,
  }) async {
    final now = DateTime.now().toUtc();

    final input = <String, dynamic>{
      'id': current.id,
      'status': status.key,
      'updatedAt': now.toIso8601String(),
      'updatedById': profile.userId,
      'updatedByName': '${profile.firstName} ${profile.lastName}'.trim(),
    };

    if (urgency != null) input['urgency'] = urgency;
    if (internalNotes != null) input['internalNotes'] = internalNotes;

    final req = GraphQLRequest<String>(
      document: updateSubmissionMutation,
      variables: {'input': input},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('updateSubmissionAsAdminMeta errors: ${res.errors}');
      throw Exception('Failed to update submission (admin).');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Update returned no data');

    final updated = FeedbackSubmission.fromJson(json);

    // Best-effort notification
    try {
      await NotificationsRepository.createStatusChangedNotification(
        previous: current,
        updated: updated,
      );
    } catch (e) {
      safePrint('createStatusChangedNotification error: $e');
    }

    return updated;
  }

  static Future<FeedbackSubmission> addAdminReply({
    required FeedbackSubmission current,
    required String message,
    required ProfileData profile,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) throw Exception('Reply is empty');

    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'admin',
      message: trimmed,
      byId: profile.userId,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    final updatedReplies = [...current.replies, newReply];

    final input = <String, dynamic>{
      'id': current.id,
      'replies': updatedReplies.map((r) => r.toJson()).toList(),
      'updatedAt': now.toIso8601String(),
      'updatedById': profile.userId,
      'updatedByName': '${profile.firstName} ${profile.lastName}'.trim(),
      'respondedAt': now.toIso8601String(),
    };

    final req = GraphQLRequest<String>(
      document: updateSubmissionMutation,
      variables: {'input': input},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('addAdminReply errors: ${res.errors}');
      throw Exception('Failed to send admin reply');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Update returned no data');

    final updated = FeedbackSubmission.fromJson(json);

    // Best-effort notification
    try {
      await NotificationsRepository.createNewAdminReplyNotification(
        submission: updated,
        replyText: trimmed,
      );
    } catch (e) {
      safePrint('createNewAdminReplyNotification error: $e');
    }

    return updated;
  }

  /// Local-only helper used for optimistic UI (no API call).
  static Future<FeedbackSubmission> makeLocalAdminReply({
    required FeedbackSubmission current,
    required String message,
    required ProfileData profile,
  }) async {
    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'admin',
      message: message.trim(),
      byId: profile.userId,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    return current.copyWith(replies: [...current.replies, newReply]);
  }

  static Future<void> deleteSubmissionAsAdmin(FeedbackSubmission s) async {
    final req = GraphQLRequest<String>(
      document: deleteSubmissionMutation,
      variables: {'input': {'id': s.id}},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('deleteSubmissionAsAdmin errors: ${res.errors}');
      throw Exception('Failed to delete submission');
    }
  }

  static Future<FeedbackSubmission> adminUpdateSubmission({
    required FeedbackSubmission current,
    required FeedbackStatusCategories status,
    required int urgency,
    String? internalNotes,
    String? replyMessage,
    required ProfileData profile,
  }) async {
    final now = DateTime.now().toUtc();

    final trimmedNotes = internalNotes?.trim();
    final effectiveNotes =
    (trimmedNotes == null || trimmedNotes.isEmpty) ? null : trimmedNotes;

    final trimmedReply = replyMessage?.trim();
    final hasNewReply = trimmedReply != null && trimmedReply.isNotEmpty;

    FeedbackReply? adminReply;
    if (hasNewReply) {
      adminReply = FeedbackReply(
        fromRole: 'admin',
        message: trimmedReply,
        byId: profile.userId,
        byName: '${profile.firstName} ${profile.lastName}'.trim(),
        at: now,
      );
    }

    final updatedReplies = <FeedbackReply>[
      ...current.replies,
      if (adminReply != null) adminReply,
    ];

    final input = <String, dynamic>{
      'id': current.id,
      'status': status.key,
      'urgency': urgency,
      'internalNotes': effectiveNotes,
      'replies': updatedReplies.map((r) => r.toJson()).toList(),
      'updatedById': profile.userId,
      'updatedByName': '${profile.firstName} ${profile.lastName}'.trim(),
      'respondedAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    final req = GraphQLRequest<String>(
      document: updateSubmissionMutation,
      variables: {'input': input},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('adminUpdateSubmission errors: ${res.errors}');
      throw Exception('Failed to update submission as admin');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) throw Exception('Admin update returned no data');

    return FeedbackSubmission.fromJson(json);
  }
}