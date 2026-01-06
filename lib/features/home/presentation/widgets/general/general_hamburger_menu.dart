import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/home/presentation/widgets/shared/menu_item.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';
import 'package:juecho/features/profile/presentation/pages/profile_page.dart';

/// Top overlay hamburger menu for General users.
///
/// What it does:
/// - Shows quick navigation actions:
///   Notifications, Home, Profile, Sign out.
/// - Closes itself via [closeMenu] before navigating.
/// - Uses `pushNamedAndRemoveUntil` for Home and Sign out to reset navigation stack.
///
/// Responsive behavior:
/// - Uses [LayoutBuilder] to constrain width on large screens.
/// - Adjusts internal layout:
///   - Narrow widths: items wrap into 2 rows (Wrap) so they don't squeeze.
///   - Wide widths: items stay in one row (Row-like) and keep spacing.
class GeneralHamburgerMenu extends StatelessWidget {
  const GeneralHamburgerMenu({super.key, required this.closeMenu});

  final VoidCallback closeMenu;

  // ---------- actions ----------

  Future<void> _handleHomeTap(BuildContext context) async {
    closeMenu();

    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute == GeneralHomePage.routeName) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      GeneralHomePage.routeName,
          (route) => false,
    );
  }

  Future<void> _handleNotificationsTap(BuildContext context) async {
    closeMenu();
    if (!context.mounted) return;
    Navigator.pushNamed(context, NotificationsPage.routeName);
  }

  Future<void> _handleProfileTap(BuildContext context) async {
    closeMenu();
    if (!context.mounted) return;
    Navigator.pushNamed(context, ProfilePage.routeName);
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // Constrain menu width on desktop so it doesn't become too wide.
        // Still respects outer Stack padding/margins.
        final double maxWidth = w >= 1200
            ? 900
            : w >= 900
            ? 820
            : w >= 700
            ? 650
            : double.infinity;

        // If the menu is narrow, use Wrap so buttons don't get squeezed.
        final bool useWrap = w < 320;

        // Keep original spacing, but scale it slightly on small screens.
        final double horizontalPad = w < 380 ? 12 : 16;
        final double topMargin = 16;
        final double sideMargin = w < 380 ? 12 : 16;

        // Build the items once.
        final items = <Widget>[
          MenuItem(
            icon: Icons.notifications_none_outlined,
            label: 'Notifications',
            color: AppColors.primary,
            onTap: () => _handleNotificationsTap(context),
          ),
          MenuItem(
            icon: Icons.home_outlined,
            label: 'Home',
            color: AppColors.primary,
            onTap: () => _handleHomeTap(context),
          ),
          MenuItem(
            icon: Icons.person_outline,
            label: 'Profile',
            color: AppColors.primary,
            onTap: () => _handleProfileTap(context),
          ),
          MenuItem(
            icon: Icons.logout,
            label: 'Sign out',
            color: AppColors.red,
            outlinedColor: AppColors.red,
            onTap: () => _handleSignOutTap(context),
          ),
        ];

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: EdgeInsets.fromLTRB(horizontalPad, 20, horizontalPad, 24),
              margin: EdgeInsets.only(
                top: topMargin,
                left: sideMargin,
                right: sideMargin,
              ),
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
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        onPressed: closeMenu,
                        icon: const Icon(Icons.close, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Actions
                  if (!useWrap)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: items,
                    )
                  else
                  // On narrow widths: wrap into multiple rows (prevents squishing).
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 14,
                      children: items,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}