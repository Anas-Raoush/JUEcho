import { defineAuth } from "@aws-amplify/backend";

/**
 * JU Echo Auth:
 * - Users sign up & sign in with email + password
 * - Verification code is sent to email
 * - Cognito only stores: sub (UUID), email, password and standard internal fields
 * - Two groups: general, admin
 */
export const auth = defineAuth({
  loginWith: {
    email: {
      // Send a 6-digit verification code to the user's email for verification
      verificationEmailStyle: "CODE",
      verificationEmailSubject: "Verify your JU Echo account",
      verificationEmailBody: (createCode) =>
        `Your JU Echo verification code is: ${createCode()}`,
    },
  },
  //
  groups: ["general", "admin"],
});
