import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_single_submission_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/single_feedback_page.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/notifications/presentation/provider/notifications_provider.dart';
import 'package:juecho/features/notifications/presentation/widgets/notification_card.dart';

/// Notifications page shared by admin and general users.
///
/// Responsibilities
/// - Initializes [NotificationsProvider] from [AuthProvider] after first frame.
/// - Renders a list of notifications with pull-to-refresh.
/// - Marks a notification as read before navigating to a submission (if linked).
///
/// Routing
/// - If the current user is an admin, navigation targets
///   [AdminSingleSubmissionPage].
/// - Otherwise navigation targets [SingleFeedbackPage].
///
/// Responsive layout
/// - Constrains max width on larger screens.
/// - Applies light horizontal padding for consistent spacing.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();

    // Initialize provider after first frame to avoid context timing issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<NotificationsProvider>().initFromAuth(auth);
    });
  }

  /// Max content width for common breakpoints to avoid over-stretching.
  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 820;
    if (w >= 700) return 650;
    return double.infinity;
  }

  /// Horizontal padding that scales for very narrow devices.
  EdgeInsets _pagePaddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 4);
  }

  /// Marks [notificationId] as read and opens the related submission route.
  ///
  /// Navigation target depends on the current user role (admin vs general).
  Future<void> _openSubmission(
      BuildContext context,
      NotificationsProvider p,
      String notificationId,
      String submissionId,
      ) async {
    await p.markRead(notificationId);

    final routeName =
    p.isAdmin ? AdminSingleSubmissionPage.routeName : SingleFeedbackPage.routeName;

    if (!context.mounted) return;

    Navigator.pushNamed(
      context,
      routeName,
      arguments: submissionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationsProvider>(
      builder: (context, p, _) {
        // Provider needs role/user id before choosing the correct scaffold + routes.
        if (!p.ready) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final content = LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final maxWidth = _maxWidthFor(w);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: _pagePaddingFor(w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const PageTitle(title: 'Notifications'),
                      const SizedBox(height: 8),

                      if (p.isLoading && p.items.isEmpty)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (p.error != null && p.items.isEmpty)
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.error!,
                                  style: const TextStyle(color: AppColors.red),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: p.load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (p.items.isEmpty)
                          const Expanded(
                            child: Center(
                              child: Text(
                                'No notifications yet.',
                                style: TextStyle(color: AppColors.gray),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: p.load,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: p.items.length,
                                itemBuilder: (context, index) {
                                  final n = p.items[index];

                                  return NotificationCard(
                                    notification: n,
                                    onViewSubmission: (n.submissionId == null)
                                        ? null
                                        : () => _openSubmission(
                                      context,
                                      p,
                                      n.id,
                                      n.submissionId!,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        return p.isAdmin
            ? AdminScaffoldWithMenu(body: content)
            : GeneralScaffoldWithMenu(body: content);
      },
    );
  }
}