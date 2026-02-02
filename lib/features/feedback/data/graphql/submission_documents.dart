/// Central place for GraphQL documents (queries/mutations/subscriptions)
/// related to the `Submission` model.
///
/// Why keep these here:
/// - Avoid duplicating long GraphQL strings across repositories
/// - Easier to maintain + update fields in one place
///
/// Tip:
/// - Keep the selected fields consistent across queries so your
///   `FeedbackSubmission.fromJson(...)` stays stable.
///
/// NOTE: Make sure there are no leading spaces before `const` (Dart formatting).
const String updateSubmissionMutation = r'''
  mutation UpdateSubmission($input: UpdateSubmissionInput!) {
    updateSubmission(input: $input) {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
''';

const String deleteSubmissionMutation = r'''
  mutation DeleteSubmission($input: DeleteSubmissionInput!) {
    deleteSubmission(input: $input) {
      id
    }
  }
''';

const String listSubmissionsPagedQuery = r'''
query ListSubmissionsPaged($filter: ModelSubmissionFilterInput, $limit: Int, $nextToken: String) {
  listSubmissions(filter: $filter, limit: $limit, nextToken: $nextToken) {
    items {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
    nextToken
  }
}
''';

const String listAllSubmissionsForAdminQuery = r'''
  query ListAllSubmissionsForAdmin {
    listSubmissions {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
''';

const String listAdminReviewSubmissionsQuery = r'''
  query ListAdminReviewSubmissions {
    listSubmissions(filter: { status: { ne: SUBMITTED } }) {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
''';

// -------------------- Subscriptions (ID-only pings) --------------------

const String onCreateSubmissionIdSub = r'''
  subscription OnCreateSubmission {
    onCreateSubmission { id }
  }
''';

const String onUpdateSubmissionIdSub = r'''
  subscription OnUpdateSubmission {
    onUpdateSubmission { id }
  }
''';

const String onDeleteSubmissionIdSub = r'''
  subscription OnDeleteSubmission {
    onDeleteSubmission { id }
  }
''';

// -------------------- Subscription (full payload) --------------------

const String onUpdateSubmissionSub = r'''
  subscription OnUpdateSubmission {
    onUpdateSubmission {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
''';

// -------------------- Create + Get --------------------

const String createSubmissionMutation = r'''
  mutation CreateSubmission($input: CreateSubmissionInput!) {
    createSubmission(input: $input) {
      id
    }
  }
''';

const String listMySubmissionsQuery = r'''
  query ListMySubmissions($ownerId: ID!) {
    listSubmissions(filter: { ownerId: { eq: $ownerId } }) {
      items {
        id
        ownerId
        serviceCategory
        title
        description
        suggestion
        rating
        attachmentKey
        status
        urgency
        internalNotes
        updatedById
        updatedByName
        respondedAt
        createdAt
        updatedAt
        replies { fromRole message byId byName at }
      }
    }
  }
''';

const String getSubmissionQuery = r'''
  query GetSubmission($id: ID!) {
    getSubmission(id: $id) {
      id
      ownerId
      serviceCategory
      title
      description
      suggestion
      rating
      attachmentKey
      status
      urgency
      internalNotes
      updatedById
      updatedByName
      respondedAt
      createdAt
      updatedAt
      replies { fromRole message byId byName at }
    }
  }
''';