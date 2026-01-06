import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/analytics/presentation/pages/analytics_reports_page.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/widgets/shared/menu_item.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';

/// Admin hamburger menu overlay content.
///
/// Responsibilities:
/// - Navigate to: Home, Notifications, Analytics
/// - Sign out
///
/// Responsive (same style as GeneralHamburgerMenu):
/// - On wide screens: one row with 4 items.
/// - On narrow screens: two rows (2 items per row) to avoid squeezing/overflow.
/// - Also constrains width so it doesn’t stretch ugly on desktop.
class AdminHamburgerMenu extends StatelessWidget {
  const AdminHamburgerMenu({
    super.key,
    required this.closeMenu,
  });

  final VoidCallback closeMenu;

  // ---------- actions ----------

  Future<void> _handleNotificationsTap(BuildContext context) async {
    closeMenu();
    if (!context.mounted) return;
    Navigator.pushNamed(context, NotificationsPage.routeName);
  }

  Future<void> _handleHomeTap(BuildContext context) async {
    closeMenu();

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == AdminHomePage.routeName) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AdminHomePage.routeName,
          (route) => false,
    );
  }

  Future<void> _handleAnalyticsTap(BuildContext context) async {
    closeMenu();
    if (!context.mounted) return;
    Navigator.pushNamed(context, AnalyticsReportsPage.routeName);
  }

  Future<void> _handleSignOutTap(BuildContext context) async {
    try {
      await AuthRepository.signOut();
    } catch (e) {
      safePrint('Sign-out failed: $e');
    }

    closeMenu();

    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
          (route) => false,
    );
  }

  /// Keeps the popup menu looking nice on large screens.
  double _maxWidthFor(double w) {
    if (w >= 900) return 700;
    if (w >= 600) return 560;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final maxWidth = _maxWidthFor(w);

        // Same “feel” as general menu:
        // If width is tight, split into 2 rows instead of squeezing.
        final bool compact = w < 350;

        final notificationsItem = MenuItem(
          icon: Icons.notifications_none_outlined,
          label: 'Notifications',
          color: AppColors.primary,
          onTap: () => _handleNotificationsTap(context),
        );

        final analyticsItem = MenuItem(
          icon: Icons.bar_chart_outlined,
          label: 'Analytics',
          color: AppColors.primary,
          onTap: () => _handleAnalyticsTap(context),
        );

        final homeItem = MenuItem(
          icon: Icons.home_outlined,
          label: 'Home',
          color: AppColors.primary,
          onTap: () => _handleHomeTap(context),
        );

        final signOutItem = MenuItem(
          icon: Icons.logout,
          label: 'Sign out',
          color: AppColors.red,
          outlinedColor: AppColors.red,
          onTap: () => _handleSignOutTap(context),
        );

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 10,
                    offset: Offset(0, 4),
                    color: AppColors.boxShadowColor,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + close X
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      const Text(
                        'JUEcho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: closeMenu,
                        icon: Icon(Icons.close, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (!compact) ...[
                    // ✅ Wide: one row (same as GeneralHamburgerMenu style)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        notificationsItem,
                        analyticsItem,
                        homeItem,
                        signOutItem,
                      ],
                    ),
                  ] else ...[
                    // ✅ Narrow: two rows (2 items per row)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        notificationsItem,
                        analyticsItem,
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        homeItem,
                        signOutItem,
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}