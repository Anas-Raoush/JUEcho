import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// Simple in-memory model representing the signed-in user's profile data.
///
/// Fields:
/// - [userId]    : unique identifier (Cognito user sub / app userId)
/// - [email]     : JU email used for authentication
/// - [firstName] : user's first name
/// - [lastName]  : user's last name
/// - [role]      : user role label (e.g., "admin" / "general")
///
/// Usage:
/// - Cached inside AuthProvider as `profile`.
/// - Used by UI to display the user's name/email without refetching.
class ProfileData {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  const ProfileData({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  /// Builds a ProfileData object from a JSON-like map (e.g., GraphQL response).
  ///
  /// Safety:
  /// - Uses empty string fallback for missing keys.
  /// - Trims all string values to prevent whitespace bugs.
  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userId: (json['userId'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      firstName: (json['firstName'] as String? ?? '').trim(),
      lastName: (json['lastName'] as String? ?? '').trim(),
      role: (json['role'] as String? ?? '').trim(),
    );
  }
}

/// ProfileRepository
///
/// Data access layer for profile-related operations.
///
/// Responsibilities:
/// - Update basic profile fields in the backend (GraphQL mutation).
/// - Update Cognito password (uses Amplify.Auth.updatePassword).
///
/// Notes:
/// - `updateNames` fetches the current user's ID from Cognito session.
/// - This repository does NOT handle UI state (loading/errors/snackbars).
class ProfileRepository {
  /// GraphQL mutation document for updating a user's profile record.
  ///
  /// Expected backend schema:
  /// - UpdateUserInput contains userId + editable fields
  /// - updateUser returns the updated user's userId
  static const String _updateUserMutation = r'''
    mutation UpdateUser($input: UpdateUserInput!) {
      updateUser(input: $input) {
        userId
      }
    }
  ''';

  /// Updates first/last name in the backend Users table using GraphQL.
  ///
  /// Steps:
  /// 1) Fetch CognitoAuthSession to get the current user sub (userId).
  /// 2) Execute GraphQL mutation with (userId, firstName, lastName).
  /// 3) If GraphQL returns errors -> throw an exception.
  ///
  /// Throws:
  /// - Exception('Failed to save profile') when GraphQL returns errors.
  /// - Any Amplify/API errors that occur during the request.
  static Future<void> updateNames({
    required String firstName,
    required String lastName,
  }) async {
    final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
    final userId = session.userSubResult.value;

    final req = GraphQLRequest<String>(
      document: _updateUserMutation,
      variables: {
        'input': {
          'userId': userId,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
        },
      },
    );

    final res = await Amplify.API.mutate(request: req).response;

    if (res.errors.isNotEmpty) {
      safePrint('UpdateUser errors: ${res.errors}');
      throw Exception('Failed to save profile');
    }
  }

  /// Updates the currently signed-in user's password in Cognito.
  ///
  /// Requirements:
  /// - User must be signed in.
  /// - oldPassword must match the current password.
  /// - newPassword must satisfy the configured password policy.
  ///
  /// Throws:
  /// - AuthNotAuthorizedException (old password wrong)
  /// - InvalidPasswordException (new password fails policy)
  /// - LimitExceededException (rate limiting / too many attempts)
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Amplify.Auth.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}