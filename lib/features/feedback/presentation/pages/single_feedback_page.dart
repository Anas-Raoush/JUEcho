// lib/features/feedback/presentation/pages/single_feedback_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:juecho/features/feedback/presentation/widgets/image_preview_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_meta_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_text_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_admin_reply_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_user_reply_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_rating_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_attachment_actions.dart';
import 'package:juecho/features/feedback/presentation/widgets/single_feedback/feedback_edit_actions_row.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';

class SingleFeedbackPage extends StatefulWidget {
  const SingleFeedbackPage({super.key});

  static const routeName = '/general-feedback-details';

  @override
  State<SingleFeedbackPage> createState() => _SingleFeedbackPageState();
}

class _SingleFeedbackPageState extends State<SingleFeedbackPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_submission == null && _isLoading) {
      final id = ModalRoute.of(context)!.settings.arguments as String;
      _load(id);
    }
  }

  FeedbackSubmission? _submission;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isReplying = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _suggestionCtrl = TextEditingController();
  final _userReplyCtrl = TextEditingController();

  int _rating = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _suggestionCtrl.dispose();
    _userReplyCtrl.dispose();
    super.dispose();
  }

  bool get _canEdit => _submission?.canEditOrDelete ?? false;

  FeedbackSubmission get _s => _submission!;

  Future<void> _load(String id) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sub = await FeedbackRepository.fetchSubmissionById(id);
      _submission = sub;
      _titleCtrl.text = sub.title ?? '';
      _descriptionCtrl.text = sub.description ?? '';
      _suggestionCtrl.text = sub.suggestion ?? '';
      _rating = sub.rating;
    } catch (e) {
      _error = 'Could not load feedback details.';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _saveEdits() async {
    if (!_canEdit) {
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

    setState(() {
      _isSaving = true;
    });

    try {
      final updated = _s.copyWith(
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim().isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
        suggestion: _suggestionCtrl.text.trim().isEmpty
            ? null
            : _suggestionCtrl.text.trim(),
        rating: _rating,
      );

      final result = await FeedbackRepository.updateSubmissionAsUser(updated);
      if (!mounted) return;
      setState(() {
        _submission = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Changes saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save changes. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete() async {
    if (!_canEdit) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete feedback'),
            content: const Text(
              'Are you sure you want to delete this feedback?',
            ),
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

    setState(() {
      _isDeleting = true;
    });

    try {
      await FeedbackRepository.deleteSubmissionAsUser(_s);
      if (!mounted) return;
      Navigator.pop(context); // back to list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete feedback. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _previewAttachment() async {
    if (_s.attachmentKey == null) return;

    try {
      final bytes = await FeedbackRepository.downloadAttachmentBytes(
        _s.attachmentKey!,
      );
      if (bytes == null || !mounted) return;

      await showDialog(
        context: context,
        builder: (_) {
          return ImagePreviewDialog(
            title: 'Attachment preview',
            image: Image.memory(bytes, fit: BoxFit.contain),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not preview attachment.')),
      );
    }
  }

  Future<void> _downloadAttachmentToFile() async {
    if (_s.attachmentKey == null) return;

    try {
      final bytes = await FeedbackRepository.downloadAttachmentBytes(
        _s.attachmentKey!,
      );
      if (bytes == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final fileName = _s.attachmentKey!.split('/').last;
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded to: ${file.path}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not download attachment.')),
      );
    }
  }

  Future<void> _sendReply() async {
    final text = _userReplyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isReplying = true;
    });

    try {
      final updated = await FeedbackRepository.addUserReply(
        current: _s,
        message: text,
      );
      if (!mounted) return;
      setState(() {
        _submission = updated;
        _userReplyCtrl.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if(e.toString().contains('admin has replied')){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can only reply after an admin has replied to this submission.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not send reply. Please try again later.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GeneralScaffoldWithMenu(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _submission == null
          ? const Center(
              child: Text(
                'Feedback not found.',
                style: TextStyle(color: AppColors.red),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PageTitle(title: 'Feedback details'),
                  ErrorMessage(error: _error),
                  // Service category + date
                  FeedbackMetaSection(
                    serviceCategoryLabel: _s.serviceCategory.label,
                    submittedAt: _formatDate(_s.createdAt),
                  ),
                  const SizedBox(height: 16),

                  // Title / Description / Suggestion
                  FeedbackTextSection(
                    titleController: _titleCtrl,
                    descriptionController: _descriptionCtrl,
                    suggestionController: _suggestionCtrl,
                    canEdit: _canEdit,
                  ),
                  const SizedBox(height: 16),

                  // Admin reply
                  FeedbackAdminReplySection(adminReplies: _s.adminReplies),
                  const SizedBox(height: 16),

                  // User reply
                  FeedbackUserReplySection(
                    controller: _userReplyCtrl,
                    isReplying: _isReplying,
                    onSendReply: _sendReply,
                    previousReplies: _s.userReplies,
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  FeedbackRatingSection(
                    rating: _rating,
                    canEdit: _canEdit,
                    onChanged: (value) {
                      if (!_canEdit) return;
                      setState(() => _rating = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Attachment actions
                  if (_s.attachmentKey != null) ...[
                    FeedbackAttachmentActions(
                      onPreview: _previewAttachment,
                      onDownload: _downloadAttachmentToFile,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Save / Delete actions
                  if (_canEdit) ...[
                    FeedbackEditActionsRow(
                      isSaving: _isSaving,
                      isDeleting: _isDeleting,
                      onSave: _saveEdits,
                      onDelete: _delete,
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
    );
  }
}
