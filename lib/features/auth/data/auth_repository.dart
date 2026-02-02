import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// Centralized authentication and identity persistence layer.
///
/// Responsibilities:
/// - Cognito authentication flows:
///   -> sign up, confirm sign up, sign in, sign out
///   -> resend confirmation code
///   -> forgot password and confirmation
/// - App profile persistence through AppSync GraphQL:
///   -> create and read Users table records
///   -> create/read/delete PendingUser records used during email confirmation
/// - Admin role detection:
///   -> resolves admin membership from Cognito JWT groups claim
///
/// Data model assumptions:
/// - Cognito user sub is the system-wide identifier (Users.userId).
/// - Users.role is stored for app-level usage; authorization is enforced by Cognito/AppSync rules.
/// - Admin membership is derived from Cognito group "admin".
///
/// Failure strategy:
/// - Profile creation is treated as critical (throws on failure).
/// - PendingUser writes/deletes are best-effort (logs errors, does not block sign up).
/// - Profile fetch failures return an empty ProfileData to keep bootstrap stable.
class AuthRepository {
  // ==================== GraphQL documents ====================

  static const _createUserMutation = r'''
  mutation CreateUser($input: CreateUserInput!) {
    createUser(input: $input) { userId }
  }
  ''';

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

  static const _createPendingUserMutation = r'''
  mutation CreatePendingUser($input: CreatePendingUserInput!) {
    createPendingUser(input: $input) {
      email
      firstName
      lastName
    }
  }
  ''';

  static const _getPendingUserQuery = r'''
  query GetPendingUser($email: String!) {
    getPendingUser(email: $email) {
      email
      firstName
      lastName
    }
  }
  ''';

  static const _deletePendingUserMutation = r'''
  mutation DeletePendingUser($input: DeletePendingUserInput!) {
    deletePendingUser(input: $input) { email }
  }
  ''';

  // ==================== Session helpers ====================

  /// Returns the current CognitoAuthSession.
  /// The cast is safe when AmplifyAuthCognito is the configured auth plugin.
  static Future<CognitoAuthSession> fetchSession() async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    return session;
  }

  /// Returns the Cognito user sub for the active session.
  /// Used as Users.userId across the data model.
  static Future<String> currentUserId() async {
    final session = await fetchSession();
    return session.userSubResult.value;
  }

  // ==================== Profile (Users table) ====================

  /// Fetches the current user's profile from AppSync (Users table).
  ///
  /// Returns:
  /// - ProfileData from the Users table if available
  /// - Empty ProfileData if AppSync returns errors, null data, or missing user record
  ///
  /// This method is designed to keep bootstrap stable and allow the caller to
  /// treat missing/failed profile reads as a recoverable state.
  static Future<ProfileData> fetchCurrentProfileData() async {
    final userId = await currentUserId();

    final request = GraphQLRequest<String>(
      document: _getUserQuery,
      variables: {'userId': userId},
    );

    final response = await Amplify.API.query(request: request).response;

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

  static Future<void> resendSignUpCode(String email) async {
    await Amplify.Auth.resendSignUpCode(username: email);
  }

  /// Signs up a general user in Cognito and persists a PendingUser row (best effort).
  ///
  /// Flow:
  /// - Cognito signUp(email, password, attributes)
  /// - createPendingUser(email, firstName, lastName) via AppSync using API key auth
  ///
  /// PendingUser exists to preserve names before email confirmation and before the Users
  /// record is created. This ensures the Users record can be built after confirmation
  /// even if the confirmation happens on a different session/device.
  static Future<void> signUpGeneral({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    await Amplify.Auth.signUp(
      username: email,
      password: password,
      options: SignUpOptions(
        userAttributes: {AuthUserAttributeKey.email: email},
      ),
    );

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

  static Future<void> confirmSignUp({
    required String email,
    required String code,
  }) async {
    await Amplify.Auth.confirmSignUp(
      username: email,
      confirmationCode: code,
    );
  }

  /// Creates a Users record after the user has confirmed their email.
  ///
  /// Flow:
  /// - ensure session exists (sign in if required) -> get user sub
  /// - resolve first/last name:
  ///   -> prefer provided values
  ///   -> if empty, fall back to PendingUser record
  /// - create Users record with role = "general"
  /// - delete PendingUser row (best effort)
  /// - sign out (forces a clean post-confirmation sign-in flow)
  static Future<void> createProfileAfterConfirmation({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final session = await _ensureSignedIn(email: email, password: password);
    final userId = session.userSubResult.value;
    final now = DateTime.now().toUtc().toIso8601String();

    String fn = firstName.trim();
    String ln = lastName.trim();

    if (fn.isEmpty && ln.isEmpty) {
      final pending = await _getPendingUser(email);
      if (pending != null) {
        fn = (pending['firstName'] as String?)?.trim() ?? fn;
        ln = (pending['lastName'] as String?)?.trim() ?? ln;
      }
    }

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

    if (createUserResponse.errors.isNotEmpty) {
      throw createUserResponse.errors.first;
    }

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

    await Amplify.Auth.signOut();
  }

  // ==================== Cognito: Sign in / sign out ====================

  /// Signs in with Cognito and returns an authenticated session.
  ///
  /// Behavior:
  /// - If signIn results in confirmSignUp next step -> throws UserNotConfirmedException
  /// - If device has a stale "already signed in" state -> sign out and retry once
  static Future<CognitoAuthSession> signIn({
    required String email,
    required String password,
  }) async {
    Future<void> doSignIn() async {
      final res = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );

      if (res.isSignedIn) return;

      final step = res.nextStep.signInStep;
      if (step == AuthSignInStep.confirmSignUp) {
        throw UserNotConfirmedException('User not confirmed');
      }
    }

    try {
      await doSignIn();
    } on NetworkException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('already signed in')) {
        await Amplify.Auth.signOut();
        await doSignIn();
      } else {
        rethrow;
      }
    }

    return await fetchSession();
  }

  static Future<void> signOut() async {
    await Amplify.Auth.signOut();
  }

  // ==================== Forgot password ====================

  static Future<void> startForgotPassword(String email) async {
    await Amplify.Auth.resetPassword(username: email);
  }

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

  /// Determines whether the current session belongs to a user in the "admin" group.
  ///
  /// Source of truth:
  /// - Cognito ID token payload claim "cognito:groups"
  ///
  /// Output is intended for UI routing and role-based presentation.
  /// Backend authorization must remain enforced by AppSync/Cognito rules.
  static bool isAdminFromSession(CognitoAuthSession session) {
    try {
      final tokens = session.userPoolTokensResult.value;
      final idToken = tokens.idToken.raw;

      final parts = idToken.split('.');
      if (parts.length != 3) return false;

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
      final groupsClaim = payload['cognito:groups'];

      if (groupsClaim is List) return groupsClaim.contains('admin');
      if (groupsClaim is String) return groupsClaim.split(',').contains('admin');

      return false;
    } catch (e) {
      safePrint('isAdminFromSession error: $e');
      return false;
    }
  }

  // ==================== Private helpers ====================

  /// Ensures a valid signed-in session exists.
  /// Used by createProfileAfterConfirmation to guarantee authenticated AppSync access.
  static Future<CognitoAuthSession> _ensureSignedIn({
    required String email,
    required String password,
  }) async {
    try {
      final session = await fetchSession();
      if (session.isSignedIn) return session;
    } catch (_) {}

    final res = await Amplify.Auth.signIn(username: email, password: password);
    if (!res.isSignedIn) {
      throw Exception('Could not establish session while creating profile.');
    }

    final session = await fetchSession();
    if (!session.isSignedIn) throw Exception('Session is not signed in.');
    return session;
  }

  /// Best-effort PendingUser lookup by email.
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