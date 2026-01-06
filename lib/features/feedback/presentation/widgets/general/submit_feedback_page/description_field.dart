import 'package:flutter/material.dart';

class DescriptionField extends StatelessWidget {
  const DescriptionField({super.key, required this.decoration, required this.descriptionCtrl});
  final InputDecoration decoration;
  final TextEditingController descriptionCtrl;

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
