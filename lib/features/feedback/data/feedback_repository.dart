import 'dart:convert';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/notifications/data/notifications_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// ============================================================================
/// FEEDBACK REPOSITORY
/// ============================================================================
///
/// This repository contains:
/// - Queries: list/get submissions
/// - Mutations: create/update/delete submissions
/// - Realtime subscriptions:
///    A) SAFE "ping" subscriptions (ID-only)
///    B) FULL payload subscriptions (full submission fields)
class FeedbackRepository {
  // ===========================================================================
  // GraphQL MUTATIONS
  // ===========================================================================

  static const String _createSubmissionMutation = r'''
  mutation CreateSubmission($input: CreateSubmissionInput!) {
    createSubmission(input: $input) {
      id
    }
  }
  ''';

  static const String _updateSubmissionMutation = r'''
  mutation UpdateSubmission($input: UpdateSubmissionInput!) {
    updateSubmission(input: $input) {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
  ''';

  static const String _deleteSubmissionMutation = r'''
  mutation DeleteSubmission($input: DeleteSubmissionInput!) {
    deleteSubmission(input: $input) {
      id
    }
  }
  ''';

  // ===========================================================================
  // GraphQL QUERIES
  // ===========================================================================

  static const String _listMySubmissionsQuery = r'''
  query ListMySubmissions($ownerId: ID!) {
    listSubmissions(filter: { ownerId: { eq: $ownerId } }) {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
  ''';

  static const String _getSubmissionQuery = r'''
  query GetSubmission($id: ID!) {
    getSubmission(id: $id) {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
  ''';

  static const String _listAdminReviewSubmissionsQuery = r'''
  query ListAdminReviewSubmissions {
    listSubmissions(filter: { status: { ne: SUBMITTED } }) {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
  ''';

  static const String _listAdminSubmissionsByStatusQuery = r'''
  query ListAdminSubmissions($status: SubmissionStatus!) {
    listSubmissions(filter: { status: { eq: $status } }) {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
  ''';

  static const String _listAllSubmissionsForAdminQuery = r'''
  query ListAllSubmissionsForAdmin {
    listSubmissions {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
  ''';

  // ===========================================================================
  // FULL PAYLOAD SUBSCRIPTIONS
  // ===========================================================================

  static const String _onCreateSubmissionSub = r'''
  subscription OnCreateSubmission {
    onCreateSubmission {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
  ''';

  static const String _onUpdateSubmissionSub = r'''
  subscription OnUpdateSubmission {
    onUpdateSubmission {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
  ''';

  // ===========================================================================
  // SAFE ID-ONLY SUBSCRIPTIONS
  // ===========================================================================

  static const String _onCreateSubmissionIdSub = r'''
  subscription OnCreateSubmission {
    onCreateSubmission { id }
  }
  ''';

  static const String _onUpdateSubmissionIdSub = r'''
  subscription OnUpdateSubmission {
    onUpdateSubmission { id }
  }
  ''';

  static const String _onDeleteSubmissionIdSub = r'''
  subscription OnDeleteSubmission {
    onDeleteSubmission { id }
  }
  ''';

  /// Helper: extracts a nested payload node from a subscription event.
  ///
  /// Works with both formats:
  /// - {"data": {"onCreateSubmission": {...}}}
  /// - {"onCreateSubmission": {...}}
  static Map<String, dynamic>? _extractNode(String? raw, String fieldName) {
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;

    final dataNode = decoded['data'];
    final root = (dataNode is Map<String, dynamic>) ? dataNode : decoded;

    final payload = root[fieldName];
    if (payload is! Map<String, dynamic>) return null;

    return payload;
  }

  /// Helper: extracts only the `id` field from subscription event data.
  static String? _extractId(String? raw, String fieldName) {
    final node = _extractNode(raw, fieldName);
    if (node == null) return null;

    final id = node['id'];
    if (id is! String || id.isEmpty) return null;

    return id;
  }

  // ===========================================================================
  // PING STREAMS (ID ONLY)  ✅ used for dashboards/providers
  // ===========================================================================

  /// Emits submission id when a submission is created.
  static Stream<String> onSubmissionCreatedId() {
    final req = GraphQLRequest<String>(
      document: _onCreateSubmissionIdSub,
      authorizationMode: APIAuthorizationType.userPools,
    );

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onCreateSubmission established'),
    );

    return op.map((event) {
      if (event.errors.isNotEmpty) {
        safePrint('onCreateSubmission errors: ${event.errors}');
      }

      final id = _extractId(event.data, 'onCreateSubmission');
      if (id == null) throw StateError('onCreateSubmission id payload missing');

      return id;
    });
  }

  /// Emits submission id when a submission is updated.
  static Stream<String> onSubmissionUpdatedId() {
    final req = GraphQLRequest<String>(
      document: _onUpdateSubmissionIdSub,
      authorizationMode: APIAuthorizationType.userPools,
    );

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onUpdateSubmission established'),
    );

    return op.map((event) {
      if (event.errors.isNotEmpty) {
        safePrint('onUpdateSubmission errors: ${event.errors}');
      }

      final id = _extractId(event.data, 'onUpdateSubmission');
      if (id == null) throw StateError('onUpdateSubmission id payload missing');

      return id;
    });
  }

  /// Emits submission id when a submission is deleted.
  static Stream<String> onSubmissionDeletedId() {
    final req = GraphQLRequest<String>(
      document: _onDeleteSubmissionIdSub,
      authorizationMode: APIAuthorizationType.userPools,
    );

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onDeleteSubmission established'),
    );

    return op.map((event) {
      if (event.errors.isNotEmpty) {
        safePrint('onDeleteSubmission errors: ${event.errors}');
      }

      final id = _extractId(event.data, 'onDeleteSubmission');
      if (id == null) throw StateError('onDeleteSubmission id payload missing');

      return id;
    });
  }

  // ===========================================================================
  // FULL PAYLOAD STREAM
  // ===========================================================================

  /// Full payload: emits FeedbackSubmission when update event includes full data.
  static Stream<FeedbackSubmission> onSubmissionUpdated() {
    final req = GraphQLRequest<String>(
      document: _onUpdateSubmissionSub,
      authorizationMode: APIAuthorizationType.userPools,
    );

    final op = Amplify.API.subscribe(
      req,
      onEstablished: () => safePrint('onUpdateSubmission (full) established'),
    );

    return op
        .map((event) {
      if (event.errors.isNotEmpty) {
        safePrint('onUpdateSubmission (full) errors: ${event.errors}');
      }

      final node = _extractNode(event.data, 'onUpdateSubmission');
      if (node == null) {
        safePrint('onUpdateSubmission (full) payload missing/null. Skipping.');
        return null;
      }

      try {
        return FeedbackSubmission.fromJson(node);
      } catch (e) {
        safePrint('onUpdateSubmission (full) parse failed: $e. Skipping.');
        return null;
      }
    })
        .where((x) => x != null)
        .cast<FeedbackSubmission>();
  }

  /// Convenience: filter updates by id (kept because you used it elsewhere).
  static Stream<FeedbackSubmission> onSubmissionUpdatedById(String id) {
    return onSubmissionUpdated().where((s) => s.id == id);
  }

  // ===========================================================================
  // LOCAL REPLY HELPERS (kept)
  // ===========================================================================

  static Future<FeedbackSubmission> makeLocalAdminReply({
    required FeedbackSubmission current,
    required String message,
    required ProfileData profile,
  }) async {
    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'ADMIN',
      message: message.trim(),
      byId: profile.userId,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    return current.copyWith(replies: [...current.replies, newReply]);
  }

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

  // ===========================================================================
  // CREATE
  // ===========================================================================

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
      document: _createSubmissionMutation,
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

  // ===========================================================================
  // FETCH (user/admin)
  // ===========================================================================

  static Future<List<FeedbackSubmission>> fetchMySubmissions({
    required ProfileData profile,
  }) async {
    final ownerId = profile.userId;

    final req = GraphQLRequest<String>(
      document: _listMySubmissionsQuery,
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
      document: _getSubmissionQuery,
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

  static Future<List<FeedbackSubmission>> fetchAdminNewSubmissions() async {
    final req = GraphQLRequest<String>(
      document: _listAdminSubmissionsByStatusQuery,
      variables: {'status': 'SUBMITTED'},
    );

    final res = await Amplify.API.query(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('fetchAdminNewSubmissions errors: ${res.errors}');
      throw Exception('Failed to load new submissions');
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

  static Future<List<FeedbackSubmission>> fetchAdminReviewSubmissions() async {
    final req = GraphQLRequest<String>(document: _listAdminReviewSubmissionsQuery);
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
    final req = GraphQLRequest<String>(document: _listAllSubmissionsForAdminQuery);
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

  // ===========================================================================
  // USER UPDATE/DELETE
  // ===========================================================================

  static Future<FeedbackSubmission> updateSubmissionAsUser(
      FeedbackSubmission submission,
      ) async {
    if (!submission.canEditOrDelete) {
      throw Exception('Submission can no longer be edited.');
    }

    final req = GraphQLRequest<String>(
      document: _updateSubmissionMutation,
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
      document: _deleteSubmissionMutation,
      variables: {'input': {'id': s.id}},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('deleteSubmission errors: ${res.errors}');
      throw Exception('Failed to delete submission');
    }
  }

  // ===========================================================================
  // REPLIES
  // ===========================================================================

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
      document: _updateSubmissionMutation,
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
      document: _updateSubmissionMutation,
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

  // ===========================================================================
  // STORAGE
  // ===========================================================================

  static Future<Uint8List?> downloadAttachmentBytes(String key) async {
    try {
      final result = await Amplify.Storage.downloadData(
        path: StoragePath.fromString(key),
      ).result;

      return Uint8List.fromList(result.bytes);
    } catch (e) {
      safePrint('downloadAttachmentBytes error for $key: $e');
      return null;
    }
  }

  // ===========================================================================
  // ADMIN-ONLY OPERATIONS
  // ===========================================================================

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
      document: _updateSubmissionMutation,
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
      document: _updateSubmissionMutation,
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

  static Future<void> deleteSubmissionAsAdmin(FeedbackSubmission s) async {
    final req = GraphQLRequest<String>(
      document: _deleteSubmissionMutation,
      variables: {'input': {'id': s.id}},
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('deleteSubmissionAsAdmin errors: ${res.errors}');
      throw Exception('Failed to delete submission');
    }
  }
}