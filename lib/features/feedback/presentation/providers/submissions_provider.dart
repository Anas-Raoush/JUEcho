import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

class AdminNewSubmissionsProvider extends SubmissionsProvider {
  AdminNewSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.adminNew);
}

class AdminReviewSubmissionsProvider extends SubmissionsProvider {
  AdminReviewSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.adminReview);
}

class MyFullSubmissionsProvider extends SubmissionsProvider {
  MyFullSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.myFull);
}

enum SubmissionsScope { adminNew, adminReview, myFull }

class SubmissionsProvider extends ChangeNotifier {
  SubmissionsProvider(
      this.auth, {
        required this.scope,
      });

  AuthProvider auth;
  final SubmissionsScope scope;

  bool isLoading = false;
  String? error;

  final List<FeedbackSubmission> _items = [];
  List<FeedbackSubmission> get items => List.unmodifiable(_items);

  void updateAuth(AuthProvider newAuth) {
    auth = newAuth;
  }

  Future<void> init() async {
    await load();
  }

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final list = await _fetch();
      _items
        ..clear()
        ..addAll(list);
    } catch (_) {
      error = 'Could not load submissions.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<FeedbackSubmission>> _fetch() async {
    final profile = auth.profile;

    switch (scope) {
      case SubmissionsScope.adminNew:
        return FeedbackRepository.fetchAdminNewSubmissions();

      case SubmissionsScope.adminReview:
        return FeedbackRepository.fetchAdminReviewSubmissions();

      case SubmissionsScope.myFull:
        if (profile == null) return [];
        final all = await FeedbackRepository.fetchMyFullSubmissions(profile: profile);
        return all;
    }
  }
}