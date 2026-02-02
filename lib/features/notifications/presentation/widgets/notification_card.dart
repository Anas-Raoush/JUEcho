import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/notification_types.dart';
import 'package:juecho/features/notifications/data/notification_model.dart';

/// Presentation widget for an [AppNotification].
///
/// UI behavior
/// - Shows a small dot indicator for unread notifications.
/// - Displays title, body preview, type label, and date.
/// - Optionally renders "View submission" when [submissionId] exists and
///   [onViewSubmission] is provided.
class NotificationCard extends StatelessWidget {
  /// Notification to render.
  final AppNotification notification;

  /// Optional action to open the related submission.
  final VoidCallback? onViewSubmission;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onViewSubmission,
  });

  /// Formats a date as dd/mm/yyyy.
  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(notification.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification.type.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray,
                  ),
                ),
                if (notification.submissionId != null && onViewSubmission != null)
                  SizedBox(
                    height: 32,
                    child: TextButton(
                      onPressed: onViewSubmission,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text('View submission'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}