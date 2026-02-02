import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/repositories/graphql_subscriptions_repository.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_submissions_repository.dart';
import 'package:juecho/features/home/data/home_repository.dart';

/// GeneralHomeStatsProvider
///
/// State holder for GENERAL dashboard statistics.
///
/// Responsibilities:
/// - Load stats (HomeRepository.fetchGeneralDashboardStats)
/// - Refresh stats on demand
/// - Keep stats consistent using realtime subscription pings
///
/// Realtime design:
/// - Uses ID-only subscriptions to reduce payload and parsing overhead:
///   -> onCreateSubmission { id }
///   -> onUpdateSubmission { id }
///
/// Ownership filtering:
/// - Subscription events are global; to decide if the current user's stats should update:
///   -> fetch submission by id
///   -> compare ownerId with AuthProvider.profile.userId
///   -> refresh stats only when it matches
class GeneralHomeStatsProvider extends ChangeNotifier {
  GeneralHomeStatsProvider(AuthProvider auth) : _auth = auth;

  AuthProvider _auth;

  GeneralDashboardStats? stats;
  bool isLoading = false;
  String? error;

  StreamSubscription<String>? _subCreatedId;
  StreamSubscription<String>? _subUpdatedId;

  /// Updates the internal auth reference (used by ProxyProvider).
  ///
  /// Side effect:
  /// - If profile becomes available and stats have not been loaded, load once.
  void updateAuth(AuthProvider auth) {
    _auth = auth;

    if (_auth.profile != null && stats == null && !isLoading) {
      load();
    }
  }

  /// Initializes the provider and establishes realtime listeners.
  ///
  /// This should be called once by the consumer page.
  Future<void> init() async {
    await load();

    await _subCreatedId?.cancel();
    await _subUpdatedId?.cancel();

    _subCreatedId =
        GraphQLSubscriptionsRepository.onSubmissionCreatedId().listen(
          _handlePingById,
          onError: (e) => debugPrint('General created subscription error: $e'),
        );

    _subUpdatedId =
        GraphQLSubscriptionsRepository.onSubmissionUpdatedId().listen(
          _handlePingById,
          onError: (e) => debugPrint('General updated subscription error: $e'),
        );
  }

  /// Processes an ID-only subscription event.
  ///
  /// Steps:
  /// 1) If auth/profile not ready -> ignore
  /// 2) Fetch submission by id
  /// 3) If submission.ownerId matches current userId -> reload stats
  Future<void> _handlePingById(String id) async {
    if (isLoading) return;

    final profile = _auth.profile;
    if (profile == null) return;

    try {
      final s = await GeneralSubmissionsRepository.fetchSubmissionById(id);
      if (s.ownerId == profile.userId) {
        await load();
      }
    } catch (e) {
      debugPrint('General ping fetch failed for $id: $e');
    }
  }

  /// Loads statistics for the current signed-in user.
  ///
  /// If profile is not available yet:
  /// - clears error/loading and returns without failing
  Future<void> load() async {
    final profile = _auth.profile;

    if (profile == null) {
      isLoading = false;
      error = null;
      notifyListeners();
      return;
    }

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      stats = await HomeRepository.fetchGeneralDashboardStats(profile: profile);
    } catch (_) {
      error = 'Could not load stats';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Manual refresh entry point (pull-to-refresh / after an action).
  Future<void> refresh() async {
    if (isLoading) return;
    await load();
  }

  @override
  void dispose() {
    _subCreatedId?.cancel();
    _subUpdatedId?.cancel();
    super.dispose();
  }
}

/// AdminHomeStatsProvider
///
/// State holder for ADMIN dashboard statistics.
///
/// Responsibilities:
/// - Load stats (HomeRepository.fetchAdminDashboardStats)
/// - Refresh stats using realtime submission events
///
/// Realtime design:
/// - Uses ID-only subscriptions for create/update/delete:
///   -> onCreateSubmission { id }
///   -> onUpdateSubmission { id }
///   -> onDeleteSubmission { id }
///
/// Refresh strategy:
/// - Any event triggers a refresh if the provider is idle (not currently loading)
class AdminHomeStatsProvider extends ChangeNotifier {
  AdminDashboardStats? stats;
  bool isLoading = false;
  String? error;

  StreamSubscription<String>? _subCreatedId;
  StreamSubscription<String>? _subUpdatedId;
  StreamSubscription<String>? _subDeletedId;

  bool _didInit = false;

  /// Initializes the provider exactly once to avoid duplicate listeners.
  Future<void> init() async {
    if (_didInit) return;
    _didInit = true;

    await load();

    await _subCreatedId?.cancel();
    await _subUpdatedId?.cancel();
    await _subDeletedId?.cancel();

    _subCreatedId =
        GraphQLSubscriptionsRepository.onSubmissionCreatedId().listen(
              (_) => _refreshIfIdle(),
          onError: (e) => debugPrint('Admin created subscription error: $e'),
        );

    _subUpdatedId =
        GraphQLSubscriptionsRepository.onSubmissionUpdatedId().listen(
              (_) => _refreshIfIdle(),
          onError: (e) => debugPrint('Admin updated subscription error: $e'),
        );

    _subDeletedId =
        GraphQLSubscriptionsRepository.onSubmissionDeletedId().listen(
              (_) => _refreshIfIdle(),
          onError: (e) => debugPrint('Admin deleted subscription error: $e'),
        );
  }

  void _refreshIfIdle() {
    if (!isLoading) load();
  }

  /// Loads admin dashboard statistics.
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      stats = await HomeRepository.fetchAdminDashboardStats();
    } catch (_) {
      error = 'Could not load stats';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subCreatedId?.cancel();
    _subUpdatedId?.cancel();
    _subDeletedId?.cancel();
    super.dispose();
  }
}