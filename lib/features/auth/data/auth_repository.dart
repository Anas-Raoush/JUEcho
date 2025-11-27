import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// Repository responsible for handling all authentication and user-profile
/// operations for the application.
///
/// This class centralizes all communication with AWS services:
///
/// • AWS Cognito — for sign-up, sign-in, password operations, and session data
/// • AWS AppSync (GraphQL) — for storing and retrieving permanent user records
/// • PendingUser table — temporary storage for user names before email confirmation
///
/// Additionally, this repository now includes:
///
/// • **Lightweight in-memory caching** of the current user's profile
///   This reduces unnecessary GraphQL reads when navigating between pages
///   (e.g., Home <-> Profile), improves perceived performance, and avoids
///   repeated backend costs.
///
/// By keeping all authentication, profile management, PendingUser migration,
/// and caching logic inside this layer, the UI remains clean, testable, and
/// fully decoupled from AWS implementation details.
class AuthRepository {
  // ==================== GraphQL documents ====================

  /// GraphQL mutation to create a permanent User record in DynamoDB.
  ///
  /// Runs after a user confirms their email. Stores:
  /// - userId (Cognito sub)
  /// - email
  /// - firstName
  /// - lastName
  /// - role (default: "general")
  /// - createdAt timestamp
  static const _createUserMutation = r'''
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) {
      userId
    }
  }
  ''';

  /// GraphQL query used to fetch a User record by Cognito userId.
  ///
  /// Primarily used inside:
  ///   - fetchCurrentUserFullName()
  static const _getUserQuery = r'''
  query GetUser($userId: ID!) {
    getUser(userId: $userId) {
      userId
      email
      firstName
      lastName
      role
    }
  }
  ''';

  /// Mutation to create a PendingUser entry.
  ///
  /// Why?
  /// Cognito does *not* store firstName/lastName.
  /// We temporarily store them in DynamoDB until the user confirms their email.
  static const _createPendingUserMutation = r'''
  mutation CreatePendingUser($input: CreatePendingUserInput!) {
    createPendingUser(input: $input) {
      email
      firstName
      lastName
    }
  }
''';

  /// Query to retrieve a PendingUser row by email.
  ///
  /// Used when a user signs up -> leaves -> returns later to confirm manually.
  static const _getPendingUserQuery = r'''
  query GetPendingUser($email: String!) {
    getPendingUser(email: $email) {
      email
      firstName
      lastName
    }
  }
  ''';

  /// Mutation that deletes a PendingUser row after confirmation.
  ///
  /// This is a cleanup step — not required for authentication, but keeps
  /// the table clean from unnecessary rows.
  static const _deletePendingUserMutation = r'''
  mutation DeletePendingUser($input: DeletePendingUserInput!) {
    deletePendingUser(input: $input) {
      email
    }
  }
''';

  // ==================== User profile helpers ====================

  /// In–memory cache of the current user's profile, populated from the Users table.
  ///
  /// This is process-local only (lost on app restart) and is used to:
  /// - avoid repeated GraphQL calls on every navigation to Home/Profile
  /// - provide an immediate "Welcome <name>" without a visible loading flicker
  static ProfileData? _cachedProfile;

  /// Convenience getter that returns a nicely formatted full name from the cache,
  /// or null if we don't have anything cached yet.
  ///
  /// This is used as:
  /// - initialData for FutureBuilders
  /// - a quick synchronous way to display the user's name when we *might* have it
  static String? get cachedFullName {
    final p = _cachedProfile;
    if (p == null) return null;
    final name = '${p.firstName} ${p.lastName}'.trim();
    return name.isEmpty ? null : name;
  }

  /// Clears all in-memory profile cache.
  ///
  /// This should be called whenever the authentication context changes in a way
  /// that makes the cached profile potentially stale (e.g. sign out).
  static void clearCachedProfile() {
    _cachedProfile = null;
  }

  /// Fetches the current user's profile from the Users table, with simple
  /// in-memory caching.
  ///
  /// Behavior:
  /// - On the first call (or when forceRefresh = true), it:
  ///   - reads the current Cognito session to get userId (userSub)
  ///   - issues a GraphQL getUser query
  ///   - builds a ProfileData and stores it in [_cachedProfile]
  /// - On subsequent calls (and forceRefresh = false), it returns the cached
  ///   ProfileData without hitting the network.
  ///
  /// In case of GraphQL errors or missing data, a fallback ProfileData is
  /// created (with empty fields and role "general") to avoid crashing the UI.
  static Future<ProfileData> fetchCurrentProfileData({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedProfile != null) {
      safePrint('Using cached profile');
      return _cachedProfile!;
    }

    // 1) Get current userId from session
    final session =
    await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final userId = session.userSubResult.value;

    // 2) GraphQL getUser
    final request = GraphQLRequest<String>(
      document: _getUserQuery,
      variables: {'userId': userId},
    );

    final response = await Amplify.API.query(request: request).response;

    if (response.errors.isNotEmpty || response.data == null) {
      safePrint('getUser error: ${response.errors}');
      // Fallback empty profile to keep UI stable
      final fallback = ProfileData(
        userId:'',
        email: '',
        firstName: '',
        lastName: '',
      );
      _cachedProfile = fallback;
      return fallback;
    }

    final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
    final userJson = decoded['getUser'] as Map<String, dynamic>?;
    /*
      decoded == {
        "getUser": {
          "userId": "b3f7a2d1-9144-4af1-aac2-80b12f5c9423",
          "firstName": "Ahmad",
          "lastName": "Saleh",
          "role": "general"
        }
      }

       */

    if (userJson == null) {
      final fallback = ProfileData(
        userId:'',
        email: '',
        firstName: '',
        lastName: '',
      );
      _cachedProfile = fallback;
      return fallback;
    }
    safePrint('Use fresh values');
    final profile = ProfileData.fromJson(userJson);
    _cachedProfile = profile;
    return profile;
  }

  /// Returns the current user's full name (First + Last) using the cached
  /// profile where possible.
  ///
  /// - If [forceRefresh] is false (default), this will reuse the in-memory
  ///   cache from [fetchCurrentProfileData] when available.
  /// - If [forceRefresh] is true, it will always re-query the backend.
  ///
  /// Returns "User" as a safe fallback when we can't resolve a name.
  static Future<String> fetchCurrentUserFullName({
    bool forceRefresh = false,
  }) async {
    final profile = await fetchCurrentProfileData(forceRefresh: forceRefresh);
    final name = '${profile.firstName} ${profile.lastName}'.trim();
    return name.isEmpty ? 'User' : name;
  }

  /// Updates only the cached first and last name in memory.
  ///
  /// This does *not* call the backend — it is meant to be used *after* a
  /// successful profile update mutation so that:
  /// - Home page welcome text updates immediately
  /// - we avoid an extra GraphQL round-trip just to refresh the name
  static void updateCachedName({
    required String firstName,
    required String lastName,
  }) {
    final existing = _cachedProfile;
    if (existing == null) return;
    _cachedProfile = ProfileData(
      email: existing.email,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Signs the user out of Cognito and clears any in-memory profile cache.
  ///
  /// This ensures that:
  /// - no stale name/role leaks into the next session
  /// - Home/Profile widgets that use [cachedFullName] start from a clean state
  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } finally {
      clearCachedProfile();
    }
  }


  // ==================== Sign up / confirm ====================

  /// Requests AWS Cognito to resend a confirmation code to the given email.
  ///
  /// Used when:
  /// - user attempts login while still unconfirmed
  /// - user taps "Resend Code" in confirmation page
  static Future<void> resendSignUpCode(String email) async {
    final res = await Amplify.Auth.resendSignUpCode(username: email);
    safePrint('resendSignUpCode: $res');
  }

  /// Registers a new user using AWS Cognito email/password authentication.
  ///
  /// Behavior:
  /// - Creates the user in Cognito.
  /// - Does **not** store the names in Cognito.
  /// - Instead, stores first/last name in `PendingUser` DynamoDB table.
  ///   (This record will be moved to `Users` table only after confirmation.)
  ///
  /// NOTE:
  /// Failure to store pending user does NOT stop signup.
  static Future<void> signUpGeneral({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final res = await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {
          AuthUserAttributeKey.email: email, // stores email as an attribute
        },
      ),
    );
    safePrint('SignUp result: $res');

    final pendingReq = GraphQLRequest<String>(
      document: _createPendingUserMutation,
      variables: {
        'input': {
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
        },
      },
      authorizationMode: APIAuthorizationType.apiKey,
    );
    try {
      final pendingRes = await Amplify.API.mutate(request: pendingReq).response;

      if (pendingRes.errors.isNotEmpty) {
        safePrint('createPendingUser error: ${pendingRes.errors}');
        // Do NOT throw, so signup flow continues even if this fails
      } else {
        safePrint('PendingUser created: ${pendingRes.data}');
      }
    } catch (e) {
      safePrint('createPendingUser exception: $e');
      // Again, don't rethrow – we don't want to block signup
    }
  }

  /// Confirms the sign-up using the verification code sent to the user's email.
  ///
  /// If the code is valid:
  ///   - Cognito marks the user as confirmed.
  ///   - No user profile is created yet; that happens later in `createProfileAfterConfirmation`.
  static Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    final res = await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
    safePrint('ConfirmSignUp result: $res');
  }

  /// After a user confirms their sign-up, this method:
  ///
  /// 1. Ensures there is a valid signed-in Cognito session (handles "already
  ///    signed in" gracefully).
  /// 2. Resolves the user's first/last name:
  ///    - uses the passed [firstName]/[lastName] when available, or
  ///    - falls back to the PendingUser row if those are empty.
  /// 3. Creates a permanent User record in the Users table with:
  ///    - userId (Cognito sub)
  ///    - email
  ///    - firstName, lastName
  ///    - role = "general"
  ///    - createdAt timestamp
  /// 4. Deletes the corresponding PendingUser row to keep that table clean.
  /// 5. Signs the user out so that the normal login flow is followed next.
  ///
  /// Any failures in the PendingUser cleanup step are logged but do not
  /// invalidate the already-created User record.
  static Future<void> createProfileAfterConfirmation({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // 1) Make sure we have a signed-in session and get the user sub.
    CognitoAuthSession session;

    /// Local helper that:
    /// - signs the user in
    /// - ensures the session is valid
    /// - returns CognitoAuthSession
    Future<CognitoAuthSession> _signInAndGetSession() async {
      try {
        final result = await Amplify.Auth.signIn(
          username: email,
          password: password,
        );

        // If Cognito says sign-in not completed, treat as error.
        if (!result.isSignedIn) {
          throw Exception(
            'Sign in was not completed while creating the profile.',
          );
        }
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();


        // AWS may say "already signed in"
        // In that case we do NOT fail; we reuse the existing session.
        if (!msg.contains('already signed in')) {
          rethrow; // bubble up other auth errors (wrong password, etc.)
        }
      }

      final s = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      if (!s.isSignedIn) {
        throw Exception('Session is not signed in after sign-in call.');
      }
      return s;
    }
    // Try to reuse existing session first
    try {
      session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      if (!session.isSignedIn) {
        session = await _signInAndGetSession();
      }
    } on AuthException {
      // If session fetch fails, explicitly sign in
      session = await _signInAndGetSession();
    }
    // Extract Cognito userSub — unique userId
    final userId = session.userSubResult.value; // v2 API
    final now = DateTime.now().toUtc().toIso8601String();

    // 2) Determine final first/last name
    //    If coming from login-after-unconfirmed, names passed to this function
    //    will be empty -> we load them from PendingUser table.
    var finalFirstName = firstName.trim();
    var finalLastName = lastName.trim();

    if (finalFirstName.isEmpty && finalLastName.isEmpty) {
      try {
        final pendingReq = GraphQLRequest<String>(
          document: _getPendingUserQuery,
          variables: {'email': email},
        );
        final pendingRes = await Amplify.API
            .query(request: pendingReq)
            .response;

        if (pendingRes.errors.isNotEmpty) {
          safePrint('getPendingUser error: ${pendingRes.errors}');
        } else if (pendingRes.data != null) {

          final decoded = jsonDecode(pendingRes.data!) as Map<String, dynamic>;
          final pending = decoded['getPendingUser'] as Map<String, dynamic>?;

          if (pending != null) {
            finalFirstName =
                (pending['firstName'] as String?)?.trim() ?? finalFirstName;
            finalLastName =
                (pending['lastName'] as String?)?.trim() ?? finalLastName;
          }
        }
      } catch (e) {
        safePrint('getPendingUser exception: $e');
      }
    }

    // 3) Create the permanent User record
    final createUserRequest = GraphQLRequest<String>(
      document: _createUserMutation,
      variables: {
        'input': {
          'userId': userId,
          'email': email,
          'firstName': finalFirstName,
          'lastName': finalLastName,
          'role': 'general',
          'createdAt': now,
        },
      },
    );

    final createUserResponse = await Amplify.API
        .mutate(request: createUserRequest)
        .response;

    // If any GraphQL errors -> fail the whole flow
    if (createUserResponse.errors.isNotEmpty) {
      throw createUserResponse.errors.first;
    }

    safePrint('User profile created: ${createUserResponse.data}');

    // 4) Delete PendingUser
    try {
      final deleteReq = GraphQLRequest<String>(
        document: _deletePendingUserMutation,
        variables: {
          'input': {
            'email': email,
          },
        },
      );

      final deleteRes =
      await Amplify.API.mutate(request: deleteReq).response;

      if (deleteRes.errors.isNotEmpty) {
        safePrint('deletePendingUser error: ${deleteRes.errors}');
      } else {
        safePrint('PendingUser deleted for $email');
      }
    } catch (e) {
      safePrint('deletePendingUser exception: $e');
    }

    // 5) Sign out the user
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('signOut after successful profile creation failed: $e');
    }
  }

  // ==================== Sign in / groups ====================

  /// Signs a user in using Cognito and returns an authenticated session.
  ///
  /// Behavior:
  /// - If credentials are correct -> returns CognitoAuthSession
  /// - If user is unconfirmed -> throws UserNotConfirmedException
  /// - If user is already signed in -> signs out and retries once
  static Future<CognitoAuthSession> signIn({
    required String email,
    required String password,
  }) async {
    Future<void> _doSignIn() async {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (!result.isSignedIn) {
        throw Exception(
          'Sign in was not completed. Please check your email and password.',
        );
      }
    }

    try {
      await _doSignIn();
    } on UserNotConfirmedException {
      // Bubble up a clearer exception message for the UI.
      throw UserNotConfirmedException(
        'Your email is not verified. Please check your inbox and confirm your account.',
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // Handle Cognito "already signed in" edge case
      if (msg.contains('already signed in')) {
        safePrint('A user was already signed in. Signing out and retrying...');
        await Amplify.Auth.signOut(); // clear old session
        await _doSignIn(); // retry
      } else {
        rethrow; // bubble up other errors
      }
    }
    // Return the final authenticated session
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session;
  }

  /// Checks whether the current user's ID token includes the 'admin' group.
  ///
  /// Group-based authorization in Cognito works by embedding group names inside
  /// the JWT *idToken* payload under `"cognito:groups"`.
  ///
  /// Returns:
  /// - true  -> user is admin
  /// - false -> user is general
  static bool isAdminFromSession(CognitoAuthSession session) {
    try {
      /*
       {
        "isSignedIn": true,
        "userSubResult": {
          "value": "b3f7a2d1-9144-4af1-aac2-80b12f5c9423"
        },
        "userPoolTokensResult": {
          "value": {
            "idToken": "header.payload.signature",
            "accessToken": "...",
            "refreshToken": "..."
          }
        }
        }
      */
      // Extract all tokens (idToken, accessToken, refreshToken)
      final tokens = session.userPoolTokensResult.value;
      // Extract raw ID token string (JWT format)
      final jwt = tokens.idToken;
      final idToken = jwt.raw;
      // JWT format = "header.payload.signature"
      final parts = idToken.split('.');
      if (parts.length != 3) return false;

      // Decode the Base64URL-encoded payload part
      final payloadJson = utf8.decode(
        base64Url.decode(
          base64Url.normalize(
            parts[1],
          ), // ensure proper padding
        ),
      );
      /*
      {
        "sub": "6cfa6625-9556-4da2-9a9b-afabef1645ef",
        "cognito:groups": ["admin"],
        "email":  "admin@ju.edu.jo",
        "email_verified": true,
        "exp": 1731397800,
        "iat": 1731394000,
        "iss": "https://cognito-idp.region.amazonaws.com/your_userpool_id",
        "cognito:username": "admin@ju.edu.jo"
      }
       */

      // Parse JSON
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      final groupsClaim = payload['cognito:groups'];

      if (groupsClaim is List) {
        return groupsClaim.contains('admin');
      } else if (groupsClaim is String) {
        return groupsClaim.split(',').contains('admin');
      }
      return false;
    } catch (e) {
      safePrint('isAdminFromSession error: $e');
      return false;
    }
  }

  // ==================== Forgot password ====================

  /// Begins the "forgot password" flow by requesting AWS Cognito to send a
  /// password-reset code to the user's email.
  static Future<void> startForgotPassword(String email) async {
    final res = await Amplify.Auth.resetPassword(username: email);
    safePrint('resetPassword: $res');
  }

  /// Completes the password reset process.
  ///
  /// Throws:
  /// - AuthException -> wrong code, weak password, expired code, etc.
  /// - Exception     -> unexpected errors
  static Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final res = await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: code,
      );
      safePrint('confirmResetPassword: $res');
    } on AuthException catch (e) {
      // Let the UI handle detailed errors (code mismatch, weak password, etc.)
      safePrint('confirmResetPassword AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      // Truly unexpected error
      safePrint('confirmResetPassword unexpected error: $e');
      throw Exception(
        'Unexpected error confirming password reset. Please try again later',
      );
    }
  }
}
