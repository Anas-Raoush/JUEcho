import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';
import 'package:juecho/features/feedback/presentation/providers/single_submission_provider.dart';
import 'package:juecho/features/feedback/presentation/utils/attachment_actions.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/single_feedback/admin_feedback_actions_row.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/single_feedback/admin_feedback_status_urgency_notes_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/admin/single_feedback/admin_feedback_text_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/conversation_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_attachment_actions.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_meta_section.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/feedback_rating_section.dart';
import 'package:juecho/features/home/presentation/widgets/admin/admin_scaffold_with_menu.dart';

/// Admin page: detailed view for a single feedback submission.
///
/// Responsibilities:
/// - Uses [SingleSubmissionProvider] for loading + updates.
/// - Allows:
///   - sending admin reply
///   - saving status/urgency/notes
///   - deleting submission
///
/// Responsive:
/// - Uses [LayoutBuilder] to constrain width on large screens.
/// - Keeps content pinned to the top (no vertical centering).
///
/// Validation (UI-only):
/// - Status is required.
/// - Urgency is required.
/// - Save is blocked until both are selected.
class AdminSingleSubmissionPage extends StatefulWidget {
  const AdminSingleSubmissionPage({super.key});

  static const routeName = '/admin-feedback-details';

  @override
  State<AdminSingleSubmissionPage> createState() =>
      _AdminSingleSubmissionPageState();
}

class _AdminSingleSubmissionPageState extends State<AdminSingleSubmissionPage> {
  // Keep controllers locally (UI state)
  final _internalNotesCtrl = TextEditingController();
  final _adminReplyCtrl = TextEditingController();

  // Local selected fields (UI state)
  FeedbackStatusCategories? _selectedStatus;
  int? _selectedUrgency;

  bool _sendingAdminReply = false;

  /// UI-only validation switch: after the first save attempt,
  /// show inline errors + snack bar if required fields are missing.
  bool _triedSave = false;

  bool _isDeleting = false;

  @override
  void dispose() {
    _internalNotesCtrl.dispose();
    _adminReplyCtrl.dispose();
    super.dispose();
  }

  // ---------- responsive helpers ----------

  double _maxWidthFor(double w) {
    if (w >= 1200) return 900;
    if (w >= 900) return 820;
    if (w >= 700) return 650;
    return double.infinity;
  }

  EdgeInsets _pagePaddingFor(double w) {
    final horizontal = w < 380 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: 4);
  }

  // ---------- helpers ----------

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _previewAttachment(
      BuildContext context,
      FeedbackSubmission s,
      ) async {
    if (s.attachmentKey == null) return;
    await AttachmentActions.previewAttachment(
      context: context,
      attachmentKey: s.attachmentKey!,
    );
  }

  Future<void> _downloadAttachment(
      BuildContext context,
      FeedbackSubmission s,
      ) async {
    if (s.attachmentKey == null) return;
    await AttachmentActions.downloadAttachment(
      context: context,
      attachmentKey: s.attachmentKey!,
    );
  }

  bool _isMetaValid() => _selectedStatus != null && _selectedUrgency != null;

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWithMenu(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final maxWidth = _maxWidthFor(w);

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Consumer<SingleSubmissionProvider>(
                builder: (context, p, _) {
                  // ---- loading state ----
                  if (p.isLoading && p.submission == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // ---- not found ----
                  if (p.submission == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'Feedback not found.',
                          style: TextStyle(color: AppColors.red),
                        ),
                      ),
                    );
                  }

                  final s = p.submission!;

                  // One-time init of UI fields when data arrives first time
                  if (_selectedStatus == null) _selectedStatus = s.status;
                  if (_selectedUrgency == null) _selectedUrgency = s.urgency;

                  if (_internalNotesCtrl.text.isEmpty &&
                      (s.internalNotes ?? '').isNotEmpty) {
                    _internalNotesCtrl.text = s.internalNotes ?? '';
                  }

                  // Inline validation messages (UI-only)
                  final statusError = (_triedSave && _selectedStatus == null)
                      ? 'Status is required'
                      : null;

                  final urgencyError = (_triedSave && _selectedUrgency == null)
                      ? 'Urgency is required'
                      : null;

                  Future<void> deleteSubmission() async {
                    if (_isDeleting) return;

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

                    setState(() => _isDeleting = true);

                    try {
                      // ✅ Admin delete
                      await p.deleteAsAdmin();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Feedback deleted'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      Navigator.pop(context); // go back after delete
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not delete feedback. Please try again later'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } finally {
                      if (mounted) setState(() => _isDeleting = false);
                    }
                  }

                  return SingleChildScrollView(
                    padding: _pagePaddingFor(w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const PageTitle(title: 'Feedback details'),
                        ErrorMessage(error: p.error),

                        FeedbackMetaSection(
                          serviceCategoryLabel: s.serviceCategory.label,
                          submittedAt: _formatDate(s.createdAt),
                          statusLabel: s.status.label,
                          ownerName: s.updatedByName,
                        ),
                        const SizedBox(height: 16),

                        AdminFeedbackTextSection(
                          title: s.title ?? '',
                          description: s.description ?? '',
                          suggestion: s.suggestion ?? '',
                        ),
                        const SizedBox(height: 16),

                        FeedbackRatingSection(rating: s.rating, canEdit: false),
                        const SizedBox(height: 16),

                        ConversationSection(
                          title: 'User replies',
                          messages: s.userReplies,
                        ),
                        const SizedBox(height: 16),

                        ConversationSection(
                          title: 'Admin reply',
                          messages: s.adminReplies,
                          canReply: true,
                          controller: _adminReplyCtrl,
                          isSending: p.isSending || _sendingAdminReply,
                          onSend: () async {
                            if (_sendingAdminReply) return;
                            if (p.isSending) return;

                            final text = _adminReplyCtrl.text.trim();
                            if (text.isEmpty) return;

                            setState(() => _sendingAdminReply = true);

                            try {
                              await p.sendAdminReply(text);
                              _adminReplyCtrl.clear();

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reply sent'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _sendingAdminReply = false);
                              }
                            }
                          },
                          inputHint: 'Write a message',
                          sendLabel: 'Send reply',
                        ),
                        const SizedBox(height: 16),

                        AdminFeedbackStatusUrgencyNotesSection(
                          selectedStatus: _selectedStatus,
                          onStatusChanged: (value) {
                            setState(() => _selectedStatus = value);
                          },
                          selectedUrgency: _selectedUrgency,
                          onUrgencyChanged: (value) {
                            setState(() => _selectedUrgency = value);
                          },
                          internalNotesController: _internalNotesCtrl,

                          statusError: statusError,
                          urgencyError: urgencyError,
                        ),
                        const SizedBox(height: 16),

                        if (s.attachmentKey != null) ...[
                          FeedbackAttachmentActions(
                            onPreview: () => _previewAttachment(context, s),
                            onDownload: () => _downloadAttachment(context, s),
                          ),
                          const SizedBox(height: 16),
                        ],

                        AdminFeedbackActionsRow(
                          isSaving: p.isSending,
                          isDeleting: _isDeleting,
                          onSave: () async {
                            setState(() => _triedSave = true);

                            if (!_isMetaValid()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please select both Status and Urgency before saving.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            await p.saveAdminMeta(
                              status: _selectedStatus!,
                              urgency: _selectedUrgency,
                              internalNotes: _internalNotesCtrl.text,
                            );
                          },
                          onDelete: deleteSubmission,
                        ),
                        const SizedBox(height: 16),

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
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}