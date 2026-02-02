import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Inline error message widget used across forms and pages.
///
/// Behavior
/// - When [error] is null, renders nothing and does not affect layout.
/// - When [error] is non-null, renders a centered red message with spacing.
///
/// Intended usage
/// - Authentication forms
/// - Submission forms
/// - Any UI surface where a simple inline error message is required
class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.error,
  });

  /// Error message to display.
  ///
  /// - null -> widget is hidden
  /// - non-null -> message is displayed
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          error!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.red,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}