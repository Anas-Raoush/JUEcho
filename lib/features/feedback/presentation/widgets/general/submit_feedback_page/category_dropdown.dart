import 'package:flutter/material.dart';

import 'package:juecho/common/constants/service_categories.dart';

/// Form dropdown used to select a service category for feedback submission.
///
/// Behavior
/// - Uses [ServiceCategories.values] to populate the dropdown.
/// - Uses [selectedCategory] as the initial value.
/// - Validates that a selection exists (required field).
///
/// Styling
/// - Delegates decoration to the parent via [decoration] to keep form styling
///   consistent across fields.
class CategoryDropdown extends StatelessWidget {
  /// Currently selected category (nullable until chosen).
  final ServiceCategories? selectedCategory;

  /// Called when the selected category changes.
  final Function(ServiceCategories?) onChanged;

  /// Input decoration supplied by the parent.
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