import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/home/presentation/widgets/shared/primary_button.dart';
import 'package:juecho/features/analytics/presentation/pages/analytics_reports_page.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_new_submissions_page.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_submissions_review_page.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_stats_grid.dart';
import 'package:juecho/features/home/presentation/widgets/shared/welcome_section.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';

/// Admin home page (dashboard).
///
/// Responsibilities:
/// - Show admin welcome + key stats + navigation buttons.
/// - Trigger loading of dashboard stats.
/// - Ensure stats update in real time using GraphQL subscriptions.
///
/// Real-time:
/// - AdminHomeStatsProvider starts subscription listeners inside `init()`.
/// - This page MUST call `init()` (not `load()`) to activate real-time refresh.
///
/// Responsive:
/// - Uses LayoutBuilder + maxWidth constraints.
/// - Uses SingleChildScrollView to avoid vertical overflow.
class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  static const routeName = '/admin-home';

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  @override
  void initState() {
    super.initState();

    // Start stats loading + real-time subscriptions once after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminHomeStatsProvider>().init();
    });
  }

  /// Keeps layout readable on wide screens (tablet/web).
  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 820;
    if (w >= 700) return 650;
    return double.infinity;
  }

  /// Small padding tweak for very small phones.
  EdgeInsets _pagePaddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 4);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fullName = auth.fullName.isNotEmpty ? auth.fullName : 'User';

    // When profile is null, bootstrap is not finished.
    final bool isLoadingProfile = auth.profile == null;

    return AdminScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);

          if (isLoadingProfile) {
            return const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: _pagePaddingFor(w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WelcomeSection(name: fullName),
                    const SizedBox(height: 8),
                    const Text(
                      'Here are some analytics results',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.gray),
                    ),
                    const SizedBox(height: 24),

                    /// Stats grid listens to AdminHomeStatsProvider internally.
                    const AdminStatsGrid(),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      label: 'New Submissions',
                      background: AppColors.primary,
                      foreground: AppColors.white,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AdminNewSubmissionsPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Submissions Review',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AdminSubmissionsReviewPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Analytics and Reports',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AnalyticsReportsPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 16),

                    PrimaryButton(
                      label: 'Notifications',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        NotificationsPage.routeName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}