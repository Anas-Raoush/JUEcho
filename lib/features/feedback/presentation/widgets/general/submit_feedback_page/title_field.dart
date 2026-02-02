import 'package:flutter/material.dart';

/// Required title input for feedback submission.
///
/// Behavior
/// - Enforces max length of 100 characters via [maxLength].
/// - Validates non-empty input.
/// - Uses [TextInputAction.next] to move focus to the next field.
class TitleField extends StatelessWidget {
  /// Controller for the title input.
  final TextEditingController titleCtrl;

  /// Input decoration supplied by the parent form.
  final InputDecoration decoration;

  const TitleField({
    super.key,
    required this.titleCtrl,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: titleCtrl,
      maxLength: 100,
      textInputAction: TextInputAction.next,
      decoration: decoration,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }
}