import 'package:flutter/material.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_single_submission_page.dart';
import 'package:juecho/features/feedback/presentation/providers/submissions_provider.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/admin_submissions_sort.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/card_data.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';

/// Admin page: Review all submissions (with sorting + filters).
///
/// Responsibilities:
/// - Initialize [AdminReviewSubmissionsProvider] once after first frame.
/// - Render sorting + filters (AdminSubmissionsSortBar).
/// - Show loading / error / empty states.
/// - Render submissions as:
///   - 1-column ListView on narrow screens
///   - 2-column GridView on wide screens
///
/// Responsive design goals:
/// - Avoid stretched content on desktop by centering and constraining max width.
/// - Fix card overflow by giving grid items a stable height (mainAxisExtent).
class AdminSubmissionsReviewPage extends StatefulWidget {
  const AdminSubmissionsReviewPage({super.key});

  static const routeName = '/admin-submissions-review';

  @override
  State<AdminSubmissionsReviewPage> createState() =>
      _AdminSubmissionsReviewPageState();
}

class _AdminSubmissionsReviewPageState extends State<AdminSubmissionsReviewPage> {
  AdminSubmissionSortKey _sortKey = AdminSubmissionSortKey.newestFirst;
  AdminSubmissionsFilter _filter = const AdminSubmissionsFilter();

  @override
  void initState() {
    super.initState();

    // Init provider AFTER first frame to avoid context issues.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminReviewSubmissionsProvider>().init();
    });
  }

  Future<void> _refresh(BuildContext context) async {
    await context.read<AdminReviewSubmissionsProvider>().load();
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd/$mm/$yyyy';
  }

  double _maxWidthFor(double screenWidth) {
    // Similar idea to your other pages: keep content readable on desktop.
    if (screenWidth >= 1100) return 1100;
    if (screenWidth >= 900) return 900;
    if (screenWidth >= 700) return 700;
    return double.infinity;
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final maxWidth = _maxWidthFor(screenWidth);

          // If the page is wide enough, show 2 cards per row.
          final bool twoColumns = screenWidth >= 900;

          return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageTitle(title: 'Submissions Review', isPar: true),

                    AdminSubmissionsSortBar(
                      sortKey: _sortKey,
                      onSortChanged: (k) => setState(() => _sortKey = k),
                      filter: _filter,
                      onFilterChanged: (newFilter) =>
                          setState(() => _filter = newFilter),
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: Consumer<AdminReviewSubmissionsProvider>(
                        builder: (context, p, _) {
                          // ---- Loading state ----
                          if (p.isLoading && p.items.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // ---- Error state ----
                          if (p.error != null && p.items.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: () => _refresh(context),
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                children: const [
                                  SizedBox(height: 40),
                                  Center(
                                    child: Text(
                                      'Could not load submissions. Pull to retry',
                                      style: TextStyle(color: AppColors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Apply filters + sorting.
                          final filtered =
                          applyAdminSubmissionsFilter(p.items, _filter);
                          final sorted = [...filtered];
                          sortSubmissions(sorted, _sortKey);

                          // ---- Empty state ----
                          if (sorted.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: () => _refresh(context),
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                children: const [
                                  SizedBox(height: 40),
                                  Center(
                                    child: Text(
                                      'No submissions to review at the moment.',
                                      style: TextStyle(color: AppColors.gray),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          // ---- Content ----
                          return RefreshIndicator(
                            onRefresh: () => _refresh(context),
                            child: twoColumns
                                ? GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              itemCount: sorted.length,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,

                                /// ✅ FIX OVERFLOW:
                                /// Give each card a stable height so the button fits
                                /// and we never get "BOTTOM OVERFLOWED".
                                mainAxisExtent: 360,
                              ),
                              itemBuilder: (context, index) {
                                final s = sorted[index];
                                return _SubmissionCard(
                                  serviceCategoryLabel:
                                  s.serviceCategory.label,
                                  title: s.title ?? '-',
                                  ratingLabel: s.rating.toString(),
                                  urgencyLabel:
                                  s.urgency?.toString() ?? '-',
                                  statusLabel: s.status.label,
                                  respondedAdminLabel: (() {
                                    final name =
                                    (s.updatedByName ?? '').trim();
                                    return name.isEmpty ? '-' : name;
                                  })(),
                                  respondedAtLabel: _formatDate(
                                    s.updatedAt ?? s.createdAt,
                                  ),
                                  onOpen: () {
                                    Navigator.pushNamed(
                                      context,
                                      AdminSingleSubmissionPage.routeName,
                                      arguments: s.id,
                                    );
                                  },
                                );
                              },
                            )
                                : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              itemCount: sorted.length,
                              itemBuilder: (context, index) {
                                final s = sorted[index];
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 12),
                                  child: _SubmissionCard(
                                    serviceCategoryLabel:
                                    s.serviceCategory.label,
                                    title: s.title ?? '-',
                                    ratingLabel: s.rating.toString(),
                                    urgencyLabel:
                                    s.urgency?.toString() ?? '-',
                                    statusLabel: s.status.label,
                                    respondedAdminLabel: (() {
                                      final name =
                                      (s.updatedByName ?? '').trim();
                                      return name.isEmpty ? '-' : name;
                                    })(),
                                    respondedAtLabel: _formatDate(
                                      s.updatedAt ?? s.createdAt,
                                    ),
                                    onOpen: () {
                                      Navigator.pushNamed(
                                        context,
                                        AdminSingleSubmissionPage.routeName,
                                        arguments: s.id,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
          );
        },
      ),
    );
  }
}

/// A single submission summary card.
///
/// Kept as a separate widget so it can be reused for:
/// - ListView (1 column)
/// - GridView (2 columns)
class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.serviceCategoryLabel,
    required this.title,
    required this.ratingLabel,
    required this.urgencyLabel,
    required this.statusLabel,
    required this.respondedAdminLabel,
    required this.respondedAtLabel,
    required this.onOpen,
  });

  final String serviceCategoryLabel;
  final String title;
  final String ratingLabel;
  final String urgencyLabel;
  final String statusLabel;
  final String respondedAdminLabel;
  final String respondedAtLabel;
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
              label: 'Rating',
              data: ratingLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
            ),
            CardData(
              label: 'Urgency',
              data: urgencyLabel,
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
              label: 'Responded Admin',
              data: respondedAdminLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
            ),
            CardData(
              label: 'Responded At',
              data: respondedAtLabel,
              labelColor: AppColors.black,
              dataColor: AppColors.primary,
              lastItem: true,
            ),
            const SizedBox(height: 10),


              ElevatedButton(
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

          ],
        ),
      ),
    );
  }
}