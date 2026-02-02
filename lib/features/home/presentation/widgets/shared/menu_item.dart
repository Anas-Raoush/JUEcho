import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// MenuItem
///
/// Reusable icon+label action used by hamburger menus.
///
/// Interaction:
/// - Uses InkWell to provide a Material ripple.
/// - Allows the caller to provide onTap behavior (navigation, sign out, etc).
///
/// Styling:
/// - Fixed 56x56 icon container for consistent visual rhythm.
/// - Optional outlinedColor for "danger" actions (e.g., Sign out).
class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.outlinedColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color? outlinedColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = outlinedColor ?? AppColors.grayBorder;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: AppColors.boxShadowColor,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}