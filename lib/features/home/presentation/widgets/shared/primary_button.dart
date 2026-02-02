import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// PrimaryButton
///
/// Standard call-to-action button used across home pages.
///
/// Features:
/// - Full-width, fixed-height layout for consistent UI.
/// - Supports "outlined" mode to represent secondary actions.
/// - Delegates press handling to the caller.
///
/// Notes:
/// - Uses ElevatedButton styling for a consistent Material interaction model.
/// - When outlined == true, background is still configurable but the border is forced.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.onPressed,
    this.outlined = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool outlined;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: outlined ? 1.5 : 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: outlined
                ? const BorderSide(color: AppColors.grayBorder, width: 1)
                : BorderSide.none,
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}