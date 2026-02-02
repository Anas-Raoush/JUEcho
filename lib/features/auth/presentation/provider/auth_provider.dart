import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// High-level authentication state for the application:
/// - unknown  -> app just launched; session state has not been resolved yet
/// - signedOut -> no authenticated session available
/// - signedIn  -> authenticated session available (role determined separately)
enum AuthStatus { unknown, signedOut, signedIn }

/// AuthProvider
///
/// Global authentication state holder exposed via Provider.
///
/// Owns and exposes:
/// - current authentication state (AuthStatus)
/// - admin flag derived from Cognito groups claim
/// - cached user ProfileData loaded once on bootstrap/sign-in
/// - last error message for UI consumption
///
/// Intended usage:
/// - SplashPage calls bootstrap() once to restore session and load profile.
/// - LoginPage calls signIn() and routes based on isAdmin.
/// - Any page can read profile/userId/fullName without refetching.
///
/// Design approach:
/// - Keeps Amplify/AuthRepository calls out of UI widgets.
/// - Caches profile to reduce repeated network calls.
/// - Relies on exceptions for flow control in sign-in/confirmation flows.
class AuthProvider extends ChangeNotifier {
  // ---------------- Private state ----------------

  AuthStatus _status = AuthStatus.unknown;
  bool _isAdmin = false;
  ProfileData? _profile;
  String? _error;

  // ---------------- Public getters ----------------

  AuthStatus get status => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get isAdmin => _isAdmin;
  ProfileData? get profile => _profile;
  String? get error => _error;

  /// Derived display name from cached profile.
  /// Returns "User" when profile is missing or name is empty.
  String get fullName {
    final p = _profile;
    if (p == null) return 'User';
    final name = '${p.firstName} ${p.lastName}'.trim();
    return name.isEmpty ? 'User' : name;
  }

  /// Convenience accessor for user identifier used by AppSync models.
  String? get userId => _profile?.userId;

  // ---------------- Session bootstrap ----------------

  /// Restores an existing Cognito session and caches the user's profile.
  ///
  /// Flow:
  /// - fetch current Cognito session
  /// - if not signed in:
  ///   -> clear local state and mark signedOut
  /// - if signed in:
  ///   -> derive admin role from session claims
  ///   -> mark signedIn
  ///   -> load profile data once
  ///   -> notify listeners
  ///
  /// Failure handling:
  /// - Any error results in signedOut state to keep routing safe.
  Future<void> bootstrap() async {
    _error = null;

    try {
      final session =
      await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      if (!session.isSignedIn) {
        _clearAuthState(signedIn: false);
        return;
      }

      _isAdmin = AuthRepository.isAdminFromSession(session);
      _status = AuthStatus.signedIn;

      _profile = await AuthRepository.fetchCurrentProfileData();

      notifyListeners();
    } catch (e) {
      safePrint('bootstrap error: $e');
      _error = 'Could not restore session.';
      _clearAuthState(signedIn: false);
    }
  }

  // ---------------- Authentication actions ----------------

  /// Signs in the user and loads profile state.
  ///
  /// Flow:
  /// - AuthRepository.signIn(email, password) -> Cognito session
  /// - derive isAdmin from session
  /// - set signedIn status
  /// - fetch and cache ProfileData
  /// - notify listeners
  ///
  /// Error handling:
  /// - UserNotConfirmedException -> rethrow for UI to route to confirmation screen
  /// - NetworkException -> rethrow for UI to show network state
  /// - AuthException -> map to user-facing message, clear local state, rethrow
  /// - Other exceptions -> generic message, clear local state, rethrow
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;

    try {
      final session =
      await AuthRepository.signIn(email: email, password: password);

      _isAdmin = AuthRepository.isAdminFromSession(session);
      _status = AuthStatus.signedIn;

      _profile = await AuthRepository.fetchCurrentProfileData();

      notifyListeners();
      return;
    } on UserNotConfirmedException {
      rethrow;
    } on NetworkException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      if (msg.contains('incorrect username or password') ||
          (msg.contains('password') && msg.contains('incorrect'))) {
        _error = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('user does not exist') ||
          msg.contains('user not found')) {
        _error = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('too many') && msg.contains('attempts')) {
        _error = 'Too many failed attempts. Please wait a moment and try again.';
      } else {
        _error = 'Sign in failed. Please try again later.';
      }

      notifyListeners();
      _clearAuthState(signedIn: false);
      rethrow;
    } catch (e) {
      safePrint('signIn error: $e');
      _error = 'Sign in failed. Please try again.';
      _clearAuthState(signedIn: false);
      notifyListeners();
      rethrow;
    }
  }

  /// Registers a new general user via AuthRepository.
  /// The UI is responsible for routing to confirmation screen afterwards.
  Future<void> signUpGeneral({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _error = null;

    try {
      await AuthRepository.signUpGeneral(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    } catch (e) {
      safePrint('signUpGeneral error: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Confirms email verification and creates the Users profile.
  ///
  /// Expected UI flow:
  /// - confirmSignUp(email, code)
  /// - createProfileAfterConfirmation(email, password, firstName, lastName)
  /// - provider clears state because repository signs out after profile creation
  Future<void> confirmAndCreateProfile({
    required String email,
    required String code,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _error = null;

    try {
      await AuthRepository.confirmSignUp(email: email, code: code);

      await AuthRepository.createProfileAfterConfirmation(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      _clearAuthState(signedIn: false);
    } catch (e) {
      safePrint('confirmAndCreateProfile error: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Resends signup verification code through AuthRepository.
  Future<void> resendSignUpCode(String email) async {
    try {
      await AuthRepository.resendSignUpCode(email);
    } catch (e) {
      safePrint('resendSignUpCode error: $e');
      rethrow;
    }
  }

  /// Starts forgot password flow (sends a reset code).
  Future<void> startForgotPassword(String email) async {
    try {
      await AuthRepository.startForgotPassword(email);
    } catch (e) {
      safePrint('startForgotPassword error: $e');
      rethrow;
    }
  }

  /// Confirms forgot password (code + new password).
  Future<void> confirmForgotPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      await AuthRepository.confirmForgotPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
    } catch (e) {
      safePrint('confirmForgotPassword error: $e');
      rethrow;
    }
  }

  /// Signs out and clears local state.
  /// Local state is cleared even if remote sign out fails.
  Future<void> signOut() async {
    _error = null;

    try {
      await AuthRepository.signOut();
    } catch (e) {
      safePrint('signOut error: $e');
    } finally {
      _clearAuthState(signedIn: false);
    }
  }

  // ---------------- Profile helpers ----------------

  /// Updates cached profile name without refetching from backend.
  /// Intended for immediate UI consistency after a profile update operation.
  void updateLocalNames({required String firstName, required String lastName}) {
    final p = _profile;
    if (p == null) return;

    _profile = ProfileData(
      userId: p.userId,
      email: p.email,
      role: p.role,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );

    notifyListeners();
  }

  // ---------------- Internal state reset ----------------

  /// Clears locally cached auth state.
  ///
  /// When signedIn is false:
  /// - clears profile cache
  /// - resets admin flag
  /// - sets status signedOut
  /// - notifies listeners
  void _clearAuthState({required bool signedIn}) {
    _profile = null;
    _isAdmin = false;
    _status = signedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
    notifyListeners();
  }
}