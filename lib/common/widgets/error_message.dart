import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Small reusable widget to display an authentication-related error message.
///
/// Usage:
///   - Pass a non-null [error] string to show a red error text with spacing.
///   - If [error] is null, this widget renders as an empty box (`SizedBox.shrink`)
///     so it doesn't affect layout.
class ErrorMessage extends StatelessWidget {
  const ErrorMessage({
    super.key,
    required this.error,
  });

  /// The error message to display.
  ///
  /// - `null` -> nothing is rendered.
  /// - non-null -> shown as red text, centered, with a bit of space below.
  final String? error;

  @override
  Widget build(BuildContext context) {
    // If there's no error, don't take any visual space.
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
