import { defineAuth } from "@aws-amplify/backend";

/**
 * Amplify Auth configuration for JU Echo (admin-only).
 *
 * Authentication model
 * - Sign-up and sign-in uses email + password.
 * - Email verification uses a 6-digit code delivered to the user's inbox.
 * - Cognito is the identity provider and stores:
 *   - Standard user pool fields (email, password hash, etc.)
 *   - The user's unique identifier (sub / UUID)
 *
 * Authorization model
 * - The app uses Cognito groups for role-based access.
 * - This deployment is admin-only:
 *   - "admin" -> staff / administrators
 *
 * Navigation dependency
 * - The client UI derives role from Cognito group membership.
 * - Only the "admin" group is declared here to avoid role ambiguity in the app
 *   and to ensure admin navigation is selected consistently.
 *
 * Notes
 * - Application data models should use Cognito `sub` as the canonical user id.
 */
export const auth = defineAuth({
  loginWith: {
    email: {
      // Sends a verification code to confirm the email address.
      verificationEmailStyle: "CODE",
      verificationEmailSubject: "Verify your JU Echo account",

      /**
       * Email body template used for sign-up verification.
       *
       * @param createCode Factory callback provided by Amplify that returns
       * a random verification code string.
       * @returns Plain text email body containing the verification code.
       */
      verificationEmailBody: (createCode) =>
        `Your JU Echo verification code is: ${createCode()}`,
    },
  },

  // Only the admin group is used in this project.
  groups: ["admin"],
});