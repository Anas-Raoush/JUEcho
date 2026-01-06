import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/presentation/pages/general/my_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/general/submit_feedback_page.dart';
import 'package:juecho/features/home/presentation/widgets/general/rating_popup.dart';
import 'package:juecho/features/home/presentation/provider/home_stats_provider.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_stats_row.dart';
import 'package:juecho/features/home/presentation/widgets/shared/primary_button.dart';
import 'package:juecho/features/home/presentation/widgets/shared/welcome_section.dart';
import 'package:juecho/features/notifications/presentation/pages/notifications_page.dart';

/// General user landing page.
///
/// What it shows:
/// - A welcome header using the signed-in user's name.
/// - A stats summary row (counts for feedback activity).
/// - Primary actions for general users:
///   - Submit Feedback
///   - My Feedback
///   - Notifications
///   - Submit Rating
///
/// Data sources:
/// - [AuthProvider]
///   - Holds the current cached profile + computed `fullName`.
///   - `profile == null` means auth is not ready yet (bootstrap still running).
/// - [GeneralHomeStatsProvider]
///   - Loads dashboard stats for the general user.
///   - Exposes `stats`, `isLoading`, and `error`.
///
/// Provider usage:
/// - `context.read<T>()`
///   - Used ONLY for one-time side effects:
///     - initial load (network call)
///     - refresh after actions
///     - showing dialogs / navigation
/// - `Selector`
///   - Used to rebuild only the welcome section when `fullName` changes.
/// - `Consumer`
///   - Used to rebuild only the stats section when stats provider changes.
///   - Prevents the whole page from rebuilding unnecessarily.
///
/// Responsive behavior:
/// - Uses [LayoutBuilder] + [ConstrainedBox] to prevent stretching on wide screens.
/// - Uses [Align.topCenter] to keep content pinned to the top.
/// - Uses [SingleChildScrollView] so small devices don’t overflow vertically.
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

    // Load stats ONCE after first frame.
    //
    // Why after first frame?
    // - `context.read(...)` in initState is sometimes risky if the widget tree
    //   isn't fully mounted yet.
    // - addPostFrameCallback ensures the Provider is available safely.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<GeneralHomeStatsProvider>().load();
    });
  }

  /// Calculates a maximum page width so the UI doesn't look stretched on tablets/web.
  ///
  /// Examples:
  /// - Phones: take full width.
  /// - Tablets: clamp to ~550–720.
  /// - Desktop/web: clamp to ~900.
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

          // Keep content pinned to the top and centered horizontally on wide screens.
          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),

              // Scroll is required because the column can be taller than the screen.
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Only rebuild this section when the name changes.
                    //
                    // Why Selector?
                    // - Avoid rebuilding the whole page when only the name updates.
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

                    // Stats section isolated:
                    // - It listens to both AuthProvider (profile readiness)
                    //   and GeneralHomeStatsProvider (loading/stats/error).
                    const _StatsSection(),
                    const SizedBox(height: 32),

                    // ---------------- Actions ----------------

                    /// Submit a full feedback submission.
                    ///
                    /// After returning from the submit page, refresh stats.
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

                        // Refresh stats after user action.
                        context.read<GeneralHomeStatsProvider>().refresh();
                      },
                    ),
                    const SizedBox(height: 12),

                    /// Navigate to the user's submissions list.
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

                    /// Navigate to notifications.
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

                    /// Opens the rating popup (rating-only submission).
                    PrimaryButton(
                      label: 'Submit Rating',
                      background: AppColors.white,
                      foreground: AppColors.darkText,
                      outlined: true,
                      onPressed: () async {
                        await _showRatingDialog(context);
                      },
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

  /// Shows the rating dialog and submits a rating-only feedback entry.
  ///
  /// Notes:
  /// - Uses [AuthProvider.profile] (cached) because the repository requires owner data.
  /// - On success:
  ///   - closes the dialog
  ///   - refreshes stats
  ///   - shows a SnackBar
  Future<void> _showRatingDialog(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;

    // If the profile isn't ready, block rating submission (safe UX).
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
              // Create a rating-only submission.
              await FeedbackRepository.createSubmission(
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
                  content: Text(
                    'Could not submit rating. Please try again later',
                  ),
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
      // Refresh stats after rating submission.
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

/// Isolated stats area for the home screen.
///
/// Why this widget exists:
/// - Prevents the entire home page from rebuilding when stats change.
/// - Handles all loading/error/empty states related to stats.
///
/// Rebuild triggers:
/// - AuthProvider changes (specifically `profile` readiness).
/// - GeneralHomeStatsProvider changes (`isLoading`, `stats`, `error`).
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, GeneralHomeStatsProvider>(
      builder: (_, auth, statsP, __) {
        // Auth not ready yet -> show loader and avoid confusing blank UI.
        if (auth.profile == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // First-time loading stats.
        if (statsP.isLoading && statsP.stats == null) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Stats failed to load.
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

        // Stats ready.
        // GeneralStatsRow reads from GeneralHomeStatsProvider internally,
        // so keeping it const here is fine (the Consumer rebuild triggers it).
        return const GeneralStatsRow();
      },
    );
  }
}