import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// A lightweight responsive wrapper for page content.
///
/// Provides:
/// - SafeArea handling
/// - Responsive padding based on screen width
/// - Max width constraint for improved readability on larger screens
/// - Vertical scrolling for overflow content
///
/// Typical maxWidth guidelines:
/// - Forms/auth pages: 480–560
/// - Content-heavy pages: 1000–1400
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.maxWidth = 1200,
    this.padding,
    this.center = true,
  });

  final Widget body;
  final double maxWidth;
  final EdgeInsets? padding;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            final EdgeInsets resolvedPadding = padding ??
                EdgeInsets.symmetric(
                  horizontal: w >= 900
                      ? 32
                      : w >= 600
                      ? 24
                      : 16,
                  vertical: w >= 600 ? 24 : 16,
                );

            final Widget constrainedContent = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: resolvedPadding, child: body),
            );

            final Widget layout =
            center ? Center(child: constrainedContent) : constrainedContent;

            return Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: layout,
              ),
            );
          },
        ),
      ),
    );
  }
}