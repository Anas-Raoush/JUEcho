import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/notification_types.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/notifications/data/notification_model.dart';

class NotificationsRepository {
  // ---------- GraphQL ops ----------

  static const String _createNotificationMutation = r'''
  mutation CreateNotification($input: CreateNotificationInput!) {
    createNotification(input: $input) {
      id
    }
  }
  ''';

  static const String _markReadMutation = r'''
  mutation UpdateNotification($input: UpdateNotificationInput!) {
    updateNotification(input: $input) {
      id
      isRead
      readAt
    }
  }
  ''';
// inside NotificationsRepository

  static const String _onCreateNotificationSub = r'''
subscription OnCreateNotification {
  onCreateNotification {
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
''';

  static const String _onUpdateNotificationSub = r'''
subscription OnUpdateNotification {
  onUpdateNotification {
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
''';
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

  // ✅ NEW: fetch by recipient id (doesn't touch AuthRepository at all)
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

  static Stream<AppNotification> onNotificationCreated() {
    final req = GraphQLRequest<String>(document: _onCreateNotificationSub);

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onCreateNotification established'),
    );

    return op.map((event) {
      final decoded = jsonDecode(event.data!) as Map<String, dynamic>;
      final json = decoded['onCreateNotification'] as Map<String, dynamic>;
      return AppNotification.fromJson(json);
    }).handleError((e) => safePrint('onNotificationCreated error: $e'));
  }

  static Stream<AppNotification> onNotificationUpdated() {
    final req = GraphQLRequest<String>(document: _onUpdateNotificationSub);

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onUpdateNotification established'),
    );

    return op.map((event) {
      final decoded = jsonDecode(event.data!) as Map<String, dynamic>;
      final json = decoded['onUpdateNotification'] as Map<String, dynamic>;
      return AppNotification.fromJson(json);
    }).handleError((e) => safePrint('onNotificationUpdated error: $e'));
  }

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

  // ---- Trigger helpers (called from FeedbackRepository) ----

  /// When admin changes status.
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

  /// When admin replies – user should see it.
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

  /// When user replies – admin should see it.
  ///
  /// We notify the last admin who updated this submission (updatedById).
  static Future<void> createNewUserReplyNotification({
    required FeedbackSubmission submission,
    required String replyText,
  }) async {
    final adminId = submission.updatedById;
    if (adminId == null) return; // no admin "owner" yet

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

  static String _makePreview(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 77)}...';
  }
}