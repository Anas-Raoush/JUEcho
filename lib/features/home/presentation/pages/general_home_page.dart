import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_submissions_repository.dart';
import 'package:juecho/features/feedback/presentation/pages/general/my_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/submit_feedback_page.dart';
import 'package:juecho/features/home/presentation/widgets/general/rating_popup.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_stats_row.dart';
import 'package:juecho/features/home/presentation/widgets/shared/primary_button.dart';
import 'package:juecho/features/home/presentation/widgets/shared/welcome_section.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';

/// GeneralHomePage
///
/// General user landing page.
///
/// Responsibilities:
/// - Welcomes the signed-in user using AuthProvider.fullName.
/// - Loads and displays dashboard statistics via GeneralHomeStatsProvider.
/// - Provides the primary user actions:
///   -> Submit Feedback (full feedback submission)
///   -> My Feedback (view submission history)
///   -> Notifications
///   -> Submit Rating (rating-only submission)
///
/// Data dependencies:
/// - AuthProvider:
///   -> caches ProfileData and exposes fullName
///   -> profile == null indicates bootstrap is still in progress
/// - GeneralHomeStatsProvider:
///   -> stats + isLoading + error for the dashboard row
///
/// Performance considerations:
/// - Selector<AuthProvider, String> isolates rebuilds to the welcome section.
/// - Stats section is isolated into _StatsSection to limit rebuild scope.
class GeneralHomePage extends StatefulWidget {
  const GeneralHomePage({super.key});

  static const routeName = '/general-home';

  @override
  State<GeneralHomePage> createState() => _GeneralHomePageState();
}

class _GeneralHomePageState extends State<GeneralHomePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GeneralHomeStatsProvider>().load();
    });
  }

  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 720;
    if (w >= 700) return 550;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    return GeneralScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = _maxWidthFor(constraints.maxWidth);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Selector<AuthProvider, String>(
                      selector: (_, a) => a.fullName,
                      builder: (_, name, __) => WelcomeSection(name: name),
                    ),
                    const Text(
                      'Here is your activity summary',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.gray),
                    ),
                    const SizedBox(height: 16),
                    const _StatsSection(),
                    const SizedBox(height: 32),

                    PrimaryButton(
                      label: 'Submit Feedback',
                      background: AppColors.primary,
                      foreground: AppColors.white,
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          SubmitFeedbackPage.routeName,
                        );
                        if (!context.mounted) return;
                        context.read<GeneralHomeStatsProvider>().refresh();
                      },
                    ),
                    const SizedBox(height: 12),

                    PrimaryButton(
                      label: 'My Feedback',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        MyFeedbackPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 12),

                    PrimaryButton(
                      label: 'Submit Rating',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () async => _showRatingDialog(context),
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

  /// Opens RatingPopup and persists a rating-only submission.
  ///
  /// Flow:
  /// - Validate that AuthProvider.profile is ready
  /// - Show RatingPopup (blocking dialog)
  /// - On submit:
  ///   -> GeneralSubmissionsRepository.createSubmission(category, rating, profile)
  /// - On success:
  ///   -> close dialog with true
  ///   -> refresh stats
  ///   -> show confirmation SnackBar
  Future<void> _showRatingDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your session is not ready. Please sign in again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return RatingPopup(
          onSubmit: ({
            required ServiceCategories category,
            required int rating,
          }) async {
            try {
              await GeneralSubmissionsRepository.createSubmission(
                category: category,
                rating: rating,
                profile: profile,
              );

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(true);
            } catch (e) {
              safePrint('Submit rating error: $e');

              if (!dialogContext.mounted) return;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                const SnackBar(
                  content: Text('Could not submit rating. Please try again later'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );

    if (!context.mounted) return;

    if (ok == true) {
      context.read<GeneralHomeStatsProvider>().refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// _StatsSection
///
/// Dedicated widget for general dashboard stats to keep rebuild scope minimal.
///
/// Render states:
/// - Auth profile not ready -> loader
/// - Stats initial load -> loader
/// - Error with no cached stats -> error + retry
/// - Stats available -> GeneralStatsRow
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, GeneralHomeStatsProvider>(
      builder: (_, auth, statsP, __) {
        if (auth.profile == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (statsP.isLoading && statsP.stats == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (statsP.error != null && statsP.stats == null) {
          return Column(
            children: [
              Text(
                statsP.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.red),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: statsP.refresh,
                child: const Text('Retry'),
              ),
            ],
          );
        }

        return const GeneralStatsRow();
      },
    );
  }
}