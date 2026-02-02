import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Compact label/value row used inside summary cards.
///
/// Responsibilities
/// - Displays a left-aligned label and right-aligned value.
/// - Trims long values for consistent card layout.
/// - Draws a divider between rows unless [lastItem] is true.
///
/// Notes
/// - [trimToMaxChars] provides deterministic shortening in addition to
///   [TextOverflow.ellipsis] to keep UI consistent across layouts.
class CardData extends StatelessWidget {
  const CardData({
    super.key,
    required this.label,
    required this.data,
    required this.labelColor,
    required this.dataColor,
    this.lastItem = false,
  });

  /// Left-side label text.
  final String label;

  /// Right-side value text.
  final String data;

  /// Color for the label text.
  final Color labelColor;

  /// Color for the value text.
  final Color dataColor;

  /// True to suppress the divider after this row.
  final bool lastItem;

  /// Trims [text] to a fixed maximum length.
  ///
  /// This is applied before rendering to avoid overly long strings even when
  /// ellipsis is available.
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
        ] else ...[
          const SizedBox(height: 15),
        ],
      ],
    );
  }
}