import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/presentation/pages/my_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/pages/submit_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/widgets/rating_popup.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_stats_row.dart';
import 'package:juecho/common/widgets/primary_button.dart';
import 'package:juecho/common/constants/service_categories.dart';

class GeneralHomePage extends StatefulWidget {
  const GeneralHomePage({super.key});

  static const routeName = '/general-home';

  @override
  State<GeneralHomePage> createState() => _GeneralHomePageState();
}

class _GeneralHomePageState extends State<GeneralHomePage> {
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
    return GeneralScaffoldWithMenu(

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WelcomeSection(name: _fullName,),
                  const SizedBox(height: 8),
                  const Text(
                    'Here is your activity summary',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.gray),
                  ),
                  const SizedBox(height: 16),
                  const GeneralStatsRow(),
                  const SizedBox(height: 32),

                  // Main actions
                  GeneralPrimaryButton(
                    label: 'Submit Feedback',
                    background: AppColors.primary,
                    foreground: AppColors.white,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        SubmitFeedbackPage.routeName,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  GeneralPrimaryButton(
                    label: 'My Feedback',
                    background: AppColors.white,
                    foreground: AppColors.darkText,
                    outlined: true,
                    onPressed: ()=> Navigator.pushNamed(context, MyFeedbackPage.routeName),
                  ),
                  const SizedBox(height: 12),
                  const GeneralPrimaryButton(
                    label: 'Notifications',
                    background: AppColors.white,
                    foreground: AppColors.darkText,
                    outlined: true,
                    // onPressed: null, // TODO: hook notifications page
                  ),
                  const SizedBox(height: 12),
                  GeneralPrimaryButton(
                    label: 'Submit Rating',
                    background: AppColors.white,
                    foreground: AppColors.darkText,
                    outlined: true,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return RatingPopup(
                            onSubmit: ({
                              required ServiceCategories category,
                              required int rating,
                            }) async {
                              try {
                                await FeedbackRepository.createSubmission(
                                  category: category,
                                  rating: rating,
                                  // if later you add comment field in popup,
                                  // pass it here e.g. comment: comment,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Rating submitted successfully.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } catch (e) {
                                safePrint('Submit rating error: $e');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not submit rating. Please try again later.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final String name;
  const _WelcomeSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Welcome $name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}