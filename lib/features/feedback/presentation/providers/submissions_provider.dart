import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/admin_submissions_sort.dart';

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
  SubmissionsProvider(this.auth, {required this.scope});

  AuthProvider auth;
  final SubmissionsScope scope;

  bool isLoading = false;
  String? error;

  final List<FeedbackSubmission> _items = [];
  List<FeedbackSubmission> get items => List.unmodifiable(_items);

  String? _nextToken;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  AdminSubmissionsFilter _activeFilter = const AdminSubmissionsFilter();
  final int _pageSize = 20;

  void updateAuth(AuthProvider newAuth) {
    auth = newAuth;
  }

  Future<void> init() async => loadFirstPage();

  Future<void> applyBackendFilter(AdminSubmissionsFilter filter) async {
    // Filters apply ONLY for admin pages
    if (scope == SubmissionsScope.myFull) return;

    _activeFilter = filter;
    await loadFirstPage();
  }

  Future<void> resetBackendFilter({bool reload = true}) async {
    if (scope == SubmissionsScope.myFull) return;

    _activeFilter = const AdminSubmissionsFilter();
    if (reload) await loadFirstPage();
  }

  Future<void> load() => loadFirstPage();

  Future<void> loadFirstPage() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _items.clear();
      _nextToken = null;
      _hasMore = true;

      // myFull: load everything once, no infinite scroll
      if (scope == SubmissionsScope.myFull) {
        final all = await _fetchAllMyFull();
        _items.addAll(all);

        _hasMore = false;
        _nextToken = null;
        return;
      }

      //  admin: first page paging
      final page = await _fetchAdminPage(nextToken: null);
      _items.addAll(page.items);
      _nextToken = page.nextToken;
      _hasMore = _nextToken != null && _nextToken!.isNotEmpty;
    } catch (_) {
      error = 'Could not load submissions.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    //  no infinite scroll for myFull
    if (scope == SubmissionsScope.myFull) return;

    if (isLoading) return;
    if (!_hasMore) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final page = await _fetchAdminPage(nextToken: _nextToken);
      _items.addAll(page.items);
      _nextToken = page.nextToken;
      _hasMore = _nextToken != null && _nextToken!.isNotEmpty;
    } catch (_) {
      error = 'Could not load more submissions.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------- ADMIN PAGED ----------------
  Future<SubmissionsPage> _fetchAdminPage({String? nextToken}) async {
    final filter = FeedbackRepository.buildAdminFilter(
      isAdminNewScope: scope == SubmissionsScope.adminNew,
      isAdminReviewScope: scope == SubmissionsScope.adminReview,
      filter: _activeFilter,
    );

    // collect until we have at least _pageSize items OR nextToken ends
    final collected = <FeedbackSubmission>[];
    String? token = nextToken;

    while (collected.length < _pageSize) {
      final page = await FeedbackRepository.fetchSubmissionsPage(
        filter: filter,
        limit: _pageSize,  // scan chunk size
        nextToken: token,
      );

      collected.addAll(page.items);

      token = page.nextToken;
      final noMore = token == null || token.isEmpty;
      if (noMore) break;

      // IMPORTANT: if page came back empty, we still continue because filter happens after scan
      if (page.items.isEmpty) continue;
    }

    // return only up to pageSize to UI, keep token for next loadMore()
    final finalItems = collected.take(_pageSize).toList();

    return SubmissionsPage(items: finalItems, nextToken: token);
  }

  // ---------------- MY FULL: LOAD ALL ----------------
  Future<List<FeedbackSubmission>> _fetchAllMyFull() async {
    final profile = auth.profile;
    if (profile == null) return [];

    String? token;
    final all = <FeedbackSubmission>[];

    do {
      final page = await FeedbackRepository.fetchSubmissionsPage(
        filter: {'ownerId': {'eq': profile.userId}},
        limit: 200,
        nextToken: token,
      );

      all.addAll(page.items);
      token = page.nextToken;
    } while (token != null && token.isNotEmpty);

    final fullOnly = all.where((s) => s.isFullFeedback).toList();
    fullOnly.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return fullOnly;
  }
}