import { a, defineData, type ClientSchema } from "@aws-amplify/backend";

/**
 * JU Echo data models (Gen 2 / TypeScript schema)
 *
 * - PendingUser:
 *    - Stores first/last name + email for users who signed up
 *      but haven’t confirmed their email yet.
 *    - Keyed by email (no Cognito sub yet).
 *
 * - User:
 *    - Auth profile linked to Cognito user (sub)
 *    - Stores first/last name, email, role, createdAt
 *
 * - Submission:
 *    - Immutable student feedback data (service, title, description,
 *      suggestion, rating, attachment, submittedAt)
 *    - Mutable workflow fields controlled by admins
 *      (status, urgency, internalNotes, replies, updatedBy..., respondedAt...)
 *
 * - Notification:
 *    - Stored notifications for general users (and optionally admins)
 *    - Used to show a list of "Your submission was updated", "New reply", etc.
 *
 * IMPORTANT INVARIANTS
 * - Cognito `sub` is the global user identifier:
 *      - User.userId          == Cognito sub
 *      - Submission.ownerId   == Cognito sub
 *      - Notification.recipientId == Cognito sub
 * - Students ("general") are in Cognito group "general"
 * - Admins ("admin") are in Cognito group "admin"
 *
 * AUTHZ CONCEPT
 * - Students can READ their own submissions via auto-generated resolvers.
 * - Students can CREATE/UPDATE/DELETE their own submissions, but:
 *      - The "only when status == SUBMITTED" rule is enforced in
 *        custom mutations (Lambdas), not in schema.
 * - Admins can manage all submissions.
 */

const schema = a.schema({
  // =====================
  // ENUMS
  // =====================

  // Submission lifecycle state
  SubmissionStatus: a.enum([
    "SUBMITTED",         // student submitted; waiting for admin
    "UNDER_REVIEW",      // admin is handling it
    "IN_PROGRESS",       // work in progress
    "RESOLVED",          // completed / closed
    "REJECTED",          // spam / invalid / policy violation
    "MORE_INFO_NEEDED",  // admin requested more info from student
  ]),

  // Service categories (code-friendly values; Flutter maps to pretty labels)
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

  // Optional: type of notification (you can map to icons in Flutter)
  NotificationType: a.enum([
    "STATUS_CHANGED",      // status changed on a submission
    "NEW_ADMIN_REPLY",     // admin replied to student
    "NEW_USER_REPLY",      // user replied back (for admin-side notifications)
    "GENERAL_INFO",        // generic info / broadcast
  ]),

  // =====================
  // EMBEDDED TYPES
  // =====================

  // Full chat-style conversation between student and admin
  ReplyEntry: a.customType({
    fromRole: a.string().required(), // "GENERAL" or "ADMIN"
    message: a.string().required(),
    byId: a.id().required(),         // Cognito sub
    byName: a.string().required(),   // snapshot of display name
    at: a.datetime().required(),     // timestamp of this message
  }),

  // =====================
  // MODELS
  // =====================

  /**
   * PendingUser (unconfirmed sign-ups)
   *
   * - Stores first/last name + email *before* Cognito confirmation
   * - Keyed by email (no Cognito sub yet)
   *
   * Flow idea:
   *  - On signup page:
   *      * call a mutation / Lambda to create PendingUser(email, firstName, lastName, createdAt)
   *  - When user confirms later via login:
   *      * look up PendingUser by email
   *      * create real User row with Cognito sub + names
   *      * delete PendingUser row
   */
  PendingUser: a
    .model({
      email: a.string().required(),      // primary key
      firstName: a.string().required(),
      lastName: a.string().required(),
    })
    .identifier(["email"])
    .authorization((allow) => [
      // 1) Allow unauthenticated "create" via API key at sign-up time
          allow.publicApiKey().to(["create"]),
          // 2) Signed-in users can read/delete their own PendingUser if needed
              allow.authenticated().to(["read", "delete"]),
    ]),

  /**
   * User profile table (DynamoDB: Users)
   *
   * - One row per Cognito user (student or admin)
   * - userId == Cognito sub (UUID)
   * - Email here must match Cognito email (used for lookups / analytics)
   */
  User: a
    .model({
      userId: a.id().required(),        // Cognito sub
      email: a.string().required(),     // must be unique in Cognito
      firstName: a.string().required(), // stored here, not in Cognito
      lastName: a.string().required(),
      role: a.string().required(),      // "general" or "admin" (for analytics / UI)
      createdAt: a.datetime().required(),
    })
    .identifier(["userId"])
    .authorization((allow) => [
      // Each signed-in user can see/update their own profile.
      // Admins do NOT modify other profiles directly through this API.
      allow.ownerDefinedIn("userId"),
    ]),

  /**
   * Feedback submissions table (DynamoDB: Submissions)
   *
   * Student's submission data:
   *  - ownerId, serviceCategory, title, description, suggestion,
   *    rating, attachmentKey, createdAt
   *
   * Workflow / moderation fields (admins manage these):
   *  - status, urgency, internalNotes, replies,
   *    updatedById, updatedByName, respondedAt, updatedAt
   *
   * NOTE:
   * - Students can technically CREATE/UPDATE/DELETE their own submissions
   *   via this API auth rule, but we will enforce:
   *      "only while status == SUBMITTED"
   *   inside custom mutations / resolver logic.
   */
  Submission: a
    .model({
      // Identity
      id: a.id().required(),      // Submission ID (uuid)
      ownerId: a.id().required(), // student's Cognito sub

      // Core submission content (immutable after creation by business rules)
      serviceCategory: a.ref("ServiceCategory").required(),
      title: a.string(),              // optional to allow rating-only submissions
      description: a.string(),        // optional to allow rating-only submissions
      suggestion: a.string(),         // optional improvement idea
      rating: a.integer().required(), // 1–5 stars, required for every submission
      attachmentKey: a.string(),      // S3 key: incoming/... or approved/...

      // Lifecycle / workflow
      status: a.ref("SubmissionStatus").required(), // initial SUBMITTED
      urgency: a.integer(),                        // 1–5, set by admin later

      // Admin-only notes (enforced in UI; backend still returns the field)
      internalNotes: a.string(),

      // Conversation (chat-style)
      replies: a.ref("ReplyEntry").array(),        // full message history

      // Who last touched this submission on the admin side
      updatedById: a.id(),
      updatedByName: a.string(),
      respondedAt: a.datetime(), // last admin reply time (if any)

      // Timestamps
      createdAt: a.datetime().required(), // "submitted at"
      updatedAt: a.datetime(),            // last workflow update
    })
    .identifier(["id"])
    .authorization((allow) => [
      // Students: CRUD their own submissions.
      // IMPORTANT: business rule "only while SUBMITTED" will be enforced
      // in custom mutations / Lambda, not here.
      allow.ownerDefinedIn("ownerId").to(["read", "create", "update", "delete"]),

      // Admins: full access to manage any submission
      allow.group("admin"),
    ]),

  /**
   * Notification model (DynamoDB: Notifications)
   *
   * - Stores notifications for users (primarily general users).
   * - One row per notification event.
   *
   * Typical examples:
   *  - "Your submission about Food Services has been marked as RESOLVED."
   *  - "Admin replied to your submission."
   */
  Notification: a
    .model({
      id: a.id().required(),          // notification id (uuid)
      recipientId: a.id().required(), // Cognito sub of the user who receives it

      // Optional links to a submission/event
      submissionId: a.id(),           // related Submission.id (if any)

      type: a.ref("NotificationType").required(),

      title: a.string().required(),   // short title: "Status updated"
      body: a.string().required(),    // longer message

      isRead: a.boolean().required(), // has the user opened it?
      createdAt: a.datetime().required(),
      readAt: a.datetime(),           // when it was marked as read
    })
    .identifier(["id"])
    .authorization((allow) => [
      // User can see their own notifications
      allow.ownerDefinedIn("recipientId"),

      // Admins may read all notifications (for analytics / debugging)
      allow.group("admin").to(["read"]),
    ]),
});

// Types for generated data client
export type Schema = ClientSchema<typeof schema>;

// Data backend definition
export const data = defineData({
  schema,
  authorizationModes: {
    defaultAuthorizationMode: "userPool",
    apiKeyAuthorizationMode: {
      expiresInDays: 30, // pick any valid number of days you want
    },
  },
});
