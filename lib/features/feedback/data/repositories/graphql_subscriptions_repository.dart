import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/data/graphql/submission_documents.dart';

/// Provides subscription streams for realtime updates.
///
/// Strategy:
/// - Prefer "id-only" subscriptions for safety + performance
/// - Optionally support full payload subscription for certain screens
class GraphQLSubscriptionsRepository {
  // ===========================================================================
  // SAFE ID-ONLY SUBSCRIPTIONS
  // ===========================================================================

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
  // PING STREAMS
  // ===========================================================================

  /// Emits submission id when a submission is created.
  static Stream<String> onSubmissionCreatedId() {
    final req = GraphQLRequest<String>(
      document: onCreateSubmissionIdSub,
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
      document: onUpdateSubmissionIdSub,
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
      document: onDeleteSubmissionIdSub,
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
      document: onUpdateSubmissionSub,
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

  /// Convenience: filter updates by id.
  static Stream<FeedbackSubmission> onSubmissionUpdatedById(String id) {
    return onSubmissionUpdated().where((s) => s.id == id);
  }
}