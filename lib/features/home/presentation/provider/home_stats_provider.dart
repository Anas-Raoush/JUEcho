import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/home/data/home_repository.dart';

/// ============================================================================
/// GENERAL HOME STATS PROVIDER
/// ============================================================================
///
/// Purpose:
/// - Holds and refreshes the GENERAL user's dashboard statistics.
///
/// Loads:
/// - [HomeRepository.fetchGeneralDashboardStats]
///
/// Realtime strategy:
/// - We listen to **ID-only** subscriptions:
///   - onCreateSubmission { id }
///   - onUpdateSubmission { id }
///
/// How we filter events to "my" user:
/// - Subscription gives `id`
/// - We fetch the submission once by `id`
/// - If ownerId matches current userId => refresh stats
class GeneralHomeStatsProvider extends ChangeNotifier {
  GeneralHomeStatsProvider(AuthProvider auth) : _auth = auth;

  /// Auth provider reference (not final because ProxyProvider can update it).
  AuthProvider _auth;

  /// Last loaded stats, null until loaded.
  GeneralDashboardStats? stats;

  /// Loading flag for UI.
  bool isLoading = false;

  /// Error message for UI, null when no error.
  String? error;

  /// Stream subscriptions: we only subscribe to IDs.
  StreamSubscription<String>? _subCreatedId;
  StreamSubscription<String>? _subUpdatedId;

  /// Called by ProxyProvider.update(...) to refresh auth reference.
  void updateAuth(AuthProvider auth) {
    _auth = auth;

    // If profile becomes ready and we haven't loaded yet, load once.
    if (_auth.profile != null && stats == null && !isLoading) {
      load();
    }
  }

  /// Initializes provider:
  /// - Loads stats once.
  /// - Listens to realtime create/update (id-only) events.
  Future<void> init() async {
    await load();

    // Avoid duplicate listeners.
    await _subCreatedId?.cancel();
    await _subUpdatedId?.cancel();

    _subCreatedId = FeedbackRepository.onSubmissionCreatedId().listen(
      _handlePingById,
      onError: (e) => debugPrint('General created subscription error: $e'),
    );

    _subUpdatedId = FeedbackRepository.onSubmissionUpdatedId().listen(
      _handlePingById,
      onError: (e) => debugPrint('General updated subscription error: $e'),
    );
  }

  /// Handles subscription ping (submission id).
  ///
  /// Steps:
  /// 1) If auth not ready -> ignore.
  /// 2) Fetch full submission by id.
  /// 3) If ownerId matches this user -> refresh stats.
  Future<void> _handlePingById(String id) async {
    if (isLoading) return;

    final profile = _auth.profile;
    if (profile == null) return;

    try {
      final s = await FeedbackRepository.fetchSubmissionById(id);
      if (s.ownerId == profile.userId) {
        await load();
      }
    } catch (e) {
      // Realtime should not break the UI.
      debugPrint('General ping fetch failed for $id: $e');
    }
  }

  /// Loads stats for the signed-in user.
  ///
  /// If profile is null (bootstrap not finished), we skip silently.
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

  /// Manual refresh (pull-to-refresh).
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

/// ============================================================================
/// ADMIN HOME STATS PROVIDER
/// ============================================================================
///
/// Purpose:
/// - Holds and refreshes ADMIN dashboard statistics.
///
/// Loads:
/// - [HomeRepository.fetchAdminDashboardStats]
///
/// Realtime strategy:
/// - Listens to id-only create/update/delete events.
/// - Any event triggers a refresh.
///
/// Note:
/// - `_didInit` prevents multiple subscriptions when navigating between pages.
class AdminHomeStatsProvider extends ChangeNotifier {
  AdminDashboardStats? stats;
  bool isLoading = false;
  String? error;

  StreamSubscription<String>? _subCreatedId;
  StreamSubscription<String>? _subUpdatedId;
  StreamSubscription<String>? _subDeletedId;

  bool _didInit = false;

  Future<void> init() async {
    if (_didInit) return;
    _didInit = true;

    await load();

    await _subCreatedId?.cancel();
    await _subUpdatedId?.cancel();
    await _subDeletedId?.cancel();

    _subCreatedId = FeedbackRepository.onSubmissionCreatedId().listen(
          (_) => _refreshIfIdle(),
      onError: (e) => debugPrint('Admin created subscription error: $e'),
    );

    _subUpdatedId = FeedbackRepository.onSubmissionUpdatedId().listen(
          (_) => _refreshIfIdle(),
      onError: (e) => debugPrint('Admin updated subscription error: $e'),
    );

    _subDeletedId = FeedbackRepository.onSubmissionDeletedId().listen(
          (_) => _refreshIfIdle(),
      onError: (e) => debugPrint('Admin deleted subscription error: $e'),
    );
  }

  void _refreshIfIdle() {
    if (!isLoading) load();
  }

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