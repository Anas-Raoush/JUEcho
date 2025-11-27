import 'dart:convert';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

class FeedbackRepository {
  // -------- GraphQL documents --------

  static const String _createSubmissionMutation = r'''
  mutation CreateSubmission($input: CreateSubmissionInput!) {
    createSubmission(input: $input) {
      id
    }
  }
  ''';

  static const String _listMySubmissionsQuery = r'''
  query ListMySubmissions($ownerId: ID!) {
    listSubmissions(
      filter: { ownerId: { eq: $ownerId } }
    ) {
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
        replies {
          fromRole
          message
          byId
          byName
          at
        }
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
      replies {
        fromRole
        message
        byId
        byName
        at
      }
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
      replies {
        fromRole
        message
        byId
        byName
        at
      }
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

  // -------- Create (full submission or rating-only) --------

  static Future<void> createSubmission({
    required ServiceCategories category,
    String? title,
    String? description,
    String? suggestion,
    String? attachmentKey,
    required int rating,
  }) async {
    final profile = await AuthRepository.fetchCurrentProfileData();
    final ownerId = profile.userId!;
    final now = DateTime.now().toUtc();

    final model = FeedbackSubmission(
      id: uuid(),
      ownerId: ownerId,
      serviceCategory: category,
      title: title
          ?.trim()
          .isEmpty ?? true ? null : title!.trim(),
      description:
      description
          ?.trim()
          .isEmpty ?? true ? null : description!.trim(),
      suggestion:
      suggestion
          ?.trim()
          .isEmpty ?? true ? null : suggestion!.trim(),
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

    final res = await Amplify.API
        .mutate(request: req)
        .response;

    if (res.errors.isNotEmpty) {
      safePrint('createSubmission errors: ${res.errors}');
      throw Exception('Failed to create submission');
    }
  }

  // -------- Fetch list (for "My Feedback") --------

  /// Returns *all* submissions for the current user.
  static Future<List<FeedbackSubmission>> fetchMySubmissions() async {
    final profile = await AuthRepository.fetchCurrentProfileData();
    final ownerId = profile.userId!;

    final req = GraphQLRequest<String>(
      document: _listMySubmissionsQuery,
      variables: {'ownerId': ownerId},
    );

    final res = await Amplify.API
        .query(request: req)
        .response;

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

    // Sort newest → oldest
    submissions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return submissions;
  }

  /// Convenience helper: only *full* submissions (not rating-only).
  static Future<List<FeedbackSubmission>> fetchMyFullSubmissions() async {
    final all = await fetchMySubmissions();
    return all.where((s) => s.isFullFeedback).toList();
  }

  // -------- Single submission --------

  static Future<FeedbackSubmission> fetchSubmissionById(String id) async {
    final req = GraphQLRequest<String>(
      document: _getSubmissionQuery,
      variables: {'id': id},
    );

    final res = await Amplify.API
        .query(request: req)
        .response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('getSubmission error: ${res.errors}');
      throw Exception('Failed to load submission');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['getSubmission'] as Map<String, dynamic>?;
    if (json == null) {
      throw Exception('Submission not found');
    }

    return FeedbackSubmission.fromJson(json);
  }

  // -------- User edit (only while SUBMITTED) --------

  static Future<FeedbackSubmission> updateSubmissionAsUser(
      FeedbackSubmission submission) async {
    if (!submission.canEditOrDelete) {
      throw Exception('Submission can no longer be edited.');
    }

    final req = GraphQLRequest<String>(
      document: _updateSubmissionMutation,
      variables: {'input': submission.toUserUpdateInput()},
    );

    final res = await Amplify.API
        .mutate(request: req)
        .response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('updateSubmission errors: ${res.errors}');
      throw Exception('Failed to update submission');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) {
      throw Exception('Update returned no data');
    }

    return FeedbackSubmission.fromJson(json);
  }

  // -------- User deletes submission (only while SUBMITTED) --------

  static Future<void> deleteSubmissionAsUser(FeedbackSubmission s) async {
    if (!s.canEditOrDelete) {
      throw Exception('Submission can no longer be deleted.');
    }

    final req = GraphQLRequest<String>(
      document: _deleteSubmissionMutation,
      variables: {
        'input': {'id': s.id},
      },
    );

    final res = await Amplify.API
        .mutate(request: req)
        .response;

    if (res.errors.isNotEmpty) {
      safePrint('deleteSubmission errors: ${res.errors}');
      throw Exception('Failed to delete submission');
    }
  }

  // -------- User adds reply (only after admin replied) --------

  static Future<FeedbackSubmission> addUserReply({
    required FeedbackSubmission current,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) throw Exception('Reply is empty');

    // only allow reply if admin has at least one message
    if (current.adminReplies.isEmpty) {
      throw Exception(
        'You can only reply after an admin has replied to this submission.',
      );
    }

    final profile = await AuthRepository.fetchCurrentProfileData();
    final now = DateTime.now().toUtc();

    final newReply = FeedbackReply(
      fromRole: 'GENERAL',
      message: trimmed,
      byId: profile.userId!,
      byName: '${profile.firstName} ${profile.lastName}'.trim(),
      at: now,
    );

    final updated = current.copyWith(
      replies: [...current.replies, newReply],
    );

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

    final res = await Amplify.API
        .mutate(request: req)
        .response;

    if (res.errors.isNotEmpty || res.data == null) {
      safePrint('addUserReply errors: ${res.errors}');
      throw Exception('Failed to send reply');
    }

    final decoded = jsonDecode(res.data!) as Map<String, dynamic>;
    final json = decoded['updateSubmission'] as Map<String, dynamic>?;
    if (json == null) {
      throw Exception('Update returned no data');
    }

    return FeedbackSubmission.fromJson(json);
  }

  // -------- Attachments (Storage) --------

  /// Downloads the attachment bytes from Amplify Storage for a given key.
  /// Returns null if the download fails.
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
}