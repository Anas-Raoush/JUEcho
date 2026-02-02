/// feedback_status_categories.dart
///
/// Feedback status enum and mapping helpers.
///
/// Purpose
/// - Defines the feedback lifecycle states used across the app.
/// - Centralizes UI labels and backend keys to avoid string duplication.
/// - Ensures stable round-trip mapping between client enum and GraphQL values.
///
/// Backend alignment
/// - Keys must match the GraphQL schema enum values exactly:
///   SUBMITTED
///   UNDER_REVIEW
///   IN_PROGRESS
///   RESOLVED
///   REJECTED
///   MORE_INFO_NEEDED
enum FeedbackStatusCategories {
  /// Feedback has been submitted and is waiting to be reviewed.
  submitted,

  /// Feedback is currently under admin/faculty review.
  underReview,

  /// Feedback is being worked on or tracked as active.
  inProgress,

  /// Feedback has been fully resolved.
  resolved,

  /// Feedback has been rejected.
  rejected,

  /// User must provide more information before progress can continue.
  moreInfoNeeded,
}

/// UI-facing label mapping for [FeedbackStatusCategories].
///
/// Intended usage
/// - List views and cards
/// - Detail screens
/// - Dropdowns and filters
extension FeedbackStatusLabel on FeedbackStatusCategories {
  /// Human-readable label for display in UI.
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

/// GraphQL enum key mapping for [FeedbackStatusCategories].
///
/// Notes
/// - Uses UPPER_SNAKE_CASE to match AppSync GraphQL enum format.
/// - Keep these values in sync with the backend schema.
extension FeedbackStatusKey on FeedbackStatusCategories {
  /// Backend-safe enum key used in GraphQL operations.
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

/// Parser utilities for converting backend keys into [FeedbackStatusCategories].
///
/// Failure mode
/// - Throws [ArgumentError] for unknown keys to fail fast on schema drift.
extension FeedbackStatusParser on FeedbackStatusCategories {
  /// Converts a GraphQL enum key (UPPER_SNAKE_CASE) into a strongly typed value.
  ///
  /// Throws
  /// - [ArgumentError] when [key] is not recognized.
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