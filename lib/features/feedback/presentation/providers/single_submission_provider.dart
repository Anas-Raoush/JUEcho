import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

class SingleSubmissionProvider extends ChangeNotifier {
  SingleSubmissionProvider(this.id, this._auth);

  final String id;
  final AuthProvider _auth;

  FeedbackSubmission? submission;
  bool isLoading = false;
  bool isSending = false;
  String? error;

  StreamSubscription<FeedbackSubmission>? _subUpdated;

  /// Prevents accidental double-submit even if UI calls twice quickly.
  String? _pendingSendKey;

  Future<void> init() async {
    await load();

    _subUpdated?.cancel();
    _subUpdated = FeedbackRepository.onSubmissionUpdatedById(id).listen((s) {
      submission = s;
      notifyListeners();
    });
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      submission = await FeedbackRepository.fetchSubmissionById(id);
    } catch (_) {
      error = 'Could not load feedback details.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
      submission = await FeedbackRepository.updateSubmissionAsAdminMeta(
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

  Future<void> deleteAsAdmin() async {
    final current = submission;
    if (current == null) return;

    isSending = true;
    error = null;
    notifyListeners();

    try {
      await FeedbackRepository.deleteSubmissionAsAdmin(current);
      submission = null;
    } catch (_) {
      error = 'Could not delete feedback.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

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

      submission = await FeedbackRepository.updateSubmissionAsUser(updatedLocal);
    } catch (_) {
      error = 'Could not save changes.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> deleteAsUser() async {
    final current = submission;
    if (current == null) return;

    isSending = true;
    error = null;
    notifyListeners();

    try {
      await FeedbackRepository.deleteSubmissionAsUser(current);
      submission = null;
    } catch (_) {
      error = 'Could not delete feedback.';
      rethrow;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

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
      submission = await FeedbackRepository.makeLocalAdminReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
      notifyListeners();

      submission = await FeedbackRepository.addAdminReply(
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
      submission = await FeedbackRepository.makeLocalUserReply(
        current: base,
        message: trimmed,
        profile: profile,
      );
      notifyListeners();

      submission = await FeedbackRepository.addUserReply(
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

  @override
  void dispose() {
    _subUpdated?.cancel();
    super.dispose();
  }
}