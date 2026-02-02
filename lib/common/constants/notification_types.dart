/// notification_types.dart
///
/// Notification type enum and mapping helpers.
///
/// Purpose
/// - Defines the types of notifications supported by the app.
/// - Provides stable mapping to GraphQL enum values and UI labels.
///
/// Notes
/// - [generalInfo] is used as a safe fallback when parsing unknown backend values.
enum NotificationTypeCategories {
  /// Notification triggered when the feedback status changes.
  statusChanged,

  /// Notification triggered when an admin adds a reply.
  newAdminReply,

  /// Notification triggered when a user adds a reply.
  newUserReply,

  /// General informational notification (default/fallback).
  generalInfo,
}

/// Mapping helpers for [NotificationTypeCategories].
extension NotificationTypeCategoriesX on NotificationTypeCategories {
  /// GraphQL enum value expected by the backend.
  String get graphqlName {
    switch (this) {
      case NotificationTypeCategories.statusChanged:
        return 'STATUS_CHANGED';
      case NotificationTypeCategories.newAdminReply:
        return 'NEW_ADMIN_REPLY';
      case NotificationTypeCategories.newUserReply:
        return 'NEW_USER_REPLY';
      case NotificationTypeCategories.generalInfo:
        return 'GENERAL_INFO';
    }
  }

  /// UI label used in notification cards and filters.
  String get label {
    switch (this) {
      case NotificationTypeCategories.statusChanged:
        return 'Status updated';
      case NotificationTypeCategories.newAdminReply:
        return 'New admin reply';
      case NotificationTypeCategories.newUserReply:
        return 'New user reply';
      case NotificationTypeCategories.generalInfo:
        return 'General info';
    }
  }

  /// Converts a GraphQL enum value into a strongly typed [NotificationTypeCategories].
  ///
  /// Fallback behavior
  /// - Unknown values return [NotificationTypeCategories.generalInfo].
  static NotificationTypeCategories fromGraphql(String value) {
    switch (value) {
      case 'STATUS_CHANGED':
        return NotificationTypeCategories.statusChanged;
      case 'NEW_ADMIN_REPLY':
        return NotificationTypeCategories.newAdminReply;
      case 'NEW_USER_REPLY':
        return NotificationTypeCategories.newUserReply;
      case 'GENERAL_INFO':
      default:
        return NotificationTypeCategories.generalInfo;
    }
  }
}