import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/primary_button.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_stats_grid.dart';
import 'package:juecho/features/home/presentation/widgets/welcome_section.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  static const routeName = '/admin-home';

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  bool _isLoading = true;
  String _fullName = 'User';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final name = await AuthRepository.fetchCurrentUserFullName();

      if (!mounted) return;
      setState(() {
        _fullName = name;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWithMenu(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WelcomeSection(name: _fullName,),
                  const SizedBox(height: 8),
                  const Text(
                    'Here are some analytics results',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                  const SizedBox(height: 24),
                  const AdminStatsGrid(),
                  const SizedBox(height: 32),

                  // Main actions
                  GeneralPrimaryButton(
                    label: 'New Submissions',
                    background: AppColors.primary,
                    foreground: AppColors.white,
                    onPressed: () {
                      // TODO: navigate to NewSubmissionsPage.routeName
                    },
                  ),
                  const SizedBox(height: 16),
                  GeneralPrimaryButton(
                    label: 'Submissions Review',
                    background: AppColors.white,
                    foreground: AppColors.darkText,
                    outlined: true,
                    onPressed: () {
                      // TODO: navigate to SubmissionsReviewPage.routeName
                    },
                  ),
                  const SizedBox(height: 16),
                  GeneralPrimaryButton(
                    label: 'Analytics and Reports',
                    background: AppColors.white,
                    foreground: AppColors.darkText,
                    outlined: true,
                    onPressed: () {
                      // TODO: navigate to AnalyticsPage.routeName
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
