import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/home/presentation/widgets/menu_item.dart';
import 'package:juecho/features/profile/presentation/pages/profile_page.dart';

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
    // TODO: when you create the notifications page, navigate to it here:
    // Navigator.pushNamed(context, NotificationsPage.routeName);
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      margin:  const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                icon: Icon(Icons.close, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // First row: Notifications - Home - Profile - sign out
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
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
            ],
          ),
        ],
      ),
    );
  }
}
