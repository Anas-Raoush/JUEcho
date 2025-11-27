import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/features/auth/data/auth_repository.dart';
import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';

/// Screen that handles registration of a new "general" user.
///
/// Responsibilities:
/// - Collect first name, last name, JU email, and password.
/// - Validate all fields locally.
/// - Call [AuthRepository.signUpGeneral] to create the Cognito user and
///   store a PendingUser row with the user's names.
/// - Navigate to [ConfirmCodePage] so the user can confirm their email.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  /// Named route used with Navigator.
  static const routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  /// Default corner radius used for text fields and buttons.
  static const double radius = 8;

  /// Form key used to validate all sign-up inputs.
  final _formKey = GlobalKey<FormState>();

  /// Text controllers for each input.
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  /// Indicates whether the sign-up process is in progress.
  ///
  /// Used to:
  /// - disable the "Sign up" button
  /// - show a loading spinner instead of the button label
  bool _isLoading = false;

  /// Holds any error message to show above the form.
  String? _error;

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks.
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// Main handler for the "Sign up" button.
  ///
  /// Flow:
  /// 1. Validate all form inputs.
  /// 2. Call [AuthRepository.signUpGeneral] to:
  ///    - create Cognito user
  ///    - create PendingUser in Dynamo
  /// 3. On success, navigate to [ConfirmCodePage] with all needed arguments.
  /// 4. On [AuthException], map specific issues (username exists, weak password)
  ///    to clear, user-friendly messages.
  Future<void> _onSignup() async {
    // 1) Run all validators defined in the Form.
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 2) Capture trimmed values from text controllers.
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      // 3) Call repository to sign up in Cognito + create PendingUser.
      await AuthRepository.signUpGeneral(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;

      // 4) Navigate to ConfirmCodePage so user can enter verification code.
      Navigator.pushNamed(
        context,
        ConfirmCodePage.routeName,
        arguments: ConfirmCodeArgs(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        ),
      );
    } on AuthException catch (e) {
      // Map common auth exceptions to friendly error copy.
      String message;

      if (e is UsernameExistsException) {
        message =
        'An account with this email already exists.\nPlease sign in instead, '
            'or use “Forgot password” if you can’t access it.';
      } else if (e is InvalidPasswordException) {
        message =
        'Password does not meet policy.\nIt must be at least 8 characters '
            'and include uppercase, lowercase, number and symbol.';
      } else {
        // Fallback to the message provided by the SDK.
        message = e.message;
      }

      setState(() => _error = message);
    } catch (e) {
      // Any other unexpected error.
      setState(() => _error = 'Sign up failed. Please try again later.');
    } finally {
      if (mounted) {
        // Ensure loading state always resets.
        setState(() => _isLoading = false);
      }
    }
  }

  /// Navigates back to the login screen.
  ///
  /// Uses [Navigator.pop] because login is expected to be the previous page.
  void _onGoToLogin() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Reusable header widget to show logo + title.
                const AuthLogoHeader(
                  title: 'Sign up',
                  spacingBelowLogo: 32,
                  spacingBelowTitle: 24,
                ),

                // Shows error message (if any) in red text.
                ErrorMessage(error: _error),

                /// The main sign-up form (first name, last name, email, passwords).
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('First Name'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Last Name'),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Enter your University Email',
                        ),
                        validator: validateJUEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration('Enter your password'),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value!.length < 8) {
                            return 'Password should be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordCtrl,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration:
                        _inputDecoration('Confirm your password'),
                        validator: (value) {
                          if ((value ?? '').isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // "Sign up" button with loading state
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radius),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                              : const Text('Sign up'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // "Already have an account? Sign in" row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkText,
                            ),
                          ),
                          GestureDetector(
                            onTap: _onGoToLogin,
                            child: Text(
                              " Sign in",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                AppColors.primary,
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

  /// Reusable InputDecoration builder for all fields on the sign-up page.
  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(
        color: AppColors.primary,
        width: 1.7,
      ),
    ),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
