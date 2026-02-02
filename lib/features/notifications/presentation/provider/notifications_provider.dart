import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/notifications/data/notification_model.dart';
import 'package:juecho/features/notifications/data/notifications_repository.dart';

/// State holder for notifications.
///
/// Responsibilities
/// - Derives role and user id from [AuthProvider] once.
/// - Loads notifications for the current user.
/// - Provides optimistic updates when marking notifications as read.
///
/// Initialization
/// - [initFromAuth] must be called once after AuthProvider is ready.
/// - [ready] indicates role/user id resolution is complete (success or error).
class NotificationsProvider extends ChangeNotifier {
  bool _initStarted = false;
  bool _ready = false;

  /// True when role/user id resolution has completed.
  bool get ready => _ready;

  /// In-memory notifications list (newest-first after load).
  List<AppNotification> items = [];

  /// Loading flag for fetch operations.
  bool isLoading = false;

  /// User-facing error message for UI rendering.
  String? error;

  /// Derived once from [AuthProvider] and used to pick UI scaffold/routes.
  bool isAdmin = false;

  String? _myUserId;

  /// Initialize provider state from [AuthProvider].
  ///
  /// Rules
  /// - No-op if already initialized.
  /// - Requires [AuthProvider.profile] to be available.
  /// - Uses [auth.isAdmin] as the role source of truth.
  ///
  /// Side effects
  /// - Sets [ready] to true and triggers an initial [load].
  Future<void> initFromAuth(AuthProvider auth) async {
    if (_initStarted) return;
    _initStarted = true;

    try {
      final profile = auth.profile;
      if (profile == null || profile.userId.isEmpty) {
        throw Exception('AuthProvider profile not ready');
      }
      // NotificationsProvider.initFromAuth
      safePrint('Notifications initFromAuth profile.userId: ${profile.userId}');
      safePrint('Notifications initFromAuth isAdmin: ${auth.isAdmin}');

      _myUserId = profile.userId;
      isAdmin = auth.isAdmin;

      _ready = true;
      notifyListeners();

      await load();
    } catch (_) {
      error = 'Could not initialize notifications';
      _ready = true;
      notifyListeners();
    }
  }

  /// Loads notifications for the current user.
  ///
  /// Requires [_myUserId] to be available from [initFromAuth].
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final uid = _myUserId;
      if (uid == null || uid.isEmpty) {
        throw Exception('Missing user id');
      }

      items = await NotificationsRepository.fetchNotificationsForUser(uid);
      _sort();
    } catch (_) {
      error = 'Could not load notifications';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Marks a notification as read using an optimistic UI update.
  ///
  /// Behavior
  /// - Updates the local item immediately if it is unread.
  /// - Fires the repository mutation in the background.
  /// - Does not surface network errors to the UI for this action.
  Future<void> markRead(String id) async {
    final idx = items.indexWhere((n) => n.id == id);
    if (idx != -1) {
      final n = items[idx];
      if (!n.isRead) {
        final copy = [...items];
        copy[idx] = AppNotification(
          id: n.id,
          recipientId: n.recipientId,
          submissionId: n.submissionId,
          type: n.type,
          title: n.title,
          body: n.body,
          isRead: true,
          createdAt: n.createdAt,
          readAt: DateTime.now().toUtc(),
        );
        items = copy;
        notifyListeners();
      }
    }

    try {
      await NotificationsRepository.markAsRead(id);
    } catch (_) {}
  }

  /// Sort notifications newest-first based on [createdAt].
  void _sort() => items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
}