import 'package:juecho/features/feedback/data/models/feedback_model.dart';

/// Simple pagination wrapper for Admin list queries.
class SubmissionsPage {
  final List<FeedbackSubmission> items;
  final String? nextToken;

  const SubmissionsPage({
    required this.items,
    required this.nextToken,
  });
}