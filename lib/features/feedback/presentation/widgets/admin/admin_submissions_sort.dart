import 'package:flutter/material.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';
import 'package:juecho/features/feedback/data/models/feedback_model.dart';

/// What field the admin is currently sorting by.
enum AdminSubmissionSortKey {
  newestFirst,
  oldestFirst,
  highestUrgency,
  lowestUrgency,
  highestRating,
  lowestRating,
  serviceCategory,
  status,
}

/// Simple filter object: any null means "no filter" on that field.
class AdminSubmissionsFilter {
  final ServiceCategories? category;
  final FeedbackStatusCategories? status;
  final int? rating; // exact rating 1–5
  final int? urgency; // exact urgency 1–5

  const AdminSubmissionsFilter({
    this.category,
    this.status,
    this.rating,
    this.urgency,
  });

  AdminSubmissionsFilter copyWith({
    ServiceCategories? category,
    bool clearCategory = false,
    FeedbackStatusCategories? status,
    bool clearStatus = false,
    int? rating,
    bool clearRating = false,
    int? urgency,
    bool clearUrgency = false,
  }) {
    return AdminSubmissionsFilter(
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      rating: clearRating ? null : (rating ?? this.rating),
      urgency: clearUrgency ? null : (urgency ?? this.urgency),
    );
  }

  bool get isEmpty =>
      category == null && status == null && rating == null && urgency == null;
}

/// In–place sort of submissions according to the selected sort key.
void sortSubmissions(
    List<FeedbackSubmission> list,
    AdminSubmissionSortKey sortKey,
    ) {
  int statusOrder(FeedbackStatusCategories s) =>
      FeedbackStatusCategories.values.indexOf(s);

  int urgencyValue(FeedbackSubmission s) => s.urgency ?? -1;

  switch (sortKey) {
    case AdminSubmissionSortKey.newestFirst:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;

    case AdminSubmissionSortKey.oldestFirst:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;

    case AdminSubmissionSortKey.highestUrgency:
    // null urgency at the end
      list.sort((a, b) => urgencyValue(b).compareTo(urgencyValue(a)));
      break;

    case AdminSubmissionSortKey.lowestUrgency:
      list.sort((a, b) => urgencyValue(a).compareTo(urgencyValue(b)));
      break;

    case AdminSubmissionSortKey.highestRating:
      list.sort((a, b) => b.rating.compareTo(a.rating));
      break;

    case AdminSubmissionSortKey.lowestRating:
      list.sort((a, b) => a.rating.compareTo(b.rating));
      break;

    case AdminSubmissionSortKey.serviceCategory:
      list.sort(
            (a, b) => a.serviceCategory.label.compareTo(b.serviceCategory.label),
      );
      break;

    case AdminSubmissionSortKey.status:
      list.sort(
            (a, b) => statusOrder(a.status).compareTo(statusOrder(b.status)),
      );
      break;
  }
}

/// Returns a new list with the filter applied (original list is untouched).
List<FeedbackSubmission> applyAdminSubmissionsFilter(
    List<FeedbackSubmission> original,
    AdminSubmissionsFilter filter,
    ) {
  return original.where((s) {
    if (filter.category != null && s.serviceCategory != filter.category) {
      return false;
    }
    if (filter.status != null && s.status != filter.status) {
      return false;
    }
    if (filter.rating != null && s.rating != filter.rating) {
      return false;
    }
    if (filter.urgency != null && s.urgency != filter.urgency) {
      return false;
    }
    return true;
  }).toList();
}

/// Reusable “Sort & Filter” bar for admin submissions pages.
class AdminSubmissionsSortBar extends StatelessWidget {
  final AdminSubmissionSortKey sortKey;
  final ValueChanged<AdminSubmissionSortKey> onSortChanged;

  final AdminSubmissionsFilter filter;
  final ValueChanged<AdminSubmissionsFilter> onFilterChanged;

  final bool showStatusFilter;
  final bool showUrgencyFilter;

  const AdminSubmissionsSortBar({
    super.key,
    required this.sortKey,
    required this.onSortChanged,
    required this.filter,
    required this.onFilterChanged,
    this.showStatusFilter = true,
    this.showUrgencyFilter = true,
  });

  String _sortLabel(AdminSubmissionSortKey key) {
    switch (key) {
      case AdminSubmissionSortKey.newestFirst:
        return 'Newest first';
      case AdminSubmissionSortKey.oldestFirst:
        return 'Oldest first';
      case AdminSubmissionSortKey.highestUrgency:
        return 'Highest urgency';
      case AdminSubmissionSortKey.lowestUrgency:
        return 'Lowest urgency';
      case AdminSubmissionSortKey.highestRating:
        return 'Highest rating';
      case AdminSubmissionSortKey.lowestRating:
        return 'Lowest rating';
      case AdminSubmissionSortKey.serviceCategory:
        return 'Service category (A→Z)';
      case AdminSubmissionSortKey.status:
        return 'Status';
    }
  }

  InputDecoration _filterDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- Sort row ----------
        Row(
          children: [
            const Text(
              'Sort by:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<AdminSubmissionSortKey>(
                initialValue: sortKey,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.arrow_drop_down),
                items: AdminSubmissionSortKey.values
                    .map(
                      (k) => DropdownMenuItem(
                    value: k,
                    child: Text(_sortLabel(k)),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ---------- Filters title ----------
        const Text(
          'Filters (optional)',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 4),

        // ---------- Row 1: Category + Status ----------
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<ServiceCategories>(
                initialValue: filter.category,
                decoration: _filterDecoration('Category'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: ServiceCategories.values
                    .map(
                      (c) => DropdownMenuItem<ServiceCategories>(
                    value: c,
                    child: Text(c.label, overflow: TextOverflow.ellipsis),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  onFilterChanged(
                    filter.copyWith(
                      category: value,
                      clearCategory: value == null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            if (showStatusFilter) ...[
              Expanded(
                child: DropdownButtonFormField<FeedbackStatusCategories>(
                  initialValue: filter.status,
                  decoration: _filterDecoration('Status'),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: FeedbackStatusCategories.values
                      .map(
                        (s) => DropdownMenuItem<FeedbackStatusCategories>(
                      value: s,
                      child: Text(s.label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    onFilterChanged(
                      filter.copyWith(status: value, clearStatus: value == null),
                    );
                  },
                ),
              ),
            ],],
        ),
        const SizedBox(height: 8),

        // ---------- Row 2: Rating + Urgency ----------
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: filter.rating,
                decoration: _filterDecoration('Rating'),
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: List.generate(5, (i) => i + 1)
                    .map(
                      (r) => DropdownMenuItem<int>(
                    value: r,
                    child: Text(r.toString()),
                  ),
                )
                    .toList(),
                onChanged: (value) {
                  onFilterChanged(
                    filter.copyWith(rating: value, clearRating: value == null),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            if (showUrgencyFilter) ...[
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: filter.urgency,
                  decoration: _filterDecoration('Urgency'),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: List.generate(5, (i) => i + 1)
                      .map(
                        (u) => DropdownMenuItem<int>(
                      value: u,
                      child: Text(u.toString()),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    onFilterChanged(
                      filter.copyWith(
                        urgency: value,
                        clearUrgency: value == null,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),

        // ---------- Clear filters ----------
        if (!filter.isEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                onFilterChanged(const AdminSubmissionsFilter());
              },
              child: const Text(
                'Clear filters',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ],
    );
  }
}