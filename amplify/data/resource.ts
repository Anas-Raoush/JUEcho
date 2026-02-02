import { a, defineData, type ClientSchema } from "@aws-amplify/backend";

/**
 * JU Echo data schema (Amplify Gen 2).
 *
 * Responsibilities
 * - Defines the AppSync GraphQL schema and DynamoDB-backed models.
 * - Declares enums shared between backend and Flutter.
 * - Centralizes authorization rules per model and operation.
 *
 * Global identifiers (invariants)
 * - Cognito `sub` is the canonical user identifier throughout the system:
 *   - User.userId == Cognito sub
 *   - Submission.ownerId == Cognito sub (submission owner)
 *   - Notification.recipientId == Cognito sub (notification receiver)
 *
 * Cognito groups
 * - "general" -> normal users (students)
 * - "admin"   -> admins (staff)
 *
 * Important separation
 * - Schema authorization controls access at the API layer.
 * - Business rules (example: "editable only while SUBMITTED") are not enforced here
 *   and must be enforced by application logic or custom resolvers.
 */
const schema = a.schema({
  // ============================================================
  // ENUMS (shared between backend and client)
  // ============================================================

  /**
   * SubmissionStatus
   *
   * Defines the lifecycle of a feedback submission.
   * Client apps map these values to user-friendly labels.
   */
  SubmissionStatus: a.enum([
    "SUBMITTED",
    "UNDER_REVIEW",
    "IN_PROGRESS",
    "RESOLVED",
    "REJECTED",
    "MORE_INFO_NEEDED",
  ]),

  /**
   * ServiceCategory
   *
   * Code-friendly values representing university services.
   * Flutter maps these to display labels (Arabic/English) in the UI layer.
   */
  ServiceCategory: a.enum([
    "STUDENT_TRANSPORTATION_SERVICES",
    "FOOD_SERVICES",
    "STUDENT_CLINIC",
    "LIBRARY_SERVICES",
    "SPORTS_ACTIVITIES_COMPLEX",
    "INTERNATIONAL_DORMITORIES",
    "LANGUAGE_CENTER",
    "E_LEARNING_PLATFORM",
    "REGISTRATION_AND_ADMISSIONS_SERVICES",
    "JORDAN_UNIVERSITY_HOSPITAL",
    "FINANCIAL_AID_AND_SCHOLARSHIPS",
    "IT_SUPPORT_SERVICES",
    "CAREER_GUIDANCE_AND_COUNSELING",
    "STUDENT_AFFAIRS_AND_EXTRACURRICULAR_ACTIVITIES",
    "SECURITY_AND_CAMPUS_SAFETY",
    "MAINTENANCE_AND_FACILITIES_MANAGEMENT",
    "PARKING_SERVICES",
    "PRINTING_AND_PHOTOCOPYING_SERVICES",
    "BOOKSTORE_SERVICES",
    "ALUMNI_RELATIONS_OFFICE",
  ]),

  /**
   * NotificationType
   *
   * Categorizes notifications for UI filtering and presentation.
   */
  NotificationType: a.enum([
    "STATUS_CHANGED",
    "NEW_ADMIN_REPLY",
    "NEW_USER_REPLY",
    "GENERAL_INFO",
  ]),

  // ============================================================
  // EMBEDDED TYPES (stored inside a model)
  // ============================================================

  /**
   * ReplyEntry
   *
   * Represents a single message in a submission conversation.
   *
   * Fields
   * - fromRole: sender role, expected values:
   *   - "GENERAL"
   *   - "ADMIN"
   * - byId: Cognito sub of the sender.
   * - byName: snapshot of sender name at time of sending.
   * - at: timestamp of the reply creation.
   *
   * Notes
   * - Keep fromRole casing consistent across clients to simplify parsing.
   * - byName is stored as a snapshot to preserve historical accuracy.
   */
  ReplyEntry: a.customType({
    fromRole: a.string().required(),
    message: a.string().required(),
    byId: a.id().required(),
    byName: a.string().required(),
    at: a.datetime().required(),
  }),

  // ============================================================
  // MODELS (DynamoDB tables)
  // ============================================================

  /**
   * PendingUser
   *
   * Purpose
   * - Temporary record created at sign-up time before email verification completes.
   * - Keyed by email because a Cognito `sub` does not exist yet.
   *
   * Recommended flow
   * - Sign up:
   *   - Create PendingUser(email, firstName, lastName)
   *   - Start Cognito sign-up flow
   * - First login after confirmation:
   *   - Lookup PendingUser by email
   *   - Create User using Cognito sub + PendingUser names
   *   - Delete PendingUser
   *
   * Authorization
   * - Public API key can create (needed before authentication exists).
   * - Authenticated users can read/delete for optional cleanup workflows.
   */
  PendingUser: a
    .model({
      email: a.string().required(),
      firstName: a.string().required(),
      lastName: a.string().required(),
    })
    .identifier(["email"])
    .authorization((allow) => [
      allow.publicApiKey().to(["create"]),
      allow.authenticated().to(["read", "delete"]),
    ]),

  /**
   * User
   *
   * Purpose
   * - Permanent profile record for a confirmed Cognito user.
   *
   * Fields
   * - userId: Cognito sub, used as primary key.
   * - role: stored role string for UI/analytics (Cognito groups remain the auth source).
   *
   * Authorization
   * - Owner-based access using userId as the owner field:
   *   - The signed-in user can read/update their own profile record.
   */
  User: a
    .model({
      userId: a.id().required(),
      email: a.string().required(),
      firstName: a.string().required(),
      lastName: a.string().required(),
      role: a.string().required(),
      createdAt: a.datetime().required(),
    })
    .identifier(["userId"])
    .authorization((allow) => [allow.ownerDefinedIn("userId")]),

  /**
   * Submission
   *
   * Represents a single feedback submission created by a general user.
   *
   * Required fields
   * - id, ownerId, serviceCategory, rating, status, createdAt
   *
   * Optional fields
   * - title, description, suggestion, attachmentKey, urgency, internalNotes, replies,
   *   updatedById, updatedByName, respondedAt, updatedAt
   *
   * Business rules (not enforced in schema)
   * - Example: general users edit/delete only when status == SUBMITTED.
   *   Enforce via application logic or custom resolvers.
   *
   * Authorization
   * - Owner can CRUD their own submissions via ownerDefinedIn("ownerId").
   * - Admin group can CRUD any submission.
   */
  Submission: a
    .model({
      id: a.id().required(),
      ownerId: a.id().required(),

      serviceCategory: a.ref("ServiceCategory").required(),
      title: a.string(),
      description: a.string(),
      suggestion: a.string(),
      rating: a.integer().required(),
      attachmentKey: a.string(),

      status: a.ref("SubmissionStatus").required(),
      urgency: a.integer(),
      internalNotes: a.string(),

      replies: a.ref("ReplyEntry").array(),

      updatedById: a.id(),
      updatedByName: a.string(),
      respondedAt: a.datetime(),
      createdAt: a.datetime().required(),
      updatedAt: a.datetime(),
    })
    .identifier(["id"])
    .authorization((allow) => [
      allow.ownerDefinedIn("ownerId").to(["read", "create", "update", "delete"]),
      allow.group("admin").to(["read", "create", "update", "delete"]),
    ]),

  /**
   * Notification
   *
   * Purpose
   * - Persisted notifications delivered to a specific user (recipientId).
   *
   * Required fields
   * - id, recipientId, type, title, body, isRead, createdAt
   *
   * Optional fields
   * - submissionId, readAt
   *
   * Authorization
   * - Owner (recipientId) can read/update/delete their own notifications.
   * - Any authenticated user can create (supports user->admin or system triggers).
   * - Admin group can CRUD all notifications.
   */
  Notification: a
    .model({
      id: a.id().required(),
      recipientId: a.id().required(),
      submissionId: a.id(),
      type: a.ref("NotificationType").required(),
      title: a.string().required(),
      body: a.string().required(),
      isRead: a.boolean().required(),
      createdAt: a.datetime().required(),
      readAt: a.datetime(),
    })
    .identifier(["id"])
    .authorization((allow) => [
      allow.ownerDefinedIn("recipientId").to(["read", "update", "delete"]),
      allow.authenticated().to(["create"]),
      allow.groups(["admin"]).to(["create", "read", "update", "delete"]),
    ]),
});

// Generated data client types for strongly typed frontend access.
export type Schema = ClientSchema<typeof schema>;

/**
 * Amplify data backend definition.
 *
 * Authorization modes
 * - Default: Cognito User Pool (signed-in users)
 * - Additional: API key for PendingUser creation at sign-up time (pre-auth)
 */
export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: "userPool",
    apiKeyAuthorizationMode: {
      expiresInDays: 30,
    },
  },
});