import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/presentation/pages/single_feedback_page.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';

class MyFeedbackPage extends StatefulWidget {
  const MyFeedbackPage({super.key});

  static const routeName = '/general-my-feedback';

  @override
  State<MyFeedbackPage> createState() => _MyFeedbackPageState();
}

class _MyFeedbackPageState extends State<MyFeedbackPage> {
  late Future<List<FeedbackSubmission>> _future;

  @override
  void initState() {
    super.initState();
    _future = FeedbackRepository.fetchMyFullSubmissions();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = FeedbackRepository.fetchMyFullSubmissions();
    });
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return GeneralScaffoldWithMenu(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageTitle(title: 'My feedback'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<FeedbackSubmission>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: const [
                        SizedBox(height: 40),
                        Center(
                          child: Text(
                            'Could not load your feedback. Pull to retry.',
                            style: TextStyle(color: AppColors.red),
                          ),
                        ),
                      ],
                    );
                  }

                  final items = snapshot.data ?? [];

                  if (items.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 40),
                        Center(
                          child: Text(
                            'You have not submitted any feedback yet.',
                            style: TextStyle(color: AppColors.gray),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final s = items[index];
                      return Card(
                        color: AppColors.card,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
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
                                data: s.serviceCategory.label,
                                labelColor: AppColors.black,
                                dataColor: AppColors.primary,
                              ),
                              CardData(
                                label: 'Title',
                                data: s.title!,
                                labelColor: AppColors.black,
                                dataColor: AppColors.primary,
                              ),
                              CardData(
                                label: 'Status',
                                data: s.status.label,
                                labelColor: AppColors.black,
                                dataColor: AppColors.primary,
                              ),
                              CardData(
                                label: 'Submission Date',
                                data: _formatDate(s.createdAt),
                                labelColor: AppColors.black,
                                dataColor: AppColors.primary,
                                lastItem: true,
                              ),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      SingleFeedbackPage.routeName,
                                      arguments: s.id,
                                    );
                                  },
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
                    },
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

class CardData extends StatelessWidget {
  const CardData({
    super.key,
    required this.label,
    required this.data,
    required this.labelColor,
    required this.dataColor,
    this.lastItem = false,
  });

  final String label;
  final String data;
  final Color labelColor;
  final Color dataColor;
  final bool? lastItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: labelColor,
              ),
            ),
            Flexible(
              child: Text(
                data,
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: dataColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (lastItem != null && !lastItem!) ...[
          const Divider(color: AppColors.dividerColor, height: 20),
        ],
        if (lastItem != null && lastItem!) ...[const SizedBox(height: 15)],
      ],
    );
  }
}