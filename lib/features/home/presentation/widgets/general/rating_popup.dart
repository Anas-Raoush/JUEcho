import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';

/// RatingPopup
///
/// Modal dialog that collects a rating-only submission from the user.
///
/// Inputs:
/// - ServiceCategories selection (required)
/// - Star rating from 1..5 (default = 3)
///
/// Submission:
/// - Delegates the actual persistence logic to the parent via onSubmit callback.
/// - Disables UI while submission is in progress to prevent duplicate requests.
///
/// Layout:
/// - Uses ConstrainedBox(maxWidth: 420) for desktop/web.
/// - Uses SingleChildScrollView to avoid overflow on small screens.
class RatingPopup extends StatefulWidget {
  const RatingPopup({super.key, required this.onSubmit});

  final Future<void> Function({
  required ServiceCategories category,
  required int rating,
  }) onSubmit;

  @override
  State<RatingPopup> createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup> {
  final _formKey = GlobalKey<FormState>();

  ServiceCategories? _selectedCategory;
  int _rating = 3;

  bool _isSubmitting = false;

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    final category = _selectedCategory!;
    final rating = _rating;

    try {
      await widget.onSubmit(category: category, rating: rating);
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Submit Rating',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ServiceCategories>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  items: ServiceCategories.values
                      .map(
                        (c) => DropdownMenuItem<ServiceCategories>(
                      value: c,
                      child: Text(
                        c.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  validator: (value) =>
                  value == null ? 'Please select a service' : null,
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Rating',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isSelected = starIndex <= _rating;

                        return IconButton(
                          onPressed: () => setState(() => _rating = starIndex),
                          icon: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color:
                            isSelected ? AppColors.primary : AppColors.gray,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Submit'),
        ),
      ],
    );
  }
}