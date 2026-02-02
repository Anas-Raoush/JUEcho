import 'package:flutter/material.dart';

/// Multi-line required description input for feedback submission.
///
/// Behavior
/// - Uses [descriptionCtrl] as the source of truth.
/// - Validates non-empty input.
/// - Accepts multi-line entry with a controlled line range.
class DescriptionField extends StatelessWidget {
  /// Input decoration supplied by the parent form.
  final InputDecoration decoration;

  /// Controller for the description field.
  final TextEditingController descriptionCtrl;

  const DescriptionField({
    super.key,
    required this.decoration,
    required this.descriptionCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: descriptionCtrl,
      textInputAction: TextInputAction.newline,
      minLines: 3,
      maxLines: 5,
      decoration: decoration,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }
}