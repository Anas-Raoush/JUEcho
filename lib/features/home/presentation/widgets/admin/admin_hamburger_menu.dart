import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/Home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/login_page.dart';
import 'package:juecho/features/home/presentation/widgets/menu_item.dart';

class AdminHamburgerMenu extends StatelessWidget {
  const AdminHamburgerMenu({
    super.key,
    required this.closeMenu,
  });

  final VoidCallback closeMenu;

  Future<void> _handleHomeTap(BuildContext context) async {
    closeMenu();
    final current = ModalRoute.of(context)?.settings.name;
    if (current == AdminHomePage.routeName) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AdminHomePage.routeName,
          (_) => false,
    );
  }

  Future<void> _handleAnalyticsTap(BuildContext context) async {
    closeMenu();
    if (!context.mounted) return;
    // TODO: when you create the notifications page, navigate to it here:
    // Navigator.pushNamed(context, AnalyticsPage.routeName);
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: closeMenu,
                icon: Icon(Icons.close, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MenuItem(
                icon: Icons.bar_chart_outlined,
                label: 'Analytics',
                color: AppColors.primary,
                onTap: () => _handleAnalyticsTap(context)
              ),
              MenuItem(
                icon: Icons.home_outlined,
                label: 'Home',
                color: AppColors.primary,
                onTap: () => _handleHomeTap(context),
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
