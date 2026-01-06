import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/notifications/data/notification_model.dart';
import 'package:juecho/features/notifications/data/notifications_repository.dart';

class NotificationsProvider extends ChangeNotifier {
  bool _initStarted = false;
  bool _ready = false;

  bool get ready => _ready;

  List<AppNotification> items = [];
  bool isLoading = false;
  String? error;

  /// Derived once from AuthProvider (source of truth).
  bool isAdmin = false;

  String? _myUserId;


  /// Initialize using the already-loaded AuthProvider.
  ///
  /// Why:
  /// - AuthProvider already fetched: session + profile (once).
  /// - Avoids a second profile fetch that can return fallback/stale data.
  Future<void> initFromAuth(AuthProvider auth) async {
    if (_initStarted) return;
    _initStarted = true;

    try {
      // Must have a profile loaded at this stage.
      final profile = auth.profile;
      if (profile == null || profile.userId.isEmpty) {
        throw Exception('AuthProvider profile not ready');
      }

      _myUserId = profile.userId;

      // Use AuthProvider's session-based flag .
      isAdmin = auth.isAdmin;

      _ready = true;
      notifyListeners();

      await load();

    } catch (e) {
      error = 'Could not initialize notifications';
      _ready = true; // unblock UI so it can show error
      notifyListeners();
    }
  }

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

  Future<void> markRead(String id) async {
    // optimistic UI
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

  void _sort() => items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

}