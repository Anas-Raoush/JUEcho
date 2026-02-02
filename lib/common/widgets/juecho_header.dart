import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// App header used across top-level pages.
///
/// Layout
/// - Left: JUEcho SVG logo
/// - Right: menu icon button
///
/// Behavior
/// - [onMenuTap] is invoked when the menu icon is pressed.
class JuechoHeader extends StatelessWidget {
  const JuechoHeader({
    super.key,
    required this.onMenuTap,
  });

  /// Callback triggered when the menu icon is pressed.
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Brand logo (SVG asset).
            SvgPicture.asset('assets/images/JUEcho_BGR.svg', height: 90),
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(
                Icons.menu,
                color: AppColors.primary,
                size: 30,
              ),
            ),
          ],
        ),
      ],
    );
  }
}