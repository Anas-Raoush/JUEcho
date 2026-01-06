import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// A reusable responsive page wrapper.
///
/// Purpose:
/// - Provides consistent horizontal padding across screen sizes
/// - Constrains content width on tablets & desktop
/// - Adds vertical scrolling for long pages
/// - Supports configurable background color
/// - Does NOT contain any business logic
///
/// Recommended usage:
/// - Auth / forms pages: maxWidth = 480–560
/// - Content pages (lists, dashboards): maxWidth = 1000–1400
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    this.maxWidth = 1200,
    this.padding,
    this.center = true,
  });

  /// The page content.
  final Widget body;

  /// Maximum width for the content on large screens.
  final double maxWidth;

  /// Optional custom padding.
  ///
  /// If null, padding is calculated automatically
  /// based on screen width.
  final EdgeInsets? padding;

  /// Whether to horizontally center the constrained content.
  ///
  /// - true  → most pages
  /// - false → full-width layouts (rare)
  final bool center;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            // -------- Responsive padding rules --------
            final EdgeInsets resolvedPadding =
                padding ??
                EdgeInsets.symmetric(
                  horizontal: w >= 900
                      ? 32
                      : w >= 600
                      ? 24
                      : 16,
                  vertical: w >= 600 ? 24 : 16,
                );

            // -------- Constrained content --------
            final Widget constrainedContent = ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: resolvedPadding, child: body),
            );

            // -------- Optional centering --------
            final Widget layout = center
                ? Center(child: constrainedContent)
                : constrainedContent;

            // -------- Vertical scrolling --------
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
