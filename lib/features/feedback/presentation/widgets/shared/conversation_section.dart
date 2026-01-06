import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

/// Generic conversation section used by both GENERAL and ADMIN.
///
/// - Shows a title
/// - Shows a numbered list of messages (if any)
/// - Optionally shows a reply input + send button
class ConversationSection extends StatelessWidget {
  final String title;
  final List<FeedbackReply> messages;

  /// If true and [controller]/[onSend] are provided,
  /// a reply input area + button will be shown.
  final bool canReply;

  /// Only used when [canReply] is true.
  final TextEditingController? controller;
  final bool isSending;
  final VoidCallback? onSend;

  /// Optional UI strings for the input area.
  final String inputHint;
  final String sendLabel;

  const ConversationSection({
    super.key,
    required this.title,
    required this.messages,
    this.canReply = false,
    this.controller,
    this.isSending = false,
    this.onSend,
    this.inputHint = 'Any reply',
    this.sendLabel = 'Send reply',
  });

  @override
  Widget build(BuildContext context) {
    final hasMessages = messages.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),

        // Previous messages list
        if (hasMessages) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < messages.length; i++) ...[
                  Text(
                    '${i + 1}) ${messages[i].message}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (i != messages.length - 1)
                    const SizedBox(height: 4),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ] else ...[
          const Text(
            'No previous messages',
            style: TextStyle(color: AppColors.gray),
          ),
          const SizedBox(height: 8),
        ],

        // Reply input area (only when canReply + controller + onSend are provided)
        if (canReply && controller != null && onSend != null) ...[
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary),
              ),
              hintText: inputHint,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: isSending ? null : onSend,
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
              child: isSending
                  ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
                  : Text(sendLabel),
            ),
          ),
        ],
      ],
    );
  }
}