import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Shared header widget used across authentication-related pages.
///
/// Displays:
/// - Application SVG logo
/// - Page title
/// - Optional subtitle (instructions, context, etc.)
///
/// Layout control:
/// - spacingBelowLogo controls distance between logo and title
/// - spacingBelowTitle controls distance below title/subtitle block
class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.spacingBelowLogo = 32,
    this.spacingBelowTitle = 24,
  });

  final String title;
  final String? subtitle;
  final double spacingBelowLogo;
  final double spacingBelowTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/JUEcho_BGR.svg',
          height: 150,
        ),
        SizedBox(height: spacingBelowLogo),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.gray,
            ),
          ),
        ],
        SizedBox(height: spacingBelowTitle),
      ],
    );
  }
}