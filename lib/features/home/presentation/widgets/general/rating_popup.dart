import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/service_categories.dart';

/// A popup dialog that lets the user submit a quick rating for a selected service.
///
/// What it does:
/// - Opens as an [AlertDialog].
/// - User must select a [ServiceCategories] value (required).
/// - User selects a rating from 1 to 5 stars (default = 3).
/// - On submit:
///   - validates the form (service must be selected)
///   - disables buttons while submitting
///   - calls [onSubmit] callback passed from the parent
///
/// Notes:
/// - The dialog content is scrollable via [SingleChildScrollView] to avoid overflow
///   on small screens.
/// - Uses [ConstrainedBox] to keep the dialog from becoming too wide on desktop/web.
class RatingPopup extends StatefulWidget {
  const RatingPopup({super.key, required this.onSubmit});

  /// Callback executed when the user taps "Submit" and the form is valid.
  ///
  /// The parent provides what happens next (e.g., calling repository / API).
  final Future<void> Function({
  required ServiceCategories category,
  required int rating,
  }) onSubmit;

  @override
  State<RatingPopup> createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup> {
  /// Form key used to validate the dropdown field (service selection).
  final _formKey = GlobalKey<FormState>();

  /// Selected service category.
  /// - null until the user chooses a service.
  ServiceCategories? _selectedCategory;

  /// Current selected rating (1–5).
  /// Default is 3 to give a reasonable starting value.
  int _rating = 3;

  /// Prevents double submission and disables UI while the request is running.
  bool _isSubmitting = false;

  /// Validate + submit the rating.
  ///
  /// Steps:
  /// 1) Validate the form (service must be selected).
  /// 2) Lock the UI (_isSubmitting = true).
  /// 3) Call parent callback [widget.onSubmit].
  /// 4) Unlock UI in finally (even if an exception happens).
  Future<void> _handleSubmit() async {
    // If the form isn't valid, do nothing.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Lock UI.
    setState(() => _isSubmitting = true);

    // Safe because validator guarantees it's not null.
    final category = _selectedCategory!;
    final rating = _rating;

    try {
      // Delegate submission logic to parent.
      await widget.onSubmit(category: category, rating: rating);

      // If the dialog got closed while waiting, stop.
      if (!mounted) return;
    } finally {
      // Always unlock UI if still mounted.
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Custom theme colors.
      backgroundColor: AppColors.white,

      // Space around dialog to ensure it doesn't touch screen edges.
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),

      // Rounded dialog shape.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      // Dialog title.
      title: const Text(
        'Submit Rating',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),

      // Dialog main content.
      content: ConstrainedBox(
        // Keeps dialog from becoming huge on desktop/web.
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            // Scrollable content prevents vertical overflow on small devices.
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------- Service dropdown ----------------
                DropdownButtonFormField<ServiceCategories>(
                  initialValue: _selectedCategory,

                  // Important to prevent horizontal overflow when text is long.
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

                  // Build dropdown items from enum values.
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

                  // Store selected category in local state.
                  onChanged: (value) {
                    setState(() => _selectedCategory = value);
                  },

                  // Validation: service is required.
                  validator: (value) {
                    if (value == null) return 'Please select a service';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ---------------- Rating stars ----------------
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "Rating" label
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

                    // 1–5 star selector (wraps if needed on small screens).
                    Wrap(
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isSelected = starIndex <= _rating;

                        return IconButton(
                          onPressed: () {
                            // Update rating when star is tapped.
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

      // Dialog action buttons.
      actions: [
        // Cancel button.
        TextButton(
          // Disabled while submitting.
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),

        // Submit button.
        ElevatedButton(
          // Disabled while submitting.
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          // Show spinner while submitting, otherwise show "Submit".
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