import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/data/repositories/admin_repositories/admin_single_submission_actions_repository.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_single_submission_actions_repository.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_submissions_repository.dart';
import 'package:juecho/features/feedback/data/repositories/graphql_subscriptions_repository.dart';

/// Provider responsible for loading and mutating a single feedback submission.
///
/// Responsibilities
/// - Loads the submission by id.
/// - Subscribes to updates for the submission and keeps local state in sync.
/// - Handles admin actions:
///   - update meta (status, urgency, internal notes)
///   - delete submission
///   - send admin replies
/// - Handles general user actions:
///   - save edits (title, description, suggestion, rating)
///   - delete submission
///   - send user replies
///
/// State
/// - [submission] is the currently loaded submission (nullable if deleted or missing).
/// - [isLoading] indicates fetch in progress.
/// - [isSending] indicates mutation in progress.
/// - [error] stores the last user-facing error message.
///
/// Concurrency
/// - Uses [_pendingSendKey] to prevent duplicate sends in rapid UI calls.
class SingleSubmissionProvider extends ChangeNotifier {
  /// Creates a provider bound to a specific submission id.
  ///
  /// The [auth] dependency is used to access the current user's [ProfileData]
  /// when generating replies and admin metadata updates.
  SingleSubmissionProvider(this.id, this._auth);

  /// Target submission id.
  final String id;

  /// Auth state and profile provider.
  final AuthProvider _auth;

  /// Currently loaded submission (nullable when not loaded, deleted, or not found).
  FeedbackSubmission? submission;

  /// Indicates an initial or refresh load request is in progress.
  bool isLoading = false;

  /// Indicates a mutation request is in progress.
  bool isSending = false;

  /// User-facing error message for the last failed operation.
  String? error;

  /// Subscription to backend updates for this submission.
  StreamSubscription<FeedbackSubmission>? _subUpdated;

  /// Prevents accidental double-submit even if UI triggers twice quickly.
  ///
  /// Used by reply sending methods to avoid duplicate writes.
  String? _pendingSendKey;

  /// Initializes provider state.
  ///
  /// - Loads the submission once.
  /// - Starts a subscription stream to keep the local submission updated.
  Future<void> init() async {
    await load();

    _subUpdated?.cancel();
    _subUpdated =
        GraphQLSubscriptionsRepository.onSubmissionUpdatedById(id).listen((s) {
          submission = s;
          notifyListeners();
        });
  }

  /// Loads the submission from the backend.
  ///
  /// Updates:
  /// - [isLoading], [error], [submission]
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      submission = await GeneralSubmissionsRepository.fetchSubmissionById(id);
    } catch (_) {
      error = 'Could not load feedback details.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Saves admin metadata changes for the current submission.
  ///
  /// Requires:
  /// - [status] always
  /// - [urgency] optional
  /// - [internalNotes] optional (empty/whitespace is converted to null)
  ///
  /// Profile requirements:
  /// - Requires [_auth.profile] to be available, otherwise sets [error].
  Future<void> saveAdminMeta({
    required FeedbackStatusCategories status,
    int? urgency,
    String? internalNotes,
  }) async {
    final current = submission;
    final profile = _auth.profile;
    if (current == null) return;

    if (profile == null) {
      error = 'Profile not loaded yet.';
      notifyListeners();
      return;
    }

    isSending = true;
    error = null;
    notifyListeners();

    try {
      submission =
      await AdminSingleSubmissionActionsRepository.updateSubmissionAsAdminMeta(
        current: current,
        status: status,
        urgency: urgency,
        internalNotes: (internalNotes == null || internalNotes.trim().isEmpty)
            ? null
            : internalNotes.trim(),
        profile: profile,
      );
    } catch (_) {
      error = 'Could not save admin changes.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Deletes the current submission as an admin.
  ///
  /// On success, sets [submission] to null.
  Future<void> deleteAsAdmin() async {
    final current = submission;
    if (current == null) return;

    isSending = true;
    error = null;
    notifyListeners();

    try {
      await AdminSingleSubmissionActionsRepository.deleteSubmissionAsAdmin(
        current,
      );
      submission = null;
    } catch (_) {
      error = 'Could not delete feedback.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Saves user-editable fields for the current submission.
  ///
  /// Behavior:
  /// - Applies trimming and converts empty strings to null.
  /// - Persists update via the general repository.
  ///
  /// Inputs are nullable to allow callers to pass optional updates.
  Future<void> saveUserEdits({
    required String? title,
    required String? description,
    required String? suggestion,
    required int rating,
  }) async {
    final current = submission;
    if (current == null) return;

    isSending = true;
    error = null;
    notifyListeners();

    try {
      final updatedLocal = current.copyWith(
        title: (title == null || title.trim().isEmpty) ? null : title.trim(),
        description: (description == null || description.trim().isEmpty)
            ? null
            : description.trim(),
        suggestion: (suggestion == null || suggestion.trim().isEmpty)
            ? null
            : suggestion.trim(),
        rating: rating,
      );

      submission = await GeneralSingleSubmissionActionsRepository
          .updateSubmissionAsUser(updatedLocal);
    } catch (_) {
      error = 'Could not save changes.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Deletes the current submission as the general user.
  ///
  /// On success, sets [submission] to null.
  Future<void> deleteAsUser() async {
    final current = submission;
    if (current == null) return;

    isSending = true;
    error = null;
    notifyListeners();

    try {
      await GeneralSingleSubmissionActionsRepository.deleteSubmissionAsUser(
        current,
      );
      submission = null;
    } catch (_) {
      error = 'Could not delete feedback.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Sends an admin reply for the current submission.
  ///
  /// Flow:
  /// - Validates message and profile availability.
  /// - Applies a local optimistic update (adds reply locally).
  /// - Persists the reply via backend mutation.
  ///
  /// Duplicate prevention:
  /// - Uses [_pendingSendKey] and [isSending] to avoid double send.
  Future<void> sendAdminReply(String message) async {
    final base = submission;
    final profile = _auth.profile;
    if (base == null) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    if (profile == null) {
      error = 'Profile not loaded yet.';
      notifyListeners();
      return;
    }

    final sendKey = 'ADMIN|$trimmed|${base.updatedAt?.toIso8601String()}';
    if (isSending || _pendingSendKey == sendKey) return;

    _pendingSendKey = sendKey;
    isSending = true;
    error = null;
    notifyListeners();

    try {
      submission = await AdminSingleSubmissionActionsRepository.makeLocalAdminReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
      notifyListeners();

      submission = await AdminSingleSubmissionActionsRepository.addAdminReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
    } catch (_) {
      error = 'Could not send reply.';
      rethrow;
    } finally {
      isSending = false;
      _pendingSendKey = null;
      notifyListeners();
    }
  }

  /// Sends a general user reply for the current submission.
  ///
  /// Flow:
  /// - Validates message and profile availability.
  /// - Applies a local optimistic update (adds reply locally).
  /// - Persists the reply via backend mutation.
  ///
  /// Duplicate prevention:
  /// - Uses [_pendingSendKey] and [isSending] to avoid double send.
  Future<void> sendUserReply(String message) async {
    final base = submission;
    final profile = _auth.profile;
    if (base == null) return;

    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    if (profile == null) {
      error = 'Profile not loaded yet.';
      notifyListeners();
      return;
    }

    final sendKey = 'GENERAL|$trimmed|${base.updatedAt?.toIso8601String()}';
    if (isSending || _pendingSendKey == sendKey) return;

    _pendingSendKey = sendKey;
    isSending = true;
    error = null;
    notifyListeners();

    try {
      submission = await GeneralSingleSubmissionActionsRepository.makeLocalUserReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
      notifyListeners();

      submission = await GeneralSingleSubmissionActionsRepository.addUserReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
    } catch (_) {
      error = 'Could not send reply.';
      rethrow;
    } finally {
      isSending = false;
      _pendingSendKey = null;
      notifyListeners();
    }
  }

  /// Cancels any active subscription stream and disposes the provider.
  @override
  void dispose() {
    _subUpdated?.cancel();
    super.dispose();
  }
}