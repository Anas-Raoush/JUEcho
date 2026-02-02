import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/home/presentation/widgets/shared/menu_item.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';
import 'package:juecho/features/profile/presentation/pages/profile_page.dart';

/// GeneralHamburgerMenu
///
/// Slide-down overlay menu content for GENERAL users.
///
/// Responsibilities:
/// - Provide navigation shortcuts:
///   -> Notifications
///   -> Home
///   -> Profile
/// - Perform sign-out and reset navigation stack back to LoginPage.
///
/// Navigation rules:
/// - Home uses pushNamedAndRemoveUntil to reset stack.
/// - Sign out uses pushNamedAndRemoveUntil after clearing session.
///
/// Responsive layout:
/// - Constrains maximum width on wide screens to keep the menu readable.
/// - Uses Row layout when possible.
/// - Switches to Wrap on narrow widths to prevent item squeezing.
class GeneralHamburgerMenu extends StatelessWidget {
  const GeneralHamburgerMenu({super.key, required this.closeMenu});

  /// Callback provided by the parent scaffold to close the overlay.
  final VoidCallback closeMenu;

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

        final double maxWidth = w >= 1200
            ? 900
            : w >= 900
            ? 820
            : w >= 700
            ? 650
            : double.infinity;

        final bool useWrap = w < 320;

        final double horizontalPad = w < 380 ? 12 : 16;
        final double topMargin = 16;
        final double sideMargin = w < 380 ? 12 : 16;

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
                        icon: const Icon(Icons.close, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!useWrap)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: items,
                    )
                  else
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