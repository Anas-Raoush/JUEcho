import 'package:flutter/material.dart';

/// Centralized color palette for the JUEcho app.
///
/// All shared colors used in the UI should be defined here so that:
/// - The visual design is consistent across screens.
/// - Future theme changes can be done in one place.
///
/// Notes:
/// - `primary` is the main brand green.
/// - Text-related colors (darkText, gray) are tuned for readability.
/// - Some colors (e.g. [red], [white]) are reused directly from [Colors].
class AppColors {
  static const primary = Color(0xFF084C28);
  static const white = Colors.white;
  static const card = Color(0xFFF5F5F5);
  static const grayBorder = Color(0xFFE0E0E0);
  static const red = Colors.red;
  static const dividerColor = Color(0xFFD5D5D5);
  static const black = Colors.black;
  static const darkText = Colors.black87;
  static const gray = Colors.black54;
  static const boxShadowColor = Colors.black26;
}
