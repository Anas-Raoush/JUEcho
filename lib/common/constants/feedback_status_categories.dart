/// Feedback status definitions and helpers.
///
/// This module provides:
/// - [FeedbackStatusCategories] enum: strongly typed feedback lifecycle states
///   shared by both the client UI and backend.
/// - [FeedbackStatusLabel]: human-friendly labels for UI.
/// - [FeedbackStatusKey]: GraphQL-safe UPPER_SNAKE_CASE keys expected by the backend.
/// - [FeedbackStatusParser]: converts backend keys back into enum values.
///
/// Design goals:
/// - Avoid scattering hard-coded strings throughout UI and networking code.
/// - Maintain strict alignment with Amplify GraphQL enum:
///     SUBMITTED
///     UNDER_REVIEW
///     IN_PROGRESS
///     RESOLVED
///     REJECTED
///     MORE_INFO_NEEDED
/// - Provide a reliable roundtrip: enum -> key -> enum.
/// - Keep UI text and backend value mapping centralized and easy to update.
enum FeedbackStatusCategories {
  /// Feedback has been successfully submitted and is pending review.
  submitted,

  /// Feedback is being reviewed by admin/faculty.
  underReview,

  /// Feedback resolution is underway or has active actions in progress.
  inProgress,

  /// The feedback has been fully resolved.
  resolved,

  /// The feedback was rejected, often due to invalid content or policy issues.
  rejected,

  /// Additional information is needed from the user before action can proceed.
  moreInfoNeeded,
}

/// Human-readable text labels for displaying feedback status in UI.
/// Used in:
/// - List tiles
/// - Status badges
/// - Feedback detail screens
/// - Filters and dropdowns
extension FeedbackStatusLabel on FeedbackStatusCategories {
  String get label {
    switch (this) {
      case FeedbackStatusCategories.submitted:
        return 'Submitted';
      case FeedbackStatusCategories.underReview:
        return 'Under Review';
      case FeedbackStatusCategories.inProgress:
        return 'In Progress';
      case FeedbackStatusCategories.resolved:
        return 'Resolved';
      case FeedbackStatusCategories.rejected:
        return 'Rejected';
      case FeedbackStatusCategories.moreInfoNeeded:
        return 'More Info Needed';
    }
  }
}

/// Backend-safe enum keys for GraphQL mutations/queries.
///
/// Why UPPER_SNAKE_CASE?
/// - AppSync GraphQL enums must match exactly.
/// - Server code often uses uppercase enum names.
/// - Prevents mistakes like typos or casing mismatches.
extension FeedbackStatusKey on FeedbackStatusCategories {
  String get key {
    switch (this) {
      case FeedbackStatusCategories.submitted:
        return 'SUBMITTED';
      case FeedbackStatusCategories.underReview:
        return 'UNDER_REVIEW';
      case FeedbackStatusCategories.inProgress:
        return 'IN_PROGRESS';
      case FeedbackStatusCategories.resolved:
        return 'RESOLVED';
      case FeedbackStatusCategories.rejected:
        return 'REJECTED';
      case FeedbackStatusCategories.moreInfoNeeded:
        return 'MORE_INFO_NEEDED';
    }
  }
}

/// Converts backend enum values (strings) back into strongly-typed
/// [FeedbackStatusCategories] values.
///
/// This is used when reading data from GraphQL:
/// Throws:
/// - [ArgumentError] if the backend sends an unknown value.
///   This ensures schema drift is caught early rather than silently failing.
extension FeedbackStatusParser on FeedbackStatusCategories {
  static FeedbackStatusCategories fromKey(String key) {
    switch (key) {
      case 'SUBMITTED':
        return FeedbackStatusCategories.submitted;
      case 'UNDER_REVIEW':
        return FeedbackStatusCategories.underReview;
      case 'IN_PROGRESS':
        return FeedbackStatusCategories.inProgress;
      case 'RESOLVED':
        return FeedbackStatusCategories.resolved;
      case 'REJECTED':
        return FeedbackStatusCategories.rejected;
      case 'MORE_INFO_NEEDED':
        return FeedbackStatusCategories.moreInfoNeeded;
      default:
        throw ArgumentError('Unknown feedback status key: $key');
    }
  }
}
