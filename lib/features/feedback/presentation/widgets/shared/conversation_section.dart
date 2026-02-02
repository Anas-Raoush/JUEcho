import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

/// Conversation timeline section used by both general and admin submission pages.
///
/// Responsibilities
/// - Renders a section [title].
/// - Shows previous messages in a bordered container when available.
/// - Shows a fallback text when there are no messages.
/// - Optionally renders a reply input area and send button.
///
/// Reply mode
/// - Enabled when [canReply] is true AND [controller] and [onSend] are not null.
/// - Disables send action when [isSending] is true.
/// - Allows customizing placeholder and button label via [inputHint] and [sendLabel].
class ConversationSection extends StatelessWidget {
  /// Section title displayed above the messages container.
  final String title;

  /// Replies list rendered in order.
  final List<FeedbackReply> messages;

  /// Controls whether the input UI can be shown.
  ///
  /// Input UI is rendered only if this is true and both [controller] and [onSend]
  /// are provided.
  final bool canReply;

  /// Controller used by the reply text field.
  final TextEditingController? controller;

  /// True when sending is in progress.
  final bool isSending;

  /// Callback invoked when the send button is pressed.
  final VoidCallback? onSend;

  /// Placeholder text for the reply input field.
  final String inputHint;

  /// Label for the send button.
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
                  if (i != messages.length - 1) const SizedBox(height: 4),
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

        // Reply input area
        if (canReply && controller != null && onSend != null) ...[
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
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