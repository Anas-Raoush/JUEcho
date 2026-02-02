import 'package:flutter/material.dart';

/// Centralized color palette for the application.
///
/// Purpose
/// - Provides a single source of truth for shared UI colors.
/// - Keeps styling consistent across screens and components.
/// - Simplifies future theme updates by changing values in one place.
///
/// Notes
/// - [primary] is the main brand color and is used for buttons, highlights,
///   headings, and key UI accents.
/// - Text colors are tuned for readability on light backgrounds.
/// - Some values reference Flutter's built-in [Colors] constants.
class AppColors {
  /// Primary brand color used across the UI.
  static const primary = Color(0xFF084C28);

  /// Default white color used for text/icons on dark backgrounds.
  static const white = Colors.white;

  /// Default card background used for panels and list items.
  static const card = Color(0xFFF5F5F5);

  /// Standard border color for light UI surfaces.
  static const grayBorder = Color(0xFFE0E0E0);

  /// Standard red used for destructive actions and error states.
  static const red = Colors.red;

  /// Divider color used between rows/fields inside cards.
  static const dividerColor = Color(0xFFD5D5D5);

  /// Solid black used for high-contrast text where needed.
  static const black = Colors.black;

  /// Default "dark" text tone used for headings and primary text.
  static const darkText = Colors.black87;

  /// Secondary text tone used for muted labels and body text.
  static const gray = Colors.black54;

  /// Standard shadow tint used for elevation-like effects.
  static const boxShadowColor = Colors.black26;
}