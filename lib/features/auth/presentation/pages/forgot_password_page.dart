import 'package:amplify_auth_cognito/amplify_auth_cognito.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:juecho/common/constants/app_colors.dart';
import 'package:juecho/common/helper/validators.dart';
import 'package:juecho/common/widgets/error_message.dart';
import 'package:juecho/features/auth/presentation/widgets/responsive_scaffold.dart';
import 'package:juecho/features/auth/presentation/provider/auth_provider.dart';
import 'package:juecho/features/auth/presentation/widgets/auth_logo_header.dart';

/// Password reset screen backed by AWS Cognito.
///
/// Two-step flow:
/// 1) Email -> request reset code (AuthProvider.startForgotPassword)
/// 2) Code + new password -> confirm reset (AuthProvider.confirmForgotPassword)
///
/// UX behavior:
/// - After a code is sent, the UI expands to show code + new password fields.
/// - Email input is disabled in step 2 to keep the flow consistent.
/// - Common Cognito errors are mapped into user-friendly messages.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  /// Step 1: Sends a reset code to the provided email.
  ///
  /// Validation:
  /// - Uses validateJUEmail before calling the provider.
  ///
  /// Behavior:
  /// - On success, transitions the screen to step 2 by setting _codeSent = true.
  /// - Shows a non-enumerating message (does not confirm if email is registered).
  Future<void> _sendCode() async {
    final emailError = validateJUEmail(_emailCtrl.text.trim());
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await context
          .read<AuthProvider>()
          .startForgotPassword(_emailCtrl.text.trim());

      if (!mounted) return;

      setState(() => _codeSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('If this email is registered, a code has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException {
      setState(() =>
      _error = 'Could not send reset code. Please try again in a moment.');
    } catch (_) {
      setState(() =>
      _error = 'Could not send reset code. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Step 2: Confirms password reset using verification code and new password.
  ///
  /// Validation:
  /// - Form validation ensures:
  ///   -> code is 6 digits
  ///   -> new password matches strength policy
  ///
  /// Error handling:
  /// - CodeMismatchException -> incorrect/expired code
  /// - LimitExceededException -> throttling
  /// - Other AuthException -> password policy (generic fallback)
  Future<void> _confirmReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    final email = _emailCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text;

    try {
      await context.read<AuthProvider>().confirmForgotPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully. Please sign in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (e is CodeMismatchException) {
        setState(() {
          _error = 'The verification code is incorrect or has expired.\n'
              'Please check the latest email or tap "Send code" again.';
        });
      } else if (e is LimitExceededException) {
        setState(() => _error =
        'Too many attempts. Please wait a little while and try again.');
      } else {
        setState(() {
          _error = 'Password must be at least 8 characters and include an uppercase letter, '
              'a lowercase letter, a number, and a special character.';
        });
      }
    } catch (_) {
      setState(() => _error = 'Could not update password. Please try again later.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Enforces password policy locally before submitting to Cognito.
  ///
  /// Policy:
  /// - At least 8 characters
  /// - Contains uppercase, lowercase, digit, and special character
  bool _isStrongPassword(String value) {
    final regex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)'
      r'(?=.*[!@#\$%^&*()_\-+=\[{\]};:"\\|,.<>/?]).{8,}$',
    );
    return regex.hasMatch(value);
  }

  /// Validates that the confirmation code is exactly 6 digits.
  bool _isNumericCode(String value) {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(value);
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _codeSent
        ? 'Enter the code sent to your email and your new password.'
        : 'Enter your email and we\'ll send you a reset code.';

    return ResponsiveScaffold(
      maxWidth: 520,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthLogoHeader(
            title: 'Reset your password',
            subtitle: subtitle,
            spacingBelowLogo: 16,
            spacingBelowTitle: 24,
          ),

          ErrorMessage(error: _error),

          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  enabled: !_codeSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Enter your Email'),
                  validator: validateJUEmail,
                ),
                const SizedBox(height: 16),

                if (_codeSent) ...[
                  TextFormField(
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration('Verification code from email'),
                    validator: (value) {
                      final v = (value ?? '').trim();
                      if (v.isEmpty) return 'Please enter the code';
                      if (!_isNumericCode(v)) return 'This code is not valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: true,
                    decoration: _inputDecoration('Enter your new password'),
                    validator: (value) {
                      final v = value ?? '';
                      if (v.isEmpty) return 'Please enter a new password';
                      if (!_isStrongPassword(v)) {
                        return 'Password must be at least 8 characters and include '
                            'an uppercase letter, a lowercase letter, a number, and a special character.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : _codeSent
                        ? _confirmReset
                        : _sendCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        : Text(_codeSent ? 'Update password' : 'Send code'),
                  ),
                ),

                if (_codeSent) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Didn't get a code?"),
                      TextButton(
                        onPressed: _isLoading ? null : _sendCode,
                        child: const Text(
                          "Resend",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Standardized InputDecoration for ForgotPasswordPage fields.
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      label: Text(label),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      errorMaxLines: 3,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}