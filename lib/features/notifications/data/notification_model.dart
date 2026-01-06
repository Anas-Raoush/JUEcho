import 'package:juecho/common/constants/notification_types.dart';

class AppNotification {
  final String id;
  final String recipientId;
  final String? submissionId;
  final NotificationTypeCategories type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
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