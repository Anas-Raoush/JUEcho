import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';

class AdminFeedbackStatusUrgencyNotesSection extends StatelessWidget {
  final FeedbackStatusCategories? selectedStatus;
  final ValueChanged<FeedbackStatusCategories?> onStatusChanged;

  final String? statusError;
  final String? urgencyError;

  final int? selectedUrgency;
  final ValueChanged<int?> onUrgencyChanged;

  final TextEditingController internalNotesController;

  const AdminFeedbackStatusUrgencyNotesSection({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedUrgency,
    required this.onUrgencyChanged,
    required this.internalNotesController,
    this.statusError,
    this.urgencyError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status dropdown
        const Text(
          'Status',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<FeedbackStatusCategories>(
          initialValue: selectedStatus,
          decoration: InputDecoration(
            errorText: statusError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            isDense: true,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          items: FeedbackStatusCategories.values
              .map(
                (s) => DropdownMenuItem<FeedbackStatusCategories>(
              value: s,
              child: Text(s.label),
            ),
          )
              .toList(),
          onChanged: onStatusChanged,
        ),
        const SizedBox(height: 16),

        // Urgency radio buttons (1–5)
        const Text(
          'Urgency (1–5)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: List.generate(5, (index) {
            final value = index + 1;
            final isSelected = selectedUrgency == value;
            return ChoiceChip(
              label: Text('$value'),
              selected: isSelected,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.white : AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onUrgencyChanged(value),
            );
          }),
        ),
        if(urgencyError != null)...[
          const SizedBox(height: 6),
          Text(
            urgencyError!,
            style: const TextStyle(
              color: AppColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Internal notes
        const Text(
          'Internal notes (admins only)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: internalNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}