import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/common/widgets/page_title.dart';
import 'package:juecho/features/feedback/presentation/widgets/image_preview_dialog.dart';
import 'package:juecho/features/home/presentation/widgets/general/general_scaffold_with_menu.dart';
import 'package:juecho/features/feedback/data/feedback_repository.dart';


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
        withData: false, // we’ll use the path
          /*This means:

      Do NOT load file into memory

      Only give the file path

      Best for large files (faster & safer)

      If you set withData: true, then:

    file.bytes contains raw data (Uint8List)

    You wouldn't need File(file.path!)*/
      );

      if (result == null || result.files.isEmpty) {
        return; // user cancelled
      }
      /*PlatformFile {
        String name;        // filename only (e.g., "photo.png")
        String? path;       // full path on device (e.g., "/storage/emulated/0/DCIM/photo.png")
        Uint8List? bytes;   // file bytes (only if withData: true)
        int size;           // in bytes
        String? extension;  // file extension
      }*/
      final file = result.files.single;
      if(!mounted) return;
      if (file.path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read selected file')),
        );
        return;
      }


      setState(() {
        // Only keep it locally for now – no upload yet
        _attachedImageFile = file;
        _attachmentKey = null; // reset any previous upload
      });
    } catch (e) {
      safePrint('Pick image error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not pick image')));
    }
  }

  Future<void> _onPreviewImagePressed() async {
    final file = _attachedImageFile;
    if (file == null || file.path == null) return;

    await showDialog(
      context: context,
      builder: (_) {
        return ImagePreviewDialog(
          title: file.name,
          image: Image.file(
            File(file.path!),
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }

  void _onRemoveImagePressed() {
    setState(() {
      _attachedImageFile = null;
      _attachmentKey = null;
    });
  }



  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      // 1) Upload image only if user actually attached one
      String? attachmentKey;
      if (_attachedImageFile != null && _attachedImageFile!.path != null) {
        final file = _attachedImageFile!;
        final key =
            'incoming/${DateTime.now().millisecondsSinceEpoch}_${file.name}';

        final awsFile = AWSFile.fromPath(file.path!);

        setState(() => _isUploadingImage = true);
        final uploadResult = await Amplify.Storage.uploadFile(
          localFile: awsFile,
          path: StoragePath.fromString(key),
        ).result;
        setState(() => _isUploadingImage = false);

        attachmentKey = uploadResult.uploadedItem.path;
        _attachmentKey = attachmentKey;
      }

      // 2) Gather the rest of the fields
      final category = _selectedCategory!;
      final title = _titleCtrl.text.trim();
      final description = _descriptionCtrl.text.trim();
      final suggestion = _suggestionCtrl.text.trim();
      final rating = _rating;

      // 3) Call repository to actually create the submission
      await FeedbackRepository.createSubmission(
        category: category,
        rating: rating,
        title: title,
        description: description,
        suggestion: suggestion.isEmpty ? null : suggestion,
        attachmentKey: attachmentKey,
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GeneralScaffoldWithMenu(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            const PageTitle(title: 'Submit Feedback'),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorMessage(error: _error,),
                  _buildCategoryField(context),
                  const SizedBox(height: 16),
                  _buildTitleField(context),
                  const SizedBox(height: 16),
                  _buildDescriptionField(context),
                  const SizedBox(height: 16),
                  _buildSuggestionField(context),
                  const SizedBox(height: 24),
                  _buildRatingAndAttachmentRow(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------
  // SMALL BUILD HELPERS
  // -----------------------

  Widget _buildCategoryField(BuildContext context) {
    return DropdownButtonFormField<ServiceCategories>(
      initialValue: _selectedCategory,
      decoration: _inputDecoration(context, 'Select service category'),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
      items: ServiceCategories.values
          .map(
            (c) => DropdownMenuItem<ServiceCategories>(
          value: c,
          child: Text(c.label),
        ),
      )
          .toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      validator: (value) {
        if (value == null) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextFormField(
      controller: _titleCtrl,
      maxLength: 100,
      textInputAction: TextInputAction.next,
      decoration: _inputDecoration(context, 'Title'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(BuildContext context) {
    return TextFormField(
      controller: _descriptionCtrl,
      textInputAction: TextInputAction.newline,
      minLines: 3,
      maxLines: 5,
      decoration: _inputDecoration(context, 'Describe your experience'),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildSuggestionField(BuildContext context) {
    return TextFormField(
      controller: _suggestionCtrl,
      textInputAction: TextInputAction.newline,
      minLines: 2,
      maxLines: 4,
      decoration: _inputDecoration(
        context,
        'Any suggestion for improvement? (optional)',
      ),
    );
  }

  Widget _buildRatingAndAttachmentRow() {
    return Row(
      children: [
        _buildRatingSection(),
        const SizedBox(width: 25),
        _buildAttachmentSection(),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        Text(
          'Overall rating',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = starIndex <= _rating;
            return IconButton(
              onPressed: () => setState(() => _rating = starIndex),
              icon: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: isSelected ? AppColors.primary : AppColors.gray,
                size: 28,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: _isUploadingImage ? null : _onAttachImagePressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isUploadingImage
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          )
              : Text(
            _attachedImageFile == null ? 'Attach Image' : 'Change Image',
          ),
        ),
        const SizedBox(width: 8),
        if (_attachedImageFile != null) ...[
          TextButton(
            onPressed: _onPreviewImagePressed,
            child: const Text('Preview'),
          ),
          IconButton(
            onPressed: _onRemoveImagePressed,
            tooltip: 'Remove image',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        )
            : const Text('Submit'),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
    );
  }
}