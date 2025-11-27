import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

class FeedbackUserReplySection extends StatelessWidget {
  final TextEditingController controller;
  final bool isReplying;
  final VoidCallback onSendReply;
  final List<FeedbackReply> previousReplies;

  const FeedbackUserReplySection({
    super.key,
    required this.controller,
    required this.isReplying,
    required this.onSendReply,
    required this.previousReplies,
  });

  @override
  Widget build(BuildContext context) {
    final hasReplies = previousReplies.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User reply',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),

        // 👇 show previous user replies (conversation-style)
        if (hasReplies) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < previousReplies.length; i++) ...[
                  Text(
                    '${i + 1}) ${previousReplies[i].message}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (i != previousReplies.length - 1)
                    const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Input for new reply
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            hintText: 'Any reply',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: isReplying ? null : onSendReply,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isReplying
                ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
                : const Text('Send reply'),
          ),
        ),
      ],
    );
  }
}
