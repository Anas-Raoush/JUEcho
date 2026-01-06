import 'package:flutter/material.dart';
import 'package:juecho/common/constants/service_categories.dart';

class CategoryDropdown extends StatelessWidget {
  final ServiceCategories? selectedCategory;
  final Function(ServiceCategories?) onChanged;
  final InputDecoration decoration;

  const CategoryDropdown({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ServiceCategories>(
      initialValue: selectedCategory,
      decoration: decoration,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
      items: ServiceCategories.values
          .map(
            (c) => DropdownMenuItem<ServiceCategories>(
          value: c,
          child: Text(c.label),
        ),
      )
          .toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Select a category';
        }
        return null;
      },
    );
  }
}