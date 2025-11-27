import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class FeedbackRatingSection extends StatelessWidget {
  final int rating;
  final bool canEdit;
  final ValueChanged<int>? onChanged;

  const FeedbackRatingSection({
    super.key,
    required this.rating,
    required this.canEdit,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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

            // Read-only mode
            if (!canEdit || onChanged == null) {
              return icon;
            }

            // Editable mode
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