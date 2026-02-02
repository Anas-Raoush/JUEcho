import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/notification_types.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/notifications/data/notification_model.dart';

/// Data access layer for notifications.
///
/// Responsibilities
/// - Fetch notifications for a recipient id.
/// - Fetch notifications for the current signed-in user.
/// - Mark a notification as read.
/// - Provide helper methods used by feedback workflows to create notifications
///   (status change and replies).
///
/// Backend
/// - Uses Amplify GraphQL API (queries + mutations).
/// - Sorting is performed client-side by [createdAt] descending.
class NotificationsRepository {
  // ---------- GraphQL ops ----------

  /// Creates a notification record.
  static const String _createNotificationMutation = r'''
  mutation CreateNotification($input: CreateNotificationInput!) {
    createNotification(input: $input) {
      id
    }
  }
  ''';

  /// Marks a notification as read.
  static const String _markReadMutation = r'''
  mutation UpdateNotification($input: UpdateNotificationInput!) {
    updateNotification(input: $input) {
      id
      isRead
      readAt
    }
  }
  ''';

  /// Lists notifications for a recipient id using a filter.
  static const String _listNotificationsQuery = r'''
  query ListNotifications($recipientId: ID) {
    listNotifications(
      filter: { recipientId: { eq: $recipientId } }
    ) {
      items {
        id
        recipientId
        submissionId
        type
        title
        body
        isRead
        createdAt
        readAt
      }
    }
  }
  ''';

  /// Fetch notifications for a specific [recipientId].
  ///
  /// - Does not depend on AuthRepository or AuthProvider.
  /// - Returns notifications sorted by newest first.
  static Future<List<AppNotification>> fetchNotificationsForUser(
      String recipientId,
      ) async {
    final req = GraphQLRequest<String>(
      document: _listNotificationsQuery,
      variables: {'recipientId': recipientId},
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchNotificationsForUser errors: ${res.errors}');
      throw Exception('Failed to load notifications');
    }

    if (res.data == null) return [];

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final list = decoded['listNotifications'] as Map<String, dynamic>?;
    final items = list?['items'] as List<dynamic>? ?? [];

    final notifications = items
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  /// Fetch notifications for the currently signed-in user.
  ///
  /// Notes
  /// - Uses [AuthRepository.fetchCurrentProfileData] to obtain the current user id.
  /// - Returns notifications sorted by newest first.
  static Future<List<AppNotification>> fetchMyNotifications() async {
    final profile = await AuthRepository.fetchCurrentProfileData();

    final req = GraphQLRequest<String>(
      document: _listNotificationsQuery,
      variables: {'recipientId': profile.userId},
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchMyNotifications errors: ${res.errors}');
      throw Exception('Failed to load notifications');
    }

    if (res.data == null) return [];

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final list = decoded['listNotifications'] as Map<String, dynamic>?;
    final items = list?['items'] as List<dynamic>? ?? [];

    final notifications = items
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return notifications;
  }

  /// Mark a notification as read.
  ///
  /// This is a best-effort call. Errors are logged but not thrown.
  static Future<void> markAsRead(String id) async {
    final input = <String, dynamic>{
      'id': id,
      'isRead': true,
      'readAt': DateTime.now().toUtc().toIso8601String(),
    };

    final req = GraphQLRequest<String>(
      document: _markReadMutation,
      variables: {'input': input},
    );

    final res = await Amplify.API.mutate(request: req).response;
    if (res.errors.isNotEmpty) {
      safePrint('markAsRead errors: ${res.errors}');
    }
  }

  // ---------- Trigger helpers (called from feedback workflows) ----------

  /// Create a notification when an admin changes the submission status.
  ///
  /// No-op if [previous.status] equals [updated.status].
  static Future<void> createStatusChangedNotification({
    required FeedbackSubmission previous,
    required FeedbackSubmission updated,
  }) async {
    if (previous.status == updated.status) return;

    final body =
        'Your feedback about ${updated.serviceCategory.label} '
        'is now ${updated.status.label}.';

    await _create(
      recipientId: updated.ownerId,
      submissionId: updated.id,
      type: NotificationTypeCategories.statusChanged,
      title: 'Feedback status updated',
      body: body,
    );
  }

  /// Create a notification when an admin adds a reply.
  ///
  /// The notification is created for the submission owner.
  static Future<void> createNewAdminReplyNotification({
    required FeedbackSubmission submission,
    required String replyText,
  }) async {
    final preview = _makePreview(replyText);

    await _create(
      recipientId: submission.ownerId,
      submissionId: submission.id,
      type: NotificationTypeCategories.newAdminReply,
      title: 'New reply from admin',
      body: preview,
    );
  }

  /// Create a notification when a user adds a reply.
  ///
  /// Notes
  /// - Notifies the last admin who updated the submission ([updatedById]).
  /// - If no admin is associated yet, this is a no-op.
  static Future<void> createNewUserReplyNotification({
    required FeedbackSubmission submission,
    required String replyText,
  }) async {
    final adminId = submission.updatedById;
    if (adminId == null) return;

    final preview = _makePreview(replyText);
    final subject = submission.title?.isNotEmpty == true
        ? submission.title!
        : submission.serviceCategory.label;

    await _create(
      recipientId: adminId,
      submissionId: submission.id,
      type: NotificationTypeCategories.newUserReply,
      title: 'New reply from user',
      body: 'User replied on "$subject": $preview',
    );
  }

  // ---------- Internal helpers ----------

  /// Creates a notification record via GraphQL mutation.
  ///
  /// Errors are logged but not thrown to avoid breaking the calling workflow.
  static Future<void> _create({
    required String recipientId,
    String? submissionId,
    required NotificationTypeCategories type,
    required String title,
    required String body,
  }) async {
    final input = <String, dynamic>{
      'recipientId': recipientId,
      'type': type.graphqlName,
      'title': title,
      'body': body,
      'isRead': false,
    };

    if (submissionId != null) {
      input['submissionId'] = submissionId;
    }

    final req = GraphQLRequest<String>(
      document: _createNotificationMutation,
      variables: {'input': input},
    );

    final res = await Amplify.API.mutate(request: req).response;
    if (res.errors.isNotEmpty) {
      safePrint('createNotification errors: ${res.errors}');
    }
  }

  /// Converts an arbitrary reply body into a compact preview string.
  ///
  /// The preview length is capped at 80 characters to keep notification cards
  /// stable in height across devices.
  static String _makePreview(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 77)}...';
  }
}