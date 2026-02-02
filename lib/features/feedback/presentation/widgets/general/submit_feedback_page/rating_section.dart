import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Simple 1-5 star rating selector.
///
/// Behavior
/// - Renders 5 star icons.
/// - Stars up to [rating] are filled.
/// - Tapping a star calls [onRatingChanged] with the selected value.
///
/// UI notes
/// - Uses [IconButton] for consistent tap target sizing.
class RatingSection extends StatelessWidget {
  /// Current rating value.
  final int rating;

  /// Callback invoked when the user selects a rating.
  final ValueChanged<int> onRatingChanged;

  const RatingSection({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
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
            final isSelected = starIndex <= rating;

            return IconButton(
              onPressed: () => onRatingChanged(starIndex),
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
}