import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Primary submit action button used on the feedback submission form.
///
/// Behavior
/// - Disabled while [isSubmitting] is true.
/// - Shows a spinner while submitting.
/// - Uses full width by default via [SizedBox(width: double.infinity)].
class SubmitButton extends StatelessWidget {
  /// True while the parent is submitting the form.
  final bool isSubmitting;

  /// Submit callback invoked when not submitting.
  final VoidCallback onPressed;

  const SubmitButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
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
        child: isSubmitting
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
}