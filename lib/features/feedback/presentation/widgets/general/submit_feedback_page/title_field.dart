import 'package:flutter/material.dart';
class TitleField extends StatelessWidget {
  const TitleField({super.key, required this.titleCtrl, required this.decoration});

  final TextEditingController titleCtrl;
  final InputDecoration decoration;

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
