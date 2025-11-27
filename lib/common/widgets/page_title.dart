import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 80),
            child: Divider(color: AppColors.dividerColor, height: 20),
          ),
          const SizedBox(height: 5),
      ],
    );
  }
}
