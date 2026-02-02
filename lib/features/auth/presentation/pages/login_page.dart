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

/// Authentication entry screen for the application.
///
/// Responsibilities:
/// - Collect and validate JU email + password.
/// - Trigger sign-in through AuthProvider (Cognito-backed).
/// - Handle unconfirmed accounts by redirecting to confirmation flow.
/// - Route authenticated users to the correct home screen:
///   -> AdminHomePage for admin users
///   -> GeneralHomePage for general users
///
/// Implementation notes:
/// - UI is responsive via ResponsiveScaffold to keep form width readable on larger screens.
/// - This page does not implement authentication directly; it delegates to AuthProvider.
/// - All navigation is performed only after a successful provider operation.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  /// Route name for Navigator.pushNamed / pushReplacementNamed.
  static const routeName = '/login';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  /// Form key for validation and submission.
  final _formKey = GlobalKey<FormState>();

  /// Controllers for form inputs.
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  /// UI state:
  /// - _isSubmitting disables the button and shows a spinner during sign-in.
  /// - _error renders a user-facing error message at the top of the form.
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Handles "user not confirmed" scenario.
  ///
  /// Flow:
  /// - Best-effort resend of the confirmation code to the provided email.
  /// - Notify user via SnackBar.
  /// - Navigate to ConfirmCodePage, passing email/password so confirmation flow
  ///   can create the app profile after verification if needed.
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

  /// Executes the sign-in flow from the login form.
  ///
  /// Flow:
  /// 1) Validate form inputs.
  /// 2) Call AuthProvider.signIn(email, password).
  /// 3) On success, route based on AuthProvider.isAdmin.
  ///
  /// Error handling:
  /// - UserNotConfirmedException:
  ///   -> resend confirmation code (best effort)
  ///   -> route to ConfirmCodePage
  /// - NetworkException:
  ///   -> show a network error message
  /// - AuthException:
  ///   -> use the provider's mapped user-facing error message
  /// - Any other exception:
  ///   -> show a generic failure message
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
      await auth.signIn(email: email, password: password);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        auth.isAdmin ? AdminHomePage.routeName : GeneralHomePage.routeName,
      );
    } on UserNotConfirmedException {
      await _handleUnconfirmedUser(email: email, password: password);
    } on NetworkException {
      setState(() => _error = 'Sign in failed due to a network error.');
    } on AuthException catch (_) {
      setState(() => _error = auth.error);
    } catch (e) {
      safePrint('Generic sign-in error: $e');
      setState(() => _error = 'Sign in failed. Please try again later.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Routes to ForgotPasswordPage.
  void _onForgotPassword() {
    Navigator.pushNamed(context, ForgotPasswordPage.routeName);
  }

  /// Routes to SignupPage.
  void _onGoToSignup() {
    Navigator.pushNamed(context, SignupPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      /// Keeps auth forms readable on tablet/web by constraining width.
      maxWidth: 520,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthLogoHeader(
            title: 'Sign in',
            spacingBelowLogo: 25,
            spacingBelowTitle: 24,
          ),

          ErrorMessage(error: _error),

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

  /// Standardized InputDecoration for login fields.
  ///
  /// Maintains consistent styling and focused border behavior across the form.
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