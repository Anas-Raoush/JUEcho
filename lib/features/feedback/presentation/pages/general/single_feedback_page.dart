import 'package:flutter/material.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:provider/provider.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/presentation/providers/single_submission_provider.dart';
import 'package:juecho/features/feedback/presentation/utils/attachment_actions.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/single_feedback/feedback_edit_actions_row.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/single_feedback/feedback_text_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/conversation_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_attachment_actions.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_meta_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_rating_section.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';

/// General user page: detailed view for a single feedback submission.
///
/// Data source:
/// - Uses [SingleSubmissionProvider] to load + update the submission.
/// - Provider already depends on [AuthProvider] for profile data when needed.
///
/// UX:
/// - Shows meta, content, admin replies, user replies, rating, attachments.
/// - Prevents double sending of replies using local and provider locks.
///
/// Responsive:
/// - The content is centered and constrained to a max width on wide screens.
/// - No logic changes, only layout wrappers.
class SingleFeedbackPage extends StatefulWidget {
  const SingleFeedbackPage({super.key});

  static const routeName = '/general-feedback-details';

  @override
  State<SingleFeedbackPage> createState() => _SingleFeedbackPageState();
}

class _SingleFeedbackPageState extends State<SingleFeedbackPage> {
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _suggestionCtrl = TextEditingController();
  final _userReplyCtrl = TextEditingController();

  bool _didInitForm = false;
  bool _sendingUserReply = false;
  bool _isDeleting = false;

  int _rating = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _suggestionCtrl.dispose();
    _userReplyCtrl.dispose();
    super.dispose();
  }

  void _initFormOnce(SingleSubmissionProvider p) {
    final s = p.submission;
    if (s == null) return;

    if (!_didInitForm) {
      _titleCtrl.text = s.title ?? '';
      _descriptionCtrl.text = s.description ?? '';
      _suggestionCtrl.text = s.suggestion ?? '';
      _rating = s.rating;
      _didInitForm = true;
    }
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SingleSubmissionProvider>(
      builder: (context, p, _) {
        _initFormOnce(p);

        final s = p.submission;
        final canEdit = s?.canEditOrDelete ?? false;

        Future<void> previewAttachment() async {
          if (s?.attachmentKey == null) return;
          await AttachmentActions.previewAttachment(
            context: context,
            attachmentKey: s!.attachmentKey!,
          );
        }

        Future<void> downloadAttachment() async {
          if (s?.attachmentKey == null) return;
          await AttachmentActions.downloadAttachment(
            context: context,
            attachmentKey: s!.attachmentKey!,
          );
        }

        Future<void> saveEdits() async {
          if (s == null) return;

          if (!canEdit) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "This feedback cannot be edited because its status isn't submitted",
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          final title = _titleCtrl.text.trim();
          final description = _descriptionCtrl.text.trim();

          // REQUIRED FIELD VALIDATION
          if (title.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Title cannot be empty'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          if (description.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Description cannot be empty'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          try {
            await p.saveUserEdits(
              title: title,
              description: description,
              suggestion: _suggestionCtrl.text.trim(),
              rating: _rating,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Changes saved'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not save changes. Please try again later'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        Future<void> deleteSubmission() async {
          if (s == null) return;
          if (!canEdit) return;
          if (_isDeleting) return;




          final confirmed =
              await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete feedback'),
                  content:
                  const Text('Are you sure you want to delete this feedback?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.red),
                      ),
                    ),
                  ],
                ),
              ) ??
                  false;

          if (!confirmed) return;
          setState(() => _isDeleting = true);
          try {
            await p.deleteAsUser();
            if (!mounted) return;
            Navigator.pop(context);
          } catch (_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not delete feedback. Please try again later'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }

        Future<void> sendReply() async {
          if (s == null) return;

          if (_sendingUserReply) return;
          if (p.isSending) return;

          final text = _userReplyCtrl.text.trim();
          if (text.isEmpty) return;

          setState(() => _sendingUserReply = true);

          try {
            await p.sendUserReply(text);

            if (!mounted) return;
            _userReplyCtrl.clear();

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reply sent'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            if (!mounted) return;

            final msg = e.toString();
            if (msg.contains('admin has replied')) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You can only reply after an admin has replied to this submission',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Could not send reply. Please try again later.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } finally {
            if (mounted) setState(() => _sendingUserReply = false);
          }
        }

        // Responsive rules (center + max width).
        final w = MediaQuery.of(context).size.width;
        final maxWidth = w >= 600 ? 600.0 : w >= 900 ? 900.0 : double.infinity;

        return GeneralScaffoldWithMenu(
          body: (p.isLoading && s == null)
              ? const Center(child: CircularProgressIndicator())
              : (s == null)
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Feedback not found.',
                  style: TextStyle(color: AppColors.red),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => p.load(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
              : Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageTitle(title: 'Feedback details'),
                    ErrorMessage(error: p.error),

                    FeedbackMetaSection(
                      serviceCategoryLabel: s.serviceCategory.label,
                      submittedAt: _formatDate(s.createdAt),
                    ),
                    const SizedBox(height: 16),

                    FeedbackTextSection(
                      titleController: _titleCtrl,
                      descriptionController: _descriptionCtrl,
                      suggestionController: _suggestionCtrl,
                      canEdit: canEdit,
                    ),
                    const SizedBox(height: 16),

                    ConversationSection(
                      title: 'Admin reply',
                      messages: s.adminReplies,
                      canReply: false,
                    ),
                    const SizedBox(height: 16),

                    ConversationSection(
                      title: 'User reply',
                      messages: s.userReplies,
                      canReply: s.adminReplies.isNotEmpty,
                      controller: _userReplyCtrl,
                      isSending: p.isSending || _sendingUserReply,
                      onSend: sendReply,
                      inputHint: s.adminReplies.isEmpty
                          ? 'Wait for admin reply first'
                          : 'Write a message',
                      sendLabel: 'Send reply',
                    ),
                    const SizedBox(height: 16),

                    FeedbackRatingSection(
                      rating: _rating,
                      canEdit: canEdit,
                      onChanged: (value) {
                        if (!canEdit) return;
                        setState(() => _rating = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (s.attachmentKey != null) ...[
                      FeedbackAttachmentActions(
                        onPreview: previewAttachment,
                        onDownload: downloadAttachment,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (canEdit) ...[
                      FeedbackEditActionsRow(
                        isSaving: p.isSending,
                        isDeleting: _isDeleting,
                        onSave: saveEdits,
                        onDelete: deleteSubmission,
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}