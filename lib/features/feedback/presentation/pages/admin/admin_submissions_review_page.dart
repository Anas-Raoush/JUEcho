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

/// Admin screen for reviewing ALL non-new submissions (Status != SUBMITTED).
///
/// Features:
/// - Provider init after first frame
/// - Pull-to-refresh
/// - Infinite scroll (loadMore near bottom)
/// - Sorting + backend filtering (status/category/rating/urgency)
/// - Responsive layout:
///   - < 900px: ListView
///   - >= 900px: 2-column GridView
///
/// Notes:
/// - Uses mainAxisExtent in grid to avoid card overflow height issues.
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

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final prov = context.read<AdminReviewSubmissionsProvider>();
      prov.init();

      _scrollCtrl.addListener(() {
        final pos = _scrollCtrl.position;
        if (pos.pixels >= pos.maxScrollExtent - 200) {
          prov.loadMore();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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
                    onFilterChanged: (newFilter) async {
                      setState(() => _filter = newFilter);
                      await context
                          .read<AdminReviewSubmissionsProvider>()
                          .applyBackendFilter(newFilter);
                    },
                  ),

                  const SizedBox(height: 8),

                  Expanded(
                    child: Consumer<AdminReviewSubmissionsProvider>(
                      builder: (context, p, _) {
                        if (p.isLoading && p.items.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

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

                        final sorted = [...p.items];
                        sortSubmissions(sorted, _sortKey);

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

                        return RefreshIndicator(
                          onRefresh: () => _refresh(context),
                          child: twoColumns
                              ? GridView.builder(
                            controller: _scrollCtrl,
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
                              mainAxisExtent: 360,
                            ),
                            itemBuilder: (context, index) {
                              final s = sorted[index];
                              return _SubmissionCard(
                                serviceCategoryLabel: s.serviceCategory.label,
                                title: s.title ?? '-',
                                ratingLabel: s.rating.toString(),
                                urgencyLabel: s.urgency?.toString() ?? '-',
                                statusLabel: s.status.label,
                                respondedAdminLabel: () {
                                  final name = (s.updatedByName ?? '').trim();
                                  return name.isEmpty ? '-' : name;
                                }(),
                                respondedAtLabel:
                                _formatDate(s.updatedAt ?? s.createdAt),
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
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final s = sorted[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SubmissionCard(
                                  serviceCategoryLabel: s.serviceCategory.label,
                                  title: s.title ?? '-',
                                  ratingLabel: s.rating.toString(),
                                  urgencyLabel: s.urgency?.toString() ?? '-',
                                  statusLabel: s.status.label,
                                  respondedAdminLabel: () {
                                    final name = (s.updatedByName ?? '').trim();
                                    return name.isEmpty ? '-' : name;
                                  }(),
                                  respondedAtLabel:
                                  _formatDate(s.updatedAt ?? s.createdAt),
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
            ),
          );
        },
      ),
    );
  }
}

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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