import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Standard page title widget.
///
/// Behavior
/// - Renders a styled title using [AppColors.primary].
/// - Adds configurable bottom spacing:
///   - [isPar] false -> large spacing for page headers
///   - [isPar] true -> compact spacing for sections/subheaders
class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    this.isPar = false,
  });

  /// Controls the spacing below the title.
  ///
  /// - false -> 30px (default for main pages)
  /// - true -> 5px (compact spacing)
  final bool isPar;

  /// The text displayed as the page title.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        if (!isPar) ...[
          const SizedBox(height: 30),
        ] else ...[
          const SizedBox(height: 5),
        ],
      ],
    );
  }
}