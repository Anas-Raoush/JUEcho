import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

class CardData extends StatelessWidget {
  const CardData({
    super.key,
    required this.label,
    required this.data,
    required this.labelColor,
    required this.dataColor,
    this.lastItem = false,
  });

  final String label;
  final String data;
  final Color labelColor;
  final Color dataColor;
  final bool lastItem;

  String trimToMaxChars(String text, {int max = 20}) {
    if (text.length <= max) return text;
    return "${text.substring(0, max)}...";
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: labelColor,
              ),
            ),
            Flexible(
              child: Text(
                trimToMaxChars(data),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14,
                  color: dataColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (!lastItem) ...[
          const Divider(color: AppColors.dividerColor, height: 20),
        ]
        else ...[const SizedBox(height: 15)],
      ],
    );
  }
}