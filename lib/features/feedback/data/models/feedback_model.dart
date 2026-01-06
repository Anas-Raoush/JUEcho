import 'package:juecho/common/constants/feedback_status_categories.dart';
import 'package:juecho/common/constants/service_categories.dart';

/// One chat-style reply in the submission's conversation.
class FeedbackReply {
  final String fromRole; // "GENERAL" or "ADMIN"
  final String message;
  final String byId;
  final String byName;
  final DateTime at;

  const FeedbackReply({
    required this.fromRole,
    required this.message,
    required this.byId,
    required this.byName,
    required this.at,
  });

  factory FeedbackReply.fromJson(Map<String, dynamic> json) {
    return FeedbackReply(
      fromRole: json['fromRole'] as String,
      message: json['message'] as String,
      byId: json['byId'] as String,
      byName: json['byName'] as String,
      at: DateTime.parse(json['at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromRole': fromRole,
      'message': message,
      'byId': byId,
      'byName': byName,
      'at': at.toUtc().toIso8601String(),
    };
  }
}

/// In-app representation of a feedback submission (Student → Admin).
///
/// Mirrors the `Submission` model in `resources.ts`.
class FeedbackSubmission {
  final String id;
  final String ownerId;

  final ServiceCategories serviceCategory;
  final String? title;       // nullable to allow rating-only submissions
  final String? description; // nullable to allow rating-only submissions
  final String? suggestion;
  final int rating;
  final String? attachmentKey;

  final FeedbackStatusCategories status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Admin-side fields
  final int? urgency;
  final String? internalNotes;
  final String? updatedById;
  final String? updatedByName;
  final DateTime? respondedAt;

  // Conversation
  final List<FeedbackReply> replies;

  const FeedbackSubmission({
    required this.id,
    required this.ownerId,
    required this.serviceCategory,
    required this.title,
    required this.description,
    required this.suggestion,
    required this.rating,
    required this.attachmentKey,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.urgency,
    this.internalNotes,
    this.updatedById,
    this.updatedByName,
    this.respondedAt,
    this.replies = const [],
  });

  /// True when this is a *full* feedback, not just rating-only.
  bool get isFullFeedback {
    final hasTitle = (title ?? '').trim().isNotEmpty;
    final hasDescription = (description ?? '').trim().isNotEmpty;
    return hasTitle && hasDescription;
  }

  List<FeedbackReply> get adminReplies {
    final adminReplies = replies
        .where((r) => r.fromRole.toUpperCase() == 'ADMIN')
        .toList();

    adminReplies.sort((a, b) => a.at.compareTo(b.at));
    return adminReplies;
  }

  /// True when the student is still allowed to edit/delete this submission.
  bool get canEditOrDelete =>
      status == FeedbackStatusCategories.submitted;

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmission(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      serviceCategory:
      ServiceCategoryParser.fromKey(json['serviceCategory'] as String),
      title: json['title'] as String?,
      description: json['description'] as String?,
      suggestion: json['suggestion'] as String?,
      rating: json['rating'] as int,
      attachmentKey: json['attachmentKey'] as String?,
      status:
      FeedbackStatusParser.fromKey(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      urgency: json['urgency'] as int?,
      internalNotes: json['internalNotes'] as String?,
      updatedById: json['updatedById'] as String?,
      updatedByName: json['updatedByName'] as String?,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      replies: (json['replies'] as List<dynamic>? ?? [])
          .map((e) => FeedbackReply.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Shape of the input map for `CreateSubmissionInput` in GraphQL.
  Map<String, dynamic> toCreateInput({
    required String ownerId,
    required String serviceKey,
    required String statusKey,
  }) {
    return <String, dynamic>{
      'id': id,
      'ownerId': ownerId,
      'serviceCategory': serviceKey,
      'title': title,
      'description': description,
      'suggestion': suggestion,
      'rating': rating,
      'attachmentKey': attachmentKey,
      'status': statusKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  /// All user (GENERAL) replies, sorted oldest → newest.
  List<FeedbackReply> get userReplies {
    final userReplies = replies
        .where((r) => r.fromRole.toUpperCase() == 'GENERAL')
        .toList();

    userReplies.sort((a, b) => a.at.compareTo(b.at));
    return userReplies;
  }


  /// Minimal user-editable update map for `UpdateSubmissionInput`.
  Map<String, dynamic> toUserUpdateInput() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'description': description,
      'suggestion': suggestion,
      'rating': rating,
      'attachmentKey': attachmentKey,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  FeedbackSubmission copyWith({
    String? title,
    String? description,
    String? suggestion,
    int? rating,
    String? attachmentKey,
    List<FeedbackReply>? replies,
    FeedbackStatusCategories? status,
  }) {
    return FeedbackSubmission(
      id: id,
      ownerId: ownerId,
      serviceCategory: serviceCategory,
      title: title ?? this.title,
      description: description ?? this.description,
      suggestion: suggestion ?? this.suggestion,
      rating: rating ?? this.rating,
      attachmentKey: attachmentKey ?? this.attachmentKey,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      urgency: urgency,
      internalNotes: internalNotes,
      updatedById: updatedById,
      updatedByName: updatedByName,
      respondedAt: respondedAt,
      replies: replies ?? this.replies,
    );
  }
}