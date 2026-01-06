import 'package:flutter/material.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:provider/provider.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/presentation/pages/general/single_feedback_page.dart';
import 'package:juecho/features/feedback/presentation/providers/submissions_provider.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/card_data.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';

/// General user page: lists the user's *full* feedback submissions.
///
/// Data source:
/// - Uses [MyFullSubmissionsProvider] which loads submissions for the current user.
/// - The provider relies on [AuthProvider.profile] internally via dependency injection.
///
/// UX:
/// - Pull-to-refresh.
/// - Loading state, error state, empty state.
/// - Each item navigates to [SingleFeedbackPage].
///
/// Responsive behavior:
/// - If the available width is large enough, show 2 cards per row.
/// - Otherwise show 1 card per row.
/// - Uses [LayoutBuilder] because it reacts to the actual available width
///   inside the scaffold, not just the device screen size.
///
/// Layout:
/// - Relies on [GeneralScaffoldWithMenu] for the outer padding (16 horizontal).
/// - Only adds light vertical padding inside (to match other pages).
class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});

  static const routeName = '/general-my-feedback';

  @override
  State<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  @override
  void initState() {
    super.initState();

    // Initialize provider AFTER first frame to avoid context issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MyFullSubmissionsProvider>().init();
    });
  }

  Future<void> _refresh() async {
    await context.read<MyFullSubmissionsProvider>().load();
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd/$mm/$yyyy';
  }
  double _maxWidthFor(double w) {
    if (w >= 1200) return 1000;
    if (w >= 900) return 900;
    if (w >= 600) return 600;
    return double.infinity;
  }
  @override
  Widget build(BuildContext context) {
    final p = context.watch<MyFullSubmissionsProvider>();

    return GeneralScaffoldWithMenu(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageTitle(title: 'My feedback', isPar: true),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child:  LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final maxWidth = _maxWidthFor(screenWidth);
                  final bool twoColumns = constraints.maxWidth >= 900;

                  Widget content;

                  // ---- Loading ----
                  if (p.isLoading && p.items.isEmpty) {
                    content = const Center(child: CircularProgressIndicator());
                  }
                  // ---- Error ----
                  else if (p.error != null) {
                    content = ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: const [
                        Center(
                          child: Text(
                            'Could not load your feedback. Pull to retry.',
                            style: TextStyle(color: AppColors.red),
                          ),
                        ),
                      ],
                    );
                  }
                  // ---- Empty ----
                  else if (p.items.isEmpty) {
                    content = ListView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      children: const [
                        Center(
                          child: Text(
                            'You have not submitted any feedback yet.',
                            style: TextStyle(color: AppColors.gray),
                          ),
                        ),
                      ],
                    );
                  }
                  // ---- Data ----
                  else if (!twoColumns) {
                    content = ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: p.items.length,
                      itemBuilder: (context, index) {
                        final s = p.items[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _FeedbackCard(
                            serviceCategoryLabel: s.serviceCategory.label,
                            title: s.title ?? '(No title)',
                            statusLabel: s.status.label,
                            dateLabel: _formatDate(s.createdAt),
                            onOpen: () {
                              Navigator.pushNamed(
                                context,
                                SingleFeedbackPage.routeName,
                                arguments: s.id,
                              );
                            },
                          ),
                        );
                      },
                    );
                  } else {
                    content = GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: p.items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.55,
                      ),
                      itemBuilder: (context, index) {
                        final s = p.items[index];
                        return _FeedbackCard(
                          serviceCategoryLabel: s.serviceCategory.label,
                          title: s.title ?? '(No title)',
                          statusLabel: s.status.label,
                          dateLabel: _formatDate(s.createdAt),
                          onOpen: () {
                            Navigator.pushNamed(
                              context,
                              SingleFeedbackPage.routeName,
                              arguments: s.id,
                            );
                          },
                        );
                      },
                    );
                  }
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable feedback summary card used by both ListView and GridView.
///
/// Important:
/// - UI stays identical across 1-column and 2-column layouts.
/// - Only the parent layout changes; functionality stays the same.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.serviceCategoryLabel,
    required this.title,
    required this.statusLabel,
    required this.dateLabel,
    required this.onOpen,
  });

  final String serviceCategoryLabel;
  final String title;
  final String statusLabel;
  final String dateLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.card,
      elevation: 3.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardData(
              label: 'Service Category',
              data: serviceCategoryLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
            ),
            CardData(
              label: 'Title',
              data: title,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
            ),
            CardData(
              label: 'Status',
              data: statusLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
            ),
            CardData(
              label: 'Submission Date',
              data: dateLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
              lastItem: true,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Full information or reply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}