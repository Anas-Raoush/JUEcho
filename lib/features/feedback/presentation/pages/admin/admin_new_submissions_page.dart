import 'package:flutter/material.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/presentation/pages/admin/admin_single_submission_page.dart';
import 'package:juecho/features/feedback/presentation/providers/submissions_provider.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/admin_submissions_sort.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/card_data.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';

/// Admin screen: shows NEW submissions (status == SUBMITTED).
///
/// Features:
/// - Initializes provider after first frame
/// - Pull-to-refresh
/// - Infinite scroll (loadMore near bottom)
/// - Sorting + backend filtering (category, rating, …)
/// - Responsive layout:
///   - < 900px: ListView
///   - >= 900px: 2-column GridView
///
/// Notes:
/// - Uses [AdminScaffoldWithMenu] for consistent admin header + menu overlay.
class AdminNewSubmissionsPage extends StatefulWidget {
  const AdminNewSubmissionsPage({super.key});

  static const routeName = '/admin-new-submissions';

  @override
  State<AdminNewSubmissionsPage> createState() => _AdminNewSubmissionsPageState();
}

class _AdminNewSubmissionsPageState extends State<AdminNewSubmissionsPage> {
  AdminSubmissionSortKey _sortKey = AdminSubmissionSortKey.newestFirst;
  AdminSubmissionsFilter _filter = const AdminSubmissionsFilter();

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final prov = context.read<AdminNewSubmissionsProvider>();
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
    await context.read<AdminNewSubmissionsProvider>().load();
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
    if (w >= 700) return 650;
    return double.infinity;
  }

  EdgeInsets _pagePaddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 4);
  }

  bool _useTwoColumns(double w) => w >= 900;

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);
          final twoCols = _useTwoColumns(w);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: _pagePaddingFor(w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageTitle(title: 'New submissions', isPar: true),

                    AdminSubmissionsSortBar(
                      sortKey: _sortKey,
                      onSortChanged: (k) => setState(() => _sortKey = k),
                      filter: _filter,
                      onFilterChanged: (newFilter) async {
                        setState(() => _filter = newFilter);
                        await context
                            .read<AdminNewSubmissionsProvider>()
                            .applyBackendFilter(newFilter);
                      },
                      showStatusFilter: false,
                      showUrgencyFilter: false,
                    ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: Consumer<AdminNewSubmissionsProvider>(
                        builder: (context, p, _) {
                          // First load
                          if (p.isLoading && p.items.isEmpty) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // Error with no cached items
                          if (p.error != null && p.items.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: () => _refresh(context),
                              child: ListView(
                                children: const [
                                  SizedBox(height: 40),
                                  Center(
                                    child: Text(
                                      'Could not load submissions. Pull to retry.',
                                      style: TextStyle(color: AppColors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final sorted = [...p.items];
                          sortSubmissions(sorted, _sortKey);

                          return RefreshIndicator(
                            onRefresh: () => _refresh(context),
                            child: sorted.isEmpty
                                ? ListView(
                              children: const [
                                SizedBox(height: 40),
                                Center(
                                  child: Text(
                                    'No new submissions at the moment.',
                                    style: TextStyle(color: AppColors.gray),
                                  ),
                                ),
                              ],
                            )
                                : (twoCols
                                ? GridView.builder(
                              controller: _scrollCtrl,
                              padding: EdgeInsets.zero,
                              itemCount: sorted.length,
                              gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.55,
                              ),
                              itemBuilder: (context, index) {
                                final s = sorted[index];
                                return _AdminSubmissionCard(
                                  serviceCategoryLabel:
                                  s.serviceCategory.label,
                                  title: s.title ?? '-',
                                  rating: s.rating.toString(),
                                  dateLabel: _formatDate(s.createdAt),
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
                              padding: EdgeInsets.zero,
                              itemCount: sorted.length,
                              itemBuilder: (context, index) {
                                final s = sorted[index];
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 12),
                                  child: _AdminSubmissionCard(
                                    serviceCategoryLabel:
                                    s.serviceCategory.label,
                                    title: s.title ?? '-',
                                    rating: s.rating.toString(),
                                    dateLabel:
                                    _formatDate(s.createdAt),
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
                            )),
                          );
                        },
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

/// Reusable admin submission card (for both grid + list).
class _AdminSubmissionCard extends StatelessWidget {
  const _AdminSubmissionCard({
    required this.serviceCategoryLabel,
    required this.title,
    required this.rating,
    required this.dateLabel,
    required this.onOpen,
  });

  final String serviceCategoryLabel;
  final String title;
  final String rating;
  final String dateLabel;
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
              data: rating,
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