import 'package:juecho/common/constants/notification_types.dart';

/// Domain model representing an in-app notification.
///
/// Notes
/// - Stored and fetched via the Notifications GraphQL API.
/// - [type] is parsed from the GraphQL enum string using
///   [NotificationTypeCategoriesX.fromGraphql].
class AppNotification {
  /// Unique notification id (GraphQL record id).
  final String id;

  /// User id of the recipient who should receive this notification.
  final String recipientId;

  /// Optional feedback submission id related to this notification.
  final String? submissionId;

  /// Notification type category (backed by a GraphQL enum string).
  final NotificationTypeCategories type;

  /// Short title displayed in the notifications list.
  final String title;

  /// Notification content displayed in the notifications list.
  final String body;

  /// Read state.
  final bool isRead;

  /// Creation timestamp (UTC expected from backend).
  final DateTime createdAt;

  /// Read timestamp (UTC) when the notification was marked as read.
  final DateTime? readAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.submissionId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.readAt,
  });

  /// Builds an [AppNotification] from a decoded GraphQL JSON map.
  ///
  /// Expected keys
  /// - id, recipientId, type, title, body, createdAt
  /// - submissionId (optional)
  /// - isRead (optional, defaults to false)
  /// - readAt (optional)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      submissionId: json['submissionId'] as String?,
      type: NotificationTypeCategoriesX.fromGraphql(
        json['type'] as String,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}