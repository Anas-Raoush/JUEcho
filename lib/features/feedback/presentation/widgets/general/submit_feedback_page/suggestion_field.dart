import 'package:flutter/material.dart';
class SuggestionField extends StatelessWidget {
  const SuggestionField({super.key, required this.suggestionCtrl, required this.decoration});
  final TextEditingController suggestionCtrl;
  final InputDecoration decoration;

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
