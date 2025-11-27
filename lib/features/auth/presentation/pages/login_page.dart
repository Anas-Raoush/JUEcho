import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/features/Home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/Home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juecho/features/auth/presentation/pages/signup_page.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';



/// Login screen for the app.
///
/// Responsibilities:
/// - Validate JU email + password.
/// - Call Cognito sign-in (including "already signed in" retry handling).
/// - Handle unconfirmed users (redirect to ConfirmCodePage).
/// - Decide whether the user is an admin or general user based on JWT groups.
/// - Navigate to the corresponding home page (AdminHomePage / GeneralHomePage).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Named route used with Navigator.pushNamed.
  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Form key used to validate the email + password form.
  final _formKey = GlobalKey<FormState>();

  /// Controller for the email TextFormField.
  final _emailCtrl = TextEditingController();

  /// Controller for the password TextFormField.
  final _passwordCtrl = TextEditingController();

  /// Indicates whether a sign-in request is currently in progress.
  ///
  /// Used to:
  /// - disable the sign-in button
  /// - show a CircularProgressIndicator instead of "Sign in" text
  bool _isSubmitting = false;

  /// Holds the current human-readable error message shown above the form.
  String? _error;

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks.
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Internal helper that wraps [Amplify.Auth.signIn] and automatically handles
  /// the "already signed in" case by signing out and retrying once.
  ///
  /// Returns:
  ///   - The [SignInResult] from the final sign-in attempt.
  ///
  /// Throws:
  ///   - [AuthException] for all other kinds of sign-in errors.
  Future _signInWithRetry({
    required String email,
    required String password,
  }) async {
    try {
      // First attempt to sign in with given credentials.
      return await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();

      // Handle "already signed in" by clearing old session and retrying once
      if (msg.contains('already') && msg.contains('signed in')) {
        safePrint('User already signed in. Signing out and retrying...');

        try {
          await Amplify.Auth.signOut();
        } catch (signOutError) {
          safePrint('signOut failed before retry: $signOutError');
        }

        // Retry once after sign-out; if this fails, let it bubble up.
        return await Amplify.Auth.signIn(
          username: email,
          password: password,
        );
      }

      // For all other auth errors, bubble up to the caller.
      rethrow;
    }
  }

  /// Handles the case where the user exists in Cognito but is not yet confirmed.
  ///
  /// Behavior:
  /// - Requests a new sign-up confirmation code from Cognito.
  /// - Shows a SnackBar informing the user.
  /// - Navigates to [ConfirmCodePage] with the email and password so they can
  ///   complete verification and profile creation.
  Future<void> _handleUnconfirmedUser({
    required String email,
    required String password,
  }) async {
    try {
      await Amplify.Auth.resendSignUpCode(username: email);
      safePrint('resendSignUpCode: success');
    } catch (e) {
      safePrint('resendSignUpCode failed: $e');
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your email is not verified yet. '
              'We sent you a new verification code.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushNamed(
      context,
      ConfirmCodePage.routeName,
      arguments: ConfirmCodeArgs(email: email, password: password),
    );
  }

  /// Main sign-in handler for the "Sign in" button.
  ///
  /// Flow:
  /// 1. Validate form (email + password).
  /// 2. Call [_signInWithRetry] to sign in the user.
  /// 3. If Cognito indicates `confirmSignUp` step -> call [_handleUnconfirmedUser].
  /// 4. If `isSignedIn` is still false -> show generic failure message.
  /// 5. If signed in:
  ///    - Fetch [CognitoAuthSession]
  ///    - Use [AuthRepository.isAdminFromSession] to detect admin group
  ///    - Navigate to [AdminHomePage] or [GeneralHomePage].
  ///
  /// Errors:
  /// - [UserNotConfirmedException] -> handled by _handleUnconfirmedUser.
  /// - Other [AuthException] -> mapped to user-friendly messages.
  /// - Generic unknown error -> "Sign in failed. Please try again later."
  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      // 1) Try to sign in (with automatic "already signed in" retry)
      final result = await _signInWithRetry(email: email, password: password);

      // 2) Handle "unconfirmed user" from nextStep
      final signInStep = result.nextStep.signInStep;
      if (!result.isSignedIn && signInStep == AuthSignInStep.confirmSignUp) {
        await _handleUnconfirmedUser(email: email, password: password);
        return;
      }

      // 3) If still not signed in and no special step -> generic failure
      if (!result.isSignedIn) {
        setState(() {
          _error =
          'Sign in was not completed. Please check your email and password.';
        });
        return;
      }

      // 4) Signed in -> check if admin or general
      final session =
      await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      final isAdmin = AuthRepository.isAdminFromSession(session);

      if (!mounted) return;

      // Navigate to appropriate home page based on Cognito group membership.
      Navigator.pushReplacementNamed(
        context,
        isAdmin ? AdminHomePage.routeName : GeneralHomePage.routeName,
      );
    } on UserNotConfirmedException {
      // Extra safety: some flows may throw this instead of using nextStep.
      await _handleUnconfirmedUser(email: email, password: password);
    } on AuthException catch (e) {
      // Handle various common Cognito error messages explicitly
      final msg = e.message.toLowerCase();
      String uiMessage;

      if (msg.contains('incorrect username or password') ||
          (msg.contains('password') && msg.contains('incorrect'))) {
        uiMessage = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('user does not exist') ||
          msg.contains('user not found')) {
        uiMessage = 'Incorrect email or password. Please try again.';
      } else if (msg.contains('too many') && msg.contains('attempts')) {
        uiMessage =
        'Too many failed attempts. Please wait a moment and try again.';
      } else {
        uiMessage = 'Sign in failed. Please try again later.';
      }

      setState(() => _error = uiMessage);
    } catch (e) {
      // Non-auth specific error (network, unexpected failure, etc.)
      safePrint('Generic sign-in error: $e');
      setState(() {
        _error = 'Sign in failed. Please try again later.';
      });
    } finally {
      if (mounted) {
        // Clear submitting state so button becomes clickable again.
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Navigates to the "Forgot password" screen.
  void _onForgotPassword() {
    Navigator.pushNamed(context, ForgotPasswordPage.routeName);
  }

  /// Navigates to the "Sign up" screen.
  void _onGoToSignup() {
    Navigator.pushNamed(context, SignupPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Reusable header widget to show logo + title.
                const AuthLogoHeader(
                  title: 'Sign in',
                  spacingBelowLogo: 25,
                  spacingBelowTitle: 24,
                ),

                /// If _error is not null, this widget shows the message in red.
                ErrorMessage(error: _error),

                /// Wrap email + password inputs and validation into a Form widget.
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Enter your Email'),
                        validator: validateJUEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration('Enter your password'),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // "Forgot password" text button aligned to the right
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _onForgotPassword,
                          child: Text(
                            'Forgot password',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Main "Sign in" button with loading indicator
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                              : const Text('Sign in'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "Don't have an account? Register now" row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          GestureDetector(
                            onTap: _onGoToSignup,
                            child: Text(
                              "Register now",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to build a consistent InputDecoration for all fields.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 1.7,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
