enum NotificationTypeCategories {
  statusChanged,
  newAdminReply,
  newUserReply,
  generalInfo,
}

extension NotificationTypeCategoriesX on NotificationTypeCategories {
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