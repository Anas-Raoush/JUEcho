import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class RatingSection extends StatelessWidget {
  const RatingSection({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });
  
  final int rating;
  final ValueChanged<int> onRatingChanged;


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
