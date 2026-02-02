import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Star rating display/edit section.
///
/// Modes
/// - Read-only: renders filled/outlined stars based on [rating].
/// - Editable: when [canEdit] is true and [onChanged] is provided,
///   stars become tappable and notify [onChanged] with the selected value.
///
/// Notes
/// - Uses [GestureDetector] for editable mode to keep icon rendering identical
///   between modes.
class FeedbackRatingSection extends StatelessWidget {
  /// Current rating value (1-5).
  final int rating;

  /// Controls whether the rating can be edited.
  final bool canEdit;

  /// Callback invoked when the rating changes in editable mode.
  final ValueChanged<int>? onChanged;

  const FeedbackRatingSection({
    super.key,
    required this.rating,
    required this.canEdit,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final editable = canEdit && onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rating',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = starIndex <= rating;

            final icon = Icon(
              isSelected ? Icons.star : Icons.star_border,
              color: isSelected ? AppColors.primary : AppColors.gray,
            );

            if (!editable) return icon;

            return GestureDetector(
              onTap: () => onChanged!(starIndex),
              child: icon,
            );
          }),
        ),
      ],
    );
  }
}