import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:amplify_flutter/amplify_flutter.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/responsive_scaffold.dart';

import 'package:juecho/features/Home/presentation/pages/admin_home_page.dart';
import 'package:juecho/features/Home/presentation/pages/general_home_page.dart';
import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:juecho/features/auth/presentation/pages/signup_page.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';

/// Login screen for the app.
///
/// Responsibilities:
/// - Validate JU email + password.
/// - Call AuthProvider.signIn().
/// - Handle unconfirmed users (redirect to ConfirmCodePage).
/// - Navigate to AdminHomePage / GeneralHomePage based on admin flag.
///
/// Note:
/// - This file only changes layout to be responsive.
/// - Sign-in functionality is untouched.
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

  /// Controller for email input.
  final _emailCtrl = TextEditingController();

  /// Controller for password input.
  final _passwordCtrl = TextEditingController();

  /// Indicates whether a sign-in request is currently in progress.
  bool _isSubmitting = false;

  /// Holds a user-facing error message displayed above the form.
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Handles the case where the user is not confirmed in Cognito.
  ///
  /// Behavior:
  /// - Resends sign-up code (best effort).
  /// - Shows a SnackBar.
  /// - Navigates to ConfirmCodePage with email + password.
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
          'Your email is not verified yet. We sent you a new verification code.',
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

  /// Main sign-in handler.
  ///
  /// Flow:
  /// 1) Validate form
  /// 2) Call AuthProvider.signIn()
  /// 3) If ok -> route to admin/general home
  /// 4) If UserNotConfirmedException -> route to confirm code
  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final auth = context.read<AuthProvider>();

    try {
      final ok = await auth.signIn(email: email, password: password);

      if (!ok) {
        setState(() => _error = 'Invalid email or password');
        return;
      }

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        auth.isAdmin ? AdminHomePage.routeName : GeneralHomePage.routeName,
      );
    } on UserNotConfirmedException {
      await _handleUnconfirmedUser(email: email, password: password);
    } on AuthException catch (e) {
      // Keep same mapping behavior you already had.
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
      safePrint('Generic sign-in error: $e');
      setState(() => _error = 'Sign in failed. Please try again later.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Navigate to forgot password page.
  void _onForgotPassword() {
    Navigator.pushNamed(context, ForgotPasswordPage.routeName);
  }

  /// Navigate to signup page.
  void _onGoToSignup() {
    Navigator.pushNamed(context, SignupPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(

      // Auth forms should not stretch too wide.
      maxWidth: 520,

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// Logo + title block (reusable).
          const AuthLogoHeader(
            title: 'Sign in',
            spacingBelowLogo: 25,
            spacingBelowTitle: 24,
          ),

          /// User-facing error text.
          ErrorMessage(error: _error),

          /// Email + password form.
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
                    if ((value ?? '').isEmpty) return 'Please enter your password';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _onForgotPassword,
                    child: Text(
                      'Forgot password',
                      style: TextStyle(fontSize: 13, color: AppColors.gray),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                      child: const Text(
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
    );
  }

  /// Builds a consistent InputDecoration for all fields.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      errorMaxLines: 2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}