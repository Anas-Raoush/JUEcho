import { a, defineData, type ClientSchema } from "@aws-amplify/backend";

/**
 * ============================================================
 * JU Echo – Data Models (Amplify Gen 2 / TypeScript schema)
 * ============================================================
 *
 * This file defines the entire AppSync GraphQL schema + DynamoDB models.
 * It is the single source of truth for:
 * - Data shapes (fields + required/optional)
 * - Enums used by Flutter
 * - Authorization rules (who can read/write what)
 *
 * ------------------------------------------------------------
 * Core identifiers (IMPORTANT INVARIANTS)
 * ------------------------------------------------------------
 * Cognito `sub` is the global user identifier across the system:
 *   - User.userId             == Cognito sub
 *   - Submission.ownerId      == Cognito sub (submission owner)
 *   - Notification.recipientId== Cognito sub (notification receiver)
 *
 * Cognito groups:
 *   - "general"  => normal users (students)
 *   - "admin"    => admins (staff)
 *
 * ------------------------------------------------------------
 * Domain models summary
 * ------------------------------------------------------------
 * 1) PendingUser
 *    - Temporary record created at sign-up BEFORE email confirmation.
 *    - Keyed by email (no Cognito sub yet).
 *
 * 2) User
 *    - Permanent profile record for confirmed Cognito users.
 *    - Keyed by Cognito sub (userId).
 *
 * 3) Submission
 *    - Feedback submissions created by general users.
 *    - Contains:
 *        a) Core content fields (service, title, description, rating, etc.)
 *        b) Workflow/admin fields (status, urgency, internalNotes, replies, etc.)
 *
 * 4) Notification
 *    - A persisted notification sent to a specific user.
 *    - Used in Flutter to show “Status updated”, “New reply”, etc.
 *
 * ------------------------------------------------------------
 * Authorization model (High-level)
 * ------------------------------------------------------------
 * - General users:
 *    - Can CRUD their own submissions (owner-based authorization).
 *    - Business rule "user can edit/delete only when status == SUBMITTED"
 *      is NOT enforced by schema; it must be enforced by your app logic
 *      or custom mutations/resolvers (Lambda).
 *
 * - Admins:
 *    - Can CRUD any submission.
 *    - Can CRUD notifications (for moderation + admin->user messages).
 *
 * - Public API key:
 *    - Only used for creating PendingUser at sign-up time
 *      (before userPool auth is available).
 *
 * NOTE:
 * Schema auth controls access at the API level, not business rules.
 * Business rules like “editable only while SUBMITTED” must be enforced separately.
 */

const schema = a.schema({
  // ============================================================
  // ENUMS (shared between backend + Flutter)
  // ============================================================

  /**
   * SubmissionStatus
   * - Defines the lifecycle of a feedback submission.
   * - Flutter should map these to user-friendly labels.
   */
  SubmissionStatus: a.enum([
    "SUBMITTED", // user submitted; waiting for admin action
    "UNDER_REVIEW", // admin started reviewing
    "IN_PROGRESS", // issue is being handled
    "RESOLVED", // done/closed
    "REJECTED", // invalid/spam/policy violation
    "MORE_INFO_NEEDED", // admin asked the user to clarify/provide more info
  ]),

  /**
   * ServiceCategory
   * - Code-friendly values.
   * - Flutter maps these to display labels (Arabic/English).
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
   * - Optional enum to categorize notifications in the UI.
   * - Useful for icons/colors and filtering.
   */
  NotificationType: a.enum([
    "STATUS_CHANGED", // submission status changed
    "NEW_ADMIN_REPLY", // admin replied
    "NEW_USER_REPLY", // user replied (useful if admins also get notified)
    "GENERAL_INFO", // generic broadcast/info
  ]),

  // ============================================================
  // EMBEDDED TYPES (stored inside a model)
  // ============================================================

  /**
   * ReplyEntry
   * Represents a single message in a submission conversation.
   *
   * fromRole:
   *   - Use "GENERAL" or "ADMIN" consistently
   *   - (Important: Keep casing consistent with Flutter parsing)
   *
   * byId:
   *   - Cognito sub of the sender
   *
   * byName:
   *   - Snapshot of name at time of sending
   *   - (So old replies still show correct names even if user edits profile later)
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
   * PendingUser (DynamoDB: PendingUsers)
   *
   * Purpose:
   * - Store user-provided names/email BEFORE Cognito confirmation.
   * - Keyed by email because Cognito sub does not exist yet.
   *
   * Recommended flow:
   * 1) Sign up screen:
   *    - Create PendingUser(email, firstName, lastName)
   *    - Then user completes Cognito sign-up flow
   *
   * 2) First login after confirmation:
   *    - Lookup PendingUser by email
   *    - Create User using Cognito sub + PendingUser names
   *    - Delete PendingUser
   *
   * Auth:
   * - Public API key can CREATE (needed pre-auth).
   * - Authenticated users can READ/DELETE (optional cleanup / support).
   */
  PendingUser: a
    .model({
      email: a.string().required(), // primary key
      firstName: a.string().required(),
      lastName: a.string().required(),
    })
    .identifier(["email"])
    .authorization((allow) => [
      allow.publicApiKey().to(["create"]),
      allow.authenticated().to(["read", "delete"]),
    ]),

  /**
   * User (DynamoDB: Users)
   *
   * Purpose:
   * - Permanent profile record for a Cognito user.
   *
   * Fields:
   * - userId: Cognito sub (primary key)
   * - role: "general" or "admin" (used for UI/analytics; group membership is in Cognito)
   *
   * Auth:
   * - ownerDefinedIn("userId") means:
   *    The signed-in user can read/update their own record (where userId == their sub).
   */
  User: a
    .model({
      userId: a.id().required(),
      email: a.string().required(),
      firstName: a.string().required(),
      lastName: a.string().required(),
      role: a.string().required(), // "general" | "admin"
      createdAt: a.datetime().required(),
    })
    .identifier(["userId"])
    .authorization((allow) => [
      allow.ownerDefinedIn("userId"),
    ]),

  /**
   * Submission (DynamoDB: Submissions)
   *
   * Represents a single feedback submission created by a general user.
   *
   * Required fields (must never be null):
   * - id, ownerId, serviceCategory, rating, status, createdAt
   *
   * Optional fields (can be null):
   * - title, description, suggestion, attachmentKey, urgency, internalNotes, replies,
   *   updatedById, updatedByName, respondedAt, updatedAt
   *
   * Business rules (NOT enforced here):
   * - General users can only edit/delete while status == SUBMITTED
   *   -> enforce in app logic or custom resolvers (Lambda).
   *
   * Auth:
   * - ownerDefinedIn("ownerId"): general users can CRUD only their own items.
   * - allow.group("admin"): admins can CRUD any item.
   */
  Submission: a
    .model({
      // Identity
      id: a.id().required(),
      ownerId: a.id().required(),

      // Core content
      serviceCategory: a.ref("ServiceCategory").required(),
      title: a.string(),
      description: a.string(),
      suggestion: a.string(),
      rating: a.integer().required(), // 1–5
      attachmentKey: a.string(), // S3 object key

      // Workflow
      status: a.ref("SubmissionStatus").required(),
      urgency: a.integer(), // 1–5 (admin set)
      internalNotes: a.string(), // admin internal notes

      // Conversation
      replies: a.ref("ReplyEntry").array(),

      // Admin audit fields
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
   * Notification (DynamoDB: Notifications)
   *
   * Purpose:
   * - Persisted notifications for users.
   *
   * Required:
   * - id, recipientId, type, title, body, isRead, createdAt
   *
   * Optional:
   * - submissionId, readAt
   *
   * Auth:
   * - Users can read/update/delete their own notifications.
   * - Any authenticated user can create (supports user->admin notifications if needed).
   * - Admins can CRUD all (moderation/admin broadcast).
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

// Types for generated data client
export type Schema = ClientSchema<typeof schema>;

/**
 * Data backend definition
 *
 * Default authorization: Cognito User Pool (signed-in users)
 * Additional mode: API key (public) for PendingUser creation at sign-up time
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