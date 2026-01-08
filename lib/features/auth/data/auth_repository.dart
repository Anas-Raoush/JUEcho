import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// AuthRepository is the single entry point for all authentication-related I/O:
/// - Cognito auth flows (sign up, confirm, sign in, sign out, forgot password)
/// - AppSync GraphQL calls to persist/load the app profile from `Users` table
/// - Admin detection from Cognito JWT groups claim
///
/// Design goals:
/// - Keep UI layers free of Amplify/AppSync implementation details
/// - Provide stable, predictable behavior for common edge cases (already signed in, unconfirmed user)
/// - Prefer "best effort" for non-critical writes (PendingUser create/delete)
class AuthRepository {
  // ==================== GraphQL documents ====================

  /// Creates a row in `Users` table after Cognito confirmation.
  /// The `userId` is the Cognito user sub (stable unique ID).
  static const _createUserMutation = r'''
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) { userId }
  }
  ''';

  /// Reads the user profile from `Users` table by `userId`.
  /// Used after login and at app bootstrap to build in-memory profile.
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

  /// Stores a "pending user" row before email confirmation.
  /// This is used to preserve first/last name because Cognito signUp stores only email attribute.
  static const _createPendingUserMutation = r'''
  mutation CreatePendingUser($input: CreatePendingUserInput!) {
    createPendingUser(input: $input) {
      email
      firstName
      lastName
    }
  }
  ''';

  /// Reads pending user data (first/last name) by email.
  /// Used in the confirmation flow if UI doesn't provide names.
  static const _getPendingUserQuery = r'''
  query GetPendingUser($email: String!) {
    getPendingUser(email: $email) {
      email
      firstName
      lastName
    }
  }
  ''';

  /// Deletes pending user row after successful profile creation.
  /// Best effort cleanup to keep PendingUser table tidy.
  static const _deletePendingUserMutation = r'''
  mutation DeletePendingUser($input: DeletePendingUserInput!) {
    deletePendingUser(input: $input) { email }
  }
  ''';

  // ==================== Session helpers ====================

  /// Returns the current Cognito auth session.
  /// Cast is safe because the configured auth plugin is Cognito.
  static Future<CognitoAuthSession> fetchSession() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session;
  }

  /// Returns the current Cognito user's `sub` (unique user identifier).
  /// This value is used as `userId` in `Users` table.
  static Future<String> currentUserId() async {
    final session = await fetchSession();
    return session.userSubResult.value;
  }

  // ==================== Profile (Users table) ====================

  /// Fetches the current user's profile from the `Users` table (AppSync).
  ///
  /// Notes:
  /// - This method always fetches fresh data (no caching).
  /// - If query fails, it returns a stable empty ProfileData instead of throwing.
  ///   This prevents the UI from crashing during bootstrap and allows graceful handling.
  static Future<ProfileData> fetchCurrentProfileData() async {
    final userId = await currentUserId();

    final request = GraphQLRequest<String>(
      document: _getUserQuery,
      variables: {'userId': userId},
    );

    final response = await Amplify.API.query(request: request).response;

    // Defensive: if AppSync errors or null data, return stable empty profile.
    if (response.errors.isNotEmpty || response.data == null) {
      safePrint('getUser error: ${response.errors}');
      return const ProfileData(
        userId: '',
        email: '',
        firstName: '',
        lastName: '',
        role: '',
      );
    }

    // GraphQL response is JSON string -> decode -> extract getUser.
    final decoded = jsonDecode(response.data!) as Map<String, dynamic>;
    final userJson = decoded['getUser'] as Map<String, dynamic>?;

    if (userJson == null) {
      return const ProfileData(
        userId: '',
        email: '',
        firstName: '',
        lastName: '',
        role: '',
      );
    }

    return ProfileData.fromJson(userJson);
  }

  // ==================== Cognito: Sign up / confirm ====================

  /// Resends the Cognito sign-up confirmation code to the provided email.
  static Future<void> resendSignUpCode(String email) async {
    await Amplify.Auth.resendSignUpCode(username: email);
  }

  /// Signs up a "general" user in Cognito and writes a PendingUser entry (best effort).
  ///
  /// Flow:
  /// 1) Cognito signUp (email + password)
  /// 2) CreatePendingUser in AppSync (API key auth), to store first/last name before confirmation
  ///
  /// Why PendingUser?
  /// - Cognito user attributes may be limited; app profile data lives in `Users` table.
  /// - Email confirmation may happen later; we persist names so we can create `Users` row after confirm.
  ///
  /// Failure behavior:
  /// - If PendingUser creation fails, sign-up still succeeds (best effort).
  static Future<void> signUpGeneral({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // Create Cognito user with email attribute.
    await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {AuthUserAttributeKey.email: email},
      ),
    );

    // Best-effort: create PendingUser using API key auth.
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
      }
    } catch (e) {
      safePrint('createPendingUser exception: $e');
    }
  }

  /// Confirms a Cognito sign-up using the email confirmation code.
  static Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  /// Creates the final app profile in the `Users` table AFTER Cognito confirmation.
  ///
  /// Responsibilities:
  /// 1) Ensure the user is signed in (needed for authenticated AppSync calls)
  /// 2) Resolve first/last name:
  ///    - Prefer the provided args
  ///    - If empty, attempt to load from PendingUser table
  /// 3) Create `Users` row in AppSync
  /// 4) Delete PendingUser entry (best effort cleanup)
  /// 5) Sign out (repo design: force user to log in after confirmation flow)
  static Future<void> createProfileAfterConfirmation({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    // 1) Ensure we have an authenticated session.
    final session = await _ensureSignedIn(email: email, password: password);
    final userId = session.userSubResult.value;
    final now = DateTime.now().toUtc().toIso8601String();

    // 2) Resolve names (use pending record if UI didn't provide names).
    String fn = firstName.trim();
    String ln = lastName.trim();

    if (fn.isEmpty && ln.isEmpty) {
      final pending = await _getPendingUser(email);
      if (pending != null) {
        fn = (pending['firstName'] as String?)?.trim() ?? fn;
        ln = (pending['lastName'] as String?)?.trim() ?? ln;
      }
    }

    // 3) Create Users record.
    final createUserRequest = GraphQLRequest<String>(
      document: _createUserMutation,
      variables: {
        'input': {
          'userId': userId,
          'email': email,
          'firstName': fn,
          'lastName': ln,
          'role': 'general',
          'createdAt': now,
        },
      },
    );

    final createUserResponse =
    await Amplify.API.mutate(request: createUserRequest).response;

    // Hard failure: profile creation is critical for the app to function.
    if (createUserResponse.errors.isNotEmpty) {
      throw createUserResponse.errors.first;
    }

    // 4) cleanup PendingUser.
    try {
      final deleteReq = GraphQLRequest<String>(
        document: _deletePendingUserMutation,
        variables: {'input': {'email': email}},
      );
      final deleteRes = await Amplify.API.mutate(request: deleteReq).response;
      if (deleteRes.errors.isNotEmpty) {
        safePrint('deletePendingUser error: ${deleteRes.errors}');
      }
    } catch (e) {
      safePrint('deletePendingUser exception: $e');
    }

    // 5) Sign out intentionally (The flow expects the user to login again).
    await Amplify.Auth.signOut();
  }

  // ==================== Cognito: Sign in / sign out ====================

  /// Signs in using Cognito and returns a CognitoAuthSession.
  ///
  /// Behavior:
  /// - If user is unconfirmed, throws UserNotConfirmedException
  ///   (so UI can route to confirmation screen).
  /// - If user is "already signed in" (stale session), signs out and retries once.
  static Future<CognitoAuthSession> signIn({
    required String email,
    required String password,
  }) async {
    Future<void> doSignIn() async {
      final res = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      // Success
      if (res.isSignedIn) return;

      // Not completed: check next step for unconfirmed user.
      final step = res.nextStep.signInStep;
      if (step == AuthSignInStep.confirmSignUp) {
        // Normalize the behavior so the UI can handle it consistently.
        throw UserNotConfirmedException('User not confirmed');
      }

      // Other incomplete states can be treated as failure by caller.
    }

    try {
      await doSignIn();
    } on NetworkException{
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // Edge case: old session exists on device.
      if (msg.contains('already signed in')) {
        await Amplify.Auth.signOut();
        await doSignIn();
      } else {
        rethrow;
      }
    }

    return await fetchSession();
  }

  /// Signs out from Cognito (clears local tokens/session).
  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  // ==================== Forgot password ====================

  /// Starts the Cognito reset password flow (sends OTP code).
  static Future<void> startForgotPassword(String email) async {
    await Amplify.Auth.resetPassword(username: email);
  }

  /// Confirms the reset password flow using OTP code and new password.
  static Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await Amplify.Auth.confirmResetPassword(
      username: email,
      newPassword: newPassword,
      confirmationCode: code,
    );
  }

  // ==================== Admin group detection ====================

  /// Returns true if the authenticated user belongs to Cognito group `admin`.
  ///
  /// Implementation details:
  /// - Cognito groups are stored in the ID token payload under `cognito:groups`.
  /// - This is used for UI routing (AdminHome vs GeneralHome).
  ///
  /// Important:
  /// - Backend authorization MUST still enforce admin permissions.
  /// - UI routing is not security.
  static bool isAdminFromSession(CognitoAuthSession session) {
    try {
      final tokens = session.userPoolTokensResult.value;
      final idToken = tokens.idToken.raw;

      // JWT format: header.payload.signature
      final parts = idToken.split('.');
      if (parts.length != 3) return false;

      // Decode base64url payload.
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final groupsClaim = payload['cognito:groups'];

      if (groupsClaim is List) return groupsClaim.contains('admin');
      if (groupsClaim is String) return groupsClaim.split(',').contains('admin');

      // No groups -> not admin -> general (Option B)
      return false;
    } catch (e) {
      safePrint('isAdminFromSession error: $e');
      return false;
    }
  }

  // ==================== Private helpers ====================

  /// Ensures a valid signed-in session exists.
  ///
  /// Used by confirmation flow before creating the `Users` record.
  /// If session does not exist, signs in with provided email/password.
  static Future<CognitoAuthSession> _ensureSignedIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = await fetchSession();
      if (session.isSignedIn) return session;
    } catch (_) {
      // Ignore and attempt sign-in
    }

    final res = await Amplify.Auth.signIn(username: email, password: password);
    if (!res.isSignedIn) {
      throw Exception('Could not establish session while creating profile.');
    }

    final session = await fetchSession();
    if (!session.isSignedIn) throw Exception('Session is not signed in.');
    return session;
  }

  /// Best-effort read of PendingUser by email.
  /// Returns null if not found or if query fails.
  static Future<Map<String, dynamic>?> _getPendingUser(String email) async {
    try {
      final pendingReq = GraphQLRequest<String>(
        document: _getPendingUserQuery,
        variables: {'email': email},
      );

      final pendingRes = await Amplify.API.query(request: pendingReq).response;

      if (pendingRes.errors.isNotEmpty || pendingRes.data == null) {
        safePrint('getPendingUser error: ${pendingRes.errors}');
        return null;
      }

      final decoded = jsonDecode(pendingRes.data!) as Map<String, dynamic>;
      return decoded['getPendingUser'] as Map<String, dynamic>?;
    } catch (e) {
      safePrint('getPendingUser exception: $e');
      return null;
    }
  }
}
