import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';

class RatingPopup extends StatefulWidget {
  const RatingPopup({super.key, required this.onSubmit});

  final void Function({
    required ServiceCategories category,
    required int rating,
  })
  onSubmit;

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

    widget.onSubmit(category: category, rating: rating);

    if (!mounted) return;
    Navigator.of(context).pop(); // Close the dialog after submit
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
        // avoid huge width on desktop, helps layout in general
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category dropdown
                DropdownButtonFormField<ServiceCategories>(
                  initialValue: _selectedCategory,
                  isExpanded: true, // <-- IMPORTANT to avoid horizontal overflow
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
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Please select a service';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Star rating
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
                          onPressed: () {
                            setState(() => _rating = starIndex);
                          },
                          icon: Icon(
                            isSelected ? Icons.star : Icons.star_border,
                            color: isSelected ? AppColors.primary : AppColors.gray,
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
