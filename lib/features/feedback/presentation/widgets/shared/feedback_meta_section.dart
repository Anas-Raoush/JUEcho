import 'package:flutter/material.dart';

import 'package:juecho/common/constants/app_colors.dart';

/// Meta information section for a feedback submission.
///
/// Display modes
/// - General: shows category + submittedAt.
/// - Admin: can additionally show status, urgency, and reviewer name.
///
/// Each row is rendered via the private [_MetaRow] widget to keep consistent
/// spacing and typography.
class FeedbackMetaSection extends StatelessWidget {
  /// Service category label shown at the top.
  final String serviceCategoryLabel;

  /// Submission date label rendered as provided by the parent.
  final String submittedAt;

  /// Optional admin-only fields.
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
        _MetaRow(
          label: 'Service category',
          value: serviceCategoryLabel,
        ),
        const SizedBox(height: 8),

        _MetaRow(
          label: 'Submitted at',
          value: submittedAt,
        ),

        if (ownerName != null) ...[
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Reviewed by',
            value: ownerName!,
          ),
        ],

        if (statusLabel != null) ...[
          const SizedBox(height: 8),
          _MetaRow(
            label: 'Status',
            value: statusLabel!,
          ),
        ],

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

/// Single meta row rendered as label on the left and value on the right.
class _MetaRow extends StatelessWidget {
  /// Label for the row.
  final String label;

  /// Value for the row.
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