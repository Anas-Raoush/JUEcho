import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/profile/data/profile_repository.dart';

/// High-level auth state for the whole app.
///
/// - [unknown] : app just started and we haven't checked the session yet.
/// - [signedOut]: user is not authenticated.
/// - [signedIn] : user is authenticated (may be admin or general user).
enum AuthStatus { unknown, signedOut, signedIn }

/// Global authentication/state holder using Provider.
///
/// This class is the single source of truth for:
/// - whether the user is signed in or not
/// - whether the user is admin
/// - the cached user profile (ProfileData)
/// - the last error message (if any)
///
/// Typical usage:
/// - SplashPage calls [bootstrap()] once at startup to restore session.
/// - LoginPage calls [signIn()] and then navigates depending on [isAdmin].
/// - ProfilePage can call [updateLocalNames] after a successful name update.
class AuthProvider extends ChangeNotifier {
  // ---------------- Private state ----------------

  /// Current authentication status.
  AuthStatus _status = AuthStatus.unknown;

  /// Whether the signed-in user is admin (derived from Cognito groups/claims).
  bool _isAdmin = false;

  /// Cached profile loaded once after login/bootstrap.
  /// This avoids re-fetching profile on every page.
  ProfileData? _profile;

  /// Last error message to display in UI (optional).
  String? _error;

  // ---------------- Getters (read-only public state) ----------------

  /// App auth status (unknown/signedOut/signedIn).
  AuthStatus get status => _status;

  /// Convenience flag for signed-in check.
  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// Role flag (admin vs general).
  bool get isAdmin => _isAdmin;

  /// Cached profile for current user.
  ProfileData? get profile => _profile;

  /// Last stored error (if any).
  String? get error => _error;

  /// Friendly display name used across UI.
  /// Falls back to "User" if profile is not ready or name is empty.
  String get fullName {
    final p = _profile;
    if (p == null) return 'User';
    final name = '${p.firstName} ${p.lastName}'.trim();
    return name.isEmpty ? 'User' : name;
  }

  /// Convenience getter (used often for API calls).
  String? get userId => _profile?.userId;

  // ---------------- Core lifecycle ----------------

  /// Called once from SplashPage to restore a session and load profile.
  ///
  /// What it does:
  /// 1) Fetch current Cognito session.
  /// 2) If not signed in -> clear local state.
  /// 3) If signed in -> determine admin role + load profile once.
  ///
  /// Notes:
  /// - This method caches the profile in-memory (in this provider).
  /// - Any UI listening to this provider will rebuild after [notifyListeners].
  Future<void> bootstrap() async {
    _error = null;

    try {
      // Ask Amplify (Cognito) for the current auth session.
      final session = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;

      // If the session is not signed in, reset all local auth state.
      if (!session.isSignedIn) {
        _clearAuthState(signedIn: false);
        return;
      }

      // Determine role (admin/general) from the session claims/groups.
      _isAdmin = AuthRepository.isAdminFromSession(session);

      // Update state to signed in.
      _status = AuthStatus.signedIn;

      // Load profile ONCE at app start and keep it cached.
      _profile = await AuthRepository.fetchCurrentProfileData();

      // Notify UI that auth/profile state is ready.
      notifyListeners();
    } catch (e) {
      safePrint('bootstrap error: $e');
      _error = 'Could not restore session.';

      // If anything fails, treat as signed out to keep routing safe.
      _clearAuthState(signedIn: false);
    }
  }

  // ---------------- Auth actions ----------------

  /// Signs in the user using email and password.
  ///
  /// Responsibilities:
  /// - Perform authentication via [AuthRepository.signIn] (Cognito).
  /// - Determine the user's role (admin or general).
  /// - Load and cache the user's profile in memory.
  /// - Update global authentication state.
  /// - Map authentication errors to user-friendly messages.
  ///
  /// Behavior:
  /// - On success:
  ///   - Sets auth status to signed in.
  ///   - Determines admin role.
  ///   - Loads user profile.
  ///   - Notifies listeners.
  /// - On [UserNotConfirmedException]:
  ///   - Rethrows so the UI can handle confirmation flow.
  /// - On [NetworkException]:
  ///   - Rethrows so the UI can show a network error.
  /// - On [AuthException]:
  ///   - Maps Cognito error messages to readable UI messages.
  ///   - Clears local auth state.
  ///   - Rethrows for the UI to react.
  /// - On any other error:
  ///   - Clears local auth state.
  ///   - Throws a generic sign-in failure.
  ///
  /// Notes:
  /// - This method uses exceptions for flow control.
  /// - UI must handle navigation and error presentation.
  /// - This method does NOT perform navigation.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _error = null;

    try {
      // Perform sign-in using repository (Cognito).
      final session = await AuthRepository.signIn(email: email, password: password);

      // Determine role (admin/general).
      _isAdmin = AuthRepository.isAdminFromSession(session);

      // Mark state as signed in.
      _status = AuthStatus.signedIn;

      // Load profile after login.
      _profile = await AuthRepository.fetchCurrentProfileData();

      // Notify UI to rebuild.
      notifyListeners();
      return;
    } on UserNotConfirmedException {
      // Let the caller handle this (navigate to confirmation flow).
      rethrow;
    } on NetworkException{
      // Let the caller handle this.
      rethrow;
    } on AuthException catch (e) {
      // Cognito/Auth-specific errors (wrong password, user not found, etc.).
      final msg = e.message.toLowerCase();

      if (msg.contains('incorrect username or password') ||
          (msg.contains('password') && msg.contains('incorrect'))) {
        _error = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('user does not exist') ||
          msg.contains('user not found')) {
        _error = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('too many') && msg.contains('attempts')) {
        _error =
        'Too many failed attempts. Please wait a moment and try again.';
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

  /// Sign up a GENERAL user (not admin).
  ///
  /// This triggers Cognito sign-up and stores a confirmation code flow.
  /// The UI should navigate the user to confirm the code after this.
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

  /// Confirm sign-up using code, then create user profile.
  ///
  /// Typical flow:
  /// 1) confirmSignUp(email, code)
  /// 2) createProfileAfterConfirmation(...)
  /// 3) clear local state (repo intentionally signs out after profile creation)
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

      // Repo flow: sign out after profile creation so user signs in normally.
      _clearAuthState(signedIn: false);
    } catch (e) {
      safePrint('confirmAndCreateProfile error: $e');
      _error = e.toString();
      rethrow;
    }
  }

  /// Resend the sign-up confirmation code.
  Future<void> resendSignUpCode(String email) async {
    try {
      await AuthRepository.resendSignUpCode(email);
    } catch (e) {
      safePrint('resendSignUpCode error: $e');
      rethrow;
    }
  }

  /// Start forgot password flow (sends reset code).
  Future<void> startForgotPassword(String email) async {
    try {
      await AuthRepository.startForgotPassword(email);
    } catch (e) {
      safePrint('startForgotPassword error: $e');
      rethrow;
    }
  }

  /// Confirm forgot password flow (code + new password).
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

  /// Signs out from Cognito and clears all local cached auth/profile state.
  Future<void> signOut() async {
    _error = null;

    try {
      await AuthRepository.signOut();
    } catch (e) {
      safePrint('signOut error: $e');
      // Even if sign out fails remotely, we still clear local state.
    } finally {
      _clearAuthState(signedIn: false);
    }
  }

  // ---------------- Profile state helpers ----------------

  /// Updates the cached profile locally (in-memory) without re-fetching.
  ///
  /// Use this after a successful profile update (e.g., updateNames).
  /// This keeps UI consistent instantly.
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

  // ---------------- Internal helpers ----------------

  /// Resets local auth state and notifies listeners.
  ///
  /// If [signedIn] is false:
  /// - clears profile
  /// - clears admin flag
  /// - sets status to signedOut
  void _clearAuthState({required bool signedIn}) {
    _profile = null;
    _isAdmin = false;
    _status = signedIn ? AuthStatus.signedIn : AuthStatus.signedOut;
    notifyListeners();
  }
}