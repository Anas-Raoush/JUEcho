import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';

/// Reusable meta info section for a feedback submission.
///
/// General user page:
/// - Pass [serviceCategoryLabel] + [submittedAt] only.
///
/// Admin page:
/// - Can also pass [statusLabel], [urgencyLabel], [ownerName].
class FeedbackMetaSection extends StatelessWidget {
  final String serviceCategoryLabel;
  final String submittedAt;

  /// Optional – shown only if not null.
  final String? statusLabel;
  final String? urgencyLabel;
  final String? ownerName;

  const FeedbackMetaSection({
    super.key,
    required this.serviceCategoryLabel,
    required this.submittedAt,
    this.statusLabel,
    this.urgencyLabel,
    this.ownerName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Service category
        _MetaRow(
          label: 'Service category',
          value: serviceCategoryLabel,
        ),
        const SizedBox(height: 8),

        // Submitted at
        _MetaRow(
          label: 'Submitted at',
          value: submittedAt,
        ),

        // Owner (admin only, optional)
        if (ownerName != null) ...[
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Reviewed by',
            value: ownerName!,
          ),
        ],

        // Status (admin only, optional)
        if (statusLabel != null) ...[
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Status',
            value: statusLabel!,
          ),
        ],

        // Urgency (admin only, optional)
        if (urgencyLabel != null) ...[
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Urgency',
            value: urgencyLabel!,
          ),
        ],
      ],
    );
  }
}
class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}