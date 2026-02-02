import 'package:flutter/material.dart';

/// WelcomeSection
///
/// Lightweight header section used on landing/dashboard pages.
///
/// Displays a single centered greeting line:
/// - "Welcome <name>"
///
/// Notes:
/// - Purely presentational.
/// - Callers are responsible for providing a sanitized display name.
class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          'Welcome $name',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}