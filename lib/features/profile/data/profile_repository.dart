import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';


/// Simple data model for the user profile.
class ProfileData {
  final String? userId;
  final String email;
  final String firstName;
  final String lastName;

  const ProfileData({
    this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      userId: json['userId'] as String?,
      email: (json['email'] as String? ?? '').trim(),
      firstName: (json['firstName'] as String? ?? '').trim(),
      lastName: (json['lastName'] as String? ?? '').trim(),
    );
  }
}

class ProfileRepository {
  // ---------- GraphQL documents ----------

  static const String _updateUserMutation = r'''
    mutation UpdateUser($input: UpdateUserInput!) {
      updateUser(input: $input) {
        userId
      }
    }
  ''';

   /// Update only first & last name for current user.
  static Future<void> updateNames({
    required String firstName,
    required String lastName,
  }) async {
    final session =
    await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
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

  /// Change password using Cognito.
  ///
  /// UI is responsible for catching [NotAuthorizedException],
  /// [InvalidPasswordException], [LimitExceededException], etc.
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