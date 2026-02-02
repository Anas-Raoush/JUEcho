import 'dart:io';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/feedback/data/repositories/general_repositories/general_submissions_repository.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/category_dropdown.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/description_field.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/rating_and_attachment_row.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/submit_button.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/suggestion_field.dart';
import 'package:juecho/features/feedback/presentation/widgets/general/submit_feedback_page/title_field.dart';
import 'package:juecho/features/feedback/presentation/widgets/shared/image_preview_dialog.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';

/// submit_feedback_page.dart
///
/// General user page: create a new feedback submission.
///
/// Features:
/// - Form validation + required category
/// - Optional image attachment using FilePicker + S3 upload
/// - Uses AuthProvider.profile for userId, Cognito identityId for S3 path
/// - Shows upload spinner while uploading
/// - Responsive: center form + max width on wide screens
///
/// Fix applied:
/// - maxWidth rule order was wrong (w >= 600 would catch 900+ too).
class SubmitFeedbackPage extends StatefulWidget {
  const SubmitFeedbackPage({super.key});

  static const routeName = '/general-submit-feedback';

  @override
  State<SubmitFeedbackPage> createState() => _SubmitFeedbackPageState();
}

class _SubmitFeedbackPageState extends State<SubmitFeedbackPage> {
  final _formKey = GlobalKey<FormState>();

  ServiceCategories? _selectedCategory;
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _suggestionCtrl = TextEditingController();

  int _rating = 3;

  PlatformFile? _attachedImageFile;
  String? _attachmentKey;
  bool _isUploadingImage = false;

  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _suggestionCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAttachImagePressed() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (!mounted) return;

      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
        return;
      }

      setState(() {
        _attachedImageFile = file;
        _attachmentKey = null; // reset (will upload again)
      });
    } catch (e) {
      safePrint('Pick image error: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image')),
      );
    }
  }

  Future<void> _onPreviewImagePressed() async {
    final file = _attachedImageFile;
    if (file == null || file.path == null) return;

    await showDialog(
      context: context,
      builder: (_) => ImagePreviewDialog(
        title: file.name,
        image: Image.file(File(file.path!), fit: BoxFit.contain),
      ),
    );
  }

  void _onRemoveImagePressed() {
    setState(() {
      _attachedImageFile = null;
      _attachmentKey = null;
    });
  }

  Future<String?> _uploadIfNeeded({
    required String identityId,
    required String userId,
  }) async {
    final file = _attachedImageFile;
    if (file == null || file.path == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final key = 'incoming/$identityId/$userId/${timestamp}_${file.name}';

    try {
      setState(() => _isUploadingImage = true);

      final awsFile = AWSFile.fromPath(file.path!);

      final uploadResult = await Amplify.Storage.uploadFile(
        localFile: awsFile,
        path: StoragePath.fromString(key),
      ).result;

      final uploadedKey = uploadResult.uploadedItem.path;
      _attachmentKey = uploadedKey;
      return uploadedKey;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCategory == null) {
      setState(() => _error = 'Please select a service category.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final profile = auth.profile;

    if (profile == null || profile.userId.isEmpty) {
      setState(() => _error = 'Your session is not ready. Please sign in again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final identityId = session.identityIdResult.value;

      final attachmentKey = await _uploadIfNeeded(
        identityId: identityId,
        userId: profile.userId,
      );

      final title = _titleCtrl.text.trim();
      final description = _descriptionCtrl.text.trim();
      final suggestion = _suggestionCtrl.text.trim();

      await GeneralSubmissionsRepository.createSubmission(
        category: _selectedCategory!,
        rating: _rating,
        title: title.isEmpty ? null : title,
        description: description.isEmpty ? null : description,
        suggestion: suggestion.isEmpty ? null : suggestion,
        attachmentKey: attachmentKey,
        profile: profile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      safePrint('Submit feedback error: $e');
      if (!mounted) return;

      setState(() {
        _error = 'Could not submit feedback. Please try again later.';
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive: center + max width.
    final w = MediaQuery.of(context).size.width;
    final maxWidth = w >= 900
        ? 900.0
        : w >= 600
        ? 600.0
        : double.infinity;

    return GeneralScaffoldWithMenu(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                const PageTitle(title: 'Submit Feedback'),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ErrorMessage(error: _error),

                      CategoryDropdown(
                        selectedCategory: _selectedCategory,
                        onChanged: (value) =>
                            setState(() => _selectedCategory = value),
                        decoration: _inputDecoration('Select service category'),
                      ),
                      const SizedBox(height: 16),

                      TitleField(
                        titleCtrl: _titleCtrl,
                        decoration: _inputDecoration('Title'),
                      ),
                      const SizedBox(height: 16),

                      DescriptionField(
                        decoration: _inputDecoration('Describe your experience'),
                        descriptionCtrl: _descriptionCtrl,
                      ),
                      const SizedBox(height: 16),

                      SuggestionField(
                        suggestionCtrl: _suggestionCtrl,
                        decoration: _inputDecoration(
                          'Any suggestion for improvement? (optional)',
                        ),
                      ),
                      const SizedBox(height: 24),

                      RatingAndAttachmentRow(
                        rating: _rating,
                        onRatingChanged: (value) => setState(() => _rating = value),
                        isUploadingImage: _isUploadingImage,
                        attachedImageFile: _attachedImageFile,
                        onAttachImagePressed: _onAttachImagePressed,
                        onPreviewImagePressed: _onPreviewImagePressed,
                        onRemoveImagePressed: _onRemoveImagePressed,
                      ),
                      const SizedBox(height: 32),

                      SubmitButton(
                        isSubmitting: _isSubmitting,
                        onPressed: _onSubmit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}