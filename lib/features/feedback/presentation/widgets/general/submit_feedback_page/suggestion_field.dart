import 'package:flutter/material.dart';

/// Optional multi-line suggestion input for feedback submission.
///
/// Behavior
/// - No validation (optional).
/// - Uses a controlled line range suitable for short suggestions.
class SuggestionField extends StatelessWidget {
  /// Controller for the suggestion input.
  final TextEditingController suggestionCtrl;

  /// Input decoration supplied by the parent form.
  final InputDecoration decoration;

  const SuggestionField({
    super.key,
    required this.suggestionCtrl,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: suggestionCtrl,
      textInputAction: TextInputAction.newline,
      minLines: 2,
      maxLines: 4,
      decoration: decoration,
    );
  }
}