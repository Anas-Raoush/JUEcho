import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

class FeedbackAdminReplySection extends StatelessWidget {
  final List<FeedbackReply> adminReplies;

  const FeedbackAdminReplySection({
    super.key,
    required this.adminReplies,
  });

  @override
  Widget build(BuildContext context) {
    final hasReplies = adminReplies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin reply',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grayBorder),
          ),
          child: hasReplies
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < adminReplies.length; i++) ...[
                Text(
                  '${i + 1}) ${adminReplies[i].message}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (i != adminReplies.length - 1)
                  const SizedBox(height: 4),
              ],
            ],
          )
              : const Text(
            'No reply from admin yet.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}