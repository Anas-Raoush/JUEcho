import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/responsive_scaffold.dart';

import 'package:juecho/features/auth/presentation/pages/confirm_code_page.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';

/// Screen that handles registration of a new "general" user.
///
/// Responsibilities:
/// - Collect first name, last name, JU email, and password.
/// - Validate all fields locally.
/// - Call AuthProvider.signUpGeneral() to:
///   - create Cognito user
///   - create PendingUser record
/// - Navigate to ConfirmCodePage on success.
///
/// Responsive behavior:
/// - Constrains width (maxWidth: 520) for tablet/web readability.
/// - Uses a 2-column layout for First/Last name on wider screens (>= 600px).
///
/// Note:
/// - Only layout changed to responsive.
/// - Signup logic and provider calls are untouched.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  /// Named route used with Navigator.
  static const routeName = '/signup';

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  static const double radius = 8;

  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  /// Primary sign-up handler.
  ///
  /// Flow:
  /// 1) Validate form
  /// 2) AuthProvider.signUpGeneral()
  /// 3) Navigate to ConfirmCodePage with required args
  Future<void> _onSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      await context.read<AuthProvider>().signUpGeneral(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (!mounted) return;

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
        message = e.message;
      }

      setState(() => _error = message);
    } catch (_) {
      setState(() => _error = 'Sign up failed. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigate back to login page (previous route).
  void _onGoToLogin() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    // Screen-based breakpoint (NOT affected by maxWidth constraints).
    final screenW = MediaQuery.of(context).size.width;
    final twoColumn = screenW >= 600;

    return ResponsiveScaffold(
      maxWidth: 520,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AuthLogoHeader(
            title: 'Sign up',
            spacingBelowLogo: 32,
            spacingBelowTitle: 24,
          ),

          ErrorMessage(error: _error),

          Form(
            key: _formKey,
            child: Column(
              children: [
                // First + Last name in one row on wider screens
                if (twoColumn)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
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
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
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
                      ),
                    ],
                  )
                else ...[
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
                ],

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Enter your University Email'),
                  validator: validateJUEmail,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration('Enter your password'),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Please enter a password';
                    if (value!.length < 8) return 'Password should be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration('Confirm your password'),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Please confirm your password';
                    if (value != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
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
                      child: const Text(
                        " Sign in",
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

  /// Reusable input decoration builder.
  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}