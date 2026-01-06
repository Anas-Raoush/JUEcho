import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.isPar = false});
  final bool isPar;
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
        if(!isPar)...[
        const SizedBox(height: 30),
        ] else ...[
          const SizedBox(height: 5),
        ]
      ],
    );
  }
}
