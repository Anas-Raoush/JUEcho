import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/data/models/submissions_page.dart';
import 'package:juecho/features/feedback/data/repositories/admin_repositories/admin_submissions_repository.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/admin_submissions_sort.dart';

/// Paged provider for feedback submissions.
///
/// Scopes
/// - adminNew: submissions awaiting first handling (status == SUBMITTED)
/// - adminReview: submissions already processed (status != SUBMITTED)
/// - myFull: current user's full feedback submissions only (non-paged load-all)
///
/// Paging (admin scopes)
/// - Uses a backend nextToken.
/// - Collects until it reaches [_pageSize] or runs out of tokens.
/// - Maintains [_hasMore] and [_nextToken] for infinite scrolling.

class AdminNewSubmissionsProvider extends SubmissionsProvider {
  /// Admin scope provider for "new submissions" view.
  AdminNewSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.adminNew);
}

class AdminReviewSubmissionsProvider extends SubmissionsProvider {
  /// Admin scope provider for "review submissions" view.
  AdminReviewSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.adminReview);
}

class MyFullSubmissionsProvider extends SubmissionsProvider {
  /// General scope provider for the current user's full feedback list.
  MyFullSubmissionsProvider(super.auth) : super(scope: SubmissionsScope.myFull);
}

/// Identifies the data scope and loading strategy for [SubmissionsProvider].
enum SubmissionsScope { adminNew, adminReview, myFull }

class SubmissionsProvider extends ChangeNotifier {
  /// Creates a submissions provider for the given [scope].
  ///
  /// The [auth] dependency is used to resolve the current user's profile
  /// for myFull scope and for filter building when needed.
  SubmissionsProvider(this.auth, {required this.scope});

  /// Auth provider used to access current user profile.
  AuthProvider auth;

  /// Defines whether this provider loads admin pages (paged) or myFull (load-all).
  final SubmissionsScope scope;

  /// Indicates load operation in progress.
  bool isLoading = false;

  /// User-facing error message for the last failed operation.
  String? error;

  /// Backing store for loaded submissions.
  final List<FeedbackSubmission> _items = [];

  /// Immutable view of the current items list.
  List<FeedbackSubmission> get items => List.unmodifiable(_items);

  /// Next token for backend pagination (admin scopes only).
  String? _nextToken;

  /// Whether more pages are available (admin scopes only).
  bool _hasMore = true;

  /// True when the provider can load more pages.
  bool get hasMore => _hasMore;

  /// Active backend filter (admin scopes only).
  AdminSubmissionsFilter _activeFilter = const AdminSubmissionsFilter();

  /// Page size used for UI-facing pagination.
  final int _pageSize = 20;

  /// Updates the auth dependency reference.
  ///
  /// Useful when provider is retained but auth instance is replaced.
  void updateAuth(AuthProvider newAuth) {
    auth = newAuth;
  }

  /// Initializes the provider and loads the first page (or full list for myFull).
  Future<void> init() async => loadFirstPage();

  /// Applies a backend filter for admin scopes and reloads from the first page.
  ///
  /// No-op for [SubmissionsScope.myFull].
  Future<void> applyBackendFilter(AdminSubmissionsFilter filter) async {
    if (scope == SubmissionsScope.myFull) return;

    _activeFilter = filter;
    await loadFirstPage();
  }

  /// Resets backend filter for admin scopes.
  ///
  /// When [reload] is true, triggers a reload from the first page.
  Future<void> resetBackendFilter({bool reload = true}) async {
    if (scope == SubmissionsScope.myFull) return;

    _activeFilter = const AdminSubmissionsFilter();
    if (reload) await loadFirstPage();
  }

  /// Alias for loading from the start.
  Future<void> load() => loadFirstPage();

  /// Loads the first page (admin scopes) or all items (myFull).
  ///
  /// Admin scopes:
  /// - Clears the current list.
  /// - Fetches a first page via [_fetchAdminPage].
  ///
  /// myFull:
  /// - Loads all current user's submissions using [_fetchAllMyFull].
  /// - Disables paging behavior.
  Future<void> loadFirstPage() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _items.clear();
      _nextToken = null;
      _hasMore = true;

      if (scope == SubmissionsScope.myFull) {
        final all = await _fetchAllMyFull();
        _items.addAll(all);

        _hasMore = false;
        _nextToken = null;
        return;
      }

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

  /// Loads the next page and appends to the current list (admin scopes only).
  ///
  /// Guards:
  /// - No-op for [SubmissionsScope.myFull]
  /// - Skips if already loading or no more results.
  Future<void> loadMore() async {
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

  /// Fetches an admin page using the active scope and filter.
  ///
  /// Behavior:
  /// - Builds a backend filter using [AdminSubmissionsRepository.buildAdminFilter].
  /// - Repeatedly requests pages until at least [_pageSize] items are collected
  ///   or the backend indicates no more data.
  /// - Returns at most [_pageSize] items while preserving the [nextToken] for
  ///   the next [loadMore] call.
  Future<SubmissionsPage> _fetchAdminPage({String? nextToken}) async {
    final filter = AdminSubmissionsRepository.buildAdminFilter(
      isAdminNewScope: scope == SubmissionsScope.adminNew,
      isAdminReviewScope: scope == SubmissionsScope.adminReview,
      filter: _activeFilter,
    );

    final collected = <FeedbackSubmission>[];
    String? token = nextToken;

    while (collected.length < _pageSize) {
      final page = await AdminSubmissionsRepository.fetchSubmissionsPage(
        filter: filter,
        limit: _pageSize,
        nextToken: token,
      );

      collected.addAll(page.items);

      token = page.nextToken;
      final noMore = token == null || token.isEmpty;
      if (noMore) break;

      if (page.items.isEmpty) continue;
    }

    final finalItems = collected.take(_pageSize).toList();
    return SubmissionsPage(items: finalItems, nextToken: token);
  }

  /// Loads all current user's submissions and returns full-feedback items only.
  ///
  /// Strategy:
  /// - Uses paged calls with large limit until nextToken is empty.
  /// - Filters by ownerId using the current profile userId.
  /// - Filters to full feedback entries only ([FeedbackSubmission.isFullFeedback]).
  /// - Sorts by createdAt descending.
  Future<List<FeedbackSubmission>> _fetchAllMyFull() async {
    final profile = auth.profile;
    if (profile == null) return [];

    String? token;
    final all = <FeedbackSubmission>[];

    do {
      final page = await AdminSubmissionsRepository.fetchSubmissionsPage(
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