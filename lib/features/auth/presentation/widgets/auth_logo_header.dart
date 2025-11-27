import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Common header widget for auth screens (login, signup, confirm, etc.).
///
/// Shows:
/// - The JUEcho SVG logo.
/// - A main [title] text.
/// - Optional [subtitle] (e.g., instructions).
/// - Configurable vertical spacing using [spacingBelowLogo] and [spacingBelowTitle].
class AuthLogoHeader extends StatelessWidget {
  const AuthLogoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.spacingBelowLogo = 32,
    this.spacingBelowTitle = 24,
  });

  /// Main title text (e.g. "Sign in", "Sign up", "Confirm your email").
  final String title;

  /// Optional subtitle displayed under the title (e.g. descriptive instructions).
  final String? subtitle;

  /// Vertical space between the logo and the title.
  final double spacingBelowLogo;

  /// Vertical space below the title (or below the subtitle if present).
  final double spacingBelowTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App logo (SVG asset) used across all auth pages.
        SvgPicture.asset(
          'assets/images/JUEcho_BGR.svg',
          height: 150,
        ),
        SizedBox(height: spacingBelowLogo),
        // Main title text
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),
        // Optional subtitle text (only rendered if non-null)
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
        // Spacing before the rest of the page content (forms/buttons)
        SizedBox(height: spacingBelowTitle),
      ],
    );
  }
}
